//
//  SM3DSkeleton.swift
//  SMKitDemo
//
//  Created by netanel-yerushalmi on 13/08/2024.
//

import Foundation

import UIKit
import SceneKit
import SMBaseDev

public class SM3DSkeleton:UIView{
    
    let joints:[Joint]
    var sphereNodes: [Joint:SCNNode] = [:]
    var limbsNodes: [Limb:SCNNode] = [:]

    var limbs:[Limb] = [
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
        Limb(startJoint: .RShoulder, endJoint: .RHip),
        Limb(startJoint: .LShoulder, endJoint: .LHip),
    ]
    
    lazy var sceneView: SCNView = {
        // Create and configure the SceneView
        let sceneView = SCNView(frame: frame)
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.black
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a new Scene
        let scene = SCNScene()
        scene.rootNode.position = SCNVector3(0,0,-0.5)
        sceneView.scene = scene
        
        // Add the SceneView to the ViewController's view
        return sceneView
    }()
    
    init(poseType: PoseType) {
        joints = poseType.bodyParts.map({$0.key})
        super.init(frame: .zero)

        self.addFloor()
        self.setupScene()
        self.createNods()
    }
    
    func setupScene() {
        self.addSubview(sceneView)
        
        NSLayoutConstraint.activate([
            sceneView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            sceneView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            sceneView.topAnchor.constraint(equalTo: self.topAnchor),
            sceneView.leftAnchor.constraint(equalTo: self.leftAnchor),
        ])
    }
    
    func createNods(){
        joints.forEach { joint in
            let sphere = SCNSphere(radius: 0.05)
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.position = SCNVector3(0,0,0)
            let color = UIColor.random
            sphereNode.geometry?.materials.first?.diffuse.contents = color
            sphereNode.geometry?.materials.first?.emission.intensity = 1
            sphereNode.geometry?.materials.first?.emission.contents = color

            sphereNodes[joint] = sphereNode
            sceneView.scene?.rootNode.addChildNode(sphereNode)
        }
        
        createLimbs()
    }
    
    func createLimbs(){
        for limb in limbs{
            // Calculate the midpoint and direction
            guard let startNode = sphereNodes[limb.startJoint],
                  let endPosition = sphereNodes[limb.endJoint]?.position else {continue}
            
            let startPosition = startNode.position

            let midPosition = SCNVector3(
                (startPosition.x + endPosition.x) / 2,
                (startPosition.y + endPosition.y) / 2,
                (startPosition.z + endPosition.z) / 2
            )
            
            let direction = SCNVector3(
                endPosition.x - startPosition.x,
                endPosition.y - startPosition.y,
                endPosition.z - startPosition.z
            )
            
            // Calculate the length of the line
            let distance = sqrt(
                pow(direction.x, 2) +
                pow(direction.y, 2) +
                pow(direction.z, 2)
            )
            
            // Create the line geometry
            let lineGeometry = SCNCylinder(radius: 0.01, height: CGFloat(distance))
            
            let lineNode = SCNNode(geometry: lineGeometry)
            lineNode.position = midPosition

            // Rotate the line to align with the direction
            let nodeZAxis = SCNVector3(0, 1, 0) // SCNCylinder's default orientation is along the y-axis
            let axis = nodeZAxis.cross(direction).normalized()
            let angle = acos(nodeZAxis.dot(direction.normalized()))
            lineNode.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)

            lineNode.geometry?.materials.first?.diffuse.contents = startNode.geometry?.materials.first?.diffuse.contents
            // Add the line to the scene
            sceneView.scene?.rootNode.addChildNode(lineNode)
            limbsNodes[limb] = lineNode
        }
    }
    
    func addFloor() {
        // Step 1: Create the Floor
        let floor = SCNFloor()
        
        // Step 2: Create a Material for the Floor
        let floorMaterial = SCNMaterial()
//        floorMaterial.diffuse.contents = UIColor.white
        floorMaterial.isDoubleSided = true
        floorMaterial.diffuse.contents = UIImage(named: "checkers_floor")
        
        // Ensure the image is properly tiled
        floorMaterial.diffuse.wrapS = .repeat
        floorMaterial.diffuse.wrapT = .repeat
        
        let textureScale: Float = 10
        floorMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(textureScale, textureScale, 1.0)
        
        floor.materials = [floorMaterial]
        floor.reflectivity = 0.5
        
        // Step 3: Create a Node for the Floor
        let floorNode = SCNNode(geometry: floor)
        
        // Step 4: Position the Floor Node
        floorNode.position = SCNVector3(0, -1, 0)  // Adjust position if needed
        
        // Step 5: Add the Floor Node to the Scene
        sceneView.scene?.rootNode.addChildNode(floorNode)
        
        // Optional: Add a light to ensure the floor is visible
        let lightNode = SCNNode()
        let light = SCNLight()
        light.type = .omni
        lightNode.light = light
        lightNode.position = SCNVector3(0, 10, 10)
        sceneView.scene?.rootNode.addChildNode(lightNode)
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateNodes(posData: [Joint : SCNVector3]){
        posData.forEach {
            sphereNodes[$0.key]?.position = $0.value - (posData[.Hip] ?? SCNVector3(0,0,0))
        }

        limbsNodes.forEach({$0.value.removeFromParentNode()})
        createLimbs()
    }
}

extension UIColor{
    static var random: UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1
        )
    }
}
