# Specification: Camera Integration for Food Logging

## Overview
This feature adds a camera button to the left of the chat input bar. Tapping this button opens a native camera interface, allowing users to take a photo of their food. Users can then preview, attach, or retake the photo. Once attached, the photo is added to the query, and the user can optionally add text before sending. Additionally, the camera interface will include a button to access the photo gallery.

## Functional Requirements
- **Camera Access:**
  - A camera button with a camera icon must be displayed to the left of the text input field in `ChatInputView`.
  - Tapping the button opens a full-screen camera view using `AVFoundation` to allow for custom UI elements (like the gallery button).
- **Gallery Integration:**
  - Inside the custom camera view, a button must be present to access the photo gallery.
  - This button should display a thumbnail of the most recent photo in the user's library.
  - Tapping this button opens the system `PhotosPicker` to allow selecting existing photos.
- **Photo Capture & Preview:**
  - After taking a photo, the user must be presented with a preview screen.
  - The preview screen must offer "Attach" (or "Use Photo") and "Retake" options.
  - Selecting "Attach" adds the photo to the current input context in `ChatInputView`.
- **Permissions:**
  - Request `AVMediaType.video` (Camera) permission on first use.
  - Request `PHPhotoLibrary` permission to display the recent photo thumbnail.
  - Show an alert if permissions are denied, explaining the necessity.
  - Fallback to Photo Picker or show a disabled state if the camera is unavailable (e.g., Simulator).
- **Input Bar Integration:**
  - The camera button follows the "Liquid Glass" aesthetic.
  - Attached photos should be visible (e.g., as a small thumbnail above or inside the input bar) before sending.
  - Users can type text alongside the attached photo(s).

## Non-Functional Requirements
- **Performance:** Camera startup should be fast (under 1 second).
- **UI/UX:** Transitions between the input bar, camera, and gallery must be smooth. The design must match the existing "Liquid Glass" aesthetic.
- **Privacy:** Only request permissions when the user explicitly initiates the action.

## Acceptance Criteria
- [ ] Tapping the camera button opens a custom camera view.
- [ ] The camera view displays a gallery button with the most recent photo thumbnail.
- [ ] Tapping the gallery button opens the photo picker.
- [ ] Taking a photo shows a preview with "Use/Attach" and "Retake" options.
- [ ] Confirmed photos are visually attached to the input bar area.
- [ ] The user can send a query with just a photo, or a photo + text.
- [ ] Permissions are handled correctly (prompt on first use, alert on denial).
- [ ] Simulator handles camera unavailability gracefully (e.g., opens gallery or shows alert).
