//
//  WelcomeView.swift
//  SMKitDemo
//
//  Created by netanel-yerushalmi on 13/08/2024.
//

import SwiftUI

struct WelcomeView: View {
    let start2DSession:()->Void
    let start3DSession:()->Void
    let startAssessment:()->Void
    
    @ObservedObject var authManager = AuthManager.shared

    var body: some View {
        VStack(spacing: 20){
            Text("SMKit Demo")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
            Spacer()
            
            Button {
                start2DSession()
            } label: {
                Text("Start 2D Session")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.blue)
                    )
            }
            
            Button {
                start3DSession()
            } label: {
                Text("Start 3D Session")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.blue)
                    )
            }

            Button {
                startAssessment()
            } label: {
                Text("Demo Assessment")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.green)
                    )
            }

            Spacer()

        }
        .padding()
        .blur(radius: !authManager.didFinishAuth ? 3.0 : 0)
        .overlay(
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.black.opacity(0.5))
                )
                .opacity(!authManager.didFinishAuth ? 1 : 0)
        )
    }
}

#Preview {
    WelcomeView(start2DSession: {}, start3DSession: {}, startAssessment: {})
}
