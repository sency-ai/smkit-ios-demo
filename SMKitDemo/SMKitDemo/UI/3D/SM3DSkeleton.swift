//
//  SM3DSkeleton.swift
//  SMKitDemo
//
//  Created by netanel-yerushalmi on 13/08/2024.
//

import Foundation

import UIKit
import SceneKit
import SMBase

public class SM3DSkeleton:UIView{
    
    let joints:[Joint]
    var sphereNodes: [Joint:SCNNode] = [:]
    var limbsNodes: [Limb:SCNNode] = [:]
    
    let cameraNode = SCNNode()
    let lightNode = SCNNode()

    // Define wall dimensions
    let wallWidth: CGFloat = 10
    let wallHeight: CGFloat = 20
    let wallThickness: CGFloat = 0.1
    
    var didAddFloor = false
    var floorNode:SCNNode?
    
    let jointsToSkip:[Joint] = [.MiddleSpine, .LEar, .REar, .LEye, .REye, .Neck, .Nose, .LowerSpine , .UpperSpine]
    
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
//        Limb(startJoint: .RShoulder, endJoint: .RHip),
//        Limb(startJoint: .LShoulder, endJoint: .LHip),
        Limb(startJoint: .LAnkle, endJoint: .LBigToe),
        Limb(startJoint: .RAnkle, endJoint: .RBigToe),
        Limb(startJoint: .Hip, endJoint: .Neck),
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
        scene.rootNode.position = SCNVector3(0,0,0)
        
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(-5, 5, -3) // Adjust the position as needed
        cameraNode.rotation = SCNVector4(0, 0, 0, Float.pi)
        
        scene.rootNode.addChildNode(cameraNode)

        // Create a light node
        lightNode.light = SCNLight()
        
        // Set the type of light
        lightNode.light?.type = .omni // Options: .omni, .directional, .spot, .ambient

        // Position the light
        lightNode.position = SCNVector3(5, 4, -10) // Position above and in front of the scene
        lightNode.light?.castsShadow = true

        // Customize the light
        lightNode.light?.intensity = 1000 // Adjust the brightness
        lightNode.light?.color = UIColor.white // Set light color
        
        scene.rootNode.addChildNode(lightNode)
        
        sceneView.scene = scene

        // Add the SceneView to the ViewController's view
        return sceneView
    }()
    
    init(poseType: _Pose) {
        joints = poseType.bodyParts.map({$0.key})
        super.init(frame: .zero)

        self.setupScene()
        self.createNods()
        self.addFloor()

        DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
            guard let self else { return }
            addCameraAnim()
        }
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
            let isHead = joint == .Head
            let radius = isHead ? 0.09 : 0.03
            let sphere = SCNSphere(radius: radius)
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.isHidden = jointsToSkip.contains(joint)
            sphereNode.position = SCNVector3(0,0,0)
            let color = isHead ? UIColor.white : UIColor.dot
            sphereNode.geometry?.materials.first?.diffuse.contents = color
            sphereNode.geometry?.materials.first?.emission.intensity = isHead ? 0 : 1
            sphereNode.geometry?.materials.first?.emission.contents = color

            sphereNodes[joint] = sphereNode
            sceneView.scene?.rootNode.addChildNode(sphereNode)
            
            if joint == .MiddleSpine{
                let lookAtConstraint = SCNLookAtConstraint(target: sphereNode)
                lookAtConstraint.isGimbalLockEnabled = true // Optional: restrict to rotation on one axis
                cameraNode.constraints = [lookAtConstraint]
            }
            

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
            let lineGeometry = SCNCylinder(radius: 0.023, height: CGFloat(distance))
            
            let lineNode = SCNNode(geometry: lineGeometry)
            lineNode.position = midPosition

            // Rotate the line to align with the direction
            let nodeZAxis = SCNVector3(0, 1, 0) // SCNCylinder's default orientation is along the y-axis
            let axis = nodeZAxis.cross(direction).normalized()
            let angle = acos(nodeZAxis.dot(direction.normalized()))
            lineNode.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)

            lineNode.geometry?.materials.first?.diffuse.contents = UIColor.white// startNode.geometry?.materials.first?.diffuse.contents
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
        floorMaterial.diffuse.contents = UIColor.floor
        let textureScale: Float = 10
        floorMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(textureScale, textureScale, 1.0)
        
        floor.materials = [floorMaterial]
        floor.reflectivity = 0
        
        // Step 3: Create a Node for the Floor
        floorNode = SCNNode(geometry: floor)
        guard let floorNode else { return }
        
        // Step 4: Position the Floor Node
        floorNode.position = SCNVector3(0, -1.2, 0)  // Adjust position if needed
        
        // Step 5: Add the Floor Node to the Scene
        sceneView.scene?.rootNode.addChildNode(floorNode)
        
//        // Optional: Add a light to ensure the floor is visible
        let lightNode = SCNNode()
        let light = SCNLight()
        light.type = .omni
        lightNode.light = light
        lightNode.position = SCNVector3(0, 10, 10)
        sceneView.scene?.rootNode.addChildNode(lightNode)
        addWalls()
    }

    func addWalls(){
        // Create a material for the walls
        let wallMaterial = SCNMaterial()
        wallMaterial.diffuse.contents = UIColor.wall // Set wall color
        
        let wallHeight = wallHeight / 2 - 1
        
        // Create and position three walls
        let wall1 = createWall(position: SCNVector3(0,wallHeight , 10), rotation: SCNVector3(0, 0, 0), wallMaterial: wallMaterial) // Back wall
        let wall2 = createWall(position: SCNVector3(-5, wallHeight, 5), rotation: SCNVector3(0, Float.pi / 2, 0), wallMaterial: wallMaterial) // Left wall
        let wall3 = createWall(position: SCNVector3(5, wallHeight , 5), rotation: SCNVector3(0, -Float.pi / 2, 0), wallMaterial: wallMaterial) // Right wall

        // Add walls to the scene
        sceneView.scene?.rootNode.addChildNode(wall1)
        sceneView.scene?.rootNode.addChildNode(wall2)
        sceneView.scene?.rootNode.addChildNode(wall3)

    }
    
    // Function to create a wall
    func createWall(position: SCNVector3, rotation: SCNVector3, wallMaterial:SCNMaterial) -> SCNNode {
        let wall = SCNBox(width: wallWidth, height: wallHeight, length: wallThickness, chamferRadius: 0)
        wall.materials = [wallMaterial]
        let wallNode = SCNNode(geometry: wall)
        wallNode.position = position
        wallNode.eulerAngles = rotation
        return wallNode
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateNodes(posData: [Joint : SCNVector3]){
        posData.forEach {
            let isHead = $0.key == .Head
            let mirrored = SCNVector3(x: -$0.value.x, y: $0.value.y - (isHead ? 0.065 : 0), z: $0.value.z)
            sphereNodes[$0.key]?.position = mirrored/* $0.value*/ //- (posData[.Hip] ?? SCNVector3(0,0,0))
        }

        limbsNodes.forEach({$0.value.removeFromParentNode()})
        createLimbs()
        floorNode?.position = SCNVector3(0, (posData[.Hip]?.y ?? 0) - 0.8 , 0)
//        if !didAddFloor{
//            addFloor()
//            didAddFloor = true
//        }
    }
    
    func addCameraAnim(){
        let targetPosition = SCNVector3(0, 0, -3)
        let moveAction = SCNAction.move(to: targetPosition, duration: 2) // 3 seconds duration
        moveAction.timingMode = .easeOut
        cameraNode.runAction(moveAction)
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
