//
//  WelcomScreenViewController.swift
//  SMKitDemoApp
//
//  Created by netanel-yerushalmi on 03/07/2024.
//

import SwiftUI
import SMKitDev

class Pre2DExerciseViewController:UIViewController{
    
    lazy var welcomeScreen:UIView = {
        guard let view = UIHostingController(rootView: Pre2DExerciseView(startWasPressed: startWasPressed, dismissWasPressed: dismissWasPressed)).view else {return UIView()}
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(welcomeScreen)
        self.view.backgroundColor = .backgroundAccent
        NSLayoutConstraint.activate([
            welcomeScreen.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            welcomeScreen.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            welcomeScreen.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            welcomeScreen.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor),
        ])
    }
    
    func startWasPressed(phonePostion:PhonePosition, exercise:[String]){
        let vc = ExerciseViewController()
        vc.configure(exercise: exercise, phonePosition: phonePostion)
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    func dismissWasPressed(){
        self.dismiss(animated: true)
    }
}
