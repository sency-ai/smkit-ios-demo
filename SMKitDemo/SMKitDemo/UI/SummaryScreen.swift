//
//  SummaryScreen.swift
//  SMKitDemoApp
//
//  Created by netanel-yerushalmi on 04/07/2024.
//

import SwiftUI

struct SummaryScreen: View {
    let summary:String
    let dissmissWasPressed:()->Void
    
    var body: some View {
        VStack(alignment: .leading){
            
            HStack{
                
                Button{
                    dissmissWasPressed()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("Workout Summary")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)

                Button {
                    UIPasteboard.general.string = summary
                } label: {
                    Image(systemName: "doc.on.doc.fill")
                }
            }
            .foregroundStyle(.white)
            .padding()
            .background(
                Color.gray
            )
            
            ScrollView{
                Text(summary)
                    .font(.callout)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
            }
            .padding()
        }
    }
}

#Preview {
    SummaryScreen(summary: "THIS I A SUMMARY", dissmissWasPressed: {})
}
