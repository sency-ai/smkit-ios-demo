//
//  ExerciseTimerView.swift
//  SMKitDemoApp
//
//  Created by netanel-yerushalmi on 02/07/2024.
//

import SwiftUI

struct ExerciseTimerView: View {
    @Binding var timePassed:Float
    @Binding var isPaused:Bool
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var formattedTime:String{
        let time = Int(timePassed)
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(
            [.minute, .second],
            from: Date(),
            to: Date() + TimeInterval(time)
        )
        let minute = components.minute ?? 0
        let second = components.second ?? 0

        return String(format: "%02d:%02d", minute, second)
    }
    
    var body: some View {
        Text(formattedTime)
            .foregroundStyle(.white)
            .font(.largeTitle)
            .fontWeight(.bold)
            .stroke(color: .black)
            .onReceive(timer) { _ in
                if !isPaused{
                    timePassed += 0.1
                }
            }
    }
}

#Preview {
    ExerciseTimerView(timePassed: .constant(0), isPaused: .constant(false))
        .padding()
        .background(.red)
}
