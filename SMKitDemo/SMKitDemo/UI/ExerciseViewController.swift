//
//  ViewController.swift
//  SMKitDemoApp
//
//  Created by netanel-yerushalmi on 02/07/2024.
//

import SwiftUI
import SMKit
import SMBase
import AVFoundation

class ExerciseViewController: UIViewController {

    var exerciseViewModel = ExerciseViewModel()
    let repModel = ExerciseIndicatorModel()
    var flowManager:SMKitFlowManager?
    var exercise:[String] = []
    var exerciseIndex = 0
    var previewLayer:AVCaptureVideoPreviewLayer?
    let dataHolder = KitDataHolder()

    var currentExercise:String{
        exercise[exerciseIndex]
    }
    
    var isDymnamic:Bool{
       (try? flowManager?.getExerciseType(ByType: currentExercise) == .Dynamic) ?? false
    }
    
    lazy var exerciceView:UIView = {
        guard let view = UIHostingController(
            rootView: ExerciseView(
                model: exerciseViewModel,
                repModel: repModel,
                delegate: self
            )
        ).view else {return UIView()}
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var skeletonView:SkeletonView = {
        let skeletonView = SkeletonView(
            poseType: .COCO,
            limbsStyle: dataHolder.limbsStyles,
            jointsStyle: dataHolder.jointsStyle,
            limbsMidData: dataHolder.limbMidData,
            frame: self.view.frame
        )
        skeletonView.frame = self.view.frame
        return skeletonView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configure(exercise: [String], phonePosition: PhonePosition, showSkeleton: Bool = false) {
        do{
            let sessionSettings = SMKitSessionSettings(
                phonePosition: phonePosition,
                jumpRefPoint: "Hip",
                jumpHeightThreshold: 10,
                userHeight: 170
            )
            flowManager = try SMKitFlowManager(delegate: self)
            
            flowManager?.setDeviceMotionActive(
                phoneCalibrationInfo: SMPhoneCalibrationInfo(
                    YZAngleRange: 70..<90,
                    XYAngleRange: -5..<5
                ),
                tiltDidChange: { _ in
//                    print("\($0.isXYTiltAngleInRange), \($0.isYZTiltAngleInRange)")
                })
            
            self.flowManager?.setDeviceMotionFrequency(isHigh: true)
            self.flowManager?.setBodyPositionCalibrationInactive()

            try flowManager?.setBodyPositionCalibrationActive(delegate: self, screenSize: self.view.frame.size)
            
            try flowManager?.startSession(sessionSettings: sessionSettings)

            self.exercise = exercise
            self.startExercise()
            
            if showSkeleton {
                self.view.addSubview(self.skeletonView)
            }
            self.view.addSubview(exerciceView)
            
            NSLayoutConstraint.activate([
                exerciceView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                exerciceView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
                exerciceView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                exerciceView.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor),
            ])
            
        }catch{
            showError(message: error.localizedDescription)
        }
    }

    func showError(message:String){
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    func setupPreviewLayer(session: AVCaptureSession){
        self.previewLayer?.removeFromSuperlayer()
        self.previewLayer = nil
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = self.view.layer.bounds
        previewLayer.contentsGravity = CALayerContentsGravity.resizeAspect
        previewLayer.videoGravity = .resizeAspect
        self.view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
    }
    
    func startExercise(){
        do{
            try flowManager?.startDetection(exercise: currentExercise)
            DispatchQueue.main.async {
                self.exerciseViewModel.startExercise(exerciseName: self.currentExercise)
                self.repModel.startExercise(isDynamic: self.isDymnamic)
            }
        }catch{
            showError(message: error.localizedDescription)
        }
    }
    
    func showSummary(summary:String){
        guard let summaryView = UIHostingController(rootView: SummaryScreen(summary: summary, dissmissWasPressed: {
            self.dismiss(animated: true)
        })).view else {return}
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(summaryView)
        
        NSLayoutConstraint.activate([
            summaryView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            summaryView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            summaryView.topAnchor.constraint(equalTo: self.view.topAnchor),
            summaryView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
        ])
    }
}

extension ExerciseViewController:SMKitSessionDelegate{
    
    func captureSessionDidSet(session: AVCaptureSession) {
        DispatchQueue.main.async {
            self.setupPreviewLayer(session: session)
        }
    }
    
    func captureSessionDidStop() {
        
    }
    
    func handleDetectionData(movementData: MovementFeedbackData?) {
        if exerciseViewModel.isPaused{
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {return}
            self.exerciseViewModel.updateIsShallow(isShallow: movementData?.isShallowRep)
            if let feedbacks = movementData?.feedback?.map({$0.description}){
                self.exerciseViewModel.addFeedback(feedbacks: feedbacks)
            }
            
            if  movementData?.didFinishMovement == true, isDymnamic{
                print(movementData!)
                
                repModel.repFeedback(isGoodRep: movementData?.isPerfectForm ?? false)
            }
            
            if !isDymnamic{
                repModel.setInPosition(inPosition: movementData?.isInPosition ?? false)
            }
        }
    }
    
    func handlePositionData(poseData2D: [Joint : JointData]?, poseData3D: [Joint : SCNVector3]?, jointAnglesData: [LimbsPairs : Float]?, jointGlobalAnglesData: [Limbs : Float]?, xyzEulerAngles: [String : SCNVector3]?) {
        guard let previewLayer else {return}
        let captureSize = previewLayer.frame.size
        let videoResultion = (previewLayer.session?.sessionPreset ?? .hd1920x1080).videoSize
        
        DispatchQueue.main.async {[weak self] in
            guard let self else {return}
            skeletonView.updateSkeleton(rawData: poseData2D ?? [:], captureSize: captureSize, videoSize: videoResultion)
        }
    }
    
    func handleSessionErrors(error: any Error) {
        DispatchQueue.main.async {
            self.showError(message: error.localizedDescription)
        }
    }

    func didCaptureBuffer(pixelBuffer: CVPixelBuffer, time: CMTime, orientation: CGImagePropertyOrientation) {
        
    }
}

extension ExerciseViewController:ExerciseViewDelegate{
    func nextWasPressed() {
        do{
            let result = try flowManager?.stopDetection()
            
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            let jsonData = try jsonEncoder.encode(result)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            
            print(json as Any)

            if exerciseIndex >= exercise.count - 1{
                self.quitWasPressed()
            }else{
                exerciseIndex += 1
            }
            startExercise()
        }catch{
            self.showError(message: error.localizedDescription)
        }
    }
    
    func puassWasPressed() {
        exerciseViewModel.isPaused.toggle()
    }
    
    func quitWasPressed() {
        do{
            exerciseViewModel.isPaused = true
            guard let result = try flowManager?.stopSession() else {return}
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            let jsonData = try jsonEncoder.encode(result)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)

            print(json as Any)
            showSummary(summary: json ?? "")
        }catch{
            self.showError(message: error.localizedDescription)
        }
        
    }
}

extension ExerciseViewController:SMBodyCalibrationDelegate{
    func bodyCalStatusDidChange(status: SMBodyCalibrationStatus) {
        
    }
    
    func didRecivedBoundingBox(box: BodyCalRectGuide) {
        
    }
}
