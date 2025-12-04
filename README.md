# [smkit-ios-demo](https://github.com/sency-ai/smkit-sdk)

## Table of contents
1. [ Installation ](#inst)
2. [ Setup ](#setup)
3. [ Configure ](#conf)
4. [ Start ](#start)
5. [ Body calibration ](#body)
6. [ Change Camera](#cam)
7. [ Setters ](#setters)
8. [ Getters ](#getters)
9. [ Data ](#data)

<a name="inst"></a>
## 1. Installation

### Cocoapods
*Latest version: `SMKit '1.4.3'`*

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

*Latest version: `smkit_package '1.4.3'`*

[add package](screenshots/spm_add_package.png)

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
## 6. Change camera<a name="cam"></a>
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

## 7. Setters <a name="setters"></a>

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

## 8. Getters <a name="getters"></a>

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

## 9. Available Data Types <a name="data"></a>

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

Having issues? [Contact us](mailto:support@sency.ai) and let us know what the problem is.
