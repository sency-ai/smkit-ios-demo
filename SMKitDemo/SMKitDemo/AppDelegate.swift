//
//  AppDelegate.swift
//  SMKitDemo
//
//  Created by netanel-yerushalmi on 15/04/2024.
//

import UIKit
import SMBase
import SMKit

private enum DemoConfiguration {
    // Demo default: wait for server-downloaded NN models before configure succeeds.
    // Set to false to start with a valid, previously server-downloaded cache when available.
    static var waitForRemoteModelsOnFirstLaunch = true
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let authKey = AuthManager.shared.smKitAuthKey
        guard AuthManager.shared.hasConfiguredAuthKey else {
            print("Missing SMKit auth key. Replace YOUR_SMKIT_AUTH_KEY in AuthManager.swift before running the demo.")
            AuthManager.shared.didFaildAuth = true
            return true
        }

        let modelDownloadPolicy: SMModelDownloadPolicy = DemoConfiguration.waitForRemoteModelsOnFirstLaunch ? .waitForRemoteModelsThenFallback : .immediateFallback
        SMKitFlowManager.configure(
            authKey: authKey,
            shouldSupport3D: true,
            modelDownloadPolicy: modelDownloadPolicy,
            downloadProgress: { completed, total in
                print("SMKit assets download progress: \(completed)/\(total)")
            }
        ) {
            // The configuration was successful
            // Your Code
            DispatchQueue.main.async {
                AuthManager.shared.didFinishAuth = true
            }
        } onFailure: { error in
            // The configuration failed with error
            // Your Code
            print(error as Any)
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}
