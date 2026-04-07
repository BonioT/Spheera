//
//  HomeView.swift
//  Spheera
//
//  Created by Antonio Bonetti.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = BreathingViewModel()

    @AppStorage("breathCuesEnabled") private var breathCuesEnabled = true
    @AppStorage("tone432Enabled") private var tone432Enabled = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.05, green: 0.1, blue: 0.2), .black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack(spacing: 6) {
                    Text("Better with headphones")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))

                    Image(systemName: "headphones")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(.top, 6)

                Spacer()

                breathingCircle
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if viewModel.isAnimating {
                            viewModel.reset()
                        } else {
                            viewModel.toggleAnimation()
                        }
                    }

                HStack(spacing: 50) {
                    IconToggleButton(systemName: "lungs.fill", isOn: $breathCuesEnabled)
                    IconToggleButton(systemName: "music.note", isOn: $tone432Enabled)
                }
                .padding(.horizontal)

                techniquePicker

                Text(viewModel.breathingPhase.localizedName)
                    .font(.system(size: 40, weight: .bold))
                    .fontWeight(.light)
                    .foregroundColor(.white.opacity(0.85))
                    .animation(.easeInOut, value: viewModel.breathingPhase)

                if viewModel.isAnimating {
                    Text(viewModel.selectedTechnique?.description ?? "")
                        .font(.headline)
                        .fontWeight(.light)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .transition(.opacity.animation(.easeIn))
                }

                Spacer()
                Spacer()
            }
            .onChange(of: tone432Enabled) {
                updateLoopState()
            }
            .onChange(of: viewModel.isAnimating) {
                updateLoopState()
            }
            .onDisappear {
                AudioManager.shared.stopLoop()
            }
            .onChange(of: viewModel.breathingPhase) { _, newPhase in
                guard breathCuesEnabled else { return }

                switch newPhase {
                case .inhale:
                    AudioManager.shared.playCue(fileName: "inhale.mp3")
                case .exhale:
                    AudioManager.shared.playCue(fileName: "exhale.mp3")
                default:
                    break
                }
            }
            .padding()
        }
    }

    private func updateLoopState() {
        if tone432Enabled && viewModel.isAnimating {
            AudioManager.shared.startLoop(fileName: "tone432.wav", volume: 0.6)
        } else {
            AudioManager.shared.stopLoop()
        }
    }

    private var breathingCircle: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2)
                .foregroundColor(.white.opacity(0.1))
                .frame(width: 250, height: 250)

            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.cyan, .blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 250, height: 250)
                .scaleEffect(viewModel.scale)
                .shadow(color: .cyan.opacity(0.4), radius: 25, x: 0, y: 0)

            Text(viewModel.countdown)
                .font(.system(size: 35, weight: .thin))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundColor(.white)
                .animation(nil, value: viewModel.countdown)
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(viewModel.isAnimating ? "Reset breathing" : "Start breathing")
    }

    private var techniquePicker: some View {
        Picker("Select a technique", selection: $viewModel.selectedTechnique) {
            ForEach(BreathingTechnique.presets) { technique in
                Text(technique.name)
                    .tag(technique as BreathingTechnique?)
            }
        }
        .pickerStyle(.menu)
        .tint(.cyan)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
        .padding(.horizontal)
        .disabled(viewModel.isAnimating)
    }
}

private struct IconToggleButton: View {
    let systemName: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.white.opacity(isOn ? 0.22 : 0.10))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(isOn ? 0.35 : 0.15), lineWidth: 1)
                    )

                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(isOn ? 0.95 : 0.6))

                if !isOn {
                    Rectangle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 28, height: 2)
                        .rotationEffect(.degrees(-45))
                        .transition(.opacity)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
