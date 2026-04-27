<!-- Product Requirements Document (PRD) -->
# Prototype Flow: Komorebi Film Camera

## Goal
To demonstrate the minimalist navigation and the core experience of capturing, developing, and viewing film.

## Screens Included
1.  **Camera (Capture)**: {{DATA:SCREEN:SCREEN_8}} - The starting point for taking photos.
2.  **Darkroom (Developing)**: {{DATA:SCREEN:SCREEN_12}} - Where photos go after being "taken" to wait for development.
3.  **Gallery (The Roll)**: {{DATA:SCREEN:SCREEN_9}} - The final destination for developed photos.
4.  **Photo Detail**: {{DATA:SCREEN:SCREEN_4}} - Viewing a specific developed photo.

## Interaction Map
*   **Global Navigation (Bottom Bar)**:
    *   Tap **Camera Icon** -> Goes to **Minimal Camera (Capture)** {{DATA:SCREEN:SCREEN_8}}
    *   Tap **Hourglass Icon** -> Goes to **Minimal Darkroom (Developing)** {{DATA:SCREEN:SCREEN_12}}
    *   Tap **Gallery/Photos Icon** -> Goes to **Minimal Gallery (The Roll)** {{DATA:SCREEN:SCREEN_9}}

*   **Specific Transitions**:
    *   **Gallery** {{DATA:SCREEN:SCREEN_9}} -> Tap any photo card -> Goes to **Photo Detail** {{DATA:SCREEN:SCREEN_4}}
    *   **Photo Detail** {{DATA:SCREEN:SCREEN_4}} -> Tap "Back" or "Gallery" -> Returns to **Gallery** {{DATA:SCREEN:SCREEN_9}}
    *   **Camera** {{DATA:SCREEN:SCREEN_8}} -> Tap the shutter button (Orange Circle) -> (Conceptually) adds to Darkroom queue.