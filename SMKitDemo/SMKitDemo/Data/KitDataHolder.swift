//
//  KitDataHolder.swift
//  SMKitDemo
//
//  Created by netanel-yerushalmi on 10/10/2024.
//

import SMKit
import SMBase

struct KitDataHolder{
    
    let jointsStyle:[JointStyle]
    let limbsStyles:[LimbStyle]
    let limbMidData:[LimbMidData]

    init(poseType: _Pose = .COCO) {
        
        let defaultLimbStyle = LimbStyle(
            limb: nil,
            pointRad: 10,
            lineWidth: 7,
            fillColor: .white,
            strokeColor: .white,
            shadowColor: .clear
        )
        
        jointsStyle = {
            var styles:[JointStyle] = []
            let joints = Array(poseType.bodyParts.keys)
            let headJoints:[Joint] = [.Neck, .Nose, .LEar, .REar, .LEye, .REye]
            joints.forEach { joint in
                if !headJoints.contains(joint){
                    styles.append(JointStyle(joint: joint, pointRad: 8, color: .black, jointShadowFactor: 0, strokeColor: .white))
                }
            }
            return styles
        }()
        
        limbsStyles = {
            var styles:[LimbStyle] = []
            
            let limbs:[Limb] = [
                Limb(startJoint: .LShoulder, endJoint: .RShoulder),
                Limb(startJoint: .LHip, endJoint: .RHip),
                Limb(startJoint: .RKnee, endJoint: .RAnkle),
                Limb(startJoint: .LKnee, endJoint: .LAnkle),
                Limb(startJoint: .RHip, endJoint: .RKnee),
                Limb(startJoint: .LHip, endJoint: .LKnee),
                Limb(startJoint: .RElbow, endJoint: .RWrist),
                Limb(startJoint: .LElbow, endJoint: .LWrist),
                Limb(startJoint: .RShoulder, endJoint: .RElbow),
                Limb(startJoint: .LShoulder, endJoint: .LElbow),
            ]
            
            limbs.forEach { limb in
                var newStyle = defaultLimbStyle
                newStyle.limb = limb
                styles.append(newStyle)
            }
            return styles
        }()
        
        limbMidData = [
            LimbMidData(
                startLimb: Limb(startJoint: .LShoulder, endJoint: .RShoulder),
                endLimb: Limb(startJoint: .LHip, endJoint: .RHip),
                limbStyle: defaultLimbStyle
            )
        ]
        
    }
    
}
