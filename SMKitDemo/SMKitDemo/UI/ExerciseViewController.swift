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
    private var pendingBoundingBox: BodyCalRectGuide?
    private var boundingBoxGuideView: BodyCalibrationGuideView?
    private var manualCameraStart = false

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
    
    func configure(exercise: [String], phonePosition: PhonePosition, showSkeleton: Bool = false, manualCameraStart: Bool = false) {
        do{
            self.exercise = exercise
            self.manualCameraStart = manualCameraStart
            exerciseViewModel.manualCameraStartEnabled = manualCameraStart
            exerciseViewModel.cameraCaptureRunning = !manualCameraStart
            exerciseViewModel.cameraStatusText = manualCameraStart ? "waiting for manual camera start" : ""
            let sessionSettings = SMKitSessionSettings(
                phonePosition: phonePosition,
                jumpRefPoint: "Hip",
                jumpHeightThreshold: 10,
                userHeight: 170,
                autoStartCamera: !manualCameraStart
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
            self.flowManager?.verboseBodyCalibration = true
            self.flowManager?.startSession(sessionSettings: sessionSettings) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    do {
                        try self.flowManager?.setBodyPositionCalibrationActive(
                            delegate: self,
                            screenSize: self.view.frame.size
                        )
                        self.setupExerciseUI(showSkeleton: showSkeleton)
                        self.startExercise()
                        if self.manualCameraStart {
                            self.exerciseViewModel.cameraStatusText = "preview attached before camera start"
                        }
                    } catch {
                        self.showError(message: error.localizedDescription)
                    }
                case .failure(let error):
                    self.showError(message: error.localizedDescription)
                }
            }
            
        }catch{
            showError(message: error.localizedDescription)
        }
    }

    private func setupExerciseUI(showSkeleton: Bool) {
        if showSkeleton, skeletonView.superview == nil {
            view.addSubview(skeletonView)
        }
        guard exerciceView.superview == nil else { return }
        view.addSubview(exerciceView)

        NSLayoutConstraint.activate([
            exerciceView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exerciceView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            exerciceView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            exerciceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
        ])
    }

    func showError(message:String){
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
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
            if self.manualCameraStart {
                self.exerciseViewModel.cameraCaptureRunning = session.isRunning
                self.exerciseViewModel.cameraStatusText = "preview attached, session running: \(session.isRunning)"
            }
            if let box = self.pendingBoundingBox {
                self.setupBoundingBoxGuideView(box: box)
            }
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
    
    func handlePositionData(poseData2D: [Joint : JointData]?, poseData3D: [Joint : SCNVector3]?, jointAnglesData: [LimbsPairs : Float]?, jointGlobalAnglesData: [Limbs : Float]?, xyzEulerAngles: [String : SCNVector3]?, xyzRelativeAngles: [String : SCNVector3]?) {
        DispatchQueue.main.async {[weak self] in
            guard let self, let previewLayer else {return}
            let captureSize = previewLayer.frame.size
            let videoResultion = (previewLayer.session?.sessionPreset ?? .hd1920x1080).videoSize
            skeletonView.updateSkeleton(rawData: poseData2D ?? [:], captureSize: captureSize, videoSize: videoResultion)
        }
    }

    func handleAnatomicalAngles(anatomicalAngles: [String : SCNVector3]?) {

    }
    
    func handleSessionErrors(error: any Error) {
        DispatchQueue.main.async {
            self.showError(message: error.localizedDescription)
        }
    }

    func didCaptureBuffer(pixelBuffer: CVPixelBuffer, time: CMTime, orientation: CGImagePropertyOrientation) {
        
    }

    func videoSessionProcessingProgress(progress: Float, processedFrames: Int) {

    }

    func videoSessionDidFinish() {

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
                return
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

    func startCameraCaptureWasPressed() {
        flowManager?.startCameraCapture { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    self.exerciseViewModel.cameraCaptureRunning = true
                    self.exerciseViewModel.cameraStatusText = "camera capture started"
                case .failure(let error):
                    self.showError(message: error.localizedDescription)
                }
            }
        }
    }

    func stopCameraCaptureWasPressed() {
        flowManager?.stopCameraCapture { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    self.exerciseViewModel.cameraCaptureRunning = false
                    self.exerciseViewModel.cameraStatusText = "camera capture stopped, session still active"
                case .failure(let error):
                    self.showError(message: error.localizedDescription)
                }
            }
        }
    }
    
    func quitWasPressed() {
        exerciseViewModel.isPaused = true
        flowManager?.stopSession { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let sessionData):
                guard let sessionData else { return }
                do {
                    let jsonEncoder = JSONEncoder()
                    jsonEncoder.outputFormatting = .prettyPrinted
                    let jsonData = try jsonEncoder.encode(sessionData)
                    let json = String(data: jsonData, encoding: String.Encoding.utf8)

                    print(json as Any)
                    self.showSummary(summary: json ?? "")
                } catch {
                    self.showError(message: error.localizedDescription)
                }
            case .failure(let error):
                self.showError(message: error.localizedDescription)
            }
        }
        
    }
}

extension ExerciseViewController: SMBodyCalibrationDelegate {
    func bodyCalStatusDidChange(status: SMBodyCalibrationStatus) {
        DispatchQueue.main.async {
            switch status {
            case .DidEnterFrame:
                self.boundingBoxGuideView?.setInPosition(true)
            case .DidLeaveFrame:
                self.boundingBoxGuideView?.setInPosition(false)
            case .TooClose:
                break
            @unknown default:
                break
            }
        }
    }

    func didRecivedBoundingBox(box: BodyCalRectGuide) {
        DispatchQueue.main.async {
            self.pendingBoundingBox = box
            if self.previewLayer != nil {
                self.setupBoundingBoxGuideView(box: box)
            }
        }
    }

    private func setupBoundingBoxGuideView(box: BodyCalRectGuide) {
        boundingBoxGuideView?.removeFromSuperview()
        let videoSize = (previewLayer?.session?.sessionPreset ?? .hd1920x1080).videoSize
        let guideRect = box.screenRect(videoSize: videoSize, viewSize: view.bounds.size)
        let guideView = BodyCalibrationGuideView(guideRect: guideRect, frame: view.bounds)
        view.insertSubview(guideView, at: 0)
        boundingBoxGuideView = guideView
    }
}
