# [smkit-ios-demo](https://github.com/sency-ai/smkit-sdk)

## Table of contents
1. [ Installation ](#inst)
2. [ Setup ](#setup)
3. [ Configure ](#conf)
4. [ Start ](#start)
5. [ Models ](#models)

<a name="inst"></a>
## 1. Installation

### Cocoapods
```ruby
# [1] add the source to the top of your Podfile.
source 'https://bitbucket.org/sency-ios/sency_ios_sdk.git'
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

Comming soon

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
        // movementData?.didFinishMovement => will be true when the user finish a dynamic movment.
        // movementData?.isShallowRep => @ofer please add.
        //movementData?.isInPosition => will be true if the user is in the currect position
        //movementData?.isPerfectForm => will be true if the user did not have any mistakes
        //movementData?.feedback => a array of feedback of the user movment.
        //movementData?.currentRomValue => the current Range Of Motion of the user
        //movementData?.specialParams => some dynamic exercises will have some special params for example the exercise "Jumps" has "JumpPeakHeight" and "currHeight".
    }
    
    //This function will be called with the user joints location.
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

Having issues? [Contact us](mailto:support@sency.ai) and let us know what the problem is.
