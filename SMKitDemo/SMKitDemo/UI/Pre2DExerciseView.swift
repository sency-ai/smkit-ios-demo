//
//  WelcomScreen.swift
//  SMKitDemoApp
//
//  Created by netanel-yerushalmi on 03/07/2024.
//

import SwiftUI
import SMKit

struct Pre2DExerciseView: View {

    @State private var selectedExercises: [String] = []
    @State private var showSkeleton: Bool = false
    @State private var useElevatedMode: Bool
    @State private var manualCameraStart: Bool = false

    let startWasPressed: ([String], Bool, Bool, Bool) -> Void
    let dismissWasPressed: () -> Void

    @ObservedObject var authManager = AuthManager.shared

    init(
        useElevatedMode: Bool,
        startWasPressed: @escaping ([String], Bool, Bool, Bool) -> Void,
        dismissWasPressed: @escaping () -> Void
    ) {
        _useElevatedMode = State(initialValue: useElevatedMode)
        self.startWasPressed = startWasPressed
        self.dismissWasPressed = dismissWasPressed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("SMKit 2D Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: dismissWasPressed) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .padding()
                }
            }
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text("Session Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Toggle(isOn: $showSkeleton) {
                    HStack {
                        Image(systemName: "figure.stand")
                        Text("Show Skeleton")
                    }
                }

                Toggle(isOn: $useElevatedMode) {
                    HStack {
                        Image(systemName: "iphone")
                        Text("Elevated Mode")
                    }
                }

                Toggle(isOn: $manualCameraStart) {
                    HStack {
                        Image(systemName: "video.badge.ellipsis")
                        Text("Manual Camera Start")
                    }
                }
            }
            .font(.title2)
            .fontWeight(.medium)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Exercises")
                        .font(.title2)
                        .fontWeight(.medium)

                    ForEach(DemoExercises.allCases.sorted { $0.rawValue < $1.rawValue }, id: \.self) { exercise in
                        let isSelected = selectedExercises.contains(exercise.rawValue)
                        Button(action: {
                            if isSelected {
                                selectedExercises.removeAll { $0 == exercise.rawValue }
                            } else {
                                selectedExercises.append(exercise.rawValue)
                            }
                        }) {
                            HStack {
                                Text(exercise.rawValue)
                                    .foregroundStyle(isSelected ? .white : .accent)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.white)
                                        .padding(.trailing, 8)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(isSelected ? .green : .clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(.accent)
                                    )
                            )
                        }
                        .padding(.horizontal, 5)
                    }
                }
            }

            Button {
                startWasPressed(selectedExercises, showSkeleton, useElevatedMode, manualCameraStart)
            } label: {
                Text("START")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(selectedExercises.isEmpty ? .gray : .blue)
                    )
            }
            .disabled(selectedExercises.isEmpty)
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
    Pre2DExerciseView(useElevatedMode: true, startWasPressed: { _, _, _, _ in }, dismissWasPressed: {})
}

enum DemoExercises: String, CaseIterable {
    case StandingSideBendRight
    case StandingSideBendLeft
    case JeffersonCurl
    case SquatRegular
    case SquatRegularOverheadStatic
    case PlankHighStatic
    case StandingKneeRaiseRight
    case StandingKneeRaiseLeft
    case AnkleMobilityLeft
    case AnkleMobilityRight
}
