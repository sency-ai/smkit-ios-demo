# Start 3D Exercise Detection

Starting a 3D session is similar to starting a 2D session, but `configure` and `SMKitSessionSettings` must enable 3D support.

## Configure With 3D Support

```swift
SMKitFlowManager.configure(
    authKey: "YOUR_KEY",
    shouldSupport3D: true,
    poseEstimation3DMode: .standard,
    poseEstimation3DAccuracy: .solid,
    downloadProgress: { completed, total in
        print("SMKit assets: \(completed)/\(total)")
    }
) {
    // Configuration succeeded.
} onFailure: { error in
    print(error as Any)
}
```

Use `.accurate` for the metric 3D estimator when your app needs it, and `.standard` for the default two-stage 3D pipeline.

## Implement `SMKitSessionDelegate`

```swift
extension ViewController: SMKitSessionDelegate {
    func captureSessionDidSet(session: AVCaptureSession) {
        // Attach AVCaptureVideoPreviewLayer here.
    }

    func captureSessionDidStop() {}

    func handleDetectionData(movementData: MovementFeedbackData?) {}

    func handlePositionData(
        poseData2D: [Joint: JointData]?,
        poseData3D: [Joint: SCNVector3]?,
        jointAnglesData: [LimbsPairs: Float]?,
        jointGlobalAnglesData: [Limbs: Float]?,
        xyzEulerAngles: [String: SCNVector3]?,
        xyzRelativeAngles: [String: SCNVector3]?
    ) {
        // poseData3D is nil when the 3D pose is unavailable or out of range.
        // jointAnglesData, jointGlobalAnglesData, and XYZ angle dictionaries are available when supported.
    }

    func handleAnatomicalAngles(anatomicalAngles: [String: SCNVector3]?) {
        // Optional anatomical angles for 3D analytics.
    }

    func didCaptureBuffer(
        pixelBuffer: CVPixelBuffer,
        time: CMTime,
        orientation: CGImagePropertyOrientation
    ) {}

    func videoSessionProcessingProgress(progress: Float, processedFrames: Int) {}

    func videoSessionDidFinish() {}

    func handleSessionErrors(error: Error) {
        print(error)
    }
}
```

## Start The 3D Session

```swift
final class ViewController: UIViewController {
    private var flowManager: SMKitFlowManager?

    func startSession() {
        do {
            let sessionSettings = SMKitSessionSettings(
                include3D: true,
                poseEstimation3DMode: .standard,
                poseEstimation3DAccuracy: .solid,
                camType: .front
            )

            flowManager = try SMKitFlowManager(delegate: self)
            flowManager?.startSession(sessionSettings: sessionSettings) { [weak self] result in
                switch result {
                case .success:
                    self?.startDetection()
                case .failure(let error):
                    print("Failed to start 3D session: \(error)")
                }
            }
        } catch {
            print("Failed to create flow manager: \(error)")
        }
    }

    func startDetection() {
        do {
            try flowManager?.startDetection(exercise: "EXERCISE_NAME")
        } catch {
            print(error)
        }
    }

    func stopDetection() {
        do {
            let exerciseData = try flowManager?.stopDetection()
            print(exerciseData as Any)
        } catch {
            print(error)
        }
    }

    func stopSession() {
        flowManager?.stopSession { result in
            switch result {
            case .success(let workoutData):
                print(workoutData as Any)
            case .failure(let error):
                print(error)
            }
        }
    }
}
```

## Notes

- `shouldSupport3D: true` must be used during `configure`; otherwise `include3D: true` cannot start.
- `poseData3D` can be nil if the user is too close, out of range, or the current frame does not produce valid 3D output.
- `handleAnatomicalAngles` fires before `handlePositionData` for each processed frame.
- Video-file 3D processing uses the same session settings with `startVideoSession(...)`.
