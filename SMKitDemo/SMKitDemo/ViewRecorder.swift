//
//  ViewRecorder.swift
//  SencyFitSDK
//
//  Created by Ofer Goldstein on 10/07/2022.
//

import Foundation
import AVFoundation
import ReplayKit
import UIKit

@objc public class ViewRecorder: NSObject {
    var index = 0
    let isDebug: Bool
    var recorder: Recorder?
    var view: UIView?
    var isRecordingPossible = false
    
    init(view: UIView?, isDebug: Bool, videoPrefix: String? = nil) {
        self.view = view
        self.isDebug = isDebug
        if let prefix = videoPrefix {
            recorder = Recorder(videoPrefix: prefix)
        } else {
            recorder = Recorder(videoPrefix: "SencyRecording")
        }
    }
    
    public func start() throws {
        if !self.isDebug {
            do {
                // Video
                try recorder?.setup()
                isRecordingPossible = true
            } catch {
                throw error
            }
        }
    }
    
    func setRecoderDelegate(delegte:RecorderDelegate){
        self.recorder?.delegate = delegte
    }
    
    public func stop() {
        isRecordingPossible = false

    }
    
    func createImageFromView(presTime: CMTime? = nil) {
        if !isRecordingPossible{
            return
        }

        DispatchQueue.main.async {
            guard let currentView = self.view else { return }
            UIGraphicsBeginImageContextWithOptions(currentView.bounds.size, false, 0)
            currentView.drawHierarchy(in: currentView.bounds, afterScreenUpdates: false)
                
            let image = UIGraphicsGetImageFromCurrentImageContext()
            if let image = image {
                let pixelBuffer = image.toCVPixelBuffer()
                if let pb = pixelBuffer {
                    if self.recorder?.didSetupRecorderSession ?? false {
                        self.index += 1
                        self.recorder?.writeToVidRecorder(pixelBuffer: pb, bufferType: .video, presTime: presTime)
                    }
                }
                UIGraphicsEndImageContext()
            }
        }
    }
    
    func addAudioData(audioURL:URL, atTime:Double){
        if isRecordingPossible{
            guard let recorder = recorder else { return }
            
            let recorderAudio = recorder.recorderAudio
            let inAppTime = recorderAudio.isEmpty ? (atTime - recorder.initialAudioDelay) : atTime

            recorder.recorderAudio.append(RecorderAudio(audioURL: audioURL, inAppTime: inAppTime))
        }
    }
}

extension UIImage {
    public func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }
        if let pixelBuffer = pixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            context?.translateBy(x: 0, y: self.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)
            UIGraphicsPushContext(context!)
            self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            return pixelBuffer
        }
        return nil
    }
}
