import Foundation
import UserNotifications

struct ScheduledNotification: Equatable {
    let identifier: String
    let title: String
    let body: String
    let fireDate: Date
}

protocol NotificationService {
    func requestAuthorization() async -> Bool
    func schedule(_ notification: ScheduledNotification) async throws
    func cancel(identifier: String) async
}

final class SystemNotificationService: NotificationService {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func schedule(_ notification: ScheduledNotification) async throws {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: notification.fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: notification.identifier,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    func cancel(identifier: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

final class MockNotificationService: NotificationService {
    var authorized = true
    private(set) var scheduled: [ScheduledNotification] = []
    private(set) var cancelled: [String] = []

    func requestAuthorization() async -> Bool { authorized }

    func schedule(_ notification: ScheduledNotification) async throws {
        scheduled.append(notification)
    }

    func cancel(identifier: String) async {
        cancelled.append(identifier)
        scheduled.removeAll { $0.identifier == identifier }
    }
}
