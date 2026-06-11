//
//  WelcomeViewController.swift
//  SMKitDemo
//
//  Created by netanel-yerushalmi on 13/08/2024.
//

import SwiftUI

class WelcomeViewController: UIViewController {
    
    lazy var welcomeView:UIView = {
        guard let view = UIHostingController(rootView: WelcomeView(start2DSession: start2DSession, start3DSession: start3DSession, startAssessment: startAssessment)).view else {return UIView()}
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add buttons to the view
        view.addSubview(welcomeView)
        
        NSLayoutConstraint.activate([
            welcomeView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            welcomeView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            welcomeView.topAnchor.constraint(equalTo: self.view.topAnchor),
            welcomeView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
        ])
    }
    
    func start2DSession(useElevatedMode: Bool) {
        let vc = Pre2DExerciseViewController()
        vc.useElevatedMode = useElevatedMode
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    @objc func start3DSession() {
        let vc = SM3DExerciseViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }

    func startAssessment(useElevatedMode: Bool, manualCameraStart: Bool) {
        let vc = AssessmentViewController()
        vc.isElevated = useElevatedMode
        vc.manualCameraStart = manualCameraStart
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
}
