//
//  ViewController.swift
//  SMKitDemo
//
//  Created by netanel-yerushalmi on 15/04/2024.
//

import UIKit
import SMKit

class ViewController: UIViewController {
    
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
}


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
    //Please notice the 2D joint location are for the video resoltion.
    //Please notice that the 3D joint location are the distance from the camera
    func handlePositionData(poseData2D: [Joint : JointData]?, poseData3D: [Joint : SCNVector3]?, jointAnglesData: [LimbsPairs : Float]?, jointGlobalAnglesData: [Limbs : Float]?) {

    }
    
    //This function will be called with if ant error occcured.
    func handleSessionErrors(error: any Error) {
        
    }
}

extension ViewController:SMBodyCalibrationDelegate{
    func bodyCalStatusDidChange(status: SMBodyCalibrationStatus) {
        switch status{
        case .DidEnterFrame:
            print("DidEnterFrame")
        case .DidLeaveFrame:
            print("DidLeaveFrame")
        case .TooClose(let tooClose):
            print("TooClose \(tooClose)")
        @unknown default:
            break
        }
    }
    
    // BodyCalRectGuide will give you the 'box' size and location
    func didRecivedBoundingBox(box: BodyCalRectGuide) {
        
    }
}
