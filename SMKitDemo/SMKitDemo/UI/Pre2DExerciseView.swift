//
//  WelcomScreen.swift
//  SMKitDemoApp
//
//  Created by netanel-yerushalmi on 03/07/2024.
//

import SwiftUI
import SMKit

struct Pre2DExerciseView: View {
    
    @State var phonePosition:PhonePosition = .Floor
    @State var selectedExercises:[String] = []
    
    let startWasPressed:(PhonePosition, [String])->Void
    let dismissWasPressed:()->Void

    @ObservedObject var authManager = AuthManager.shared
    
    var body: some View {
        VStack(alignment: .leading,spacing: 20){
            HStack{
                Text("SMKit 2D Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: dismissWasPressed){
                    Image(systemName: "xmark")
                        .font(.title2)
                        .padding()
                }
            }
            Spacer()

            VStack(alignment:.leading){
                HStack{
                    Image(systemName: "iphone")
                    Text("Phone Position")
                }
                
                Picker("", selection: $phonePosition){
                    ForEach(PhonePosition.allCases, id:\.self){ pos in
                        Text(pos.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            .font(.title2)
            .fontWeight(.medium)
            
            ScrollView{
                VStack(alignment:.leading, spacing: 10){
                    Text("Exercises")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    ForEach(DemoExercises.allCases, id:\.self){ exercise in
                        Button(action: {
                            selectedExercises.append(exercise.rawValue)
                        }){
                            HStack{
                                Text(exercise.rawValue)
                                    .foregroundStyle(.accent)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Spacer()
                                let selectedCount = selectedExercises.filter({$0 == exercise.rawValue}).count
                                if selectedCount < 5{
                                    ForEach(0..<selectedCount, id: \.self){ _ in
                                        Circle()
                                            .fill(.green)
                                            .frame(height: 5)
                                    }
                                }else{
                                    Text("\(selectedCount)")
                                        .font(.footnote)
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.trailing)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(.accent)
                                    .shadow(color: .black,radius: 1)
                            )                            
                        }
                        .padding(.horizontal, 5)
                        .onAppear{
                            selectedExercises.removeAll()
                        }
                    }
                }
            }
            
            
            Button {
                startWasPressed(phonePosition, selectedExercises)
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
    Pre2DExerciseView(startWasPressed: {_,_ in}, dismissWasPressed: {})
}

enum DemoExercises:String, CaseIterable{
    // Dynamic Exercises
    case AlternateWindmillToeTouch
    case Burpees
    case Crunches
    case LungeFrontRight
    case LungeFrontLeft
    case Froggers
    case GlutesBridge
    case HighKnees
    case Jumps
    case JumpingJacks
    case LateralRaises
    case LungeSide
    case LungeSideRight
    case LungeSideLeft
    case PlankHighShoulderTaps
    case PushupKnees
    case PushupKneesNarrow
    case PushupKneesWide
    case PushupNarrow
    case PushupWide
    case PushupRegular
    case ReverseSitToTableTop
    case SquatRegular
    case SquatAndRotationJab
    case SquatAndStep
    case SquatSumo
    case SquatNarrow
    case SquatRegularOverhead
    case ShouldersPress
    case StandingAlternateToeTouch
    case StandingBicycleCrunches
    case StandingObliqueCrunches
    case ShouldersPress
    case SkiJumps
    case SkaterHops
    case QuadThoraticRotation

    // Static / Isometric Exercises
    case PlankHighStatic
    case LungeRegularStaticLeft
    case LungeRegularStaticRight
    case LungeSideStaticLeft
    case LungeSideStaticRight
    case SquatRegularOverheadStatic
    case PlankSideLowStatic
    case SquatRegularStatic
    case SquatSumoStatic
    case TuckHold
    case AnkleMobilityLeft
    case AnkleMobilityRight
    case HamstringMobility
    case HipExternalRotationLeft
    case HipExternalRotationRight
    case HipFlexionLeft
    case HipFlexionRight
    case HipInternalRotationLeft
    case HipInternalRotationRight
    case InnerThighMobility
    case JeffersonCurl
    case OverheadMobility
    case StandingKneeRaiseRight
    case StandingKneeRaiseLeft
    case StandingSideBendRight
    case StandingSideBendLeft


    case Rest
    case Cooldown
}
