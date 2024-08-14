##Start 3D exercise detection 

Starting a 3D session is very similar to starting a 2D session, with only a few minor adjustments.

###Configure
First you will have to configure SMKit the similery to [the previus section](https://github.com/sency-ai/smkit-ios-demo?tab=readme-ov-file#conf) but with the add `shouldSupport3D` this Bool wil make sure that 3D data is supported
```Swift
SMKitFlowManager.configure(authKey: "YOUR_KEY", shouldSupport3D: true) {
    // The configuration was successful
    // Your Code
} onFailure: { error in
    // The configuration failed with error
    // Your Code
}
```
To reduce wait time we recommend to call `configure` on app launch.

###Implement **SMKitSessionDelegate**.
Now please implement the SMKitSessionDelegate.
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
    //Please notice the 2D joint location are for the video resoltion.
    //Please notice that the 3D joint location are the distance from the camera
    func handlePositionData(poseData2D: [Joint:CGPoint]?, poseData3D: [Joint:SCNVector3]?, jointAnglesData: [LimbsPairs:Float]?){
        
    }
    
    //This function will be called with if ant error occcured.
    func handleSessionErrors(error: any Error) {
        
    }
}
```
###Starting the 3D session
Now we can start the 3D session, to do so please call startSession with a `SMKitSessionSettings` and make sure that `include3D` is set to true.
```swift
//First you will need to start the session with include3D.
func statSession(){
    let sessionSettings = SMKitSessionSettings(
        include3D: true
    )
    do{
        self.flowManager = try SMKitFlowManager(delegate: self)
        try flowManager?.startSession(sessionSettings: sessionSettings)
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
