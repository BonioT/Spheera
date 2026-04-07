//
//  BreathingViewModel.swift
//  Spheera
//
//  Created by Antonio Bonetti.
//

import Foundation
import SwiftUI
import Combine

enum BreathingPhase: String {
    case ready = "Ready?"
    case inhale = "Inhale..."
    case hold = "Hold"
    case exhale = "Exhale..."

    var localizedName: String {
        switch self {
        case .ready: return String(localized: "Ready?")
        case .inhale: return String(localized: "Inhale...")
        case .hold: return String(localized: "Hold")
        case .exhale: return String(localized: "Exhale...")
        }
    }
}

@MainActor
final class BreathingViewModel: ObservableObject {
    @Published var selectedTechnique: BreathingTechnique? = BreathingTechnique.presets.first
    @Published var breathingPhase: BreathingPhase = .ready
    @Published var scale: CGFloat = 0.4
    @Published var countdown: String = "Start"
    @Published var isAnimating = false

    private var animationTask: Task<Void, Never>?

    func toggleAnimation() {
        guard selectedTechnique != nil else { return }

        isAnimating.toggle()

        if isAnimating {
            startBreathingCycle()
        } else {
            stopBreathingCycle()
        }
    }

    func reset() {
        stopBreathingCycle()
        resetToInitialState()
        isAnimating = false
    }

    private func startBreathingCycle() {
        guard let technique = selectedTechnique else { return }
        animationTask?.cancel()

        animationTask = Task {
            while isAnimating {
                guard !Task.isCancelled else { break }

                await runPhase(
                    phase: .inhale,
                    duration: technique.inhaleDuration,
                    targetScale: 1.0
                )
                guard isAnimating && !Task.isCancelled else { break }

                if technique.holdDuration > 0 {
                    await runPhase(
                        phase: .hold,
                        duration: technique.holdDuration,
                        targetScale: 1.0
                    )
                    guard isAnimating && !Task.isCancelled else { break }
                }

                await runPhase(
                    phase: .exhale,
                    duration: technique.exhaleDuration,
                    targetScale: 0.4
                )
                guard isAnimating && !Task.isCancelled else { break }
            }

            resetToInitialState()
            isAnimating = false
        }
    }

    private func stopBreathingCycle() {
        animationTask?.cancel()
        animationTask = nil
    }

    private func runPhase(phase: BreathingPhase, duration: TimeInterval, targetScale: CGFloat) async {
        breathingPhase = phase

        let animationDuration = (phase == .exhale) ? duration * 0.9 : duration

        withAnimation(.easeInOut(duration: animationDuration)) {
            scale = targetScale
        }

        await runCountdown(for: duration)
    }

    private func runCountdown(for duration: TimeInterval) async {
        for i in (1...Int(duration)).reversed() {
            if Task.isCancelled { return }
            countdown = "\(i)"
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func resetToInitialState() {
        withAnimation(.easeInOut(duration: 1.5)) {
            scale = 0.4
            breathingPhase = .ready
            countdown = "Start"
        }
    }
}
