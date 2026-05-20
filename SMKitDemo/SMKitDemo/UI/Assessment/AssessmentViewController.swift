//
//  AssessmentViewController.swift
//  SMKitDemo
//

import UIKit
import SwiftUI
import SMKit
import SMBase
import AVFoundation
import SceneKit

struct AssessmentExerciseResult {
    let name: String
    let techniqueScore: Float   // 0-100
    let feedbacks: [String]
    let timeInPosition: Float   // seconds
    let peakRom: Float?         // 0.0-1.0, nil if no ROM
}

class AssessmentViewController: UIViewController {

    var isElevated: Bool = true

    private let exercises = [
        "OverheadMobility",
        "SquatRegularOverheadStatic",
        "JeffersonCurl",
        "StandingSideBendRight",
        "StandingSideBendLeft"
    ]
    private let exerciseDuration: Float = 15.0

    private var exerciseIndex = 0
    private var flowManager: SMKitFlowManager?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private var currentTechniqueScores: [Float] = []       // all in-position frames
    private var currentFeedbacks: Set<String> = []          // all in-position feedbacks
    private var currentRomValues: [Float] = []

    private var greenZoneTechniqueScores: [Float] = []      // frames where ROM is in target zone
    private var greenZoneFeedbacks: Set<String> = []        // feedbacks from green-zone frames

    private var currentRomRange: ClosedRange<Float>? = nil  // cached for frame checks
    private var results: [AssessmentExerciseResult] = []

    private var viewModel = AssessmentViewModel()
    private var calibrationViewModel = CalibrationViewModel()
    private var skeletonView: SkeletonView?
    private var boundingBoxGuideView: BodyCalibrationGuideView?
    private var currentExerciseUsesGuidance = false
    private var didCompleteGuidanceForCurrentExercise = false
    private var didInspectFirstGuidanceFrame = false
    private var isWaitingForGuidanceRecheckFrame = false
    private var highestGuidanceVideoStepRank = -1

    // Calibration state
    private var isBodyInFrame = false
    private var isPhoneAngleReady = false
    private var calibrationHostingController: UIHostingController<CalibrationView>?

    private lazy var assessmentView: UIView = {
        guard let view = UIHostingController(
            rootView: AssessmentView(model: viewModel, delegate: self)
        ).view else { return UIView() }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private lazy var calibrationOverlay: UIView = {
        let calibrationView = CalibrationView(
            model: calibrationViewModel,
            onStop: { [weak self] in
                self?.stopAndDismiss()
            },
            onSkip: { [weak self] in
                DispatchQueue.main.async { self?.beginAssessment() }
            }
        )
        let host = UIHostingController(rootView: calibrationView)
        calibrationHostingController = host
        guard let view = host.view else { return UIView() }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private var currentExercise: String { exercises[exerciseIndex] }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        do {
            let sessionSettings = SMKitSessionSettings(
                phonePosition: isElevated ? .Elevated : .Floor,
                jumpRefPoint: "Hip",
                jumpHeightThreshold: 10,
                userHeight: 170
            )
            flowManager = try SMKitFlowManager(delegate: self)
            flowManager?.verboseBodyCalibration = true

            // Phone calibration
            flowManager?.setDeviceMotionActive(
                phoneCalibrationInfo: SMPhoneCalibrationInfo(
                    YZAngleRange: 70..<90,
                    XYAngleRange: -5..<5
                ),
                tiltDidChange: { [weak self] tiltInfo in
                    let ready = tiltInfo.isYZTiltAngleInRange && tiltInfo.isXYTiltAngleInRange
                    DispatchQueue.main.async {
                        self?.phoneAngleDidUpdate(isReady: ready)
                    }
                }
            )
            flowManager?.setDeviceMotionFrequency(isHigh: true)

            flowManager?.startSession(sessionSettings: sessionSettings) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    self.showCalibrationOverlay()
                case .failure(let error):
                    self.showError(message: error.localizedDescription)
                }
            }
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func showCalibrationOverlay() {
        guard calibrationOverlay.superview == nil else { return }
        view.addSubview(calibrationOverlay)
        NSLayoutConstraint.activate([
            calibrationOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            calibrationOverlay.leftAnchor.constraint(equalTo: view.leftAnchor),
            calibrationOverlay.rightAnchor.constraint(equalTo: view.rightAnchor),
            calibrationOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        // Add hosting controller as child so responder chain and touch delivery work
        if let host = calibrationHostingController {
            addChild(host)
            host.didMove(toParent: self)
        }
    }

    private func phoneAngleDidUpdate(isReady: Bool) {
        guard isPhoneAngleReady != isReady else { return }
        isPhoneAngleReady = isReady
        calibrationViewModel.isPhoneReady = isReady
        checkCalibrationComplete()
    }

    private func checkCalibrationComplete() {
        guard isBodyInFrame && isPhoneAngleReady else { return }
        beginAssessment()
    }

    private func beginAssessment() {
        guard assessmentView.superview == nil else { return }
        if let host = calibrationHostingController {
            host.willMove(toParent: nil)
            host.view.removeFromSuperview()
            host.removeFromParent()
            calibrationHostingController = nil
        }
        boundingBoxGuideView?.removeFromSuperview()
        boundingBoxGuideView = nil
        flowManager?.setBodyPositionCalibrationInactive()

        // Add exercise UI (on top of skeleton)
        view.addSubview(assessmentView)
        NSLayoutConstraint.activate([
            assessmentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            assessmentView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            assessmentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            assessmentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        // Show countdown for first exercise
        showCountdown()
    }

    private func showCountdown() {
        DispatchQueue.main.async {
            self.viewModel.startCountdown(exerciseName: self.currentExercise)
        }
    }

    private func startExercise() {
        do {
            currentTechniqueScores = []
            currentFeedbacks = []
            currentRomValues = []
            greenZoneTechniqueScores = []
            greenZoneFeedbacks = []
            currentExerciseUsesGuidance = shouldUseGuidance(for: currentExercise)
            didCompleteGuidanceForCurrentExercise = !currentExerciseUsesGuidance
            didInspectFirstGuidanceFrame = false
            isWaitingForGuidanceRecheckFrame = false
            highestGuidanceVideoStepRank = currentExerciseUsesGuidance ? GuidanceStep.orient.sequenceIndex : -1
            let guidanceVideoURL = DemoGuidanceVideoPolicy.videoURL(for: currentExercise)
            let initialGuidanceStep: GuidanceStep? = currentExerciseUsesGuidance ? .orient : nil
            let initialGuidanceSegment = initialGuidanceStep.flatMap {
                DemoGuidanceVideoPolicy.segment(for: $0, detector: currentExercise)
            }

            try flowManager?.startDetection(
                exercise: currentExercise,
                guidanceMode: currentExerciseUsesGuidance
            )

            let romRange = flowManager?.getExerciseRange()
            currentRomRange = romRange

            DispatchQueue.main.async {
                self.viewModel.startExercise(
                    name: self.currentExercise,
                    index: self.exerciseIndex,
                    total: self.exercises.count,
                    duration: self.exerciseDuration,
                    guidanceEnabled: self.currentExerciseUsesGuidance,
                    guidanceVideoURL: guidanceVideoURL,
                    initialGuidanceStep: initialGuidanceStep,
                    initialGuidanceSegment: initialGuidanceSegment
                )
                self.viewModel.setRomRange(romRange)
            }
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func shouldUseGuidance(for detector: String) -> Bool {
        GuidanceModePolicy.exerciseUsesDefaultGuidanceOrchestration(detector: detector)
    }

    private func assessmentInPosition(rawInPosition: Bool, rom: Float?) -> Bool {
        if rawInPosition { return true }

        guard GuidanceModePolicy.isOverheadSquatStaticGuidance(detector: currentExercise),
              let rom else {
            return false
        }

        return currentRomRange?.contains(rom) == true
    }

    private func guidanceInAssessmentPosition(
        step: GuidanceStep,
        rawInPosition: Bool,
        refinedInPosition: Bool,
        rom: Float?
    ) -> Bool {
        if GuidanceModePolicy.isJeffersonCompactGuidance(detector: currentExercise), step == .hold {
            guard let rom, rom.isFinite else { return false }
            return rom >= GuidanceModePolicy.jeffersonGuidanceMinDescentRom
        }

        return refinedInPosition || assessmentInPosition(rawInPosition: rawInPosition, rom: rom)
    }

    private func updateGuidance(from movementData: MovementFeedbackData) -> Bool {
        guard currentExerciseUsesGuidance else {
            DispatchQueue.main.async { self.viewModel.clearGuidance() }
            return false
        }

        guard !didCompleteGuidanceForCurrentExercise else { return false }

        guard let step = movementData.coachStep else { return true }

        if !didInspectFirstGuidanceFrame {
            didInspectFirstGuidanceFrame = true
            if step.sequenceIndex > GuidanceStep.orient.sequenceIndex {
                highestGuidanceVideoStepRank = GuidanceStep.orient.sequenceIndex
                let initialSegment = DemoGuidanceVideoPolicy.segment(for: .orient, detector: currentExercise)
                DispatchQueue.main.async {
                    self.viewModel.updateGuidance(
                        step: .orient,
                        progress: 0,
                        vocalKey: nil,
                        requestsReplay: false,
                        videoSegment: initialSegment
                    )
                }
                flowManager?.resetGuidanceMode()
                isWaitingForGuidanceRecheckFrame = true
                return true
            }
        }

        if isWaitingForGuidanceRecheckFrame {
            isWaitingForGuidanceRecheckFrame = false
            return true
        }

        let refinedInPosition = GuidanceModePolicy.refinedGuidanceInPosition(
            rawInPosition: movementData.isInPosition == true,
            detector: currentExercise,
            step: step,
            currentRom: movementData.currentRomValue ?? 0,
            feedback: movementData.feedback
        )
        let isInAssessmentPosition = guidanceInAssessmentPosition(
            step: step,
            rawInPosition: movementData.isInPosition == true,
            refinedInPosition: refinedInPosition,
            rom: movementData.currentRomValue
        )
        let segment = advanceGuidanceVideoIfNeeded(for: step)

        DispatchQueue.main.async {
            self.viewModel.updateGuidance(
                step: step,
                progress: movementData.coachAdvanceProgress,
                vocalKey: movementData.guidanceVocalKey,
                requestsReplay: movementData.requestGuidanceVocalReplay == true,
                videoSegment: segment,
                isInPosition: isInAssessmentPosition,
                romValue: movementData.currentRomValue
            )
        }

        if step == .hold, isInAssessmentPosition {
            completeGuidanceMode()
        }

        return currentExerciseUsesGuidance && !didCompleteGuidanceForCurrentExercise
    }

    private func advanceGuidanceVideoIfNeeded(for step: GuidanceStep) -> GuidanceVideoSegment? {
        let targetRank = step.sequenceIndex
        guard targetRank > highestGuidanceVideoStepRank else { return nil }

        let detector = currentExercise
        let compact = GuidanceModePolicy.skipsIntermediateGuidanceRanks(detector: detector)
        if compact, highestGuidanceVideoStepRank >= 0, targetRank > highestGuidanceVideoStepRank + 1 {
            highestGuidanceVideoStepRank = targetRank
            return DemoGuidanceVideoPolicy.segment(for: step, detector: detector)
        }

        var nextSegment: GuidanceVideoSegment?
        for rank in (highestGuidanceVideoStepRank + 1)...targetRank {
            if GuidanceModePolicy.shouldSkipGuidanceVideoRank(rank, detector: detector) {
                highestGuidanceVideoStepRank = rank
                continue
            }
            guard let stepForRank = GuidanceStep.from(sequenceIndex: rank) else { continue }
            highestGuidanceVideoStepRank = rank
            nextSegment = DemoGuidanceVideoPolicy.segment(for: stepForRank, detector: detector) ?? nextSegment
        }

        return nextSegment
    }

    private func completeGuidanceMode() {
        guard currentExerciseUsesGuidance, !didCompleteGuidanceForCurrentExercise else { return }
        didCompleteGuidanceForCurrentExercise = true
        flowManager?.endGuidanceMode()
        DispatchQueue.main.async {
            self.viewModel.completeGuidance()
        }
    }

    private func finishCurrentExercise() {
        do {
            _ = try flowManager?.stopDetection()

            // Use green-zone data if the user ever reached the target ROM, otherwise all in-position data
            let scoresToUse = greenZoneTechniqueScores.isEmpty ? currentTechniqueScores : greenZoneTechniqueScores
            let feedbacksToUse = greenZoneTechniqueScores.isEmpty ? currentFeedbacks : greenZoneFeedbacks

            let avg = scoresToUse.isEmpty ? 0 : scoresToUse.reduce(0, +) / Float(scoresToUse.count)
            let peakRom: Float? = currentRomValues.isEmpty ? nil : currentRomValues.max()
            results.append(AssessmentExerciseResult(
                name: currentExercise,
                techniqueScore: avg * 100,
                feedbacks: Array(feedbacksToUse),
                timeInPosition: viewModel.timeInPosition,
                peakRom: peakRom
            ))
            if exerciseIndex < exercises.count - 1 {
                exerciseIndex += 1
                showCountdown()
            } else {
                finishAssessment()
            }
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func finishAssessment() {
        flowManager?.stopSession { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.showAssessmentSummary()
            case .failure(let error):
                self.showError(message: error.localizedDescription)
            }
        }
    }

    private func showAssessmentSummary() {
        guard let summaryView = UIHostingController(rootView: AssessmentSummaryView(
            results: results,
            dismissWasPressed: { self.dismiss(animated: true) }
        )).view else { return }
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(summaryView)
        NSLayoutConstraint.activate([
            summaryView.topAnchor.constraint(equalTo: view.topAnchor),
            summaryView.leftAnchor.constraint(equalTo: view.leftAnchor),
            summaryView.rightAnchor.constraint(equalTo: view.rightAnchor),
            summaryView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupPreviewLayer(session: AVCaptureSession) {
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.frame = view.layer.bounds
        layer.contentsGravity = .resizeAspect
        layer.videoGravity = .resizeAspect
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer

        setupSkeletonView()
    }

    private func setupSkeletonView() {
        skeletonView?.removeFromSuperview()

        // Slim preset: pointRad 5, lineWidth 1.5, black fill / white stroke
        // Dots glow: 0.5, Dots opacity: 0.8, Connection: none
        let allowedJoints: [Joint] = [
            .RShoulder, .RElbow, .RWrist,
            .LShoulder, .LElbow, .LWrist,
            .RHip, .RKnee, .RAnkle,
            .LHip, .LKnee, .LAnkle
        ]
        let jointsStyle: [JointStyle] = allowedJoints.map { joint in
            JointStyle(
                joint: joint,
                pointRad: 5,
                color: UIColor.black.withAlphaComponent(0.8),
                jointShadowFactor: 3,
                strokeColor: UIColor.white.withAlphaComponent(0.8),
                lineWidth: 1.5,
                shadowOpacity: 0.5,
                shadowRadiusScale: 1
            )
        }

        let sv = SkeletonView(
            poseType: .COCO,
            limbsStyle: [],          // connection: none
            jointsStyle: jointsStyle,
            frame: view.bounds,
            skeletonAnimationDuration: 0.05
        )
        sv.frame = view.bounds
        view.addSubview(sv)
        skeletonView = sv
        // Keep calibration overlay on top so Skip / Close buttons remain tappable
        if calibrationOverlay.superview != nil {
            view.bringSubviewToFront(calibrationOverlay)
        }
    }

    private func stopAndDismiss() {
        guard let flowManager else {
            dismiss(animated: true)
            return
        }
        flowManager.stopSession { [weak self] _ in
            self?.dismiss(animated: true)
        }
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension AssessmentViewController: SMKitSessionDelegate {
    func captureSessionDidSet(session: AVCaptureSession) {
        DispatchQueue.main.async {
            self.setupPreviewLayer(session: session)
            self.flowManager?.setBodyPositionCalibrationInactive()
            try? self.flowManager?.setBodyPositionCalibrationActive(
                delegate: self,
                screenSize: self.view.frame.size
            )
        }
    }

    func captureSessionDidStop() {}

    func handleDetectionData(movementData: MovementFeedbackData?) {
        guard let movementData else { return }
        if updateGuidance(from: movementData) {
            return
        }

        let rawInPosition = movementData.isInPosition ?? false
        let rom = movementData.currentRomValue
        let isInPosition = assessmentInPosition(rawInPosition: rawInPosition, rom: rom)
        let feedbackStrings = movementData.feedback?.map { $0.description } ?? []

        if let score = movementData.techniqueScore, isInPosition {
            currentTechniqueScores.append(score)
        }
        if isInPosition {
            feedbackStrings.forEach { currentFeedbacks.insert($0) }
        }
        if let r = rom {
            currentRomValues.append(r)
        }

        // Track green-zone frames separately
        let inGreenZone: Bool = {
            guard let r = rom, let range = currentRomRange else { return false }
            return range.contains(r)
        }()
        if inGreenZone, let score = movementData.techniqueScore {
            greenZoneTechniqueScores.append(score)
            feedbackStrings.forEach { greenZoneFeedbacks.insert($0) }
        }

        // Color the top feedback's joints red on the skeleton
        let topFeedbackJoints = movementData.feedback?.first?.assessmentJoints ?? []

        DispatchQueue.main.async {
            self.viewModel.update(
                techniqueScore: movementData.techniqueScore,
                feedbacks: feedbackStrings,
                isInPosition: isInPosition,
                romValue: rom
            )

            if isInPosition, !topFeedbackJoints.isEmpty {
                self.skeletonView?.setCirclsColor(
                    joints: topFeedbackJoints,
                    removeAfter: 1.0,
                    color: .systemRed
                )
            }
        }
    }

    func handlePositionData(poseData2D: [Joint: JointData]?, poseData3D: [Joint: SCNVector3]?, jointAnglesData: [LimbsPairs: Float]?, jointGlobalAnglesData: [Limbs: Float]?, xyzEulerAngles: [String: SCNVector3]?, xyzRelativeAngles: [String: SCNVector3]?) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let previewLayer = self.previewLayer else { return }
            let hasPerson = poseData2D != nil && !(poseData2D?.isEmpty ?? true)
            guard let joints = poseData2D else {
                self.skeletonView?.isHidden = true
                return
            }
            let captureSize = previewLayer.frame.size
            let videoSize = (previewLayer.session?.sessionPreset ?? .hd1920x1080).videoSize
            self.skeletonView?.isHidden = !hasPerson
            if hasPerson {
                self.skeletonView?.updateSkeleton(
                    rawData: joints,
                    captureSize: captureSize,
                    videoSize: videoSize
                )
            }
        }
    }

    func handleAnatomicalAngles(anatomicalAngles: [String : SCNVector3]?) {

    }

    func handleSessionErrors(error: Error) {
        DispatchQueue.main.async { self.showError(message: error.localizedDescription) }
    }

    func didCaptureBuffer(pixelBuffer: CVPixelBuffer, time: CMTime, orientation: CGImagePropertyOrientation) {}

    func videoSessionProcessingProgress(progress: Float, processedFrames: Int) {}

    func videoSessionDidFinish() {}
}

extension AssessmentViewController: SMBodyCalibrationDelegate {
    func bodyCalStatusDidChange(status: SMBodyCalibrationStatus) {
        DispatchQueue.main.async {
            switch status {
            case .DidEnterFrame:
                self.isBodyInFrame = true
                self.calibrationViewModel.isBodyInFrame = true
                self.boundingBoxGuideView?.setInPosition(true)
                self.checkCalibrationComplete()
            case .DidLeaveFrame:
                self.isBodyInFrame = false
                self.calibrationViewModel.isBodyInFrame = false
                self.boundingBoxGuideView?.setInPosition(false)
            case .TooClose:
                break
            @unknown default:
                break
            }
        }
    }

    func didRecivedBoundingBox(box: BodyCalRectGuide) {
        DispatchQueue.main.async {
            guard let previewLayer = self.previewLayer else { return }
            let videoSize = (previewLayer.session?.sessionPreset ?? .hd1920x1080).videoSize
            let guideRect = box.screenRect(videoSize: videoSize, viewSize: self.view.bounds.size)
            let guideView = BodyCalibrationGuideView(guideRect: guideRect, frame: self.view.bounds)
            self.boundingBoxGuideView?.removeFromSuperview()
            if self.calibrationOverlay.superview != nil {
                self.view.insertSubview(guideView, belowSubview: self.calibrationOverlay)
            } else {
                self.view.addSubview(guideView)
            }
            self.boundingBoxGuideView = guideView
        }
    }
}

extension AssessmentViewController: AssessmentViewDelegate {
    func exerciseTimeDidFinish() {
        finishCurrentExercise()
    }

    func countdownDidFinish() {
        startExercise()
    }

    func stopWasPressed() {
        stopAndDismiss()
    }
}

extension BodyCalRectGuide {
    /// Converts the normalized guide rect to screen coordinates, accounting for
    /// the .resizeAspect letterboxing applied by AVCaptureVideoPreviewLayer.
    func screenRect(videoSize: CGSize, viewSize: CGSize) -> CGRect {
        let videoRect = getRect(videoSize: videoSize)
        let scale = min(viewSize.width / videoSize.width, viewSize.height / videoSize.height)
        let offsetX = (viewSize.width - videoSize.width * scale) / 2
        let offsetY = (viewSize.height - videoSize.height * scale) / 2
        return CGRect(
            x: videoRect.origin.x * scale + offsetX,
            y: videoRect.origin.y * scale + offsetY,
            width: videoRect.width * scale,
            height: videoRect.height * scale
        )
    }
}

/// A transparent overlay that draws a darkened surround with a clear guide
/// rectangle and a white/green border indicating whether the person is in frame.
final class BodyCalibrationGuideView: UIView {
    private let borderLayer = CAShapeLayer()
    private let guideRect: CGRect

    init(guideRect: CGRect, frame: CGRect) {
        self.guideRect = guideRect
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        setupLayers()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayers() {
        let overlayLayer = CAShapeLayer()
        let overlayPath = UIBezierPath(rect: bounds)
        overlayPath.append(UIBezierPath(roundedRect: guideRect, cornerRadius: 12).reversing())
        overlayLayer.path = overlayPath.cgPath
        overlayLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        layer.addSublayer(overlayLayer)

        borderLayer.path = UIBezierPath(roundedRect: guideRect, cornerRadius: 12).cgPath
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = 3
        layer.addSublayer(borderLayer)
    }

    func setInPosition(_ inPosition: Bool) {
        borderLayer.strokeColor = inPosition ? UIColor.green.cgColor : UIColor.white.cgColor
    }
}

extension FormFeedbackTypeBr {
    /// Maps feedback types to the body joints that should be highlighted red.
    /// Covers the assessment exercises: OverheadMobility, SquatRegularOverheadStatic,
    /// JeffersonCurl, StandingSideBend.
    var assessmentJoints: [Joint] {
        switch self {
        // OverheadMobility
        case .overheadMobilityStraightHands:
            return [.LWrist, .LElbow, .RWrist, .RElbow]
        case .overheadMobilityStraightBack:
            return [.LShoulder, .LHip, .RShoulder, .RHip]
        case .overheadMobilityRaiseHands:
            return [.RWrist, .LWrist]
        case .overheadMobilitySideStand:
            return [.LHip, .RHip, .LShoulder, .RShoulder]
        case .overheadMobilityLowerRibs:
            return [.LHip, .RHip]

        // Squat
        case .squatKneesCollapsingInward, .squatKneesCollapsingOutward:
            return [.LKnee, .RKnee]
        case .squatForwardLean:
            return [.LShoulder, .LHip, .RShoulder, .RHip]
        case .squatHipCreaseDepth:
            return [.LHip, .RHip]
        case .squatOverHeadHandsNotStraight:
            return [.LWrist, .LElbow, .RWrist, .RElbow]
        case .squatAnkleWidth, .squatAnkleTooNarrowWidth, .squatAnkleTooWideWidth:
            return [.LAnkle, .RAnkle]

        // Jefferson Curl
        case .jeffersonCurlSideView:
            return [.LShoulder, .LHip, .RShoulder, .RHip]
        case .jeffersonCurlLegsStraight:
            return [.LKnee, .RKnee]
        case .jeffersonCurlHandsReach:
            return [.LWrist, .RWrist]
        case .jeffersonCurlHipFlex:
            return [.LHip, .RHip, .LShoulder, .RShoulder]

        // Standing Side Bend
        case .standingSideBendTorsoRotation, .standingSideBendLateralTorsoFlex:
            return [.LShoulder, .RShoulder]
        case .standingSideBendHandsAboveHead:
            return [.RWrist, .LWrist]
        case .standingSideBendFeetOnFloor:
            return [.LAnkle, .RAnkle]

        default:
            return []
        }
    }
}
