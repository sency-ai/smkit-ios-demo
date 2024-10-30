//
//  SM3DExerciseViewController.swift
//  SMKitDemo
//
//  Created by netanel-yerushalmi on 13/08/2024.
//

import SwiftUI

import SMKit
import SMBase
import SceneKit

class SM3DExerciseViewController: UIViewController {

    var flowManager:SMKitFlowManager?

    var session:AVCaptureSession?
    var previewLayer:AVCaptureVideoPreviewLayer?
    let sm3DInfoViewModel = SM3DInfoViewModel()
    
    lazy var sm3DInfoView:UIView = {
        guard let view = UIHostingController(rootView: SM3DInfoView(model: sm3DInfoViewModel, dismissWasPressed: dismissWasPressed)).view else {return UIView()}
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do{
            self.flowManager = try SMKitFlowManager(delegate: self)
            self.startSession()
            
            self.view.addSubview(sm3DInfoView)
            
            NSLayoutConstraint.activate([
                sm3DInfoView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                sm3DInfoView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
                sm3DInfoView.topAnchor.constraint(equalTo: self.view.topAnchor),
                sm3DInfoView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            ])
            
        }catch{
            self.showAlert(message: error.localizedDescription)
        }
    }
    
    func dismissWasPressed(){
        let _ = try? self.flowManager?.stopSession()
        self.dismiss(animated: true)
    }
    
    func startSession(){
        do{
            try flowManager?.startSession(sessionSettings: SMKitSessionSettings(include3D: true))
        }catch{
            showAlert(message: error.localizedDescription)
        }
    }

    func setupPreviewLayer(){
        self.previewLayer?.removeFromSuperlayer()
        self.previewLayer = nil
        if let session = session {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = self.view.layer.bounds
            previewLayer.contentsGravity = CALayerContentsGravity.resizeAspect
            previewLayer.videoGravity = .resizeAspect
            self.view.layer.insertSublayer(previewLayer, at: 0)
            self.previewLayer = previewLayer
        }
    }
    
    func showAlert(message:String){
        let alert = UIAlertController(title: "ERROR", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
}

extension SM3DExerciseViewController:SMKitSessionDelegate{
    func captureSessionDidSet(session: AVCaptureSession) {
        self.session = session
        DispatchQueue.main.async {
            self.setupPreviewLayer()
        }
    }
    
    func captureSessionDidStop() {
        
    }
    
    func handleDetectionData(movementData: MovementFeedbackData?) {
        
    }
    
    
    func handleSessionErrors(error: any Error) {
        
    }
    
    func handlePositionData(poseData2D: [Joint : CGPoint]?, poseData3D: [Joint : SCNVector3]?, jointAnglesData: [LimbsPairs : Float]?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {return}
            sm3DInfoViewModel.posData = poseData3D ?? [:]
            sm3DInfoViewModel.threeDAnglesData = jointAnglesData ?? [:]
        }
    }
}
