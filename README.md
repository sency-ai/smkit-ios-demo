# [smkit-ios-demo](https://github.com/sency-ai/smkit-sdk)

## Table of contents
1. [ Installation ](#inst)
2. [ Setup ](#setup)
3. [ Configure ](#conf)
4. [ Start ](#start)
5. [ Models ](#models)
6. [ Data ](#data)

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

In your **Package Dependencies** add this url `https://bitbucket.org/sency-ios/smkit_package` and then press **Add package**

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

//First you will need to start to start the session.
func statSession(){
    do{
        self.flowManager = try SMKitFlowManager(delegate: self)
        try flowManager?.startSession()
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

## 4. Models <a name="models"></a>

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
## Available Data Types <a name="data"></a>
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

Having issues? [Contact us](mailto:support@sency.ai) and let us know what the problem is.
