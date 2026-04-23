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
        case .ready:  return String(localized: "Ready?")
        case .inhale: return String(localized: "Inhale...")
        case .hold:   return String(localized: "Hold")
        case .exhale: return String(localized: "Exhale...")
        }
    }
}

@MainActor
final class BreathingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedTechnique: BreathingTechnique? = BreathingTechnique.presets.first
    @Published var breathingPhase: BreathingPhase = .ready
    @Published var scale: CGFloat = 0.4
    @Published var countdown: String = String(localized: "Start")
    @Published var isAnimating = false
    
    // Session State
    @Published var phaseElapsedTime: Double = 0.0
    private var animationTask: Task<Void, Never>?
    
    // MARK: - Public Methods

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

    // MARK: - Private Logic

    private func startBreathingCycle() {
        guard let technique = selectedTechnique else { return }
        
        stopBreathingCycle()

        animationTask = Task {
            while isAnimating {
                guard !Task.isCancelled else { break }

                // 1. Inhale
                await runPhase(
                    phase: .inhale,
                    duration: technique.inhaleDuration,
                    targetScale: 1.0
                )
                
                // 2. Hold (Optional)
                if isAnimating && !Task.isCancelled && technique.holdDuration > 0 {
                    await runPhase(
                        phase: .hold,
                        duration: technique.holdDuration,
                        targetScale: 1.0
                    )
                }

                // 3. Exhale
                if isAnimating && !Task.isCancelled {
                    await runPhase(
                        phase: .exhale,
                        duration: technique.exhaleDuration,
                        targetScale: 0.4
                    )
                }
                
                guard isAnimating && !Task.isCancelled else { break }
            }

            if !Task.isCancelled {
                resetToInitialState()
                isAnimating = false
            }
        }
    }

    private func stopBreathingCycle() {
        animationTask?.cancel()
        animationTask = nil
    }

    private func runPhase(phase: BreathingPhase, duration: TimeInterval, targetScale: CGFloat) async {
        breathingPhase = phase
        phaseElapsedTime = 0.0

        // Exhale animation is slightly shorter to feel more natural
        let animationDuration = (phase == .exhale) ? duration * 0.9 : duration

        withAnimation(.easeInOut(duration: animationDuration)) {
            scale = targetScale
        }

        await runCountdown(for: duration)
    }

    private func runCountdown(for duration: TimeInterval) async {
        let startTime = Date()
        
        while phaseElapsedTime < duration {
            if Task.isCancelled { return }
            
            let elapsed = Date().timeIntervalSince(startTime)
            phaseElapsedTime = min(elapsed, duration)
            
            let remaining = Int(ceil(duration - phaseElapsedTime))
            countdown = remaining > 0 ? "\(remaining)" : "0"
            
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private func resetToInitialState() {
        withAnimation(.easeInOut(duration: 1.5)) {
            scale = 0.4
            breathingPhase = .ready
            countdown = String(localized: "Start")
            phaseElapsedTime = 0.0
        }
    }
}
