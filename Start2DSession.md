# Start 2D Exercise Detection

This guide shows a minimal 2D SMKit session using the completion-based session APIs.

## Implement `SMKitSessionDelegate`

```swift
extension ViewController: SMKitSessionDelegate {
    func captureSessionDidSet(session: AVCaptureSession) {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspect
        view.layer.insertSublayer(previewLayer, at: 0)
    }

    func captureSessionDidStop() {
        // Remove preview layers and reset UI state.
    }

    func handleDetectionData(movementData: MovementFeedbackData?) {
        guard let data = movementData else { return }
        print(data)
    }

    func handlePositionData(
        poseData2D: [Joint: JointData]?,
        poseData3D: [Joint: SCNVector3]?,
        jointAnglesData: [LimbsPairs: Float]?,
        jointGlobalAnglesData: [Limbs: Float]?,
        xyzEulerAngles: [String: SCNVector3]?,
        xyzRelativeAngles: [String: SCNVector3]?
    ) {
        // Render poseData2D into your own skeleton overlay.
    }

    // Optional (default empty implementation). Usually nil for basic 2D sessions.
    func handleAnatomicalAngles(anatomicalAngles: [String: SCNVector3]?) {
    }

    func didCaptureBuffer(
        pixelBuffer: CVPixelBuffer,
        time: CMTime,
        orientation: CGImagePropertyOrientation
    ) {
        // Optional raw frame access.
    }

    // Optional (default empty implementations), for video-file sessions.
    func videoSessionProcessingProgress(progress: Float, processedFrames: Int) {}

    func videoSessionDidFinish() {}

    func handleSessionErrors(error: Error) {
        print("Session error: \(error)")
    }
}
```

## Start A Session

```swift
final class ViewController: UIViewController {
    private var flowManager: SMKitFlowManager?

    func startSession() {
        do {
            let sessionSettings = SMKitSessionSettings(
                phonePosition: .Floor,
                jumpRefPoint: "Hip",
                jumpHeightThreshold: 20,
                userHeight: 180,
                include3D: false,
                camType: .front
            )

            flowManager = try SMKitFlowManager(delegate: self)
            flowManager?.startSession(sessionSettings: sessionSettings) { [weak self] result in
                switch result {
                case .success:
                    self?.startDetection(exercise: "SquatRegular")
                case .failure(let error):
                    print("Failed to start session: \(error)")
                }
            }
        } catch {
            print("Failed to create flow manager: \(error)")
        }
    }

    func startDetection(exercise: String) {
        flowManager?.startDetection(exercise: exercise) { result in
            if case .failure(let error) = result {
                print("Failed to start detection: \(error)")
            }
        }
    }

    func stopDetection() {
        flowManager?.stopDetection { result in
            switch result {
            case .success(let exerciseData):
                print(exerciseData as Any)
            case .failure(let error):
                print("Failed to stop detection: \(error)")
            }
        }
    }

    func stopSession() {
        flowManager?.stopSession { result in
            switch result {
            case .success(let workoutData):
                print(workoutData as Any)
            case .failure(let error):
                print("Failed to stop session: \(error)")
            }
        }
    }
}
```

## Typical Workflow

1. Call `SMKitFlowManager.configure(...)` during app launch.
2. Create `SMKitFlowManager(delegate:)`.
3. Call `startSession(sessionSettings:completion:)`.
4. Start exercise detection from the success callback.
5. Receive live feedback through `SMKitSessionDelegate`.
6. Call `stopDetection(completion:)` for each exercise.
7. Call `stopSession(completion:)` when the workout ends.

## Notes

- 2D joint coordinates are in video-resolution space, not screen coordinates.
- All `SMKitSessionSettings` parameters are optional.
- Pass `phoneMovementCountPreventionEnabled` or `landscapeCamera` to the `SMKitSessionSettings` initializer when your flow needs them. `cameraFps` is a property: set it after creating the settings (`var settings = SMKitSessionSettings(...); settings.cameraFps = 30`).
- `SMKitSessionSettings` arguments must be passed in the initializer's order (for example `include3D:` before `camType:`).
- Use `startVideoSession(url:sessionSettings:fpsLimit:deterministicProcessing:realtimeSequentialProcessing:completion:)` for video-file processing.
