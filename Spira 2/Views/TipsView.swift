//
//  TipsView.swift
//  Spheera
//
//  Created by Antonio Bonetti.
//

import SwiftUI
import CoreData

struct TipsView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FeelingEntry.date, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<FeelingEntry>

    @AppStorage("selectedFeeling") private var selectedFeelingRaw: String = FeelingState.anxiety.rawValue
    @State private var selectedFeeling: FeelingState = .anxiety
    @State private var moodSelected: Bool = false
    @State private var showSavedToast: Bool = false
    @State private var isCalendarModalPresented: Bool = false

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        headerSection
                        
                        selectionSection
                        
                        calendarPreview
                        
                        if moodSelected {
                            suggestionsSection
                                .id("suggestions")
                        }

                        Spacer(minLength: 24)
                    }
                    .padding()
                    .animation(.spring(response: 0.45, dampingFraction: 0.75), value: moodSelected)
                }
                .onChange(of: moodSelected) { _, selected in
                    if selected { scrollStateToSuggestions(proxy) }
                }
            }
            
            if showSavedToast { toastOverlay }
        }
        .fullScreenCover(isPresented: $isCalendarModalPresented) {
            FullCalendarDashboard(entries: Array(entries))
        }
        .onAppear { loadInitialState() }
        .onChange(of: selectedFeeling) { _, newValue in
            selectedFeelingRaw = newValue.rawValue
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(red: 0.05, green: 0.1, blue: 0.2), .black]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "How do you feel today?"))
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white.opacity(0.92))

            Text(moodSelected
                 ? String(localized: "You selected a state. Here are your suggestions.")
                 : String(localized: "Pick one. One entry per day keeps your timeline clean."))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.75))
                .animation(.easeInOut(duration: 0.3), value: moodSelected)
        }
    }
    
    @ViewBuilder
    private var selectionSection: some View {
        if moodSelected {
            SelectedMoodChip(feeling: selectedFeeling) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    moodSelected = false
                }
            }
            .transition(.asymmetric(
                insertion: .push(from: .top).combined(with: .opacity),
                removal: .opacity
            ))
        } else {
            feelingPicker
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .push(from: .bottom).combined(with: .opacity)
                ))
        }
    }
    
    private var feelingPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Select a state"))
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(FeelingState.allCases) { state in
                    FeelingButton(
                        title: state.title,
                        systemName: state.systemImage,
                        isSelected: state == selectedFeeling
                    ) {
                        selectFeeling(state)
                    }
                }
            }
        }
        .padding(.top, 6)
    }
    
    private var calendarPreview: some View {
        HistoryCalendar(entries: Array(entries), mode: .week) {
            isCalendarModalPresented = true
        }
        .padding(.top, 8)
    }
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Suggestions"))
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            ForEach(TipsLibrary.tips(for: selectedFeeling), id: \.self) { tip in
                TipCard(text: tip)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var toastOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                Text(String(localized: "Saved to Calendar")).font(.subheadline.bold()).foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.85))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .zIndex(1)
    }
    
    // MARK: - Logic
    
    private func loadInitialState() {
        selectedFeeling = FeelingState(rawValue: selectedFeelingRaw) ?? .anxiety
    }
    
    private func selectFeeling(_ state: FeelingState) {
        selectedFeeling = state
        saveToCoreData(state)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            moodSelected = true
        }
    }
    
    private func scrollStateToSuggestions(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation {
                proxy.scrollTo("suggestions", anchor: .top)
            }
        }
    }

    private func saveToCoreData(_ state: FeelingState) {
        let cal = Calendar.current
        let today = Date()
        
        if let existing = entries.first(where: { cal.isDate($0.date, inSameDayAs: today) }) {
            existing.date = today
            existing.stateRaw = state.rawValue
        } else {
            let entry = FeelingEntry(context: context)
            entry.id = UUID()
            entry.date = today
            entry.stateRaw = state.rawValue
        }

        do {
            try context.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                showSavedToast = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showSavedToast = false }
            }
        } catch {
            print("Failed to save feeling: \(error)")
        }
    }
}

// MARK: - View Components

private struct SelectedMoodChip: View {
    let feeling: FeelingState
    let onClear: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feeling.systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.cyan)

            Text(feeling.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            Spacer(minLength: 0)

            Button(action: onClear) {
                Text(String(localized: "Change"))
                    .font(.caption.weight(.medium))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.10))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LinearGradient(colors: [Color.cyan.opacity(0.18), Color.blue.opacity(0.10)], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.cyan.opacity(0.35), lineWidth: 1))
    }
}

private struct FeelingButton: View {
    let title: String
    let systemName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(isSelected ? 0.95 : 0.75))
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(isSelected ? 0.95 : 0.75))
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(.white.opacity(isSelected ? 0.18 : 0.10))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(isSelected ? 0.30 : 0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct TipCard: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))
                .padding(.top, 2)
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
    }
}

// MARK: - Models

enum FeelingState: String, CaseIterable, Identifiable {
    case peaceful, grateful, calm, lowMood, overthinking, stress, anxiety, anguish, panic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .peaceful: return String(localized: "Peaceful")
        case .grateful: return String(localized: "Grateful")
        case .calm: return String(localized: "Calm")
        case .anxiety: return String(localized: "Anxiety")
        case .anguish: return String(localized: "Anguish")
        case .panic: return String(localized: "Panic")
        case .overthinking: return String(localized: "Overthinking")
        case .stress: return String(localized: "Stress")
        case .lowMood: return String(localized: "Low mood")
        }
    }

    var systemImage: String {
        switch self {
        case .peaceful: return "sun.max"
        case .grateful: return "heart.text.square"
        case .calm: return "leaf"
        case .anxiety: return "wind"
        case .anguish: return "cloud.rain"
        case .panic: return "exclamationmark.triangle"
        case .overthinking: return "brain"
        case .stress: return "bolt"
        case .lowMood: return "moon.stars"
        }
    }

    var color: Color {
        switch self {
        case .peaceful: return .mint
        case .grateful: return .teal
        case .calm: return .green
        case .anxiety: return .orange
        case .anguish: return .indigo
        case .panic: return .red
        case .overthinking: return .purple
        case .stress: return .yellow
        case .lowMood: return .blue
        }
    }
    
    var stressLevel: Int {
        switch self {
        case .peaceful: return 0
        case .grateful: return 1
        case .calm: return 2
        case .lowMood: return 4
        case .overthinking: return 5
        case .stress: return 6
        case .anxiety: return 7
        case .anguish: return 8
        case .panic: return 10
        }
    }
}

enum TipsLibrary {
    static func tips(for state: FeelingState) -> [String] {
        switch state {
        case .peaceful:
            return [String(localized: "Let the stillness wash over you."), String(localized: "You are exactly where you need to be.")]
        case .grateful:
            return [String(localized: "Take a mental picture of this moment."), String(localized: "Expand your chest slightly to welcome the feeling.")]
        case .calm:
            return [String(localized: "Notice this feeling. Anchor it in your body."), String(localized: "Breathe gently to maintain this serene state.")]
        case .anxiety:
            return [String(localized: "Try a longer exhale than inhale."), String(localized: "Relax your jaw and drop your shoulders before starting.")]
        case .anguish:
            return [String(localized: "Ground yourself: name 3 things you see, 2 you feel, 1 you hear."), String(localized: "If emotions spike, pause and return when ready.")]
        case .panic:
            return [String(localized: "Comfort first: keep breaths small at the beginning."), String(localized: "Extend the exhale gently. Let the body downshift.")]
        case .overthinking:
            return [String(localized: "Pick one anchor: the countdown or the circle."), String(localized: "Label thoughts as 'thought' and return to breathing.")]
        case .stress:
            return [String(localized: "Reduce input: headphones + fewer distractions."), String(localized: "A steady rhythm helps: equal inhale and exhale.")]
        case .lowMood:
            return [String(localized: "Start with one cycle. Small steps count."), String(localized: "After the session, drink water and stretch once.")]
        }
    }
}

