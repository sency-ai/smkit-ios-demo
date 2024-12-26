//
//  SceneKitRecorder.swift
//  SMKitDemo
//
//  Created by netanel-yerushalmi on 10/12/2024.
//

import SceneKit
import AVFoundation

class SceneKitRecorder {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var frameIndex: Int64 = 0
    private var recordingQueue = DispatchQueue(label: "ScreenRecordingQueue")
    
    func startRecording(sceneView: SCNView, outputURL: URL, videoSize: CGSize) throws {
        // Setup asset writer
        assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height
        ]
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput?.expectsMediaDataInRealTime = true
        
        guard let videoInput = videoInput, let assetWriter = assetWriter else { return }
        if assetWriter.canAdd(videoInput) {
            assetWriter.add(videoInput)
        }
        
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: videoSize.width,
            kCVPixelBufferHeightKey as String: videoSize.height
        ]
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: pixelBufferAttributes
        )
        
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        frameIndex = 0
    }
    
    func captureFrame(sceneView: SCNView, time:CMTime) {
        guard let assetWriter = assetWriter, assetWriter.status == .writing,
              let videoInput = videoInput, videoInput.isReadyForMoreMediaData,
              let pixelBufferAdaptor = pixelBufferAdaptor else { return }
        
        let snapshot = sceneView.snapshot()
        guard let pixelBuffer = createPixelBuffer(from: snapshot, size: sceneView.bounds.size) else { return }
        
        let presentationTime = CMTime(value: frameIndex, timescale: 30) // 30 FPS
        pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
        frameIndex += 1
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        recordingQueue.async {
            self.videoInput?.markAsFinished()
            self.assetWriter?.finishWriting {
                completion(self.assetWriter?.outputURL)
            }
            self.assetWriter = nil
            self.videoInput = nil
            self.pixelBufferAdaptor = nil
        }
    }
    
    private func createPixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attributes as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )
        guard let cgImage = image.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
