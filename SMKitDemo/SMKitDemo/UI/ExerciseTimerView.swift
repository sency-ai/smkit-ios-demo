//
//  ExerciseTimerView.swift
//  SMKitDemoApp
//
//  Created by netanel-yerushalmi on 02/07/2024.
//

import SwiftUI

struct ExerciseTimerView: View {
    @Binding var timePassed:Int
    @Binding var isPaused:Bool
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var formattedTime:String{
        let minute = timePassed / 60
        let second = timePassed % 60
        
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
                    timePassed += 1
                }
            }
    }
}

#Preview {
    ExerciseTimerView(timePassed: .constant(0), isPaused: .constant(false))
        .padding()
        .background(.red)
}
