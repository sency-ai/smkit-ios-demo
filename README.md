# [smkit-ios-demo](https://github.com/sency-ai/smkit-sdk)

## Table of contents
1. [ Installation ](#inst)
2. [ Setup ](#setup)
3. [ Configure ](#conf)
4. [ Start ](#start)
5. [ Body calibration ](#body)
6. [ Modifying Feedback Parameters ](#feedback)
7. [ Change Camera](#cam)
8. [ Setters ](#setters)
9. [ Getters ](#getters)
10. [ Data ](#data)
11. [ MCP Server Integration ](#mcp)
12. [ Troubleshooting ](#troubleshoot)

<a name="inst"></a>
## 1. Installation

This branch uses **Swift Package Manager (SPM)** for dependency management.

> Looking for **CocoaPods** integration? See the [`main`](https://github.com/sency-ai/smkit-ios-demo) branch.
>
> Need to switch between CocoaPods and SPM? See the [Troubleshooting Guide](TROUBLESHOOTING.md).

### SPM (Swift Package Manager)

*Latest version: `1.4.7` (SMKit), `1.4.9` (SMBase)*

#### Fresh SPM Integration:

1. **Open your project in Xcode**

2. **Add the package dependency:**
   - Go to **File → Add Package Dependencies...**
   - Enter the repository URL: `https://bitbucket.org/sencyai/smkit_package`
   - **Dependency Rule:** Select "Branch" → `main` (recommended)
     - Alternatively, use "Exact Version" → `1.4.7`
   - Click **Add Package**

3. **Select the package product:**
   - When prompted, select **`SMKitPackage`** (not "SMKit")
   - Add to your app target
   - Click **Add Package**

4. **Configure build settings:**
   - Select your project → Your target → **Build Settings**
   - Search for "Excluded Architectures"
   - Add `arm64` to **Excluded Architectures** for "Any iOS Simulator SDK"
   - This setting: `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64`

5. **Import in your code:**
   ```swift
   import SMKit
   import SMBase
   ```

#### Updating SPM Packages:

- **Xcode:** File → Packages → Update to Latest Package Versions
- **Or resolve to specific version:** File → Packages → Resolve Package Versions

<a name="setup"></a>
## 2. Setup
Add camera permission request to `Info.plist`
```Xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed</string>
```

<a name="conf"></a>
## 3. Configure
```Swift
SMKitFlowManager.configure(authKey: "YOUR_KEY") {
    // The configuration was successful
    // Your Code
} onFailure: { error in
    // The configuration failed with error
    // Your Code
}
```
To reduce wait time we recommend to call `configure` on app launch.

**⚠️ SMKit will not work if you don't first call configure.**


<a name="start"></a>
## 4. Start
- [Start 2D exercise detection](https://github.com/sency-ai/smkit-ios-demo/blob/main/Start2DSession.md)

- [Start 3D exercise detection](https://github.com/sency-ai/smkit-ios-demo/blob/main/Start3DSession.md)

## 5. Body calibration <a name="body"></a>

### Body calibration
*Body calibration* is used to get information about the users' location during the session.

#### Implement **SMBodyCalibrationDelegate**

```swift
extension ViewController:SMBodyCalibrationDelegate{
    // indicates the user current position status
    func bodyCalStatusDidChange(status: SMBodyCalibrationStatus) {
        switch status {
        case .DidEnterFrame:
            // This status is triggered when the user enters the bounding box.
            // You can add specific logic here to handle when the user is detected in frame.
            break
        case .DidLeaveFrame:
            // This status is triggered when the user leaves the bounding box.
            // Implement any necessary actions when the user is no longer detected.
            break
        case .TooClose(let tooClose):
            // This status is triggered only when 3D data is available.
            // The `tooClose` parameter indicates whether the user is too close to the screen.
            break
        }
    }
    
    // BodyCalRectGuide will give you the 'box' size and location
    func didRecivedBoundingBox(box: BodyCalRectGuide) {
        
    }
}
```
Now we can set the body calibration active.
```swift
//Sets the body calibration active (make sure to first call statSession)
func setBodyPositionCalibrationActive(){
    do{
        try flowManager?.setBodyPositionCalibrationActive(delegate: self, screenSize: self.view.frame.size)
    }catch{
        print(error)
    }
}

//Sets the body calibration inactive.
func setBodyPositionCalibrationInactive(){
    flowManager?.setBodyPositionCalibrationInactive()
}
```

## 6. Modifying Feedback Parameters <a name="feedback"></a>

You have the ability to modify specific feedback parameters for exercises. This allows you to customize the thresholds and ranges for feedback detection according to your application's needs.

### How to Modify Parameters

Use the `modifications` dictionary to customize feedback parameters for specific exercises:

```swift
let modifications: [String: Any] = [
    "Crunches": [
        // Feedback/parameter name: [parameter values]
        "DepthCrunchesShallowDepth": ["low": 0.1, "high": 0.9],
        // Add more parameters as needed
    ]
]

// Apply modifications when starting a workout (SMKitUI)
try SMKitUIModel.startWorkout(
    viewController: self,
    workout: workout,
    delegate: self,
    modifications: modifications
)
```

### Parameter Structure

Each modification follows this structure:
- **Exercise Name** (e.g., "Crunches", "Squats"): The key identifying the exercise
- **Parameter Name** (e.g., "DepthCrunchesShallowDepth"): The specific feedback parameter to modify
- **Values**: A dictionary containing threshold values (typically `"low"` and `"high"`)

### Getting Available Parameters

**Note:** We will release our feedbacks catalog soon with a complete list of available parameters for each exercise.

For assistance in applying modifications or to request the current catalog, please [contact us](mailto:support@sency.ai).

## 7. Change camera<a name="cam"></a>
In SMKit you have the ability to choose which camera you prefer to use front or back you can achieve this with two different way

### Before session start
To choose which camera to use before the session starts, you need to call start session with SMKitSessionSettings and add a SMCameraType like so:

```swift
try flowManager.startSession(sessionSettings: SMKitSessionSettings(camType: SMCameraType.front))
```

### while session is running
To switch the camera type during the session you need to call `changeCameraType` like so:

```swift
self.flowManager.changeCameraType(type: SMCameraType.back)
```

## 8. Setters <a name="setters"></a>

### `setDeviceMotionActive`

Activates DeviceMotion with [phoneCalibrationInfo](#SMPhoneCalibrationInfo) and a callback that will be called when the phone orientation changes.

```swift
flowManager.setDeviceMotionActive(
    phoneCalibrationInfo: SMPhoneCalibrationInfo(YZAngleRange: 60..<90, XYAngleRange: 3..< -3),
    tiltDidChange: { info in
        if info.isXYTiltAngleInRange && info.isYZTiltAngleInRange {
            print("In Range")
        }
    }
)
```

### `setDeviceMotionInactive`

Deactivates DeviceMotion.

```swift
flowManager.setDeviceMotionInactive()
```

### `setDeviceMotionFrequency`

Changes the device motion update frequency. When `isHigh` is `true`, updates every 0.1 seconds. When `false`, updates every 0.5 seconds.

```swift
flowManager.setDeviceMotionFrequency(isHigh: true)
```

### `setBodyPositionCalibrationActive`

Activates body position calibration. For more details, see [Body Calibration](#body).

```swift
flowManager.setBodyPositionCalibrationActive(delegate: self, screenSize: self.view.frame.size)
```

### `setBodyPositionCalibrationInactive`

Deactivates body position calibration.

```swift
flowManager.setBodyPositionCalibrationInactive()
```

## 9. Getters <a name="getters"></a>

### `getExerciseType() -> ExerciseTypeBr?`

Returns the currently running [ExerciseTypeBr](#ExerciseTypeBr), if available.

```swift
let exerciseType = flowManager.getExerciseType()
```

### `getExerciseType(ByType:) throws -> ExerciseTypeBr`

Returns an [ExerciseTypeBr](#ExerciseTypeBr) for the given exercise type name.

```swift
do {
    let exerciseType = try flowManager.getExerciseType(ByType: "HighKnees")
} catch {
    print(error)
}
```

### `getExerciseRange() -> ClosedRange<Float>?`

Returns the exercise range of movement, if available.

```swift
let range = flowManager.getExerciseRange()
```

### `getModelsID() -> [String:String]`

Returns a dictionary with model names as keys and their IDs as values.

```swift
let models = flowManager.getModelsID()
```

## 10. Available Data Types <a name="data"></a>

#### `SMKitSessionSettings`
| Type                       | Format                              | Description                                                                                    |
|----------------------------|-------------------------------------|------------------------------------------------------------------------------------------------|
| phonePosition              | `PhonePosition`                     | The phone position mode for the session (Floor or Elevated).                                   |
| jumpRefPoint               | `String?`                           | Reference point for jump detection.                                                            |
| jumpHeightThreshold        | `Float?`                            | Threshold value for jump height detection.                                                     |
| userHeight                 | `Float?`                            | The user's height in centimeters.                                                              |
| include3D                  | `Bool?`                             | Whether to include 3D pose estimation in the session.                                          |
| camType                    | `SMCameraType`                      | Camera type to use (front or back).                                                            |
| configFileName             | `String?`                           | Optional custom configuration file name.                                                       |

#### `MovementFeedbackData`
| Type                | Format                                                       | Description                                                                                                  |
|---------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| didFinishMovement   | `Bool?`                                                      | Will be true when the user finish a dynamic movment.                                                         |
| isShallowRep        | `Bool?`                                                      | Will be true when the user finish a shallow dynamic movment.                                                 |
| isInPosition        | `Bool?`                                                      | Will be true if the user is in the currect position                                                          |
| isPerfectForm       | `Bool?`                                                      | Will be true if the user did not have any mistakes                                                           |
| techniqueScore      | `Float?`                                                     | The score representing the user's technique during the exercise.                                             |
| detectionConfidence | `Float?`                                                     | The confidence score                                                                                         |
| feedback            | `[FormFeedbackTypeBr]?`                                      | Array of feedback of the user movment.                                                                       |
| currentRomValue     | `Float?`                                                     | The current Range Of Motion of the user.                                                                     |
| specialParams       | `[String:Float?]`                                            | Some dynamic exercises will have some special params for example the exercise "Jumps" has "JumpPeakHeight" and "currHeight". |

#### `SMExerciseInfo`
| Type                | Format                                                       | Description                                                                                                  |
|---------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| sessionId           | `String`                                                     | The identifier for the session in which the exercise was performed.                                          |
| exerciseName        | `String`                                                     | The name/ID of the exercise being performed.                                                                 |
| startTime           | `String`                                                     | The start time of the exercise session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                 |
| endTime             | `String`                                                     | The end time of the exercise session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                   |
| totalTime           | `Double`                                                     | The total time taken for the exercise session in seconds.                                                    |
| techniqueScore      | `Float`                                                      | The technique score for the exercise.                                                                        |

#### `SMExerciseStaticInfo` type of `SMExerciseInfo`
| Type                   | Format                                                       | Description                                                                                                  |
|------------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| sessionId              | `String`                                                     | The identifier for the session in which the exercise was performed.                                          |
| exerciseName           | `String`                                                     | The name/ID of the exercise being performed.                                                                 |
| startTime              | `String`                                                     | The start time of the exercise session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                 |
| endTime                | `String`                                                     | The end time of the exercise session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                   |
| totalTime              | `Double`                                                     | The total time taken for the exercise session in seconds.                                                    |
| timeInActiveZone       | `Double`                                                     | The time the user was in position.                                                                           |
| timeInPositionPerfect  | `Double`                                                     | The time the user was in perfect position.                                                                   |
| positionTechniqueScore | `Float`                                                      | The technique score for the static exercise.                                                                 |
| peakRangeOfMotionScore | `Float`                                                      | The peak range of motion score achieved during the exercise.                                                 |
| inPosition             | `[StaticData]?`                                              | Array of static data (optional).                                                                             |


#### `StaticData`
| Type                     | Format                                                       | Description                                                                                                  |
|--------------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| detectionStartTime       | `String`                                                     | The start time of the detection.                                                                             |
| detectionEndTime         | `String`                                                     | The end time of detection.                                                                                   |
| detectionConfidenceScore | `Float`                                                      | The confidence in the detection.                                                                             |
| inGreenZone              | `Bool`                                                       | Will be true if the user is in the success zone.                                                             |
| rangeOfMotionScore       | `Float`                                                      | The range of motion score.                                                                                   |
| techniqueScore           | `Float`                                                      | The user technique score.                                                                                    |
| inPosition               | `Bool`                                                       | Will be true if the user is in position.                                                                     |
| isGood                   | `Bool`                                                       | Indicates if the detection is good.                                                                          |
| feedback                 | `[FormFeedbackTypeBr]?`                                      | Array of feedback for the user movement.                                                                     |
#### `SMExerciseDynamicInfo` type of `SMExerciseInfo`
| Type                   | Format                                                       | Description                                                                                                  |
|------------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| sessionId              | `String`                                                     | The identifier for the session in which the exercise was performed.                                          |
| exerciseName           | `String`                                                     | The name/ID of the exercise being performed.                                                                 |
| startTime              | `String`                                                     | The start time of the exercise session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                 |
| endTime                | `String`                                                     | The end time of the exercise session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                   |
| totalTime              | `Double`                                                     | The total time taken for the exercise session in seconds.                                                    |
| performedReps          | `[RepData]`                                                  | Array of RepData containing information about each repetition.                                               |
| numberOfPerformedReps  | `Int?`                                                       | The number of times the user repeated the exercise.                                                          |
| perfectReps            | `Int`                                                        | The number of perfect reps performed.                                                                        |
| repsTechniqueScore     | `Float`                                                      | The overall technique score for the dynamic exercise.                                                        |


#### `RepData`
| Type                     | Format                                                       | Description                                                                                                  |
|--------------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| detectionStartTime       | `String`                                                     | The start time of the detection.                                                                             |
| detectionEndTime         | `String`                                                     | The end time of detection.                                                                                   |
| detectionConfidenceScore | `Float`                                                      | The Confidence in the detection.                                                                             |
| isShallowRep             | `Bool`                                                       | Will be true if the Rep is shallow                                                                           |
| romScore                 | `Float`                                                      | The ROM score.                                                                                               |
| techniqueScore           | `Float`                                                      | The user technic score.                                                                                      |
| isGood                   | `Bool`                                                       | Is good detection                                                                                            |
| feedback                 | `[FormFeedbackTypeBr]?`                                      | Array of feedback of the user movment.                                                                       |

#### `DetectionSessionResultData`
| Type                | Format                                                       | Description                                                                                                  |
|---------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| sessionID           | `String`                                                     | The session identifier.                                                                                      |
| exercises           | `[SMExerciseInfo]`                                           | Array of all the exercises performed in the session.                                                         |
| startTime           | `String`                                                     | The start time of the session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                          |
| endTime             | `String`                                                     | The end time of the session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                            |
| totalTime           | `Double`                                                     | The total time for the session in seconds.                                                                   |
| totalScore          | `Int`                                                        | The overall score for the session.                                                                           |


#### `Joint`

| 2D Joints           | 3D Joins     |
|---------------------|--------------|
| Head                | Head         |
| REye                | REye         |
| LEye                | LEye         |
| LEar                | LEar         |
| REar                | REar         |
| Nose                | Nose         |
| Neck                | Neck         |
| RShoulder           | RShoulder    |
| RElbow              | RElbow       |
| RWrist              | RWrist       |
| LShoulder           | LShoulder    |
| LElbow              | LElbow       |
| LWrist              | LWrist       |
| UpperSpine          | UpperSpine   |
| MiddleSpine1        | MiddleSpine1 |
| Hip                 | Hip          |
| RHip                | RHip         |
| RKnee               | RKnee        |
| RAnkle              | RAnkle       |
| RHeel               | RBigToe      |
| RBigToe             | LHip         |
| RSmallToe           | LKnee        |
| LHip                | LAnkle       |
| LKnee               | LBigToe      |
| LAnkle              |              |
| LHeel               |              |
| LBigToe             |              |
| LSmallTo            |              |




### `SMPhoneCalibrationInfo` <a name="SMPhoneCalibrationInfo"></a>
| Type                | Format                                                       | Description                                                                                                  |
|---------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| YZTiltAngle         | `Float`                                                      | The current Y angle.                                                                                         |
| YZTiltAngle         | `Float`                                                      | The current X angle.                                                                                         |
| YZAngleRange        | `Range<Float>`                                               | The currect Y range.                                                                                         |
| XYAngleRange        | `Range<Float>`                                               | The currect X range.                                                                                         |
| isYZTiltAngleInRange| `Bool`                                                       | Will be true if Y angle is in range.                                                                         |
| isXYTiltAngleInRange| `Bool`                                                       | Will be true if X angle is in range.                                                                         |

### `PhonePositionMode` <a name ="PhonePositionMode"></a>
| Type                |
|---------------------|
| Floor               |
| Elevated            |

### `ExerciseTypeBr` <a name ="ExerciseTypeBr"></a>
| Type                |
|---------------------|
| Dynamic             |
| Static              |
| BodyAssessment      |
| Mobility            |
| Highlights          |
| Other               |

### `SMBodyCalibrationStatus`
| Type                | Description                           |
|---------------------|---------------------------------------|
| DidEnterFrame       | if the user enterd the frame          |
| DidLeaveFrame       | if the user left the frame            |
| TooClose(Bool)      | if the user is too close (using 3D)   |

### `SMCameraType`
| Type                | Description                           |
|---------------------|---------------------------------------|
| front               | the front camera                      |
| back                | the back camera                       |

## 11. MCP Server Integration <a name="mcp"></a>

Sency provides an MCP (Model Context Protocol) server for integration with AI development tools like Cursor and Claude CLI. This enables AI-assisted development with direct access to SMKit documentation and examples.

### Integration with Cursor

Add the server definition to `~/.cursor/mcp.json` and reload Cursor:

```json
{
  "mcpServers": {
    "smkitui": {
      "type": "streamable-http",
      "url": "https://sency-mcp-production.up.railway.app/mcp",
      "headers": {
        "X-API-Key": "Your-API-Key"
      }
    }
  }
}
```
### Integration with Claude Code

To use the Sency MCP server with Claude Code, follow these steps:

**1. Configure MCP Settings**

Create or edit the file `~/.claude/mcp_settings.json` and add the following configuration:

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

**2. Restart Claude Code**

After adding the configuration, restart Claude Code to load the MCP server:

```bash
# Exit your current Claude Code session
# Then start a new session
claude
```

After setup, you can ask Claude Code questions like:
- "Show me the iOS setup guide"
- "List all available exercises"
- "Create a beginner workout focused on upper body"
- "Generate Swift code for a cardio workout"
- "Search for exercises targeting core muscles"

### Getting Your API Key

Contact us at [support@sency.ai](mailto:support@sency.ai) to receive your MCP server API key.

### What is MCP?

The Model Context Protocol (MCP) allows AI assistants to access external context and tools. With Sency's MCP server, your AI development assistant can:
- Access SMKit documentation and API references
- Provide contextual code suggestions
- Help troubleshoot integration issues
- Suggest best practices for exercise detection implementation

## 12. Troubleshooting <a name="troubleshoot"></a>

For common issues and migration guides, see the [Troubleshooting Guide](TROUBLESHOOTING.md), including:
- Switching from CocoaPods to SPM
- Switching from SPM back to CocoaPods

---

Having issues? [Contact us](mailto:support@sency.ai) and let us know what the problem is.

