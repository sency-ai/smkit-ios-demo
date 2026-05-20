//
//  ExerciseGuidance.swift
//  SMKitDemo
//

import AVKit
import Foundation
import SMBase
import SMKit
import SwiftUI

struct GuidanceVideoSegment: Equatable {
    enum Kind {
        case freeze
        case play
    }

    let kind: Kind
    let startSeconds: Double
    let endSeconds: Double?

    static func freeze(at seconds: Double) -> GuidanceVideoSegment {
        GuidanceVideoSegment(kind: .freeze, startSeconds: seconds, endSeconds: seconds)
    }

    static func play(from startSeconds: Double, to endSeconds: Double?) -> GuidanceVideoSegment {
        GuidanceVideoSegment(kind: .play, startSeconds: startSeconds, endSeconds: endSeconds)
    }
}

enum DemoGuidanceVideoPolicy {
    static func videoURL(for detector: String) -> URL? {
        for fileExtension in ["mp4", "mov", "m4v"] {
            if let url = Bundle.main.url(forResource: detector, withExtension: fileExtension) {
                return url
            }
        }
        return nil
    }

    static func segment(for step: GuidanceStep, detector: String) -> GuidanceVideoSegment? {
        if GuidanceModePolicy.isStandingSideBendGuidance(detector: detector) {
            switch step {
            case .orient:
                return .freeze(at: 0)
            case .prepare:
                return .play(from: 0, to: 1.35)
            case .action:
                return .play(from: 1.35, to: nil)
            default:
                return nil
            }
        }

        if GuidanceModePolicy.isJeffersonCompactGuidance(detector: detector) {
            switch step {
            case .orient, .setup, .prepare:
                return .freeze(at: 0)
            case .action:
                return .play(from: 0, to: nil)
            default:
                return nil
            }
        }

        if GuidanceModePolicy.isOverheadSquatStaticGuidance(detector: detector) {
            switch step {
            case .orient:
                return .play(from: 0, to: 1.0)
            case .setup:
                return .play(from: 1.0, to: 2.5)
            case .prepare:
                return .play(from: 2.5, to: 4.0)
            case .action:
                return .play(from: 4.0, to: nil)
            default:
                return nil
            }
        }

        if GuidanceModePolicy.isOverheadMobilityCompactGuidance(detector: detector) {
            switch step {
            case .orient:
                return .play(from: 0, to: 2.0)
            case .setup:
                return .freeze(at: 2.0)
            case .prepare:
                return .play(from: 2.0, to: nil)
            default:
                return nil
            }
        }

        if GuidanceModePolicy.isPlankHighStaticGuidance(detector: detector) {
            switch step {
            case .orient:
                return .freeze(at: 0)
            case .setup:
                return .play(from: 0, to: 2.5)
            case .hold:
                return .play(from: 2.5, to: nil)
            default:
                return nil
            }
        }

        if GuidanceModePolicy.isStandingKneeRaiseGuidance(detector: detector) {
            switch step {
            case .orient:
                return .freeze(at: 0)
            case .prepare:
                return .play(from: 0, to: nil)
            default:
                return nil
            }
        }

        if GuidanceModePolicy.isAnkleMobilityGuidance(detector: detector) {
            switch step {
            case .orient:
                return .freeze(at: 0)
            case .setup:
                return .play(from: 0, to: 2.0)
            case .action:
                return .play(from: 2.0, to: nil)
            default:
                return nil
            }
        }

        switch step {
        case .orient, .setup:
            return .freeze(at: 0)
        case .prepare:
            return .play(from: 0, to: 2.0)
        case .action:
            return .play(from: 2.0, to: nil)
        default:
            return nil
        }
    }
}

struct ExerciseGuidanceDisplayState: Equatable {
    var isEnabled = false
    var isCompleted = false
    var step: GuidanceStep?
    var progress: Float = 0
    var vocalKey: String?
    var requestsReplay = false
    var videoURL: URL?
    var videoSegment: GuidanceVideoSegment?
    var videoRevision = 0

    static let inactive = ExerciseGuidanceDisplayState()

    var isVisible: Bool {
        isEnabled && !isCompleted
    }

    var locksTimer: Bool {
        isEnabled && !isCompleted
    }

    var progressValue: Double {
        Double(max(0, min(1, progress)))
    }

    var stepTitle: String {
        guard let step else { return "Waiting for guidance" }
        switch step {
        case .orient:
            return "Orient"
        case .setup:
            return "Setup"
        case .prepare:
            return "Prepare"
        case .action:
            return "Action"
        case .hold:
            return "Hold"
        @unknown default:
            return "Guidance"
        }
    }
}

struct GuidanceVideoPlaybackRequest: Equatable {
    let url: URL?
    let segment: GuidanceVideoSegment?
    let revision: Int
}

final class GuidanceVideoPlaybackModel: ObservableObject {
    let player = AVPlayer()
    private var loadedURL: URL?
    private var appliedRequest: GuidanceVideoPlaybackRequest?
    private var applyGeneration = 0
    private var timeObserver: Any?

    deinit {
        removeTimeObserver()
    }

    func configure(_ request: GuidanceVideoPlaybackRequest) {
        guard let url = request.url else {
            applyGeneration += 1
            loadedURL = nil
            appliedRequest = nil
            removeTimeObserver()
            player.pause()
            player.replaceCurrentItem(with: nil)
            return
        }

        let nextSegment = request.segment ?? .freeze(at: 0)
        let nextRequest = GuidanceVideoPlaybackRequest(
            url: url,
            segment: nextSegment,
            revision: request.revision
        )
        guard appliedRequest != nextRequest else { return }

        applyGeneration += 1
        let generation = applyGeneration

        if loadedURL != url {
            player.replaceCurrentItem(with: AVPlayerItem(url: url))
            loadedURL = url
        }

        appliedRequest = nextRequest
        apply(segment: nextSegment, generation: generation)
    }

    private func apply(segment: GuidanceVideoSegment, generation: Int) {
        removeTimeObserver()
        player.pause()
        let startTime = CMTime(seconds: segment.startSeconds, preferredTimescale: 600)
        player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self else { return }
            guard generation == self.applyGeneration else { return }
            switch segment.kind {
            case .freeze:
                self.player.pause()
            case .play:
                self.player.play()
                if let endSeconds = segment.endSeconds {
                    self.addEndObserver(endSeconds: endSeconds)
                }
            }
        }
    }

    private func addEndObserver(endSeconds: Double) {
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            if time.seconds >= endSeconds {
                self.player.pause()
                self.removeTimeObserver()
            }
        }
    }

    private func removeTimeObserver() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
}

struct GuidanceVideoPlayerView: View {
    let url: URL?
    let segment: GuidanceVideoSegment?
    let revision: Int
    let detector: String

    @StateObject private var playback = GuidanceVideoPlaybackModel()
    private var playbackRequest: GuidanceVideoPlaybackRequest {
        GuidanceVideoPlaybackRequest(url: url, segment: segment, revision: revision)
    }

    var body: some View {
        Group {
            if url != nil {
                VideoPlayer(player: playback.player)
                    .allowsHitTesting(false)
                    .onAppear {
                        playback.configure(playbackRequest)
                    }
                    .onChange(of: playbackRequest) { request in
                        playback.configure(request)
                    }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "video.slash")
                        .font(.title)
                    Text("Add \(detector).mp4")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("The demo will play it here during guidance.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.45))
            }
        }
        .onDisappear {
            playback.configure(GuidanceVideoPlaybackRequest(url: nil, segment: nil, revision: 0))
        }
    }
}

struct GuidancePanelView: View {
    let detector: String
    let state: ExerciseGuidanceDisplayState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GuidanceVideoPlayerView(
                url: state.videoURL,
                segment: state.videoSegment,
                revision: state.videoRevision,
                detector: detector
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Label(state.stepTitle, systemImage: "figure.mind.and.body")
                    .font(.headline)

                Spacer()

                Text("\(Int(state.progressValue * 100))%")
                    .font(.subheadline.monospacedDigit())
            }

            ProgressView(value: state.progressValue)
                .tint(.green)

            if let vocalKey = state.vocalKey, !vocalKey.isEmpty {
                Text("vocal: \(vocalKey)\(state.requestsReplay ? " replay" : "")")
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .foregroundStyle(.white)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.62))
        )
    }
}
