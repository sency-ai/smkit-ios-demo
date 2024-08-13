//
//  AuthManager.swift
//  SMKitDemoApp
//
//  Created by netanel-yerushalmi on 03/07/2024.
//

import Foundation

protocol AuthManagerDelegate:NSObject{
    func didFinishAuth()
    func didFailAuth()
}

class AuthManager:ObservableObject{
    static let shared = AuthManager()
    
    @Published var didFinishAuth = false{
        didSet{
            if didFaildAuth{
                delegate?.didFinishAuth()
            }
        }
    }
    @Published var didFaildAuth = false{
        didSet{
            delegate?.didFailAuth()
        }
    }
    
    weak var delegate:AuthManagerDelegate?
}
