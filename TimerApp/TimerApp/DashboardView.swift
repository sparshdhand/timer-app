//
//  DashboardView.swift
//  TimerApp
//
//  Created by Sparsh on 30/05/26.
//

import SwiftUI
import Charts
import AppKit

struct CategoryStats: Identifiable {
    var id: String { category }
    let category: String
    let minutes: Int
    let color: Color
}

struct DailyStats: Identifiable {
    var id: Date { date }
    let date: Date
    let minutes: Int
}

struct DashboardView: View {
    @ObservedObject var store: TimerStore
    @Environment(\.dismiss) var dismiss
    
    // Group categories with clean tailored colors
    private var categoryStats: [CategoryStats] {
        var groups: [String: Int] = [:]
        for session in store.completedSessions {
            groups[session.category, default: 0] += session.durationMinutes
        }
        
        let colors: [String: Color] = [
            "Coding": Color(red: 0.32, green: 0.48, blue: 0.40), // Emerald Sage
            "Design": Color(red: 0.70, green: 0.55, blue: 0.45), // Terracotta
            "Writing": Color(red: 0.42, green: 0.52, blue: 0.62), // Slate Blue
            "Learning": Color(red: 0.75, green: 0.65, blue: 0.35), // Solar Gold
            "Research": Color(red: 0.60, green: 0.45, blue: 0.65)  // Heather Purple
        ]
        
        return groups.map { key, value in
            CategoryStats(
                category: key,
                minutes: value,
                color: colors[key, default: Color.gray]
            )
        }.sorted { $0.minutes > $1.minutes }
    }
    
    // Generate daily trends for the last 7 days
    private var dailyStats: [DailyStats] {
        let calendar = Calendar.current
        var trends: [Date: Int] = [:]
        
        // Initialize last 7 days
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let startOfDay = calendar.startOfDay(for: date)
                trends[startOfDay] = 0
            }
        }
        
        // Sum sessions
        for session in store.completedSessions {
            let sessionDate = calendar.startOfDay(for: session.timestamp)
            if trends[sessionDate] != nil {
                trends[sessionDate, default: 0] += session.durationMinutes
            }
        }
        
        return trends.map { key, value in
            DailyStats(date: key, minutes: value)
        }.sorted { $0.date < $1.date }
    }
    
    private var totalFocusMinutes: Int {
        store.completedSessions.reduce(0) { $0 + $1.durationMinutes }
    }
    
    var body: some View {
        ZStack {
            // Glass background
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analytics Dashboard")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Visualize your focus metrics and categories")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.4))
                            .hoverEffect()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Total Metrics Row
                        HStack(spacing: 16) {
                            MetricCard(
                                title: "Total Focused Time",
                                value: String(format: "%.1fh", Double(totalFocusMinutes) / 60.0),
                                icon: "hourglass",
                                color: Color(red: 0.32, green: 0.48, blue: 0.40)
                            )
                            
                            MetricCard(
                                title: "Sessions Logged",
                                value: "\(store.completedSessions.count)",
                                icon: "checkmark.seal.fill",
                                color: Color(red: 0.70, green: 0.55, blue: 0.45)
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Daily Trend Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Weekly Focus Trend")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                            
                            if store.completedSessions.isEmpty {
                                emptyStateView(message: "Weekly activity trend will populate as you log focus sessions.")
                            } else {
                                Chart {
                                    ForEach(dailyStats) { stat in
                                        BarMark(
                                            x: .value("Day", stat.date, unit: .day),
                                            y: .value("Minutes", stat.minutes)
                                        )
                                        .foregroundStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.32, green: 0.48, blue: 0.40),
                                                    Color(red: 0.22, green: 0.34, blue: 0.28)
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .cornerRadius(4)
                                    }
                                }
                                .frame(height: 140)
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day)) { value in
                                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { value in
                                        AxisGridLine().foregroundStyle(.white.opacity(0.05))
                                        AxisValueLabel() {
                                            if let min = value.as(Int.self) {
                                                Text("\(min)m")
                                                    .foregroundStyle(.white.opacity(0.5))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.04)))
                        .padding(.horizontal, 24)
                        
                        // Category Distribution
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Category Allocation")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                            
                            if store.completedSessions.isEmpty {
                                emptyStateView(message: "Category allocation breakdown will load when a session completes.")
                            } else {
                                Chart {
                                    ForEach(categoryStats) { stat in
                                        SectorMark(
                                            angle: .value("Minutes", stat.minutes),
                                            innerRadius: .ratio(0.65),
                                            angularInset: 2
                                        )
                                        .cornerRadius(4)
                                        .foregroundStyle(stat.color)
                                    }
                                }
                                .frame(height: 140)
                                
                                // Legend grid
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(categoryStats) { stat in
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(stat.color)
                                                .frame(width: 8, height: 8)
                                            Text(stat.category)
                                                .font(.system(.caption, design: .rounded))
                                                .foregroundColor(.white.opacity(0.7))
                                            Spacer()
                                            Text("\(stat.minutes)m")
                                                .font(.system(.caption, design: .rounded))
                                                .fontWeight(.bold)
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }
                                }
                                .padding(.top, 10)
                            }
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.04)))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .frame(width: 360, height: 520)
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.2))
            
            Text(message)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

extension View {
    func hoverEffect() -> some View {
        self.onHover { isHovered in
            if isHovered {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}
