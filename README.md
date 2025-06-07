# iOS Lip Color Overlay Camera Demo

This project demonstrates how to use **AVFoundation** and **Vision** frameworks to capture live front camera video, detect face landmarks, and overlay lipstick color on the lips in real-time. The UI includes a bottom menu to select different facial features (currently only Lips is implemented).

---

## Features

- Access front camera video feed with proper permissions.
- Use Vision framework to detect face landmarks.
- Precisely draw and fill lips with semi-transparent lipstick color.
- Simple horizontal menu at the bottom for facial feature selection.
- Proper coordinate conversion between Vision normalized points and UIKit coordinates.

---

## Requirements

- iOS 14.0+
- Xcode 14+
- Swift 5+
- Device with a front camera

---

## How to Use

1. Clone or download this repository.
2. Open the Xcode project.
3. Run on a real device (Face landmark detection doesn’t work on the Simulator).
4. Allow camera permissions when prompted.
5. Use the bottom menu to select "Lips" to see the lip color overlay.

---

## Project Structure

- `ViewController.swift`: Main controller handling camera setup, face detection, overlay drawing, and UI.
- Uses `AVCaptureSession` to stream front camera.
- Uses `VNDetectFaceLandmarksRequest` to detect lips.
- Converts Vision normalized points to UIKit coordinates with coordinate flipping.
- Draws lips overlay using `CAShapeLayer` and `UIBezierPath`.

---

## Important Functions

### Camera Permission & Setup

```swift
func checkCameraPermissionAndStart()
func setupCamera()
```
## Face Landmark Detection & Drawing
 ```swift
func captureOutput(_:didOutput:from:)
func drawLips(on:)
func convert(_:faceBoundingBox:)
```

---
## Coordinate Conversion Notes
 - Vision framework returns landmark points normalized to the image with the origin at bottom-left. UIKit uses top-left origin, so the points must be flipped vertically and scaled to the view size.

## Future Improvements
- Implement overlays and color fills for Eyelashes, Eyelid, Chin, and Cheek.

- Add smoother animation transitions when switching features.

- Allow custom lipstick colors.

 - Optimize performance for better FPS.

