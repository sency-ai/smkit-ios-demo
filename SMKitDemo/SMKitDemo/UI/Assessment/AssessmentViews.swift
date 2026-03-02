//
//  AssessmentViews.swift
//  SMKitDemo
//

import SwiftUI

// MARK: - Calibration ViewModel

class CalibrationViewModel: ObservableObject {
    @Published var isPhoneReady: Bool = false
    @Published var isBodyInFrame: Bool = false
    @Published var isTooClose: Bool = false
}

// MARK: - Calibration View

struct CalibrationView: View {
    @ObservedObject var model: CalibrationViewModel
    let onStop: () -> Void
    let onSkip: () -> Void

    var statusMessage: String {
        if model.isTooClose { return "Too close — step back" }
        if !model.isPhoneReady { return "Tilt your phone upright" }
        if !model.isBodyInFrame { return "Step into the frame" }
        return "Hold still…"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onStop) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding()
                }
            }

            Spacer()

            VStack(spacing: 20) {
                Text("Calibration")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                VStack(spacing: 12) {
                    CalibrationRow(
                        icon: "iphone.gen3",
                        label: "Phone angle",
                        isReady: model.isPhoneReady
                    )
                    CalibrationRow(
                        icon: "figure.stand",
                        label: "Body in frame",
                        isReady: model.isBodyInFrame && !model.isTooClose
                    )
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(16)

                Text(statusMessage)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Button(action: onSkip) {
                    Text("Skip Calibration")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding()

            Spacer()
        }
    }
}

struct CalibrationRow: View {
    let icon: String
    let label: String
    let isReady: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 28)
            Text(label)
                .font(.body)
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: isReady ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isReady ? .green : .white.opacity(0.4))
        }
    }
}

// MARK: - Delegate

protocol AssessmentViewDelegate {
    func exerciseTimeDidFinish()
    func countdownDidFinish()
    func stopWasPressed()
}

// MARK: - ViewModel

class AssessmentViewModel: ObservableObject {
    @Published var exerciseName: String = ""
    @Published var exerciseIndex: Int = 0
    @Published var totalExercises: Int = 0
    @Published var timeRemaining: Float = 15
    @Published var techniqueScore: Float = 0
    @Published var feedbacks: [String] = []
    @Published var isInPosition: Bool = false
    @Published var timeInPosition: Float = 0

    // Countdown state
    @Published var isCountingDown: Bool = false
    @Published var countdownValue: Int = 3
    @Published var countdownExerciseName: String = ""

    // ROM state
    @Published var currentRomValue: Float = 0
    @Published var romRange: ClosedRange<Float>? = nil
    var isRomInRange: Bool {
        guard let range = romRange else { return false }
        return range.contains(currentRomValue)
    }

    var duration: Float = 15

    func startCountdown(exerciseName: String) {
        isCountingDown = true
        countdownValue = 3
        countdownExerciseName = exerciseName
    }

    func startExercise(name: String, index: Int, total: Int, duration: Float) {
        isCountingDown = false
        exerciseName = name
        exerciseIndex = index
        totalExercises = total
        timeRemaining = duration
        self.duration = duration
        techniqueScore = 0
        feedbacks = []
        isInPosition = false
        timeInPosition = 0
        currentRomValue = 0
        romRange = nil
    }

    func setRomRange(_ range: ClosedRange<Float>?) {
        romRange = range
    }

    // Feedbacks that are ROM-depth cues — suppress when already in the green zone
    private static let romDepthFeedbacks: Set<String> = [
        "Let your hands reach a bit further toward the floor.",  // JeffersonCurl
        "Lower your hips a bit further down."                    // SquatRegularOverheadStatic
    ]

    func update(techniqueScore: Float?, feedbacks: [String], isInPosition: Bool, romValue: Float?) {
        if let score = techniqueScore {
            self.techniqueScore = score * 100
        }
        self.isInPosition = isInPosition
        if let rom = romValue {
            self.currentRomValue = rom
        }

        if isInPosition {
            let filtered = isRomInRange
                ? feedbacks.filter { !AssessmentViewModel.romDepthFeedbacks.contains($0) }
                : feedbacks
            self.feedbacks = filtered
        } else {
            if !self.feedbacks.isEmpty { self.feedbacks = [] }
        }
    }
}

// MARK: - Assessment View

struct AssessmentView: View {
    @ObservedObject var model: AssessmentViewModel
    let delegate: AssessmentViewDelegate

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    let countdownTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var progressColor: Color {
        model.timeRemaining > 10 ? .green : model.timeRemaining > 5 ? .orange : .red
    }

    var body: some View {
        ZStack {
            // Exercise UI
            exerciseContent
                .opacity(model.isCountingDown ? 0 : 1)

            // Countdown overlay
            if model.isCountingDown {
                countdownOverlay
            }
        }
    }

    // MARK: - Countdown Overlay

    var countdownOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { delegate.stopWasPressed() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding()
                }
            }

            Spacer()

            VStack(spacing: 24) {
                Text("NEXT UP")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.7))

                Text(model.countdownExerciseName)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("\(model.countdownValue)")
                    .font(.system(size: 120, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }

            Spacer()
        }
        .background(Color.black.opacity(0.7))
        .onReceive(countdownTimer) { _ in
            guard model.isCountingDown else { return }
            if model.countdownValue > 1 {
                withAnimation { model.countdownValue -= 1 }
            } else {
                delegate.countdownDidFinish()
            }
        }
    }

    // MARK: - Exercise Content

    var exerciseContent: some View {
        VStack(spacing: 0) {
            // Header — large exercise name
            VStack(spacing: 4) {
                Text(model.exerciseName)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                HStack {
                    Text("\(model.exerciseIndex + 1) / \(model.totalExercises)")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Button { delegate.stopWasPressed() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.6))

            Spacer()

            // ROM gauge
            VStack(spacing: 12) {
                if model.romRange != nil {
                    RomGaugeView(
                        value: model.currentRomValue,
                        range: model.romRange!,
                        isInPosition: model.isInPosition
                    )
                }

                Text(model.isInPosition ? "In Position" : "Get in position")
                    .font(.headline)
                    .foregroundStyle(model.isInPosition ? .green : .white)
            }

            Spacer()

            // Timer countdown
            Text(String(format: "%.1f", max(model.timeRemaining, 0)))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(progressColor)
                .padding(.bottom, 8)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.white.opacity(0.2))
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geo.size.width * CGFloat(max(model.timeRemaining, 0) / model.duration))
                        .animation(.linear(duration: 0.1), value: model.timeRemaining)
                }
            }
            .frame(height: 6)

            // Feedbacks
            if !model.feedbacks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(model.feedbacks, id: \.self) { feedback in
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(feedback)
                                .font(.callout)
                        }
                    }
                }
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.6))
            }
        }
        .onReceive(timer) { _ in
            guard !model.isCountingDown, model.timeRemaining > 0 else { return }
            model.timeRemaining -= 0.1
            if model.isInPosition { model.timeInPosition += 0.1 }
            if model.timeRemaining <= 0 {
                delegate.exerciseTimeDidFinish()
            }
        }
    }
}

// MARK: - ROM Gauge View

struct RomGaugeView: View {
    let value: Float       // 0.0–1.0
    let range: ClosedRange<Float>
    let isInPosition: Bool

    private var normalizedValue: Float { 0.5 * value + 0.5 }
    private var normalizedRange: ClosedRange<Float> {
        (0.5 * range.lowerBound + 0.5)...(0.5 * range.upperBound + 0.5)
    }
    private var isInRange: Bool {
        normalizedRange.contains(normalizedValue)
    }
    private var needleAngle: Double {
        Double(value) * 180
    }

    var body: some View {
        ZStack {
            // Background arc
            Circle()
                .trim(from: 0.5, to: 1.0)
                .stroke(Color.white.opacity(0.25), lineWidth: 30)
                .frame(width: 140, height: 140)

            // Target zone arc
            Circle()
                .trim(
                    from: CGFloat(normalizedRange.lowerBound),
                    to: CGFloat(normalizedRange.upperBound)
                )
                .stroke(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 30
                )
                .opacity(0.75)
                .frame(width: 140, height: 140)

            // Needle
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .frame(width: 6, height: 60)
                .shadow(color: .black.opacity(0.8), radius: 4)
                .offset(y: -40)
                .rotationEffect(.degrees(-90 + needleAngle))
                .animation(.easeOut(duration: 0.15), value: value)

            // ROM percentage text
            VStack(spacing: 0) {
                Text("\(Int(value * 100))%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isInRange ? .green : .white)
                Text("ROM")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .offset(y: 12)
        }
        .frame(height: 90)
    }
}

// MARK: - Assessment Summary View

struct AssessmentSummaryView: View {
    let results: [AssessmentExerciseResult]
    let dismissWasPressed: () -> Void

    var overallScore: Int {
        guard !results.isEmpty else { return 0 }
        return Int(results.map { $0.techniqueScore }.reduce(0, +) / Float(results.count))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button { dismissWasPressed() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Text("Assessment Results")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
            .foregroundStyle(.white)
            .padding()
            .background(Color.gray)

            ScrollView {
                VStack(spacing: 16) {
                    // Overall score
                    VStack(spacing: 4) {
                        Text("Overall Score")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("\(overallScore)")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundStyle(scoreColor(overallScore))
                        Text("/ 100")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Per-exercise cards
                    ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                        ExerciseResultCard(result: result)
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
    }

    func scoreColor(_ score: Int) -> Color {
        score >= 80 ? .green : score >= 60 ? .orange : .red
    }
}

// MARK: - Exercise Result Card

struct ExerciseResultCard: View {
    let result: AssessmentExerciseResult

    var score: Int { Int(result.techniqueScore) }
    /// No issues = had feedbacks while in position and none were corrections. Never in position → no checkmark.
    var isPerfect: Bool { result.feedbacks.isEmpty && result.timeInPosition > 0 }
    var isMaxRom: Bool { (result.peakRom ?? 0) >= 1.0 }

    var scoreColor: Color {
        score >= 80 ? .green : score >= 60 ? .orange : .red
    }

    /// Explanation for the technique score (green/orange/red bar).
    var scoreExplanation: String {
        if score >= 80 {
            return "Form score when in position (and in target ROM when applicable)."
        } else if score >= 60 {
            return "Form had some issues while in position."
        } else {
            return "Form needs improvement when in position."
        }
    }

    /// Explanation for ROM: why 100% vs e.g. 90%.
    var romExplanation: String? {
        guard let rom = result.peakRom else { return nil }
        if rom >= 1.0 {
            return "You reached the full target range."
        } else {
            return "You reached \(Int(rom * 100))% of the target range (100% = full range)."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(result.name)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isPerfect {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("No issues")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }
            }
            if isPerfect {
                Text("No form corrections were given while you were in position.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Score bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreColor)
                        .frame(width: geo.size.width * CGFloat(result.techniqueScore / 100), height: 8)
                }
            }
            .frame(height: 8)
            Text(scoreExplanation)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom) {
                Text("Time in position: \(String(format: "%.1f", result.timeInPosition))s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if isMaxRom {
                    Text("100%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.green)
                } else if let rom = result.peakRom {
                    Text("Peak ROM: \(Int(rom * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let explanation = romExplanation {
                Text(explanation)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !result.feedbacks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Issues detected:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    ForEach(result.feedbacks, id: \.self) { feedback in
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(feedback)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
