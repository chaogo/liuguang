<!-- Product Requirements Document (PRD) -->
# Product Requirements Document (PRD): Komorebi Film Camera

## 1. Product Vision
"A film camera that lets moments develop in time." Komorebi is a minimalist iOS app designed to bring back the intentionality and surprise of analog photography.

## 2. Core Features & User Stories

### A. The 12-Frame Limit
*   **Requirement:** Users are limited to capturing exactly 12 photos per 24-hour cycle.
*   **User Story:** As a photographer, I want a limited number of shots so that I think carefully about every composition.
*   **Logic:** 
    *   Reset the counter every 24 hours from the first photo taken in a batch.
    *   The shutter button disables once the 12th photo is taken.

### B. The Darkroom (Delayed Development)
*   **Requirement:** Photos are not visible immediately. They enter a "Developing" state for 24 hours.
*   **User Story:** As a user, I want to wait for my photos to develop so that I experience the anticipation of seeing my memories later.
*   **Logic:**
    *   Timestamp each capture.
    *   Photos remain in the "Darkroom" tab with a countdown timer.
    *   Push notification alerts the user when a photo is "Developed."

### C. The "Surprise" Film Grain
*   **Requirement:** Each developed photo applies a unique set of film-style filters (grain, light leaks, color shifts).
*   **User Story:** As a user, I want every photo to look unique so that I am surprised by the "physical" quality of the digital image.
*   **Logic:**
    *   Maintain a library of 5-10 film profiles.
    *   Randomly assign a profile and varying intensity of "artifacts" (dust/scratches) upon completion of development.

## 3. Functional Requirements (Technical)
*   **Platform:** iOS (SwiftUI preferred for the minimalist UI).
*   **Local Storage:** Use SwiftData/CoreData to store image metadata and development timestamps.
*   **Camera API:** Custom camera UI overlaying `AVFoundation`.
*   **Image Processing:** Use Core Image filters to apply randomized film aesthetics post-capture.

## 4. Design Guidelines
*   **Typography:** Noto Serif (Elegant, Analog feel).
*   **Color Palette:** #F9F9F7 (Paper White), #FF5722 (International Orange for Shutter).
*   **UI Philosophy:** "The Analog Ghost" — remove all non-essential buttons and text. Focus on the image and the passage of time.