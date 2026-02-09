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

<a name="inst"></a>
## 1. Installation

> **Note:** CocoaPods and SPM both provide the same frameworks (`SMKit`, `SMBase`). Only one can be active at a time — using both will cause a "Multiple commands produce" build error.

### CocoaPods

*Latest version: `SMKit '1.4.6'`*

#### Step-by-step Integration:

1. **Add the repository sources to your `Podfile`:**
   ```ruby
   platform :ios, '16.0'

   source 'https://bitbucket.org/sencyai/ios_sdks_release.git'
   source 'https://github.com/CocoaPods/Specs.git'
   ```

2. **Add the pod to your target:**
   ```ruby
   target 'YourApp' do
     use_frameworks!
     pod 'SMKit', '1.4.6'
   end
   ```

3. **Add post_install hooks** (required for proper build configuration):
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

4. **Install the pods:**
   ```bash
   pod install
   ```

5. **Open the workspace:**
   - ⚠️ **Important:** Always open the `.xcworkspace` file, not the `.xcodeproj` file
   - Example: `YourApp.xcworkspace`

#### Updating to a New Version:
```bash
pod update SMKit
```

### SPM (Swift Package Manager)

*Latest version: `1.4.6` (SMKit), `1.4.9` (SMBase)*

#### Fresh SPM Integration:

1. **Open your project in Xcode**

2. **Add the package dependency:**
   - Go to **File → Add Package Dependencies...**
   - Enter the repository URL: `https://bitbucket.org/sencyai/smkit_package`
   - **Dependency Rule:** Select "Branch" → `main` (recommended)
     - Alternatively, use "Exact Version" → `1.4.6`
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

#### Switching from CocoaPods to SPM:

1. **Remove CocoaPods:**
   ```bash
   pod deintegrate
   ```

2. **Clean derived data:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

3. **Follow the Fresh SPM Integration steps above**

4. **Build your project** to verify the integration

#### Switching from SPM back to CocoaPods:

1. **In Xcode, remove the package:**
   - Select your project → **Package Dependencies** tab
   - Remove `smkit_package`

2. **Uncomment the pod** in your `Podfile`:
   ```ruby
   pod 'SMKit', '1.4.6'
   ```

3. **Install pods:**
   ```bash
   pod install
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
    ],
    "Squats": [
        "DepthSquatsShallowDepth": ["low": 0.2, "high": 0.85],
    ]
]

// Apply modifications when starting a session
try flowManager.startSession(
    sessionSettings: SMKitSessionSettings(),
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

setDeviceMotionActive(phoneCalibrationInfo:SMPhoneCalibrationInfo, tiltDidChange: @escaping (SMPhoneCalibrationInfo) -> Void)
**Description**: Activate DeviceMotion with [phoneCalibrationInfo](#SMPhoneCalibrationInfo) and a callback tiltDidChange that wiךl be called when the phone changed

```swift
    flowManager.setDeviceMotionActive(
    phoneCalibrationInfo: SMPhoneCalibrationInfo(YZAngleRange: 60..<90, XYAngleRange: 3..< -3),
    tiltDidChange: { info in
        if info.isXYTiltAngleInRange && info.isYZTiltAngleInRange{
            print("In Range")
        }
    })
```

setDeviceMotionInactive()
**Description**: Sets DeviceMotion inactive.

```swift
    flowManager.setDeviceMotionInactive()
```

setDeviceMotionFrequency(isHigh: Bool)
**Description**: Changes the device motion frequency, if true will update DeviceMotion every 0.1 seconds and if false updates every 0.5 seconds

```swift
    flowManager.setDeviceMotionFrequency(isHigh: true)
```

setBodyPositionCalibrationActive(delegate: SMBodyCalibrationDelegate, screenSize:CGSize, boundingBox:BodyCalRectGuide? = nil)
**Description**: for more detailed information please check out [ Body calibration ](#body)

```string
    flowManager.setBodyPositionCalibrationActive(delegate: self, screenSize: self.view.frame.size)
```

setBodyPositionCalibrationInactive()
**Description**: Sets BodyPositionCalibration inactive.

```swift
    flowManager.setBodyPositionCalibrationInactive()
```

## 9. Getters <a name="getters">

getExerciseType() -> ExerciseTypeBr?
**Description**: Returns the currently running [ExerciseTypeBr](#ExerciseTypeBr) if possible

```swift
    let exerciseType = flowManager.getExerciseType()
```

getExerciseType(ByType type:String) throws -> ExerciseTypeBr
**Description**: Returns [ExerciseTypeBr](#ExerciseTypeBr) according to the type

```swift
    do{
        let exerciseType = try flowManager.getExerciseType(ByType: "HighKnees")
    }catch{
        print(error)
    }
```

getExerciseRange() -> ClosedRange<Float>?
**Description**: Returns the exercise rang of movment if possible

```swift
    let range = flowManager.getExerciseRange()
```

getModelsID() -> [String:String]
**Description**: Returns a dictionary with the model's name as the key and its ID as the value.

```swift
    let models = flowManager.getModelsID()
```

## 10. Available Data Types <a name="data"></a>

#### `SMKitSessionSettings`
| Type                | Format                                                       | Description                                                                                                  |
|---------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| phonePosition       | `PhonePositionMode?`                                         | The session PhonePositionMode.                                                                              |
| jumpRefPoint        | `String?`                                                    | The session jumpRefPoint                                                                                    |
| isInPosition        | `jumpHeightThreshold?`                                       | The session jumpHeightThreshold                                                                             |
| userHeight        | `jumpHeightThreshold?`                                         | The session userHeight                                                                                      |

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
| startTime           | `String`                                                     | The start time of the exercise session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                 |
| endTime             | `String`                                                     | The end time of the exercise session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                   |
| totalTime           | `Double`                                                     | The total time taken for the exercise session in seconds.                                                    |

#### `SMExerciseStaticInfo` type of `SMExerciseInfo`
| Type                   | Format                                                       | Description                                                                                                  |
|------------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| sessionId              | `String`                                                     | The identifier for the session in which the exercise was performed.                                          |
| startTime              | `String`                                                     | The start time of the exercise session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                 |
| endTime                | `String`                                                     | The end time of the exercise session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                   |
| totalTime              | `Double`                                                     | The total time taken for the exercise session in seconds.                                                    |
| timeInActiveZone       | `Double`                                                     | The time the user was in position.                                                                           |
| positionTechniqueScore | `Double`                                                     | The user score.                                                                                              |
| inPosition             | `[StaticData]`                                               | Array of static data.                                                                                        |


#### `StaticData`
| Type                     | Format                                                       | Description                                                                                                  |
|--------------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| detectionStartTime       | `String`                                                     | The start time of the detection.                                                                             |
| detectionEndTime         | `String`                                                     | The end time of detection.                                                                                   |
| detectionConfidenceScore | `Float`                                                      | The Confidence in the detection.                                                                             |
| inGreenZone              | `Bool`                                                       | Will be true if the user is in the success zone.                                                             |
| romScore                 | `Float`                                                      | The ROM score.                                                                                               |
| techniqueScore           | `Float`                                                      | The user technic score.                                                                                      |
| inPosition               | `Bool`                                                       | Will be true if the user in position.                                                                        |
| isGood                   | `Bool`                                                       | Is good detection                                                                                            |
| feedback                 | `[FormFeedbackTypeBr]?`                                      | Array of feedback of the user movment.                                                                       |

#### `SMExerciseDynamicInfo` type of `SMExerciseInfo`
| Type                   | Format                                                       | Description                                                                                                  |
|------------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| sessionId              | `String`                                                     | The identifier for the session in which the exercise was performed.                                          |
| startTime              | `String`                                                     | The start time of the exercise session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                 |
| endTime                | `String`                                                     | The end time of the exercise session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                   |
| totalTime              | `Double`                                                     | The total time taken for the exercise session in seconds.                                                    |
| performedReps          | `[RepData]`                                                  | Array of RepData.                                                                                            |
| numberOfPerformedReps  | `Int?`                                                       | The number of times the user repeated the exercise.                                                          |
| repsTechniqueScore     | `[Double]`                                                   | The exercise score.                                                                                          |

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
| exercises           | `[SMExerciseInfo]`                                           | Array of all the exerxises.                                                                                  |
| startTime           | `String`                                                     | The start time of the session session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                 |
| endTime             | `String`                                                     | The end time of the session session in "YYYY-MM-dd HH:mm:ss.SSSZ" format.                                   |


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
| TooClose(Bool)      | will be true if the user is too close |

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

### Integration with Claude CLI

Run the following command:

```bash
npx @modelcontextprotocol/cli client http \
  --url https://sency-mcp-production.up.railway.app/mcp \
  --header "X-API-Key: Your-API-Key"
```

### Getting Your API Key

Contact us at [support@sency.ai](mailto:support@sency.ai) to receive your MCP server API key.

### What is MCP?

The Model Context Protocol (MCP) allows AI assistants to access external context and tools. With Sency's MCP server, your AI development assistant can:
- Access SMKit documentation and API references
- Provide contextual code suggestions
- Help troubleshoot integration issues
- Suggest best practices for exercise detection implementation

---

Having issues? [Contact us](mailto:support@sency.ai) and let us know what the problem is.
