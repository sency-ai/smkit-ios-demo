# Start 2D Exercise Detection

This guide shows a minimal 2D SMKit session using the 1.9.8 async session APIs.

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

    func handleAnatomicalAngles(anatomicalAngles: [String: SCNVector3]?) {
        // Usually nil for basic 2D sessions.
    }

    func didCaptureBuffer(
        pixelBuffer: CVPixelBuffer,
        time: CMTime,
        orientation: CGImagePropertyOrientation
    ) {
        // Optional raw frame access.
    }

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
        do {
            try flowManager?.startDetection(exercise: exercise)
        } catch {
            print("Failed to start detection: \(error)")
        }
    }

    func stopDetection() {
        do {
            let exerciseData = try flowManager?.stopDetection()
            print(exerciseData as Any)
        } catch {
            print("Failed to stop detection: \(error)")
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
6. Call `stopDetection()` for each exercise.
7. Call `stopSession(completion:)` when the workout ends.

## Notes

- 2D joint coordinates are in video-resolution space, not screen coordinates.
- All `SMKitSessionSettings` parameters are optional.
- Use `phoneMovementCountPreventionEnabled`, `cameraFps`, or `landscapeCamera` in `SMKitSessionSettings` when your flow needs them.
- Use `startVideoSession(url:sessionSettings:fpsLimit:deterministicProcessing:)` for video-file processing.
