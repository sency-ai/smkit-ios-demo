//
//  VideoRecorder.swift
//  SencyFitSDK
//
//  Created by Ofer Goldstein on 10/07/2022.
//

import Foundation
@preconcurrency import AVFoundation
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

class Recorder: @unchecked Sendable {
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
    private var audioExportSession: AVAssetExportSession?
    private var videoExportSession: AVAssetExportSession?
    private var activeExportSession: AVAssetExportSession?

    
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
    
    func finishRecordingToLocal(complition: @escaping () -> Void) {
        guard self.assetVideoWriter != nil else { return complition() }

        // Video
        guard self.assetVideoWriterInput?.isReadyForMoreMediaData == true, self.assetVideoWriter?.status != .failed else {
            print("RECORDER: no video to write")
            return
        }
        self.assetVideoWriterInput?.markAsFinished()
        assetVideoWriter.finishWriting(completionHandler: {
            self.assetVideoWriter = nil
            self.assetVideoWriterInput = nil
            self.saveToLibrary(videoURL: self.videoPath) { complition() }
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
    
    func mergeAudioFiles(recorderAudio: [RecorderAudio], compltion: @escaping (URL?) -> Void) {
        Task {
            let composition = AVMutableComposition()
            for rAudio in recorderAudio {
                guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID()) else { continue }
                let asset = AVURLAsset(url: rAudio.audioURL)
                guard let track = try? await asset.loadTracks(withMediaType: .audio).first,
                      let trackTimeRange = try? await track.load(.timeRange) else { continue }
                let timeRange = CMTimeRange(start: CMTimeMake(value: 0, timescale: 600), duration: trackTimeRange.duration)
                let newTime = CMTime(seconds: rAudio.inAppTime, preferredTimescale: 600)
                try? compositionAudioTrack.insertTimeRange(timeRange, of: track, at: newTime)
            }

            if let audioPath = audioPath {
                cleanup(fileURL: audioPath)
            }

            guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
                compltion(nil)
                return
            }
            self.audioExportSession = session
            self.audioExportSession?.outputFileType = .m4a
            self.audioExportSession?.outputURL = self.audioPath
            checkProgress(exportSession: session)

            self.audioExportSession?.exportAsynchronously(completionHandler: {
                let error = self.audioExportSession?.error?.localizedDescription ?? ""
                switch self.audioExportSession?.status {
                case .failed: print("failed \(error)")
                case .cancelled: print("cancelled \(error)")
                case .unknown: print("unknown\(error)")
                case .waiting: print("waiting\(error)")
                case .exporting: print("exporting\(error)")
                default: print("Audio Concatenation Complete")
                }
                compltion(self.audioPath)
            })
        }
    }
    
    func mergeVideoWithAudio(videoUrl: URL, audioUrl: URL, complition: @escaping () -> Void) {
        Task {
            let mixComposition = AVMutableComposition()
            let totalVideoCompositionInstruction = AVMutableVideoCompositionInstruction()

            let aVideoAsset = AVURLAsset(url: videoUrl)
            let aAudioAsset = AVURLAsset(url: audioUrl)

            guard let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
                  let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }

            if let aVideoAssetTrack = try? await aVideoAsset.loadTracks(withMediaType: .video).first,
               let aAudioAssetTrack = try? await aAudioAsset.loadTracks(withMediaType: .audio).first {
                do {
                    let videoTimeRange = try await aVideoAssetTrack.load(.timeRange)
                    let preferredTransform = try await aVideoAssetTrack.load(.preferredTransform)
                    try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoTimeRange.duration), of: aVideoAssetTrack, at: .zero)
                    try audioTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoTimeRange.duration), of: aAudioAssetTrack, at: .zero)
                    videoTrack.preferredTransform = preferredTransform
                    totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: videoTimeRange.duration)
                } catch {
                    print(error)
                }
            }

            let mutableVideoComposition = AVMutableVideoComposition()
            mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: videoTrack.naturalTimeScale)
            mutableVideoComposition.renderSize = CGSize(width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)

            guard let outputURL = self.mergePath,
                  let session = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetPassthrough),
                  (try? await aVideoAsset.loadTracks(withMediaType: .video).first) != nil else {
                print("[Error - merging files]")
                return
            }

            self.videoExportSession = session
            self.videoExportSession?.outputURL = outputURL
            self.videoExportSession?.outputFileType = .mp4
            self.videoExportSession?.shouldOptimizeForNetworkUse = false
            checkProgress(exportSession: session)

            self.videoExportSession?.exportAsynchronously(completionHandler: {
                switch self.videoExportSession?.status {
                case .failed:
                    if let _error = self.videoExportSession?.error { print("[Error - .failed - merging files]: \(_error)") }
                case .cancelled:
                    if let _error = self.videoExportSession?.error { print("[Error - cancelled - merging files]: \(_error)") }
                default:
                    print("finished merging files")
                    self.saveToLibrary(videoURL: self.mergePath) { complition() }
                }
            })
        }
    }
    
    func checkProgress(exportSession: AVAssetExportSession) {
        self.activeExportSession = exportSession
        DispatchQueue.main.async {
            self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self else { return }
                if self.activeExportSession?.progress == 1 {
                    self.progressTimer?.invalidate()
                }
            }
        }
    }
}
