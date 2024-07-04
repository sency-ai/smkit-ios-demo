//
//  ExerciseView.swift
//  SMKitDemoApp
//
//  Created by netanel-yerushalmi on 02/07/2024.
//

import SwiftUI

class ExerciseViewModel:ObservableObject{
    @Published var exerciseName:String = ""
    @Published var isPaused = false
    @Published fileprivate var feedbacks:[String] = []
    @Published var isShallow:Bool? = false
    @Published var timePassed = 0
    
    func addFeedback(feedbacks:[String]){
        if self.feedbacks != feedbacks{
            self.feedbacks = feedbacks
        }
    }
    
    func updateIsShallow(isShallow:Bool?){
        if self.isShallow != isShallow{
            self.isShallow = isShallow
        }
    }
    
    func startExercise(exerciseName:String){
        self.exerciseName = exerciseName
        feedbacks = []
        isPaused = false
        timePassed = 0
    }
}

protocol ExerciseViewDelegate{
    func nextWasPressed()
    func puassWasPressed()
    func quitWasPressed()
}

struct ExerciseView: View {
    @ObservedObject var model:ExerciseViewModel
    @ObservedObject var repModel:ExerciseIndicatorModel
    
    let delegate:ExerciseViewDelegate
    
    var body: some View {
        VStack(spacing: 0){
            
            Text(model.exerciseName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    Color.black.opacity(0.5)
                )
            
            
            VStack{
                ExerciseIndicatorView(model: repModel)
                
                Spacer()
                
                ExerciseTimerView(timePassed: $model.timePassed, isPaused: $model.isPaused)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            .overlay(
                HStack(spacing: 0){
                    VStack{
                        ExerciseViewButton(imageName: "arrowshape.right", action: delegate.nextWasPressed)
                        ExerciseViewButton(
                            imageName: model.isPaused ? "play.fill" : "pause.fill",
                            action: delegate.puassWasPressed
                        )
                        ExerciseViewButton(imageName: "stop.fill", action: delegate.quitWasPressed)
                    }
                    .frame(maxHeight: .infinity)
                    .background(
                        Color.black.opacity(0.5)
                    )
                    Spacer()
                }
            )
            .frame(maxHeight: .infinity)
            
            VStack(alignment: .leading){
                ForEach(model.feedbacks, id:\.self){ feedback in
                    Text(feedback)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("isShallow: \(model.isShallow?.description ?? "nil")")
                    .frame(maxWidth: .infinity,alignment: .leading)
            }
            .foregroundStyle(.white)
            .padding()
            .frame(minWidth: 100)
            .background(
                Color.black.opacity(0.5)
            )
        }
    }
}

#Preview {
    ExerciseView(model: ExerciseViewModel(), repModel: ExerciseIndicatorModel(), delegate: ExerciseViewDelegateTest())
}

class ExerciseViewDelegateTest:ExerciseViewDelegate{
    func nextWasPressed() {
        
    }
    
    func puassWasPressed() {
        
    }
    
    func quitWasPressed() {
        
    }
}

struct ExerciseViewButton: View {
    let imageName:String
    let action:()->Void
    
    var body: some View {
        Button(action: action){
            Image(systemName: imageName)
                .font(.title2)
                .foregroundStyle(.white)
                .padding()
        }
    }
}
