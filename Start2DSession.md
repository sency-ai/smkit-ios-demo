# Start 2D Exercise Detection

## Overview

This guide shows you how to implement 2D exercise detection using SMKit. You'll need to implement the `SMKitSessionDelegate` protocol and manage the session lifecycle.

---

## 1. Implement SMKitSessionDelegate

The `SMKitSessionDelegate` protocol provides callbacks for session events, detection data, and camera frames.

```swift
extension ViewController: SMKitSessionDelegate {

    // MARK: - Session Lifecycle

    /// Called when the session starts and the camera is ready
    func captureSessionDidSet(session: AVCaptureSession) {
        // Configure your camera preview layer here
    }

    /// Called when the session stops
    func captureSessionDidStop() {
        // Clean up resources
    }

    // MARK: - Detection Data

    /// Called when SMKit detects movement data
    /// - Parameter movementData: Contains feedback about the user's movement, technique score, etc.
    func handleDetectionData(movementData: MovementFeedbackData?) {
        guard let data = movementData else { return }
        // Process movement feedback
    }

    /// Called with the user's joint positions
    /// - Parameters:
    ///   - poseData2D: 2D joint positions (in video resolution coordinates)
    ///   - poseData3D: 3D joint positions in space
    ///   - jointAnglesData: Angles between limb pairs
    ///   - jointGlobalAnglesData: Global angles for individual limbs
    ///   - xyzEulerAngles: Euler angles in XYZ format
    ///   - xyzRelativeAngles: Relative angles in XYZ format
    func handlePositionData(
        poseData2D: [Joint: JointData]?,
        poseData3D: [Joint: SCNVector3]?,
        jointAnglesData: [LimbsPairs: Float]?,
        jointGlobalAnglesData: [Limbs: Float]?,
        xyzEulerAngles: [String: SCNVector3]?,
        xyzRelativeAngles: [String: SCNVector3]?
    ) {
        // Process joint position data
    }

    // MARK: - Error Handling

    /// Called if any error occurs during the session
    func handleSessionErrors(error: any Error) {
        print("Session error: \(error)")
    }

    // MARK: - Camera Frames

    /// Called with each camera frame
    /// - Parameters:
    ///   - pixelBuffer: The camera frame buffer
    ///   - time: Frame timestamp
    ///   - orientation: Frame orientation
    func didCaptureBuffer(
        pixelBuffer: CVPixelBuffer,
        time: CMTime,
        orientation: CGImagePropertyOrientation
    ) {
        // Process raw camera frames if needed
    }
}
```

---

## 2. Session Management

### Initialize Flow Manager

```swift
var flowManager: SMKitFlowManager?
```

### Start Session

Create a session with optional settings and start the camera.

```swift
func startSession() {
    // Configure session settings (optional)
    let sessionSettings = SMKitSessionSettings(
        phonePosition: .Floor,
        jumpRefPoint: "Hip",
        jumpHeightThreshold: 20,
        userHeight: 180
    )

    do {
        // Initialize flow manager with delegate
        self.flowManager = try SMKitFlowManager(delegate: self)

        // Start the session
        // Note: sessionSettings is optional - omit it to use default values
        try flowManager?.startSession(sessionSettings: sessionSettings)
    } catch {
        print("Failed to start session: \(error)")
    }
}
```

### Start Detection

Begin detecting a specific exercise.

```swift
func startDetection() {
    do {
        try flowManager?.startDetection(exercise: "EXERCISE_NAME")
    } catch {
        print("Failed to start detection: \(error)")
    }
}
```

### Stop Detection

Stop the current exercise detection and retrieve exercise data.

```swift
func stopDetection() {
    do {
        // Returns SMExerciseInfo with exercise data
        let exerciseData = try flowManager?.stopDetection()

        if let data = exerciseData {
            print("Exercise completed: \(data)")
        }
    } catch {
        print("Failed to stop detection: \(error)")
    }
}
```

### Stop Session

Stop the entire session and retrieve workout data.

```swift
func stopSession() {
    do {
        // Returns DetectionSessionResultData with complete workout information
        let workoutData = try flowManager?.stopSession()

        if let data = workoutData {
            print("Workout completed: \(data)")
        }
    } catch {
        print("Failed to stop session: \(error)")
    }
}
```

---

## Typical Workflow

1. **Start Session** → Initialize camera and SMKit engine
2. **Start Detection** → Begin detecting a specific exercise
3. **Receive Callbacks** → Get real-time feedback via delegate methods
4. **Stop Detection** → End exercise and get results
5. **Repeat 2-4** → For multiple exercises (optional)
6. **Stop Session** → End workout and get complete session data

---

## Example Usage

```swift
// 1. Start the session
startSession()

// 2. Start detecting squats
try? flowManager?.startDetection(exercise: "SquatRegular")

// 3. Exercise in progress - receive callbacks
// - handleDetectionData() provides real-time feedback
// - handlePositionData() provides joint positions

// 4. Stop detection when done
stopDetection()

// 5. Optionally start another exercise
try? flowManager?.startDetection(exercise: "PlankHighStatic")
stopDetection()

// 6. Stop the session when workout is complete
stopSession()
```

---

## Notes

- **2D Joint Positions**: Coordinates are in video resolution space, not screen coordinates
- **Session Settings**: All parameters in `SMKitSessionSettings` are optional
- **Error Handling**: Always implement proper error handling for production apps
- **Multiple Exercises**: You can detect multiple exercises in a single session
