//
//  ExerciseIndicatorView.swift
//  SMKitDemoApp
//
//  Created by netanel-yerushalmi on 02/07/2024.
//

import SwiftUI

class ExerciseIndicatorModel:ObservableObject{
    @Published fileprivate var didFinishRep: Bool = false
    @Published var finishedReps:Int = 0
    @Published var isDynamic = true
    @Published var inPosition = false
    
    private var lastGoodRep = Date(){
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self = self else {return}
                if canShrinkCircle, didFinishRep{
                    didFinishRep = false
                }
            }
        }
    }
    
    var canShrinkCircle:Bool{
       return Date().timeIntervalSince1970 - lastGoodRep.timeIntervalSince1970 >= 0.8
    }
    
    func startExercise(isDynamic:Bool){
        finishedReps = 0
        self.isDynamic = isDynamic
    }
    
    func setInPosition(inPosition: Bool){
        if self.inPosition != inPosition{
            self.inPosition = inPosition
        }
    }
    
    func repFeedback(isGoodRep:Bool){
        finishedReps += 1
        if isGoodRep{
            didFinishRep = true
            lastGoodRep = Date()
        }
    }
}

struct ExerciseIndicatorView: View {
    @ObservedObject var model: ExerciseIndicatorModel
    @State private var scale:CGFloat = 1
    @State private var circleColor:Color = .black.opacity(0.8)
    
    var body: some View {
        Circle()
            .fill(circleColor)
            .frame(height: 100)
            .overlay(
                ZStack{
                    Circle()
                        .stroke(.white)
                    
                    Text("\(model.finishedReps)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .opacity(model.isDynamic ? 1 : 0)
                }
            )
            .scaleEffect(scale)
            .onChange(of: model.didFinishRep) { newValue in
                playScaleAnim()
            }
            .onChange(of: model.inPosition) { newValue in
                if newValue{
                    playBreathingAnim()
                }
            }
    }
    
    func playScaleAnim(){
        let didFinishRep = model.didFinishRep
        circleColor = didFinishRep ? .green : .black
        withAnimation(.easeInOut(duration: 0.5)) {
            scale = didFinishRep ? 1.2 : 0.8
        }
    }
    
    func playBreathingAnim(){
        let animTime:Double = 1
        withAnimation(.easeIn(duration: animTime)) {
            scale = 1.1
            circleColor = .green
        }
        withAnimation(.easeOut(duration: animTime).delay(animTime)) {
            scale = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (animTime * 2)) {
            if model.inPosition{
                playBreathingAnim()
            }else{
                circleColor = .black
            }
        }
    }
}

#Preview {
    ExerciseIndicatorView(model: ExerciseIndicatorModel())
        .padding()
        .background( Color.red)
}
