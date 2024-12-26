//
//  VideoRecorder.swift
//  SencyFitSDK
//
//  Created by Ofer Goldstein on 10/07/2022.
//

import Foundation
import AVFoundation
import Photos
import ReplayKit
import CoreMedia

protocol RecorderDelegate{
    func videoSaveProgressDidChange(progress:Float)
}

enum RecorderError: Swift.Error {
    case discSpaceError
    case fileSavingError
    case fileWriterError
    case unknown
}

struct RecorderAudio{
    let audioURL:URL
    let inAppTime:Double
}

class Recorder {
    // Video
    var assetVideoWriter: AVAssetWriter!
    var assetVideoWriterInput: AVAssetWriterInput?
    var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    var videoFileName: String!
    var videoPath: URL!
    // Audio
    var audioFileName: String!
    var audioPath: URL!
    var recorderAudio:[RecorderAudio] = []
    // Merged
    var mergedFileName: String!
    var mergePath: URL!
    
    var videoPathPrefix: String!
    var frame: Int
    var videoDataOutput: AVCaptureVideoDataOutput?
    let recorderQueue = DispatchQueue(label: "recorderQueue")
    let fileExtension: String = ".mp4"
    var workoutId: String = ""
    var spaceLeft: Bool = false
    var delegate:RecorderDelegate?
    var progressTimer:Timer?
    var didSetupRecorderSession: Bool = false
    let initialAudioDelay = 0.43

    
    var didVideoUploadComplete: Bool = false {
        didSet {
            if self.didVideoUploadComplete {
                print("split session predictions")
            }
            self.didVideoUploadComplete = false
        }
    }
    
    init(videoPrefix: String) {
        // Set up recorder
        self.frame = 0
        self.videoPathPrefix = videoPrefix
        self.videoFileName = [self.videoPathPrefix, generateCurrTimeStamp(), fileExtension].joined(separator: "_")
        self.audioFileName = [self.videoPathPrefix, generateCurrTimeStamp(), "audio", fileExtension].joined(separator: "_")
        self.mergedFileName = [self.videoPathPrefix, generateCurrTimeStamp(), "merged", fileExtension].joined(separator: "_")
        if let videoPath = self.videoFileName, let audioPath = self.audioFileName, let mergePath = self.mergedFileName {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

            self.videoPath = documentsDirectory.appendingPathComponent(videoPath)
            self.audioPath = documentsDirectory.appendingPathComponent(audioPath)
            self.mergePath = documentsDirectory.appendingPathComponent(mergePath)
        }
    }

    func setup() throws {
        spaceLeft = testDiscSpace()
        if !spaceLeft {
            print("insufficient disc space - no recording in this session")
            throw RecorderError.discSpaceError
        }

        recorderAudio.removeAll()
        frame = 0
        didSetupRecorderSession = true
        do {
            self.updateVideoPath()
            assetVideoWriter = try AVAssetWriter(outputURL: videoPath, fileType: .mp4)
            // Video
            let recordingSettings = self.videoDataOutput?.recommendedVideoSettingsForAssetWriter(writingTo: .mp4)

            assetVideoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: recordingSettings)
            assetVideoWriterInput?.expectsMediaDataInRealTime = true
            if let vidInput = assetVideoWriterInput {
                adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: vidInput, sourcePixelBufferAttributes: nil)
                if assetVideoWriter.canAdd(vidInput) {
                    assetVideoWriter.add(vidInput)
                } else {
                    print("RECORDER: could not add assetVideoWriterInput")
                }
            }
        } catch let err {
            didSetupRecorderSession = false
            print("unexpected error: \(err.localizedDescription)")
            throw RecorderError.fileWriterError
        }
    }
    
    func testDiscSpace() -> Bool {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
            let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value
            let mbs = (freeSpace ?? 0) / 1024 / 1024
            if mbs > 500 {
                print("enough disk space available - activate recorder")
                return true
            } else {
                print("not enough disk space available")
                return false
            }
            
        } catch {
            print(error.localizedDescription)
            return false
        }
    }

    func writeToVidRecorder(pixelBuffer: CVPixelBuffer, bufferType: RPSampleBufferType, presTime: CMTime? = nil) {
        guard self.spaceLeft else { return }
        recorderQueue.sync {
            if assetVideoWriter == nil {
                return
            }

            if let presentationTime = presTime {
                if assetVideoWriter.status == .unknown {
                    print("RECORDER: startWriting")
                    assetVideoWriter.startWriting()
                    assetVideoWriter.startSession(atSourceTime: presentationTime)
                }
                
                if assetVideoWriter.status == .failed {
                    print("\(presentationTime.seconds) RECORDER: assetWriter status - 'failed' error: \(String(describing: assetVideoWriter.error))")
                    if let e = assetVideoWriter.error {
                        let errorCode = (e as NSError).code
                        if errorCode == 28 {
                            self.spaceLeft = false
                        }
                    }
                    return
                }
                
                if bufferType == .video {
                    if assetVideoWriterInput?.isReadyForMoreMediaData == true {
                        self.frame += 1
                        adaptor?.append(pixelBuffer, withPresentationTime: presentationTime)
                    } else {
                        print("\(presentationTime.seconds) RECORDER: isReadyForMoreMediaData false")
                    }
                }
            }
        }
    }


    func cleanup(fileURL: URL) {
        let path = fileURL.path
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print("Could not remove file at url: \(fileURL)")
            }
        }
    }
    
    func handleSourceRecordingComplition(_ audioComplition: Bool, _ videoComplition: Bool, _ complition: @escaping () -> Void) {
            self.saveToLibrary(videoURL: self.videoPath) { complition() }
    }

    func finishRecordingToLocal(complition: @escaping () -> Void) {
        var didFinishWritingAudio: Bool = false {
            didSet {
                handleSourceRecordingComplition(didFinishWritingAudio,didFinishWritingVideo) {complition()}
            }
        }
        var didFinishWritingVideo: Bool = false {
            didSet {
                handleSourceRecordingComplition(didFinishWritingAudio,didFinishWritingVideo) {complition()}
            }
        }
        
        guard self.assetVideoWriter != nil else { return complition() }

        // Video
        guard self.assetVideoWriterInput?.isReadyForMoreMediaData == true, self.assetVideoWriter?.status != .failed else {
            print("RECORDER: no video to write")
            return
        }
        self.assetVideoWriterInput?.markAsFinished()
        assetVideoWriter.finishWriting(completionHandler: {
            let urlVid = self.assetVideoWriter.outputURL
//            SencyFitDelegateManager.shared.videoURL = urlVid
            self.assetVideoWriter = nil
            self.assetVideoWriterInput = nil
            didFinishWritingVideo = true
        })
        didSetupRecorderSession = false
    }

    func saveToLibrary(videoURL: URL, complition: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                if !success {
                    print("Could not save video to photo library: \( error as Any)")
                } else {
                    complition()
                }
            }
        }
    }
        
    func updateVideoPath() {
        self.videoFileName = [self.videoPathPrefix, generateCurrTimeStamp(), fileExtension].joined(separator: "_")
        self.audioFileName = [self.videoPathPrefix, generateCurrTimeStamp(), "audio", fileExtension].joined(separator: "_")
        self.mergedFileName = [self.videoPathPrefix, generateCurrTimeStamp(), "merged", fileExtension].joined(separator: "_")
        if let videoPath = self.videoFileName, let audioPath = self.audioFileName, let mergePath = self.mergedFileName {
            self.videoPath = FileManager.default.temporaryDirectory.appendingPathComponent(videoPath)
            self.audioPath = URL(fileURLWithPath: FileManager.default.temporaryDirectory.appendingPathComponent(audioPath).path)
            self.mergePath = FileManager.default.temporaryDirectory.appendingPathComponent(mergePath)
        }
    }
    
    func generateCurrTimeStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_hhmmss"
        return (formatter.string(from: Date()) as NSString) as String
    }

    func currentTime() -> String {
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "HH-mm-ss"
        return format.string(from: date)
    }

    func currentDate() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        return dateFormatter.string(from: date)
    }

    func getRandomString(length: Int = 20) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    func mergeAudioFiles(recorderAudio: [RecorderAudio], compltion:@escaping (URL?)->Void) {
        let composition = AVMutableComposition()
        for rAudio in recorderAudio {
            
            guard let compositionAudioTrack :AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID()) else {continue}
            
            let asset = AVURLAsset(url: rAudio.audioURL)
            let track = asset.tracks(withMediaType: .audio)[0]
            let timeRange = CMTimeRange(start: CMTimeMake(value: 0, timescale: 600), duration: track.timeRange.duration)
            let newTime = CMTime(seconds: rAudio.inAppTime, preferredTimescale: 600)
                        
            try! compositionAudioTrack.insertTimeRange(timeRange, of: track, at: newTime)
        }

        if let audioPath = audioPath{
            cleanup(fileURL: audioPath)
        }
        
        guard let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {return compltion(nil)}
        assetExport.outputFileType = .m4a
        assetExport.outputURL = audioPath
        checkProgress(exportSession: assetExport)

        DispatchQueue.main.async {
            assetExport.exportAsynchronously(completionHandler:{
                let error = assetExport.error?.localizedDescription ?? ""
                switch assetExport.status{
                case .failed:
                    print("failed \(error)")
                case .cancelled:
                    print("cancelled \(error)")
                case .unknown:
                    print("unknown\(error)")
                case .waiting:
                    print("waiting\(error)")
                case .exporting:
                    print("exporting\(error)")
                default:
                    print("Audio Concatenation Complete")
                }
                
                compltion(self.audioPath)
            })
        }
    }
    
    func mergeVideoWithAudio(videoUrl: URL, audioUrl: URL, complition: @escaping () -> Void) {
        let mixComposition: AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack: [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack: [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()

        let aVideoAsset: AVAsset = AVAsset(url: videoUrl)
        let aAudioAsset: AVAsset = AVAsset(url: audioUrl)
        
        if let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid), let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            mutableCompositionVideoTrack.append(videoTrack)
            mutableCompositionAudioTrack.append(audioTrack)

            if let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: .video).first, let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: .audio).first {
                do {
                    try mutableCompositionVideoTrack.first?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: CMTime.zero)
                    try mutableCompositionAudioTrack.first?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: CMTime.zero)
                       videoTrack.preferredTransform = aVideoAssetTrack.preferredTransform
                       
                } catch{
                    print(error)
                }
                
                totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration)
            }
            
            let mutableVideoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
            mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: videoTrack.naturalTimeScale)
            mutableVideoComposition.renderSize = CGSize(width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            
            if let outputURL = self.mergePath {
                if let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetPassthrough) {
                    if let _: AVAssetTrack = aVideoAsset.tracks(withMediaType: .video).first {
                        
                        exportSession.outputURL = outputURL
                        exportSession.outputFileType = AVFileType.mp4
                        exportSession.shouldOptimizeForNetworkUse = false
                        checkProgress(exportSession: exportSession)

                        exportSession.exportAsynchronously(completionHandler: {
                            switch exportSession.status {
                            case .failed:
                                if let _error = exportSession.error {
                                    print("[Error - .failed - merging files]: \(_error)")
                                }

                            case .cancelled:
                                if let _error = exportSession.error {
                                    print("[Error - cancelled - merging files]: \(_error)")
                                }

                            default:
                                print("finished merging files")
                                self.saveToLibrary(videoURL: self.mergePath) { complition() }
                            }
                        })
                    }
                } else {
                    print("[Error - merging files]")
                }
            }
        }
    }
    
    func checkProgress(exportSession:AVAssetExportSession){
        DispatchQueue.main.async {
            self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in

                if exportSession.progress == 1{
                    self.progressTimer?.invalidate()
                }
            }
        }
    }
}
