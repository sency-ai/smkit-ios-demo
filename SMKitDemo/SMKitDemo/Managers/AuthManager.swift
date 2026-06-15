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
    private static let authKeyPlaceholder = "YOUR_SMKIT_AUTH_KEY"
    private static let configuredAuthKey = authKeyPlaceholder
    
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

    var smKitAuthKey: String {
        Self.configuredAuthKey
    }

    var hasConfiguredAuthKey: Bool {
        let key = smKitAuthKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && key != Self.authKeyPlaceholder
    }
}
