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

    // Calibration state
    private var isBodyInFrame = false
    private var isPhoneAngleReady = false

    private lazy var assessmentView: UIView = {
        guard let view = UIHostingController(
            rootView: AssessmentView(model: viewModel, delegate: self)
        ).view else { return UIView() }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private lazy var calibrationOverlay: UIView = {
        guard let view = UIHostingController(
            rootView: CalibrationView(model: calibrationViewModel, onStop: { [weak self] in
                self?.stopAndDismiss()
            }, onSkip: { [weak self] in
                self?.beginAssessment()
            })
        ).view else { return UIView() }
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
                phonePosition: .Floor,
                jumpRefPoint: "Hip",
                jumpHeightThreshold: 10,
                userHeight: 170
            )
            flowManager = try SMKitFlowManager(delegate: self)

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

            try flowManager?.startSession(sessionSettings: sessionSettings)

            // Show calibration UI first
            view.addSubview(calibrationOverlay)
            NSLayoutConstraint.activate([
                calibrationOverlay.topAnchor.constraint(equalTo: view.topAnchor),
                calibrationOverlay.leftAnchor.constraint(equalTo: view.leftAnchor),
                calibrationOverlay.rightAnchor.constraint(equalTo: view.rightAnchor),
                calibrationOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        } catch {
            showError(message: error.localizedDescription)
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
        calibrationOverlay.removeFromSuperview()
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
            try flowManager?.startDetection(exercise: currentExercise)

            let romRange = flowManager?.getExerciseRange()
            currentRomRange = romRange

            DispatchQueue.main.async {
                self.viewModel.startExercise(
                    name: self.currentExercise,
                    index: self.exerciseIndex,
                    total: self.exercises.count,
                    duration: self.exerciseDuration
                )
                self.viewModel.setRomRange(romRange)
            }
        } catch {
            showError(message: error.localizedDescription)
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
        do {
            _ = try flowManager?.stopSession()
            DispatchQueue.main.async { self.showAssessmentSummary() }
        } catch {
            showError(message: error.localizedDescription)
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
    }

    private func stopAndDismiss() {
        do { _ = try flowManager?.stopSession() } catch {}
        dismiss(animated: true)
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
        let isInPosition = movementData.isInPosition ?? false
        let rom = movementData.currentRomValue
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

        DispatchQueue.main.async {
            self.viewModel.update(
                techniqueScore: movementData.techniqueScore,
                feedbacks: feedbackStrings,
                isInPosition: isInPosition,
                romValue: rom
            )
        }
    }

    func handlePositionData(poseData2D: [Joint: JointData]?, poseData3D: [Joint: SCNVector3]?, jointAnglesData: [LimbsPairs: Float]?, jointGlobalAnglesData: [Limbs: Float]?, xyzEulerAngles: [String: SCNVector3]?, xyzRelativeAngles: [String: SCNVector3]?) {
        guard let joints = poseData2D, let previewLayer = previewLayer else { return }
        let captureSize = previewLayer.frame.size
        let videoSize = (previewLayer.session?.sessionPreset ?? .hd1920x1080).videoSize
        skeletonView?.updateSkeleton(
            rawData: joints,
            captureSize: captureSize,
            videoSize: videoSize
        )
    }

    func handleSessionErrors(error: Error) {
        DispatchQueue.main.async { self.showError(message: error.localizedDescription) }
    }

    func didCaptureBuffer(pixelBuffer: CVPixelBuffer, time: CMTime, orientation: CGImagePropertyOrientation) {}
}

extension AssessmentViewController: SMBodyCalibrationDelegate {
    func bodyCalStatusDidChange(status: SMBodyCalibrationStatus) {
        DispatchQueue.main.async {
            switch status {
            case .DidEnterFrame:
                self.isBodyInFrame = true
                self.calibrationViewModel.isBodyInFrame = true
                self.checkCalibrationComplete()
            case .DidLeaveFrame:
                self.isBodyInFrame = false
                self.calibrationViewModel.isBodyInFrame = false
            case .TooClose(let tooClose):
                self.calibrationViewModel.isTooClose = tooClose
            }
        }
    }

    func didRecivedBoundingBox(box: BodyCalRectGuide) {}
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
