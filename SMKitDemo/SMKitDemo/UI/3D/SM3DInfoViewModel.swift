//
//  SM3DInfoViewModel.swift
//  SMKitDemo
//
//  Created by netanel-yerushalmi on 13/08/2024.
//

import SwiftUI

import SwiftUI
import SceneKit
import SMBaseDev

public class SM3DInfoViewModel:ObservableObject{
    @Published public var posData:[Joint : SCNVector3] = [:]
    @Published public var threeDAnglesData: [LimbsPairs:Float] = [:]
    
    public init() {}
}

public struct SM3DInfoView: View {
    @ObservedObject var model:SM3DInfoViewModel
    let dismissWasPressed:()->Void
    var hip:String{
        (model.posData[.Hip] ?? .init(0, 0, 0)).stringValue
    }
    
    var sortedAngles:[LimbsPairs]{
        model.threeDAnglesData.keys.sorted(by: {$0.sortValue < $1.sortValue}) as [LimbsPairs]
    }
    
    public var body: some View {
        VStack(alignment: .leading){
//            HStack(alignment: .top){
                if !model.posData.isEmpty{
                    SM3DSkeletonRepresentable(posData: $model.posData)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .frame(width: 150, height: 300)
                }
//                Spacer()
                
//                Button(action: dismissWasPressed){
//                    Image(systemName: "xmark")
//                        .foregroundStyle(.white)
//                        .padding()
//                        .background(
//                            RoundedRectangle(cornerRadius: 10)
//                                .fill(.black.opacity(0.5))
//                        )
//                }
//                .padding(.horizontal)
//            }
            if model.posData.isEmpty{
                Spacer()
                Text("MOVE IN RANGE")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                        .fill(.black.opacity(0.5))
                    )
                    .frame(maxWidth: .infinity,alignment: .center)
            }
//            Spacer()
            
//            HStack{
//                Spacer()
//                VStack{
//                    SM3DInfoViewLabel(title: "Hip", value: hip)
//                    ForEach(0..<sortedAngles.count, id: \.self){ i in
//                        let angle = sortedAngles[i]
//                        let value = model.threeDAnglesData[angle]
//                        
//                        SM3DInfoViewLabel(title: angle.rawValue, value: "\(String(format: "%.1f", value ?? 0))")
//                    }
//                }
//                .foregroundColor(.white)
//            }
        }
        .background(Color.clear)
        .overlay(
            Button(action: dismissWasPressed){
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.black.opacity(0.5))
                    )
            }
            .padding(.horizontal)
            ,alignment: .topLeading
        )
    }
}

#Preview {
    SM3DInfoView(model: .init(), dismissWasPressed: {})
}

struct SM3DSkeletonRepresentable:UIViewRepresentable{
    
    @State var skeleton:SM3DSkeleton = SM3DSkeleton(poseType: .Sency25)
    @Binding var posData:[Joint : SCNVector3]
    
    func makeUIView(context: Context) -> some SM3DSkeleton {
        skeleton
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        skeleton.updateNodes(posData: posData)
    }
}


fileprivate struct SM3DInfoViewLabel:View{
    let title:String
    let value:String
    
    var body: some View {
        HStack{
            Text("\(title):")
                .fontWeight(.bold)
            Text(value)
        }
        .font(.title3)
        .foregroundColor(.red)
    }
}

extension SCNVector3{
    var stringValue:String{
        "x: \(String(format: "%.1f",x)), y: \(String(format: "%.1f",y)), z: \(String(format: "%.1f",z))"
    }
}
