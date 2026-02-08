//
//  WelcomScreen.swift
//  SMKitDemoApp
//
//  Created by netanel-yerushalmi on 03/07/2024.
//

import SwiftUI
import SMKit

struct Pre2DExerciseView: View {

    @State var selectedExercises: [String] = []
    @State var showSkeleton: Bool = false

    let startWasPressed: ([String], Bool) -> Void
    let dismissWasPressed: () -> Void

    @ObservedObject var authManager = AuthManager.shared

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

            Toggle(isOn: $showSkeleton) {
                HStack {
                    Image(systemName: "figure.stand")
                    Text("Show Skeleton")
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
                startWasPressed(selectedExercises, showSkeleton)
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
    Pre2DExerciseView(startWasPressed: { _, _ in }, dismissWasPressed: {})
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
