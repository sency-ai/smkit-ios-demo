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
    
    init(poseType: _Pose = .HALPE26, excludeHeadJoint: Bool = true) {
        
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
            joints.forEach { joint in
//                let headJoints:[Joint] = [.Neck, .Nose, .LEar, .REar, .LEye, .REye]
//                if !headJoints.contains(joint) || !excludeHeadJoint{
                    styles.append(JointStyle(joint: joint, pointRad: 8, color: .black, jointShadowFactor: 0, strokeColor: .white))
//                }
            }
            return styles
        }()
        
        limbsStyles = {
            var styles:[LimbStyle] = []
            
            let limbs:[Limb] = KitDataHolder.getLimbs(poseType: poseType)
            
            limbs.forEach { limb in
                var newStyle = defaultLimbStyle
                newStyle.limb = limb
                styles.append(newStyle)
            }
            return styles
        }()
        
        var limbMidData:[LimbMidData] = []
        
        if poseType == .COCO{
            limbMidData = [
                LimbMidData(
                    startLimb: Limb(startJoint: .LShoulder, endJoint: .RShoulder),
                    endLimb: Limb(startJoint: .LHip, endJoint: .RHip),
                    limbStyle: defaultLimbStyle
                )
            ]
        }
        
        self.limbMidData = limbMidData
    }
    
    static func getLimbs(poseType: _Pose) -> [Limb] {
        switch poseType{
        case .COCO:
            return [
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
        case .HALPE26:
            return [
                Limb(startJoint: .Nose, endJoint: .LEye),
                Limb(startJoint: .Nose, endJoint: .REye),
                Limb(startJoint: .Nose, endJoint: .LEar),
                Limb(startJoint: .Nose, endJoint: .REar),
                Limb(startJoint: .Neck, endJoint: .LShoulder),
                Limb(startJoint: .Neck, endJoint: .RShoulder),
                Limb(startJoint: .LShoulder, endJoint: .LElbow),
                Limb(startJoint: .LElbow, endJoint: .LWrist),
                Limb(startJoint: .RShoulder, endJoint: .RElbow),
                Limb(startJoint: .RElbow, endJoint: .RWrist),
                Limb(startJoint: .Hip, endJoint: .LHip),
                Limb(startJoint: .Hip, endJoint: .RHip),
                Limb(startJoint: .LHip, endJoint: .LKnee),
                Limb(startJoint: .LKnee, endJoint: .LAnkle),
                Limb(startJoint: .RHip, endJoint: .RKnee),
                Limb(startJoint: .RKnee, endJoint: .RAnkle),
                Limb(startJoint: .LAnkle, endJoint: .LBigToe),
                Limb(startJoint: .RAnkle, endJoint: .RBigToe),
                Limb(startJoint: .LAnkle, endJoint: .LSmallToe),
                Limb(startJoint: .RAnkle, endJoint: .RSmallToe),
                Limb(startJoint: .LAnkle, endJoint: .LHeel),
                Limb(startJoint: .RAnkle, endJoint: .RHeel),
                Limb(startJoint: .Head, endJoint: .Nose),
                Limb(startJoint: .Neck, endJoint: .Nose),
                Limb(startJoint: .Hip, endJoint: .Neck)
            ]
        default:
            return poseType.limbs
        }
    }
    
}
