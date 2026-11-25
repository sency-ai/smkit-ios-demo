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
9. [Guidance Mode](#guidance-mode)
10. [Adaptive ROM](#adaptive-rom)
11. [Feedback Parameter Modifications](#feedback-parameter-modifications)
12. [Output Events](#output-events)
13. [Setters](#setters)
14. [Getters](#getters)
15. [Data Types](#data-types)
16. [MCP Server Integration](#mcp-server-integration)
17. [Troubleshooting](#troubleshooting)

## Installation

This branch uses **CocoaPods** for dependency management.

Looking for Swift Package Manager integration? Use the [`release/2.3.6_spm`](https://github.com/sency-ai/smkit-ios-demo/tree/release/2.3.6_spm) branch as a project reference, or add `https://bitbucket.org/sencyai/smkit_package` at version `2.3.6` to your own app.

### CocoaPods

Latest version: `SMKit '2.7.3'`

1. Add the repository sources to your `Podfile`:

   ```ruby
   platform :ios, '16.0'

   source 'https://bitbucket.org/sencyai/ios_sdks_release.git'
   source 'https://github.com/CocoaPods/Specs.git'
   ```

2. Add the pod to your target:

   ```ruby
   target 'YourApp' do
     use_frameworks!
     pod 'SMKit', '2.7.3'
   end
   ```

3. Add the post-install build settings:

   ```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       target.build_configurations.each do |config|
         config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
         config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
         config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
       end
     end
   end
   ```

4. Install pods and open the workspace:

   ```bash
   pod install --repo-update
   open SMKitDemo.xcworkspace
   ```

Always open the `.xcworkspace`, not the `.xcodeproj`, when using CocoaPods.

### Swift Package Manager

For SPM apps, add:

```text
https://bitbucket.org/sencyai/smkit_package
```

Use version `2.3.6`. The package product is `SMKitPackage`; import `SMKit` and `SMBase` in source files that use SDK APIs and data types. For the complete SPM demo project, use the [`release/2.3.6_spm`](https://github.com/sency-ai/smkit-ios-demo/tree/release/2.3.6_spm) branch.

## Setup

Add camera permission to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed for exercise detection</string>
```

The demo app reads its auth key from `SMKitDemo/SMKitDemo/Config/AuthKey.local.xcconfig`, which is intentionally ignored by Git. Create it with your Sency key before running the demo:

```xcconfig
SMKIT_AUTH_KEY = YOUR_KEY
```

The key reaches the app through `Info.plist` (`SMKitAuthKey = $(SMKIT_AUTH_KEY)`) and is read in `AppDelegate.swift`.

## Configure

Call `configure` once, preferably during app launch, before creating `SMKitFlowManager`.

```swift
SMKitFlowManager.configure(
    authKey: "YOUR_KEY",
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

| Parameter | Default | Description |
|---|---|---|
| `authKey` | — | Your Sency public SDK key. |
| `customerCode` | `nil` | Your customer code, when Sency has provided one. It selects your customer configuration and customer assets. |
| `shouldSupport3D` | `false` | Downloads/enables 3D models. Required before starting sessions with `include3D: true`. |
| `poseEstimation3DMode` | `.standard` | `.standard` (two-stage 3D pipeline) or `.accurate` (metric 3D estimator). |
| `poseEstimation3DAccuracy` | `.light` | `.light`, `.fastSolid`, or `.solid`. |
| `uiVersion` | `nil` | Optional SDK asset version stamp. Most direct SMKit integrations can leave it unset. |
| `modelDownloadPolicy` | `.waitForRemoteModelsThenFallback` | Controls use of remote downloads and a valid, previously downloaded cache (see below). |
| `downloadProgress` | `nil` | Reports background asset/model download progress. |
| `voiceFeedbackLanguage` | `"en"` | Language of the voice assets downloaded during configuration: `"en"`, `"he"`, or `"zh"`. Only relevant if your app plays the SDK's voice assets. |
| `voiceFeedbackVoice` | `"male_1"` | `"male_1"` or `"female_1"` for English and Mandarin voice assets. |
| `mobilityFlowVoice` | `"female_1"` | Voice used for Mobility Flow voice assets. |

SMKit will not work until `configure` succeeds.

You can also warm models before a workout:

```swift
SMKitFlowManager.preloadModelsInBackground()
```

### Customer assets

When you configure with a `customerCode`, files that Sency has set up for your account can be fetched by identifier:

```swift
// Local URL when the asset is already downloaded, otherwise nil.
let url = SMKitFlowManager.customerAssetURL(for: "ASSET_ID")

// Downloads the asset if needed. The completion receives nil when it is unavailable.
SMKitFlowManager.requestCustomerAsset(for: "ASSET_ID") { url in
}
```

### Exercise discovery

These work after `configure`, without a running session:

```swift
let movements = SMKitModel.getSupportedMovements() ?? []
let type = try SMKitModel.getExerciseType(type: "SquatRegular") // .Dynamic, .Static, .BodyAssessment, .Mobility, ...
```

## Model And Asset Delivery

SMKit 2.7.3 downloads models and required SDK assets from the server. It does not include bundled fallback models. Keep the device online for the first configuration and asset download; a valid, previously downloaded cache can be used offline later.

`SMModelDownloadPolicy` controls how configuration uses the downloaded cache. Its fallback is a previously server-downloaded cache only, never an embedded model.

| Policy | Behavior |
|---|---|
| `.waitForRemoteModelsThenFallback` | Default. Configure accepts the server metadata and downloads models in the background; session startup waits for the current server models. A verified, matching cache from an earlier download is the fallback. |
| `.immediateFallback` | Starts right away when the required models are already cached from an earlier download, and refreshes them in the background. |

## Session Lifecycle

Implement `SMKitSessionDelegate`, create a flow manager, start a session, then start exercise detection.

```swift
final class WorkoutViewController: UIViewController {
    private var flowManager: SMKitFlowManager?

    func startSession() {
        do {
            let settings = SMKitSessionSettings(
                phonePosition: .Floor,
                include3D: false,
                camType: .front
            )

            flowManager = try SMKitFlowManager(delegate: self)
            flowManager?.startSession(sessionSettings: settings) { [weak self] result in
                switch result {
                case .success:
                    self?.flowManager?.startDetection(exercise: "SquatRegular") { result in
                        if case .failure(let error) = result { print(error) }
                    }
                case .failure(let error):
                    print(error)
                }
            }
        } catch {
            print(error)
        }
    }

    func stopCurrentExercise() {
        flowManager?.stopDetection { result in
            switch result {
            case .success(let exerciseInfo):
                print(exerciseInfo as Any)
            case .failure(let error):
                print(error)
            }
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

`SMKitSessionSettings` arguments are optional but must be passed in the initializer's order: `phonePosition`, `jumpRefPoint`, `jumpHeightThreshold`, `userHeight`, `include3D`, `isRightHanded`, `drawWithCocking`, `isCovers`, `camType`, `useWideAngleCamera`, `isStrikeCross`, `configFileName`, `poseEstimation3DMode`, `poseEstimation3DAccuracy`, … (see [Data Types](#data-types)).

Completion handlers are called on the main thread. The older throwing `startSession(sessionSettings:)`, `stopSession()`, and `stopDetection()` APIs are still present for binary compatibility, but they are deprecated. Prefer the completion APIs so camera/model startup and teardown do not block the main thread. `startDetection` is available both as a throwing call and with a completion handler.

### Detection options

```swift
flowManager?.startDetection(
    exercise: "SquatRegular",
    guidanceMode: nil,                   // nil = default for the exercise, true/false to force (see Guidance Mode)
    guidanceSuggestionEnabled: nil,      // nil = use SMKitSessionSettings.guidanceSuggestionEnabled
    adaptiveRomFeedbackEnabled: false,   // See Adaptive ROM
    adaptiveRomWarmupReps: 2,
    adaptiveRomEligible: false,
    exerciseViewMonitoringEnabled: true  // Detects a camera angle that does not match the exercise
) { result in
}

// Pass recordExercise: false to discard the exercise instead of adding it to the session results.
flowManager?.stopDetection(recordExercise: false) { result in
}
```

### Starting the camera yourself

By default `startSession` starts the camera. To prepare the session first and start capture later (for example after your own countdown):

```swift
let settings = SMKitSessionSettings(autoStartCamera: false)
flowManager?.startSession(sessionSettings: settings) { [weak self] result in
    // captureSessionDidSet(session:) has delivered the AVCaptureSession
    self?.flowManager?.startCameraCapture { result in }
}

// Pause capture inside a running session, and resume it with startCameraCapture.
flowManager?.stopCameraCapture { result in }
```

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

    func didCaptureBuffer(
        pixelBuffer: CVPixelBuffer,
        time: CMTime,
        orientation: CGImagePropertyOrientation
    ) {
        // Optional raw frame access.
    }

    func handleSessionErrors(error: Error) {
        print(error)
    }

    // Optional — these have default empty implementations:

    func handleAnatomicalAngles(anatomicalAngles: [String: SCNVector3]?) {
        // 3D anatomical angles, when available.
    }

    func videoSessionProcessingProgress(progress: Float, processedFrames: Int) {
        // Called for video-file processing sessions.
    }

    func videoSessionDidFinish() {
        // Called when a video-file session reaches the end.
    }

    func didRecoverSessionSummary(_ summary: SMKitRecoveredSessionSummary) {
        // A partial result from a session that could not continue (see below).
    }
}
```

To receive raw camera sample buffers as well, pass an `SMKitImageSessionDelegate` when creating the flow manager:

```swift
flowManager = try SMKitFlowManager(delegate: self, imageDelegate: self)

extension WorkoutViewController: SMKitImageSessionDelegate {
    func handleImage(sampleBuffer: CMSampleBuffer) {
    }
}
```

### Recovered sessions

If native processing can no longer continue safely (or the app was terminated during a session), SMKit keeps a durable partial result and delivers it through `didRecoverSessionSummary(_:)`:

| Property | Type | Description |
|---|---|---|
| `sessionResult` | `DetectionSessionResultData` | The exercises recorded before the fault. |
| `faultCode` | `String` | Why the session stopped. |
| `recoveredAfterRelaunch` | `Bool` | `true` when the result was recovered on a later app launch. |
| `recoveredAt` | `Date` | When the result was recovered. |

### Session diagnostics

```swift
flowManager?.lifecycleDiagnosticsHandler = { diagnostic in
    // diagnostic.name, .stage, .generation, .elapsedMilliseconds, .timeoutSeconds
    print(diagnostic.name, diagnostic.stage, diagnostic.elapsedMilliseconds)
}

let id = flowManager?.sessionID // Stable identifier for the current session
```

Diagnostics are delivered on the main queue.

### Errors

`SMKitSessionError` cases have a readable `errorDescription`:

| Case | Meaning |
|---|---|
| `CameraIsAlreadyRunning` | A session is already running. Stop it before starting a new one. |
| `DetectionAlreadyRunning` | Detection is already running. Stop it before starting another exercise. |
| `NoSessionRunning` | The operation needs a running session. |
| `NoDetectionSessionRunning` | The operation needs running detection. |
| `NativeClientUnavailable` | `configure` has not completed successfully. |
| `UnableToStartCamera` | The camera could not start (permission, availability, or another active session). |
| `CameraPermissionDenied` | Camera access was denied. |
| `CameraCaptureFailed` | The camera stream stopped or did not provide frames. |
| `SessionStartTimedOut` | Camera or native session startup did not finish in time. |
| `UnexpectedExerciseInitializationError` | The exercise could not be initialized. Check the exercise name and custom configuration. |
| `UnableToStart3DSession` | 3D support was not configured or its models are unavailable. |
| `ConfigFileNotFound` | The `configFileName` passed in the session settings was not found. |

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

You can pass a custom guide:

```swift
let guide = try BodyCalRectGuide(widthScale: 0.7, heightScale: 0.75, originY: 0.15)
try flowManager?.setBodyPositionCalibrationActive(
    delegate: self,
    screenSize: view.bounds.size,
    boundingBox: guide
)
```

Deactivate it with:

```swift
flowManager?.setBodyPositionCalibrationInactive()
```

Set `sendInitialBodyCalibrationStatus: true` in `SMKitSessionSettings` to receive one status from the first calibration frame instead of only on changes.

Enable diagnostics when needed:

```swift
flowManager?.verboseBodyCalibration = true
```

## Demo Assessment

The **Demo Assessment** entry point in the sample app is a complete, local assessment implementation. It runs Overhead Mobility, Squat Regular Overhead Static, Jefferson Curl, and left/right Standing Side Bend in sequence.

Before the first exercise, the demo waits for both phone-angle and body-in-frame calibration, draws the SDK bounding-box guide, and lets the user skip calibration. During each timed exercise it shows a countdown, current technique score, form feedback, time in position, and a ROM gauge when supported. The top feedback highlights its relevant skeleton joints in red.

At completion, the app presents an overall score and per-exercise technique score, peak ROM, time in position, and detected form issues. See the implementation in `SMKitDemo/UI/Assessment` to adapt the protocol and presentation to your own assessment.

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

Set the camera frame rate (normalized to 10, 15, or 30) or landscape capture:

```swift
var settings = SMKitSessionSettings(landscapeCamera: false)
settings.cameraFps = 30
```

Process a video file instead of a live camera:

```swift
flowManager?.startVideoSession(
    url: videoURL,
    sessionSettings: SMKitSessionSettings(include3D: true),
    fpsLimit: 15,
    deterministicProcessing: false,      // true = process frames sequentially, independent of playback timing
    realtimeSequentialProcessing: false  // true = play in real time while sampling frames in the background
) { result in
    switch result {
    case .success(let player):
        // Attach the AVPlayer to an AVPlayerLayer if you want to show the video
        break
    case .failure(let error):
        print(error)
    }
}
```

A throwing `startVideoSession(url:sessionSettings:fpsLimit:deterministicProcessing:realtimeSequentialProcessing:)` that returns the `AVPlayer?` directly is also available. Use `videoSessionProcessingProgress(progress:processedFrames:)` and `videoSessionDidFinish()` to update UI while processing a video.

## Guidance Mode

Guidance mode teaches an exercise step by step. SMKit tracks the current step and reports it in `MovementFeedbackData`; your app shows the instruction, plays the matching vocal, and pauses the instruction video on each step.

Start guided detection:

```swift
if GuidanceModePolicy.exerciseUsesDefaultGuidanceOrchestration(detector: "StandingSideBendRight") {
    flowManager?.startDetection(exercise: "StandingSideBendRight", guidanceMode: true) { result in }
}
```

When `guidanceMode` is `nil`, SMKit uses guidance only for exercises where `SMKitFlowManager.exerciseHasDefaultGuidanceMode(_:)` is true, and only while `SMKitFlowManager.useDefaultGuidanceMode` is `true` (default `false`).

Read the guidance state in `handleDetectionData(movementData:)`:

```swift
func handleDetectionData(movementData: MovementFeedbackData?) {
    guard let data = movementData, flowManager?.isGuidanceModeActive == true else { return }

    let step = data.coachStep                   // .orient, .setup, .prepare, .action, .hold
    let text = data.coachInstruction            // Instruction to show
    let progress = data.coachAdvanceProgress    // Progress toward the next step
    let vocal = data.guidanceVocalKey           // Vocal asset key for this step
    if data.requestGuidanceVocalReplay == true {
        // Replay the current step's vocal
    }
}
```

While your app plays a guidance vocal, tell SMKit so the step does not advance mid-sentence:

```swift
flowManager?.setGuidanceVocalPlaying(true)
// ... vocal finishes ...
flowManager?.setGuidanceVocalPlaying(false)
```

Other controls:

```swift
flowManager?.resetGuidanceMode()          // Restart guidance from the first step
flowManager?.endGuidanceMode()            // Finish guidance and continue with the regular exercise checks
flowManager?.setGuidanceStepFailOpenSeconds(3) // Optional bounded recovery from a stalled step; nil keeps strict behavior
```

For dynamic exercises, guidance runs setup → one complete movement → acknowledgement; the movement step completes on an accepted rep. For static and mobility exercises, it walks through the position steps and finishes in the hold.

### Guidance suggestions

SMKit can suggest guidance when a user struggles with a supported exercise. Enable it in the session settings (or per exercise with `startDetection(guidanceSuggestionEnabled:)`) and listen for suggestions:

```swift
var settings = SMKitSessionSettings()
settings.guidanceSuggestionEnabled = true

final class SuggestionListener: SMKitGuidanceSuggestionOutputDelegate {
    func smKitDidEmitGuidanceSuggestion(_ output: SMKitGuidanceSuggestionOutput) {
        // output.exerciseName, output.exerciseType, output.elapsedEligibleTime
    }
}
SMKitOutputManager.shared.addGuidanceSuggestionOutputDelegate(listener) // Held weakly
```

Call `resetGuidanceSuggestionTracking()` when the exercise's active phase begins (so intro time doesn't count), and `rearmGuidanceSuggestionTrackingForCurrentExercise()` to allow another suggestion for the running exercise.

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
let events = flowManager?.consumeAdaptiveRomFeedbackEvents() // [.romSet, .recordBroken]

// The saved target from an earlier session; works before detection starts.
let target = flowManager?.getCachedAdaptiveRomTarget(exercise: "JeffersonCurl")
```

Each exercise result includes its adaptive ROM state in `SMExerciseInfo.adaptiveRom`. Save it on your server to restore the user's target after reinstalling the app or on another device:

```swift
let merged = SMKitFlowManager.mergeAdaptiveRomPilotCache(from: savedSnapshots) // [[String: Any]]; returns the number merged
```

Reset the local adaptive ROM cache:

```swift
SMKitFlowManager.clearAdaptiveRomPilotCache()
```

## Feedback Parameter Modifications

Change feedback thresholds for an exercise, then pass the generated configuration to the session:

```swift
let config = ConfigManager.shared
config.setValue(forExercise: "Crunches", parameter: "DepthCrunchesShallowDepth", key: "low", value: 0.1)
config.setValue(forExercise: "Crunches", parameter: "DepthCrunchesShallowDepth", key: "high", value: 0.9)

let configName = config.createTempConfigFile(named: "my_config")
let settings = SMKitSessionSettings(configFileName: configName)
flowManager?.startSession(sessionSettings: settings) { result in }
```

`getValue(forExercise:parameter:key:)` reads a value, `updateValue(...)` changes an existing one, and `resetToDefaults()` clears your changes.

## Output Events

`SMKitOutputManager.shared` publishes higher-level events:

```swift
final class OutputListener: SMKitOutputDelegate {
    func smKitDidEmitWatchOutput(_ output: SMKitWatchOutput) {}                       // Rep count, exercise, heart rate, state
    func smKitDidEmitRestSuggestion(_ output: SMKitRestOutput) {}                     // reason: heartRate, formFatigue, paceFatigue, inactivity, excellentForm
    func smKitDidEmitModificationApplied(_ output: SMKitModificationOutput) {}        // A feedback parameter change was applied
    func smKitDidEmitModificationSuggestion(_ output: SMKitModificationSuggestionOutput) {} // A suggested exercise change
}

SMKitOutputManager.shared.delegate = listener   // Held weakly
SMKitOutputManager.shared.logToConsole = true   // Optional console logging
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
flowManager?.blockEvents(key: "YOUR_BLOCK_EVENTS_KEY")
```

Contact [support@sency.ai](mailto:support@sency.ai) for a key.

### Camera-View Monitoring

```swift
flowManager?.setExerciseViewMonitoringEnabled(false) // Stop camera-angle mismatch detection for the active exercise
```

When enabled, `MovementFeedbackData.exerciseViewCorrectionVocalKey` reports a camera-orientation correction.

### Pause Gesture Region

Keep the wrist-hover pause gesture aligned with your pause button (normalized Y bounds):

```swift
flowManager?.setWorkoutPausedGestureRegion(minY: 0.0, maxY: 0.15)
flowManager?.resetWorkoutPausedGestureRegion()
```

## Getters

```swift
let currentType = flowManager?.getExerciseType()
let namedType = try flowManager?.getExerciseType(ByType: "HighKnees")
let romRange = flowManager?.getExerciseRange()
let modelIDs = flowManager?.getModelsID()
let screenshot = flowManager?.getScreenshoot()
let boundingBoxInfo = flowManager?.getBoundingBoxInfo()
let handGripLocation = try flowManager?.getCurrentPersonLocationForHandGrip()
let guidanceActive = flowManager?.isGuidanceModeActive
```

## Data Types

### `SMKitSessionSettings`

Initializer arguments are listed in their required order. `cameraFps`, `guidanceSuggestionEnabled`, and `guidanceSuggestionJointArrowsEnabled` are properties you set after creating the settings.

| Property | Type | Default | Description |
|---|---|---|---|
| `phonePosition` | `PhonePosition` | `.Floor` | `.Floor` or `.Elevated`. |
| `jumpRefPoint` | `String?` | `nil` | Reference joint for jump detection. |
| `jumpHeightThreshold` | `Float?` | `nil` | Minimum jump height threshold. |
| `userHeight` | `Float?` | `nil` | User height in centimeters. |
| `include3D` | `Bool?` | `nil` | Enables 3D output for the session. |
| `isRightHanded` | `Bool` | `true` | Dominant hand setting for supported exercises. |
| `drawWithCocking` | `Bool` | `true` | Draw/cocking option for supported strike/draw exercises. |
| `isCovers` | `Bool?` | `nil` | Exercise-specific option for cover-style movements. |
| `camType` | `SMCameraType` | `.front` | `.front` or `.back`. |
| `useWideAngleCamera` | `Bool` | `false` | Uses the front wide-angle camera when available. |
| `isStrikeCross` | `Bool?` | `nil` | Strike variation option for supported exercises. |
| `configFileName` | `String?` | `nil` | Custom configuration name (see [Feedback Parameter Modifications](#feedback-parameter-modifications)). |
| `poseEstimation3DMode` | `PoseEstimation3DMode` | `.standard` | `.standard` or `.accurate`. |
| `poseEstimation3DAccuracy` | `PoseEstimation3DAccuracy` | `.solid` | `.light`, `.fastSolid`, or `.solid`. |
| `instructionVideoConfig` | `InstructionVideoConfig` | default | Optional instruction-video metadata carried with the session settings. |
| `allowRomWhenNotInPosition` | `Bool` | `false` | Allows ROM updates outside in-position for supported flows. |
| `phoneMovementCountPreventionEnabled` | `Bool` | `false` | Blocks rep counting/in-position while phone movement is detected. |
| `variationMismatchFeedbackEnabled` | `Bool` | `false` | Enables mapped detector/variation mismatch feedback. |
| `sendInitialBodyCalibrationStatus` | `Bool` | `false` | Sends one body-calibration status from the first calibration frame. |
| `landscapeCamera` | `Bool` | `false` | Starts live camera capture in landscape orientation. |
| `autoStartCamera` | `Bool` | `true` | When `false`, `startSession` delivers the capture session without starting capture; call `startCameraCapture`. |
| `accurate3DModelOverrideURL` | `URL?` | `nil` | Optional override for the `.accurate` 3D model file. Leave `nil` to use the downloaded model. |
| `cameraFps` | `Float?` | `nil` | Live-camera FPS, normalized to 10, 15, or 30. |
| `guidanceSuggestionEnabled` | `Bool` | `false` | Emits guidance suggestions for supported exercises. |
| `guidanceSuggestionJointArrowsEnabled` | `Bool` | `false` | Supported joint-arrow exercises wait longer before suggesting guidance. |

### `MovementFeedbackData`

| Property | Type | Description |
|---|---|---|
| `didFinishMovement` | `Bool?` | Dynamic rep completed, or static user moved out after time in position. |
| `isShallowRep` | `Bool?` | Dynamic rep was shallow. |
| `isInPosition` | `Bool?` | Static/in-position state. |
| `intent` | `ExerciseIntent` | The next required exercise step, or `.none` when not supported for the exercise. |
| `isPhoneMoved` | `Bool?` | Phone movement gate state. |
| `isPerfectForm` | `Bool?` | No feedback mistakes for the current rep/frame. |
| `isPoseDetected` | `Bool?` | A pose with at least one confidently detected core joint was present on this frame. |
| `techniqueScore` | `Float?` | Technique score, usually normalized 0.0 to 1.0 in live frames. |
| `detectionConfidence` | `Float?` | Detection confidence. |
| `feedback` | `[FormFeedbackTypeBr]?` | Feedback identifiers. |
| `currentRomValue` | `Float?` | Current ROM value. |
| `currentRomRawValue` | `Float?` | Current ROM value before normalization. |
| `specialParams` | `[String: Float?]` | Exercise-specific values, such as jump height. |
| `debugParams` | `[String: Float?]` | Debug-only values in dev builds. |
| `isGestureDetected` | `Bool?` | Gesture detection state. |
| `gestureProgress` | `Float?` | Gesture progress. |
| `coachStep` | `GuidanceStep?` | Active guidance step: `.orient`, `.setup`, `.prepare`, `.action`, `.hold`. |
| `coachInstruction` | `String?` | Human-readable coaching instruction. |
| `coachAdvanceProgress` | `Float?` | Progress toward the next guidance step. |
| `guidanceVocalKey` | `String?` | Vocal asset key for guidance. |
| `requestGuidanceVocalReplay` | `Bool?` | Requests replay of the current guidance vocal. |
| `exerciseViewCorrectionVocalKey` | `String?` | Camera-orientation correction (does not affect scoring). |
| `positionEntryVocalFeedback` | `FormFeedbackTypeBr?` | Correction for a position that can't enter the normal feedback stage. |

### Result Models

`stopDetection(recordExercise:completion:)` returns an `SMExerciseInfo?`. Dynamic exercises return `SMExerciseDynamicInfo`; static, body assessment, and mobility exercises return `SMExerciseStaticInfo`. `stopSession(completion:)` returns `DetectionSessionResultData?`. All result types are `Codable`.

#### `SMExerciseInfo`

| Property | Type | Description |
|---|---|---|
| `sessionId` | `String` | Session identifier. |
| `exerciseName` | `String` | Detector name. |
| `startTime` / `endTime` | `String` | Exercise start and end time. |
| `totalTime` | `Double` | Exercise time in seconds. |
| `techniqueScore` | `Float` | Technique score. |
| `adaptiveRomPercentage` | `Float?` | Adaptive ROM result, when enabled. |
| `adaptiveRom` | `[String: Any]?` | Adaptive ROM state (see [Adaptive ROM](#adaptive-rom)). |

#### `SMExerciseDynamicInfo`

| Property | Type | Description |
|---|---|---|
| `numberOfPerformedReps` | `Int?` | Reps performed. |
| `perfectReps` | `Int` | Reps without form feedback. |
| `performedReps` | `[RepData]` | Per rep: `detectionStartTime`, `detectionEndTime`, `techniqueScore`, `detectionConfidenceScore`, `isGood`, `isShallowRep`, `romScore`, `feedback`. |

#### `SMExerciseStaticInfo`

| Property | Type | Description |
|---|---|---|
| `timeInPosition` | `Double` | Seconds in position. |
| `timeInPositionPerfect` | `Double` | Seconds in position without form feedback. |
| `peakRangeOfMotionScore` | `Float` | Peak ROM score. |
| `peakRangeOfMotionRawValue` | `Float?` | Peak ROM before normalization. |
| `inPosition` | `[StaticData]?` | Per in-position interval: times, `techniqueScore`, `detectionConfidenceScore`, `inGreenZone`, `inPosition`, `rangeOfMotionScore`, `isGood`, `feedback`, `iterationTime`. |

#### `DetectionSessionResultData`

| Property | Type | Description |
|---|---|---|
| `sessionID` | `String` | Session identifier. |
| `exercises` | `[SMExerciseInfo]` | All recorded exercises. |
| `startDate` / `endDate` | `Date` / `Date?` | Session start and end. |
| `startTime` / `endTime` | `String` | Formatted start and end time. |
| `totalTime` | `Double` | Session time in seconds. |
| `totalScore` | `Int` | Session score. |

### Common Enums

| Type | Values |
|---|---|
| `PhonePosition` | `.Floor`, `.Elevated` |
| `ExerciseTypeBr` | `.Dynamic`, `.Static`, `.BodyAssessment`, `.Mobility`, `.Other` |
| `SMBodyCalibrationStatus` | `.DidEnterFrame`, `.DidLeaveFrame`, `.TooClose(Bool)` |
| `SMCameraType` | `.front`, `.back` |
| `PoseEstimation3DMode` | `.standard`, `.accurate` |
| `PoseEstimation3DAccuracy` | `.light`, `.fastSolid`, `.solid` |
| `GuidanceStep` | `.orient`, `.setup`, `.prepare`, `.action`, `.hold` |

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
