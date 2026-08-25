# [smkit-ios-demo](https://github.com/sency-ai/smkit-sdk)

This repository demonstrates direct SMKit integration for iOS. It is the lower-level SDK demo: you own the camera preview, session lifecycle, exercise UI, skeleton rendering, and result presentation.

For the prebuilt UI product, see [smkit-ui-ios-demo](https://github.com/sency-ai/smkit-ui-ios-demo).

## Table of Contents

1. [Installation](#installation)
2. [Setup](#setup)
3. [Configure](#configure)
4. [Model And Asset Delivery](#model-and-asset-delivery)
5. [Session Lifecycle](#session-lifecycle)
6. [Body Calibration](#body-calibration)
7. [Demo Assessment](#demo-assessment)
8. [Camera And Video](#camera-and-video)
9. [Adaptive ROM](#adaptive-rom)
10. [Setters](#setters)
11. [Getters](#getters)
12. [Data Types](#data-types)
13. [MCP Server Integration](#mcp-server-integration)
14. [Troubleshooting](#troubleshooting)

## Installation

This branch uses **Swift Package Manager (SPM)** for dependency management.

Looking for CocoaPods integration? Use the [`release/2.3.6`](https://github.com/sency-ai/smkit-ios-demo/tree/release/2.3.6) branch as a CocoaPods project reference, or add `pod 'SMKit', '2.3.6'` to your own app.

### Swift Package Manager

Latest version: `2.3.6` (SMKit)

This demo already has the package connected in `SMKitDemo.xcodeproj`. For a fresh SPM integration, add:

```text
https://bitbucket.org/sencyai/smkit_package
```

Use exact version `2.3.6`. Select the `SMKitPackage` product for your app target, then import `SMKit` and `SMBase` in source files that use SDK APIs and data types.

Open `SMKitDemo.xcodeproj` for this branch. There are no CocoaPods build phases in the SPM demo project.

### CocoaPods

For CocoaPods apps, use the [`release/2.3.6`](https://github.com/sency-ai/smkit-ios-demo/tree/release/2.3.6) branch as a CocoaPods project reference or add the pod directly:

```ruby
platform :ios, '16.0'

source 'https://bitbucket.org/sencyai/ios_sdks_release.git'
source 'https://github.com/CocoaPods/Specs.git'

target 'YourApp' do
  use_frameworks!
  pod 'SMKit', '2.3.6'
end
```

## Setup

Add camera permission to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed for exercise detection</string>
```

The demo is committed with a placeholder SDK key. Before running it locally,
replace `YOUR_SMKIT_AUTH_KEY` in `SMKitDemo/SMKitDemo/Managers/AuthManager.swift`
with your Sency SDK key.

Do not commit real SDK keys. Integrating apps should load keys from their own
configuration system.

## Configure

Call `configure` once, preferably during app launch, before creating `SMKitFlowManager`.

```swift
SMKitFlowManager.configure(
    authKey: AuthManager.shared.smKitAuthKey,
    shouldSupport3D: true,
    poseEstimation3DMode: .standard,
    poseEstimation3DAccuracy: .light,
    modelDownloadPolicy: .waitForRemoteModelsThenFallback,
    downloadProgress: { completed, total in
        print("SMKit assets: \(completed)/\(total)")
    }
) {
    // Configuration succeeded
} onFailure: { error in
    print(error as Any)
}
```

Important options:

| Parameter | Description |
|---|---|
| `authKey` | Your Sency public SDK key. |
| `includesHighlights` | Downloads/enables highlight models when needed. Default: `false`. |
| `shouldSupport3D` | Downloads/enables 3D models. Required before starting sessions with `include3D: true`. |
| `poseEstimation3DMode` | `.standard` or `.accurate`. |
| `poseEstimation3DAccuracy` | `.light` or `.solid`. |
| `modelDownloadPolicy` | Choose whether configuration waits for remote models or uses a valid, previously server-downloaded cache when available. |
| `uiVersion` | Optional SDK asset version stamp. Most direct SMKit integrations can leave it unset. |
| `downloadProgress` | Reports background asset/model download progress. |

SMKit will not work until `configure` succeeds.

You can also warm models before a workout:

```swift
SMKitFlowManager.preloadModelsInBackground()
```

## Model And Asset Delivery

SMKit 2.3.6 downloads models and required SDK assets from the server. It does not include bundled fallback models. Keep the device online for the first configuration and asset download; a valid, previously downloaded cache can be used offline later.

`SMModelDownloadPolicy` controls how configuration uses the downloaded cache. Its fallback is a previously server-downloaded cache only, never an embedded model.

## Session Lifecycle

Implement `SMKitSessionDelegate`, create a flow manager, start a session, then start exercise detection.

```swift
final class WorkoutViewController: UIViewController {
    private var flowManager: SMKitFlowManager?

    func startSession() {
        do {
            let settings = SMKitSessionSettings(
                phonePosition: .Floor,
                camType: .front,
                include3D: false
            )

            flowManager = try SMKitFlowManager(delegate: self)
            flowManager?.startSession(sessionSettings: settings) { [weak self] result in
                switch result {
                case .success:
                    try? self?.flowManager?.startDetection(exercise: "SquatRegular")
                case .failure(let error):
                    print(error)
                }
            }
        } catch {
            print(error)
        }
    }

    func stopCurrentExercise() {
        do {
            let exerciseInfo = try flowManager?.stopDetection()
            print(exerciseInfo as Any)
        } catch {
            print(error)
        }
    }

    func stopSession() {
        flowManager?.stopSession { result in
            switch result {
            case .success(let sessionData):
                print(sessionData as Any)
            case .failure(let error):
                print(error)
            }
        }
    }
}
```

The older throwing `startSession(sessionSettings:)` and `stopSession()` APIs are still present for binary compatibility, but they are deprecated. Prefer the completion APIs so camera/model startup and teardown do not block the main thread.

### Delegate

```swift
extension WorkoutViewController: SMKitSessionDelegate {
    func captureSessionDidSet(session: AVCaptureSession) {
        // Attach AVCaptureVideoPreviewLayer here.
    }

    func captureSessionDidStop() {
        // Remove preview layers and clean up UI state.
    }

    func handleDetectionData(movementData: MovementFeedbackData?) {
        // Reps, in-position state, feedback, ROM, guidance, and gesture data.
    }

    func handlePositionData(
        poseData2D: [Joint: JointData]?,
        poseData3D: [Joint: SCNVector3]?,
        jointAnglesData: [LimbsPairs: Float]?,
        jointGlobalAnglesData: [Limbs: Float]?,
        xyzEulerAngles: [String: SCNVector3]?,
        xyzRelativeAngles: [String: SCNVector3]?
    ) {
        // Render 2D/3D skeletons or collect pose diagnostics.
    }

    func handleAnatomicalAngles(anatomicalAngles: [String: SCNVector3]?) {
        // Optional 3D anatomical angles, when available.
    }

    func didCaptureBuffer(
        pixelBuffer: CVPixelBuffer,
        time: CMTime,
        orientation: CGImagePropertyOrientation
    ) {
        // Optional raw frame access.
    }

    func videoSessionProcessingProgress(progress: Float, processedFrames: Int) {
        // Called for video-file processing sessions.
    }

    func videoSessionDidFinish() {
        // Called when a video-file session reaches the end.
    }

    func handleSessionErrors(error: Error) {
        print(error)
    }
}
```

More focused examples:

- [Start 2D exercise detection](Start2DSession.md)
- [Start 3D exercise detection](Start3DSession.md)

## Body Calibration

Body calibration reports whether the user is inside the expected frame region.

```swift
extension WorkoutViewController: SMBodyCalibrationDelegate {
    func bodyCalStatusDidChange(status: SMBodyCalibrationStatus) {
        switch status {
        case .DidEnterFrame:
            print("User entered frame")
        case .DidLeaveFrame:
            print("User left frame")
        case .TooClose(let tooClose):
            print("Too close: \(tooClose)")
        @unknown default:
            break
        }
    }

    func didRecivedBoundingBox(box: BodyCalRectGuide) {
        // Render the guide box if desired.
    }
}
```

Activate it after the session has started:

```swift
try flowManager?.setBodyPositionCalibrationActive(
    delegate: self,
    screenSize: view.bounds.size
)
```

Deactivate it with:

```swift
flowManager?.setBodyPositionCalibrationInactive()
```

Enable diagnostics when needed:

```swift
flowManager?.verboseBodyCalibration = true
```

## Demo Assessment

The **Demo Assessment** entry point in the sample app is a complete, local assessment implementation. Its current protocol covers Overhead Mobility, Squat Regular Overhead Static, Jefferson Curl, left/right Standing Side Bend, left/right Hip Flexion, and left/right Standing Knee Raise.

Before the first exercise, the demo waits for phone-angle and body-in-frame calibration, draws the SDK bounding-box guide, and lets the user skip calibration. It supports an optional manual camera start. During each timed exercise it shows a countdown, current technique score, form feedback, time in position, and a ROM gauge when supported. The top feedback highlights its relevant skeleton joints in red.

At completion, the app presents an overall score and per-exercise technique score, peak ROM, time in position, and detected form issues. See the implementation in `SMKitDemo/UI/Assessment` to adapt the protocol and presentation to your own assessment.

You can pass a custom guide:

```swift
let guide = try BodyCalRectGuide(widthScale: 0.7, heightScale: 0.75, originY: 0.15)
try flowManager?.setBodyPositionCalibrationActive(
    delegate: self,
    screenSize: view.bounds.size,
    boundingBox: guide
)
```

## Camera And Video

Choose a camera before session start:

```swift
let settings = SMKitSessionSettings(camType: .front)
flowManager?.startSession(sessionSettings: settings) { result in
    // ...
}
```

Switch camera during a live session:

```swift
flowManager?.changeCameraType(type: .back)
```

Toggle wide-angle front camera:

```swift
flowManager?.setUseWideAngleCamera(true)
```

Process a video file instead of a live camera:

```swift
let player = try flowManager?.startVideoSession(
    url: videoURL,
    sessionSettings: SMKitSessionSettings(include3D: true),
    fpsLimit: 15,
    deterministicProcessing: false
)
```

Use `videoSessionProcessingProgress(progress:processedFrames:)` and `videoSessionDidFinish()` to update UI while processing a video.

## Adaptive ROM

Adaptive ROM lets supported exercises calibrate a user's current range and then adjust feedback thresholds.

```swift
try flowManager?.startDetection(
    exercise: "JeffersonCurl",
    guidanceMode: nil,
    adaptiveRomFeedbackEnabled: true,
    adaptiveRomWarmupReps: 2,
    adaptiveRomEligible: true
)
```

Useful runtime state:

```swift
let isCalibrating = flowManager?.isAdaptiveRomCalibrationActive
let shouldMuteVocals = flowManager?.shouldSuppressAdaptiveRomVocalFeedback
let events = flowManager?.consumeAdaptiveRomFeedbackEvents()
```

Reset the local adaptive ROM pilot cache:

```swift
SMKitFlowManager.clearAdaptiveRomPilotCache()
```

## Setters

### Device Motion

```swift
flowManager?.setDeviceMotionActive(
    phoneCalibrationInfo: SMPhoneCalibrationInfo(
        YZAngleRange: 60..<90,
        XYAngleRange: -5..<5
    ),
    tiltDidChange: { info in
        print(info.isYZTiltAngleInRange, info.isXYTiltAngleInRange)
    }
)

flowManager?.setDeviceMotionFrequency(isHigh: true)
flowManager?.setDeviceMotionInactive()
```

### Feedback Exclusion

```swift
flowManager?.setFeedbacksToExclude(feedbacksToExclude: [.pushupKneesOnFloor])
```

### Model Sensitivity

```swift
try flowManager?.setModelsSensitivity(
    jointThresh: 0.2,
    poseThresh: 0.2,
    aggregationDiff: 0.1
)
```

### Events

```swift
flowManager?.blockEvents(key: "XeBimnhu3r7g@o&&bBACK1B!^")
```

### Guidance Recovery

Guidance Mode is strict by default. If your product needs a bounded recovery from a stalled guidance step, set a positive timeout for the active flow:

```swift
flowManager?.setGuidanceStepFailOpenSeconds(3)
```

Pass `nil` or a non-positive value to retain regular strict Guidance Mode behavior.

## Getters

```swift
let currentType = flowManager?.getExerciseType()
let namedType = try flowManager?.getExerciseType(ByType: "HighKnees")
let romRange = flowManager?.getExerciseRange()
let modelIDs = flowManager?.getModelsID()
let screenshot = flowManager?.getScreenshoot()
let boundingBoxInfo = flowManager?.getBoundingBoxInfo()
let handGripLocation = try flowManager?.getCurrentPersonLocationForHandGrip()
```

## Data Types

### `SMKitSessionSettings`

| Property | Type | Description |
|---|---|---|
| `phonePosition` | `PhonePosition` | `.Floor` or `.Elevated`. |
| `jumpRefPoint` | `String?` | Reference joint for jump detection. |
| `jumpHeightThreshold` | `Float?` | Minimum jump height threshold. |
| `userHeight` | `Float?` | User height in centimeters. |
| `include3D` | `Bool?` | Enables 3D output for the session. |
| `isRightHanded` | `Bool` | Dominant hand setting for supported exercises. |
| `drawWithCocking` | `Bool` | Draw/cocking option for supported strike/draw exercises. |
| `isCovers` | `Bool?` | Exercise-specific option for cover-style movements. |
| `camType` | `SMCameraType` | `.front` or `.back`. |
| `useWideAngleCamera` | `Bool` | Uses the front wide-angle camera when available. |
| `isStrikeCross` | `Bool?` | Strike variation option for supported exercises. |
| `configFileName` | `String?` | Optional custom config file. |
| `poseEstimation3DMode` | `PoseEstimation3DMode` | `.standard` or `.accurate`. |
| `poseEstimation3DAccuracy` | `PoseEstimation3DAccuracy` | `.light` or `.solid`. |
| `instructionVideoConfig` | `InstructionVideoConfig` | Optional instruction-video metadata carried with the session settings. |
| `allowRomWhenNotInPosition` | `Bool` | Allows ROM updates outside in-position for supported flows. |
| `phoneMovementCountPreventionEnabled` | `Bool` | Blocks rep counting/in-position while phone movement is detected. |
| `variationMismatchFeedbackEnabled` | `Bool` | Enables mapped detector/variation mismatch feedback. |
| `landscapeCamera` | `Bool` | Starts live camera capture in landscape orientation. |
| `cameraFps` | `Float?` | Optional live-camera FPS. SMBase normalizes to supported values. |

### `MovementFeedbackData`

| Property | Type | Description |
|---|---|---|
| `didFinishMovement` | `Bool?` | Dynamic rep completed, or static user moved out after time in position. |
| `isShallowRep` | `Bool?` | Dynamic rep was shallow. |
| `isInPosition` | `Bool?` | Static/in-position state. |
| `isPhoneMoved` | `Bool?` | Phone movement gate state. |
| `isPerfectForm` | `Bool?` | No feedback mistakes for the current rep/frame. |
| `techniqueScore` | `Float?` | Technique score, usually normalized 0.0 to 1.0 in live frames. |
| `detectionConfidence` | `Float?` | Detection confidence. |
| `feedback` | `[FormFeedbackTypeBr]?` | Feedback identifiers. |
| `currentRomValue` | `Float?` | Current ROM value. |
| `specialParams` | `[String: Float?]` | Exercise-specific values, such as jump height. |
| `debugParams` | `[String: Float?]` | Debug-only values in dev builds. |
| `isGestureDetected` | `Bool?` | Gesture detection state. |
| `gestureProgress` | `Float?` | Gesture progress. |
| `coachStep` | `GuidanceStep?` | Active mobility coaching step. |
| `coachInstruction` | `String?` | Human-readable coaching instruction. |
| `coachAdvanceProgress` | `Float?` | Progress toward the next guidance step. |
| `guidanceVocalKey` | `String?` | Vocal asset key for guidance. |
| `requestGuidanceVocalReplay` | `Bool?` | Requests replay of the current guidance vocal. |

### Result Models

`stopDetection()` returns an `SMExerciseInfo?`. Dynamic exercises return `SMExerciseDynamicInfo`; static, body assessment, and mobility exercises return `SMExerciseStaticInfo`.

`stopSession(completion:)` returns `DetectionSessionResultData?`, which includes all recorded exercises, start/end times, total time, and total score.

### Common Enums

| Type | Values |
|---|---|
| `PhonePosition` | `.Floor`, `.Elevated` |
| `ExerciseTypeBr` | `.Dynamic`, `.Static`, `.BodyAssessment`, `.Mobility`, `.Highlights`, `.Other` |
| `SMBodyCalibrationStatus` | `.DidEnterFrame`, `.DidLeaveFrame`, `.TooClose(Bool)` |
| `SMCameraType` | `.front`, `.back` |
| `PoseEstimation3DMode` | `.standard`, `.accurate` |
| `PoseEstimation3DAccuracy` | `.light`, `.solid` |
## MCP Server Integration

Sency provides an MCP server for AI development tools that need direct SMKit documentation and exercise context.

Cursor example:

```json
{
  "mcpServers": {
    "sency": {
      "type": "streamable-http",
      "url": "https://sency-mcp-production.up.railway.app/mcp",
      "headers": {
        "X-API-Key": "YOUR-API-KEY"
      }
    }
  }
}
```

Claude Code example:

```json
{
  "mcpServers": {
    "sency": {
      "type": "http",
      "url": "https://sency-mcp-production.up.railway.app/mcp",
      "headers": {
        "X-API-Key": "YOUR-API-KEY"
      }
    }
  }
}
```

Contact [support@sency.ai](mailto:support@sency.ai) for an API key.

## Troubleshooting

For CocoaPods/SPM migration notes, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

Having issues? [Contact us](mailto:support@sency.ai) and let us know what the problem is.
