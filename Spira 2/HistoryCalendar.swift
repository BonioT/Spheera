//
//  HistoryCalendar.swift
//  Spheera
//
//  Created by Antonio Bonetti.
//

import SwiftUI
import Charts

enum CalendarMode {
    case week
    case month
}

struct HistoryCalendar: View {
    let entries: [FeelingEntry]
    var mode: CalendarMode = .month
    var onWeekTap: (() -> Void)? = nil

    @State private var monthOffset: Int = 0
    @State private var selectedDay: Date?

    private var groupedEntries: [Date: [FeelingEntry]] {
        let cal = Calendar.current
        var dict: [Date: [FeelingEntry]] = [:]
        for entry in entries {
            let start = cal.startOfDay(for: entry.date)
            dict[start, default: []].append(entry)
        }
        return dict
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow

            let referenceDate = mode == .month ? monthDate(offset: monthOffset) : Date()
            
            if mode == .month {
                Text(monthTitle(for: referenceDate))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
            }

            weekdayHeader

            calendarGrid(referenceDate: referenceDate)

            if mode == .month {
                detailView
            }
        }
        .padding(14)
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: selectedDay)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var headerRow: some View {
        if mode == .month {
            HStack {
                Text(String(localized: "Timeline"))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                HStack(spacing: 15) {
                    Button { monthOffset -= 1 } label: { Image(systemName: "chevron.left") }
                    Button { monthOffset += 1 } label: { Image(systemName: "chevron.right") }
                }
                .foregroundColor(.white.opacity(0.85))
                .buttonStyle(.plain)
            }
        } else {
            HStack {
                Text(String(localized: "This Week"))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .contentShape(Rectangle())
            .onTapGesture { onWeekTap?() }
        }
    }

    private var weekdayHeader: some View {
        let symbols = Calendar.current.shortWeekdaySymbols
        let monFirst = Array(symbols[1...]) + [symbols[0]]
        return HStack {
            ForEach(monFirst, id: \.self) { s in
                Text(s.uppercased())
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.55))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }

    private func calendarGrid(referenceDate: Date) -> some View {
        let gridDays = mode == .month ? daysInMonthGrid(for: referenceDate) : daysInCurrentWeek()
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            ForEach(gridDays, id: \.self) { day in
                let dayEntries = groupedEntries[day] ?? []
                let isInMonth = Calendar.current.isDate(day, equalTo: referenceDate, toGranularity: .month)
                
                DayCell(
                    day: day,
                    isInCurrentMonth: isInMonth,
                    entries: dayEntries,
                    mode: mode
                ) {
                    handleDayTap(day)
                }
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let selected = selectedDay, let dayEntries = groupedEntries[selected], !dayEntries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Divider().background(Color.white.opacity(0.1))
                    .padding(.vertical, 4)
                
                Text(dayTitle(selected))
                    .font(.headline)
                    .foregroundColor(.cyan)
                
                ForEach(dayEntries, id: \.id) { entry in
                    entryRow(entry)
                }
            }
            .padding(.top, 4)
            .transition(.opacity)
        } else {
            Text(String(localized: "Don’t focus on one moment. Look at the whole timeline. Breathe. You’re okay."))
                .font(.footnote)
                .foregroundColor(.white.opacity(0.75))
                .padding(.top, 8)
        }
    }

    private func entryRow(_ entry: FeelingEntry) -> some View {
        let feeling = FeelingState(rawValue: entry.stateRaw)
        return HStack(spacing: 12) {
            Circle()
                .fill(feeling?.color ?? .gray)
                .frame(width: 8, height: 8)
            
            Text(feeling?.title ?? entry.stateRaw)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Text(timeString(entry.date))
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Logic & Helpers
    
    private func handleDayTap(_ day: Date) {
        if mode == .week {
            onWeekTap?()
        } else {
            selectedDay = (selectedDay == day) ? nil : day
        }
    }

    private func dayTitle(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }

    private func monthDate(offset: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: offset, to: Date()) ?? Date()
    }

    private func monthTitle(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date)
    }

    private func daysInCurrentWeek() -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let mondayFirstOffset = (weekday + 5) % 7
        var days: [Date] = []
        if let startOfWeek = cal.date(byAdding: .day, value: -mondayFirstOffset, to: today) {
            for i in 0..<7 {
                if let d = cal.date(byAdding: .day, value: i, to: startOfWeek) { days.append(d) }
            }
        }
        return days
    }

    private func daysInMonthGrid(for month: Date) -> [Date] {
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: month)) ?? month
        let range = cal.range(of: .day, in: .month, for: startOfMonth) ?? 1..<2
        let weekday = cal.component(.weekday, from: startOfMonth)
        let mondayFirstOffset = (weekday + 5) % 7
        var days: [Date] = []
        for i in 0..<mondayFirstOffset {
            if let d = cal.date(byAdding: .day, value: i - mondayFirstOffset, to: startOfMonth) { days.append(d) }
        }
        for d in 0..<range.count {
            if let date = cal.date(byAdding: .day, value: d, to: startOfMonth) { days.append(date) }
        }
        while days.count % 7 != 0 {
            if let last = days.last, let next = cal.date(byAdding: .day, value: 1, to: last) {
                days.append(next)
            } else { break }
        }
        return days
    }
}

// MARK: - DayCell

private struct DayCell: View {
    let day: Date
    let isInCurrentMonth: Bool
    let entries: [FeelingEntry]
    let mode: CalendarMode
    let action: () -> Void

    private var baseColor: Color {
        guard !entries.isEmpty else { return .white.opacity(0.0) }
        let counts = entries.reduce(into: [String: Int]()) { $0[$1.stateRaw] = ($0[$1.stateRaw] ?? 0) + 1 }
        let dominantRaw = counts.max(by: { $0.value < $1.value })?.key ?? ""
        return FeelingState(rawValue: dominantRaw)?.color ?? .cyan
    }
    
    private var cellBgColor: Color {
        if entries.isEmpty { return .white.opacity(isInCurrentMonth ? 0.06 : 0.03) }
        return mode == .month ? baseColor.opacity(0.3) : .white.opacity(0.08)
    }
    
    private var cellBorderColor: Color {
        if entries.isEmpty { return .white.opacity(0.06) }
        return mode == .month ? baseColor.opacity(0.5) : .white.opacity(0.20)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(cellBgColor)
                
                VStack(spacing: 6) {
                    Text("\(Calendar.current.component(.day, from: day))")
                        .font(.caption)
                        .foregroundColor(entries.isEmpty ? .white.opacity(isInCurrentMonth ? 0.85 : 0.35) : .white)
                    
                    Circle()
                        .fill(entries.isEmpty ? .clear : (mode == .week ? baseColor : .white.opacity(0.85)))
                        .frame(width: 5, height: 5)
                }
                .padding(.vertical, 8)
            }
            .frame(height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(cellBorderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Full Calendar Dashboard

struct FullCalendarDashboard: View {
    let entries: [FeelingEntry]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date?
    @State private var visibleDays: Int = 14
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        HistoryCalendar(entries: entries, mode: .month)
                        
                        if !entries.isEmpty {
                            chartCard
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(String(localized: "Your Timeline"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Close")) { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(red: 0.05, green: 0.1, blue: 0.2), .black]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String(localized: "Stress & Peace Function"))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Picker("", selection: $visibleDays) {
                    Text(String(localized: "1W")).tag(7)
                    Text(String(localized: "2W")).tag(14)
                    Text(String(localized: "1M")).tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            
            chartContainer
        }
        .padding()
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var chartContainer: some View {
        let sortedEntries = entries.sorted(by: { $0.date < $1.date })
        
        return Chart {
            ForEach(sortedEntries, id: \.id) { entry in
                let feeling = FeelingState(rawValue: entry.stateRaw)
                let stress = feeling?.stressLevel ?? 5
                
                chartMarks(for: entry, stress: stress, feeling: feeling)
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: Double(visibleDays) * 86400)
        .frame(height: 250)
        .chartXAxis { xAxisStyle(for: visibleDays) }
        .chartYAxis { yAxisStyle }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: visibleDays)
    }
    
    @ChartContentBuilder
    private func chartMarks(for entry: FeelingEntry, stress: Int, feeling: FeelingState?) -> some ChartContent {
        AreaMark(
            x: .value("Date", entry.date),
            y: .value("Stress", stress)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(
            .linearGradient(
                colors: [.cyan.opacity(0.3), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        
        LineMark(
            x: .value("Date", entry.date),
            y: .value("Stress", stress)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(.cyan)
        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        
        PointMark(
            x: .value("Date", entry.date),
            y: .value("Stress", stress)
        )
        .foregroundStyle(.white)
        .symbolSize(40)
        
        if let selectedDate, Calendar.current.isDate(entry.date, inSameDayAs: selectedDate) {
            RuleMark(x: .value("Selected", selectedDate))
                .foregroundStyle(.white.opacity(0.2))
                .annotation(position: .top) {
                    annotationView(for: entry, feeling: feeling)
                }
        }
    }
    
    private func annotationView(for entry: FeelingEntry, feeling: FeelingState?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.date.formatted(.dateTime.hour().minute()))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
            Text(feeling?.title ?? "")
                .font(.caption.bold())
                .foregroundColor(feeling?.color ?? .cyan)
        }
        .padding(8)
        .background(.black.opacity(0.8))
        .cornerRadius(8)
    }
    
    private func xAxisStyle(for days: Int) -> some AxisContent {
        let stride = days > 14 ? 5 : (days > 7 ? 2 : 1)
        
        return AxisMarks(values: .stride(by: .day, count: stride)) { _ in
            AxisGridLine().foregroundStyle(.white.opacity(0.05))
            AxisValueLabel(format: .dateTime.day())
                .foregroundStyle(.white.opacity(0.5))
        }
    }
    
    private var yAxisStyle: some AxisContent {
        AxisMarks(position: .leading, values: [0, 5, 10]) { value in
            AxisGridLine().foregroundStyle(.white.opacity(0.05))
            if let level = value.as(Int.self) {
                AxisValueLabel {
                    Text(level == 0 ? String(localized: "Zen") : (level == 10 ? String(localized: "Peak") : "\(level)"))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }
}

