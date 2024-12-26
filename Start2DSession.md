##Start 2D exercise detection 

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
    //Please notice the 2D joint location are for the video resoltion.
    func handlePositionData(poseData2D: [Joint:JointData]?, poseData3D: [Joint : SCNVector3]?, jointAnglesData: [LimbsPairs : Float]?) {
        
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
