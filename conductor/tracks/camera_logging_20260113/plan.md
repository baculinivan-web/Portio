# Plan: Camera Integration for Food Logging

## Phase 1: Foundation and UI Layout

- [x] Task: Add camera and photo library usage descriptions to `Info.plist` dd8880c
- [x] Task: Update `ChatInputView` to include the camera button to the left of the text field b678ee2
- [ ] Task: Create a placeholder `CameraView` using `ZStack` and `AVFoundation` base classes
- [ ] Task: Conductor - User Manual Verification 'Foundation and UI Layout' (Protocol in workflow.md)

## Phase 2: Custom Camera Interface

- [ ] Task: Implement `CameraManager` (AVFoundation) for capturing photos and handling session
- [ ] Task: Implement `CameraPreview` view to show the live camera feed
- [ ] Task: Implement the Gallery Button in the camera view with the latest photo thumbnail
- [ ] Task: Implement Permission handling for Camera and Photo Library
- [ ] Task: Conductor - User Manual Verification 'Custom Camera Interface' (Protocol in workflow.md)

## Phase 3: Capture, Preview, and Attachment

- [ ] Task: Implement Photo Capture logic and transition to a `PhotoPreviewView`
- [ ] Task: Implement "Attach" and "Retake" logic in `PhotoPreviewView`
- [ ] Task: Update `CalorieTrackerViewModel` (or a new shared state) to manage pending attachments
- [ ] Task: Update `ChatInputView` to display thumbnails of attached photos
- [ ] Task: Conductor - User Manual Verification 'Capture, Preview, and Attachment' (Protocol in workflow.md)

## Phase 4: Integration and Sending

- [ ] Task: Update `addItem` in `ContentView` to pass attached image data to the `ViewModel`
- [ ] Task: Verify that `NutritionService` correctly processes the images via OpenRouter
- [ ] Task: Handle simulator fallback (disable camera/alert)
- [ ] Task: Final Polish: animations for camera presentation and attachment removal
- [ ] Task: Conductor - User Manual Verification 'Integration and Sending' (Protocol in workflow.md)
