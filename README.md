# [smkit-ios-demo](https://github.com/sency-ai/smkit-sdk)

## Table of contents
1. [ Installation ](#inst)
2. [ Setup ](#setup)
3. [ Configure ](#conf)
4. [ Start ](#start)
5. [ Body calibration ](#body)
6. [ Setters ](#setters)
7. [ Getters ](#getters)
8. [ Data ](#data)

<a name="inst"></a>
## 1. Installation

### Cocoapods
```ruby
# [1] add the source to the top of your Podfile.
source 'https://bitbucket.org/sencyai/ios_sdks_release.git'
source 'https://github.com/CocoaPods/Specs.git'

# [2] add the pod to your target
target 'YourApp' do
  use_frameworks!
  pod 'SMKit'
end

# [3] add post_install hooks
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.5'
    end
  end
end
```

### SPM

In your **Package Dependencies** add this url `https://bitbucket.org/sencyai/smkit_package` and then press **Add package**

[!add package](screenshots/AddSMKit.png)

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
### Start exercise detection 

Implement **SMKitSessionDelegate**.
```swift
extension ViewController:SMKitSessionDelegate{
    //This function will be called when the session started and the camera is ready.
    func captureSessionDidSet(session: AVCaptureSession) {
        
    }
    
    //This function will be called when the session stoped.
    func captureSessionDidStop() {
        
    }
    
    //This function will be called when SMKit detects movement data.
    func handleDetectionData(movementData: MovementFeedbackData?) {
    }
    
    //This function will be called with the user joints location.
    //Please notice the joint location are for the video resoltion.
    func handlePositionData(poseData: [Joint : CGPoint]?) {
        
    }
    
    //This function will be called with if ant error occcured.
    func handleSessionErrors(error: any Error) {
        
    }
}
```

Now we can start the exercise.

```swift
var flowManager:SMKitFlowManager?

//First you will need to start the session.
func statSession(){
    let sessionSettings = SMKitSessionSettings(
        phonePosition: .Floor,
        jumpRefPoint: "Hip",
        jumpHeightThreshold: 20,
        userHeight: 180
    )
    do{
        self.flowManager = try SMKitFlowManager(delegate: self)
        try flowManager?.startSession(sessionSettings: sessionSettings) // sessionSettings is optinal if you dont want to change the values please omit sessionSettings
    }catch{
        print(error)
    }
}

//Then call startDetection to start the exercise detection.
func startDetection(){
    do{
        try flowManager?.startDetection(exercise: "EXERCISE_NAME")
    }catch{
        print(error)
    }
}

//When you are ready to stop the exercise call stopDetection.
func stopDetection(){
    do{
        //returns a SMExerciseInfo.
        let exerciseData = try flowManager?.stopDetection()
    }catch{
        print(error)
    }
}

//When you are ready to stop the session call stopSession.
func stopSession(){
    do{
        //returns a DetectionSessionResultData.
        let workoutData = try flowManager?.stopSession()
    }catch{
        print(error)
    }
}
```

## 5. Body calibration <a name="body"></a>

### Body calibration
*Body calibration* is used to get information about the users' location during the session.

#### Implement **SMBodyCalibrationDelegate**

```swift
extension ViewController:SMBodyCalibrationDelegate{
    // indicates the user is positioned 'inside' the 'rect' defined in "setBodyPositionCalibrationActive"
    func didEnterFrame() {
        
    }
    
    // indicates the user is positioned 'outside' the 'rect' defined in "setBodyPositionCalibrationActive"
    func didLeaveFrame() {
        
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
## 6. Setters <a name="setters"></a>

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

## 7. Getters <a name="getters"></a>

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

## 8. Available Data Types <a name="data"></a>

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
| Name                |
|---------------------|
| Nose                |
| Neck                |
| RShoulder           |
| RElbow              |
| RWrist              |
| LShoulder           |
| LElbow              |
| LWrist              |
| RHip                |
| RKnee               |
| RAnkle              |
| LHip                |
| LKnee               |
| LAnkle              |
| REye                |
| LEye                |
| REar                |
| LEar                |
| Hip                 |
| Chest               |
| Head                |
| LBigToe             |
| RBigToe             |
| LSmallToe           |
| RSmallToe           |
| LHeel               |
| RHeel               |

### `SMPhoneCalibrationInfo` <a name="SMPhoneCalibrationInfo"></a>
| Type                | Format                                                       | Description                                                                                                  |
|---------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| YZTiltAngle         | `Float`                                                      | The current Y angle.                                                                                         |
| YZTiltAngle         | `Float`                                                      | The current X angle.                                                                                         |
| YZAngleRange        | `Range<Float>`                                               | The currect Y range.                                                                                         |
| XYAngleRange        | `Range<Float>`                                               | The currect X range.                                                                                         |
| isYZTiltAngleInRange| `Bool`                                                       | Will be true if Y angle is in range.                                                                         |
| isXYTiltAngleInRange| `Bool`                                                       | Will be true if X angle is in range.                                                                         |

### `PhonePositionMode` <a name ="PhonePositionMode)"></a>
| Type                |
|---------------------|
| Floor               |
| Elevated            |

### `ExerciseTypeBr` <a name ="ExerciseTypeBr)"></a>
| Type                |
|---------------------|
| Dynamic             |
| Static              |
| BodyAssessment      |
| Mobility            |
| Highlights          |
| Other               |

Having issues? [Contact us](mailto:support@sency.ai) and let us know what the problem is.
