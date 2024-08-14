//
//  WelcomeViewController.swift
//  SMKitDemo
//
//  Created by netanel-yerushalmi on 13/08/2024.
//

import SwiftUI

class WelcomeViewController: UIViewController {
    
    lazy var welcomeView:UIView = {
        guard let view = UIHostingController(rootView: WelcomeView(start2DSession: start2DSession, start3DSession: start3DSession)).view else {return UIView()}
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
    
    @objc func start2DSession() {
        let vc = Pre2DExerciseViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    @objc func start3DSession() {
        let vc = SM3DExerciseViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
}
