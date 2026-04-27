import Foundation
@preconcurrency import AVFoundation
import UIKit

final class AVFoundationCamera: NSObject, PhotoCapturing, @unchecked Sendable {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var currentPosition: AVCaptureDevice.Position = .back
    private let sessionQueue = DispatchQueue(label: "com.liuguang.camera.session")

    private let preview: AVCaptureVideoPreviewLayer
    var previewLayer: CALayer? { preview }

    private var pendingContinuation: CheckedContinuation<CapturedPhoto, Error>?

    override init() {
        self.preview = AVCaptureVideoPreviewLayer(session: session)
        super.init()
        self.preview.videoGravity = .resizeAspectFill
    }

    func requestPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }

    func start() async throws {
        guard await requestPermission() else { throw CaptureError.permissionDenied }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [self] in
                do {
                    try configureIfNeeded()
                    if !session.isRunning { session.startRunning() }
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    func stop() {
        sessionQueue.async { [self] in
            session.stopRunning()
        }
    }

    func flip() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [self] in
                let next: AVCaptureDevice.Position = (currentPosition == .back) ? .front : .back
                session.beginConfiguration()
                do {
                    try swapInput(to: next)
                    session.commitConfiguration()
                    cont.resume()
                } catch {
                    session.commitConfiguration()
                    cont.resume(throwing: error)
                }
            }
        }
    }

    func capture() async throws -> CapturedPhoto {
        try await withCheckedThrowingContinuation { cont in
            sessionQueue.async { [self] in
                guard pendingContinuation == nil else {
                    cont.resume(throwing: CaptureError.captureFailed("capture already in progress"))
                    return
                }
                guard session.isRunning else {
                    cont.resume(throwing: CaptureError.deviceUnavailable)
                    return
                }
                guard let connection = photoOutput.connection(with: .video),
                      connection.isActive, connection.isEnabled else {
                    cont.resume(throwing: CaptureError.deviceUnavailable)
                    return
                }
                pendingContinuation = cont
                let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    private func configureIfNeeded() throws {
        guard session.inputs.isEmpty else { return }
        session.beginConfiguration()

        do {
            session.sessionPreset = .photo
            try swapInput(to: currentPosition)

            guard session.canAddOutput(photoOutput) else {
                session.commitConfiguration()
                throw CaptureError.deviceUnavailable
            }
            session.addOutput(photoOutput)
            session.commitConfiguration()
        } catch {
            session.commitConfiguration()
            throw error
        }
    }

    private func swapInput(to position: AVCaptureDevice.Position) throws {
        guard let device = resolveDevice(preferring: position) else {
            throw CaptureError.deviceUnavailable
        }
        let input = try AVCaptureDeviceInput(device: device)

        let previous = currentInput
        if let previous {
            session.removeInput(previous)
        }
        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
            currentPosition = input.device.position
        } else {
            if let previous, session.canAddInput(previous) {
                session.addInput(previous)
            } else {
                currentInput = nil
            }
            throw CaptureError.deviceUnavailable
        }
    }

    private func resolveDevice(preferring position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            return device
        }
        let opposite: AVCaptureDevice.Position = (position == .back) ? .front : .back
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: opposite) {
            return device
        }
        return AVCaptureDevice.default(for: .video)
    }
}

extension AVFoundationCamera: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        sessionQueue.async { [self] in
            guard let cont = pendingContinuation else { return }
            pendingContinuation = nil

            if let error {
                cont.resume(throwing: CaptureError.captureFailed(error.localizedDescription))
                return
            }
            guard let data = photo.fileDataRepresentation() else {
                cont.resume(throwing: CaptureError.captureFailed("no data"))
                return
            }

            let meta = photo.metadata
            let exif = (meta[kCGImagePropertyExifDictionary as String] as? [String: Any]) ?? [:]
            let iso = (exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int])?.first ?? 400
            let shutter = exif[kCGImagePropertyExifExposureTime as String] as? Double ?? (1.0 / 125.0)
            let aperture = exif[kCGImagePropertyExifFNumber as String] as? Double ?? 2.8

            cont.resume(returning: CapturedPhoto(
                jpegData: data,
                iso: iso,
                shutterDenominator: Int((1.0 / max(shutter, 0.0001)).rounded()),
                aperture: aperture,
                capturedAt: Date()
            ))
        }
    }
}
