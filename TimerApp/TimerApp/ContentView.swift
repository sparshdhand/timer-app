//
//  ContentView.swift
//  TimerApp
//
//  Created by Sparsh on 29/05/26.
//

import SwiftUI
import UserNotifications
import Combine
import AppKit

struct FocusSession: Identifiable, Codable {
    var id = UUID()
    var category: String
    var durationMinutes: Int
    var timestamp: Date
}

enum TimerMode: String, CaseIterable, Identifiable {
    case focus = "Focus"
    case shortBreak = "Break"
    case longBreak = "Rest"
    
    var id: String { self.rawValue }
    
    var defaultSeconds: Int {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }
    
    var themeColor: Color {
        switch self {
        case .focus:
            return Color(red: 0.32, green: 0.48, blue: 0.40) // Muted Forest Sage
        case .shortBreak:
            return Color(red: 0.42, green: 0.52, blue: 0.62) // Muted Slate Steel
        case .longBreak:
            return Color(red: 0.70, green: 0.55, blue: 0.45) // Elegant Terracotta/Sand
        }
    }
    
    var gradient: Gradient {
        switch self {
        case .focus:
            return Gradient(colors: [Color(red: 0.32, green: 0.48, blue: 0.40), Color(red: 0.22, green: 0.34, blue: 0.28)])
        case .shortBreak:
            return Gradient(colors: [Color(red: 0.42, green: 0.52, blue: 0.62), Color(red: 0.30, green: 0.38, blue: 0.46)])
        case .longBreak:
            return Gradient(colors: [Color(red: 0.70, green: 0.55, blue: 0.45), Color(red: 0.52, green: 0.40, blue: 0.32)])
        }
    }
}

struct ContentView: View {
    // Timer State
    @State private var timeRemaining: Int = TimerMode.focus.defaultSeconds
    @State private var totalDuration: Int = TimerMode.focus.defaultSeconds
    @State private var isRunning: Bool = false
    @State private var currentMode: TimerMode = .focus
    @State private var currentCategory: String = "Coding"
    
    // Window State (Normal vs Mini Mode)
    @State private var isMiniMode: Bool = false
    
    // Animation States
    @State private var scaleEffect: CGFloat = 1.0
    @State private var glowRadius: CGFloat = 8.0
    
    // Local Persistence (AppStorage for basic settings & sessions)
    @AppStorage("completedSessionsJSON") private var completedSessionsJSON: String = "[]"
    @State private var completedSessions: [FocusSession] = []
    
    // Timer subscription
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let categories = ["Coding", "Design", "Writing", "Learning", "Research"]
    
    var body: some View {
        ZStack {
            // Dark Visual Effect Glassmorphic Background
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            if isMiniMode {
                // MARK: - Mini Mode UI (Ultra-Minimalist Floating Circle)
                VStack(spacing: 0) {
                    ZStack {
                        // Track
                        Circle()
                            .stroke(Color.white.opacity(0.04), lineWidth: 6)
                        
                        // Active Progress
                        Circle()
                            .trim(from: 0.0, to: CGFloat(timeRemaining) / CGFloat(totalDuration))
                            .stroke(
                                LinearGradient(gradient: currentMode.gradient, startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        
                        // Digital Clock (Compact)
                        VStack(spacing: 2) {
                            Text(timeString(timeRemaining))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Image(systemName: currentMode == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                                .font(.system(size: 10))
                                .foregroundColor(currentMode.themeColor.opacity(0.8))
                        }
                    }
                    .frame(width: 90, height: 90)
                }
                .padding(15)
                .transition(.scale.combined(with: .opacity))
                .help("Focus timer active - Click to expand")
            } else {
                // MARK: - Normal Mode UI
                VStack(spacing: 24) {
                    // Header Mode Picker
                    HStack(spacing: 12) {
                        ForEach(TimerMode.allCases) { mode in
                            Button(action: {
                                selectMode(mode)
                            }) {
                                Text(mode.rawValue)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(currentMode == mode ? mode.themeColor.opacity(0.15) : Color.white.opacity(0.05))
                                    )
                                    .foregroundColor(currentMode == mode ? mode.themeColor : .white.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(currentMode == mode ? mode.themeColor.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 16)
                    
                    // Ring Timer Visualizer
                    ZStack {
                        // Outer Glow Ring
                        Circle()
                            .stroke(currentMode.themeColor.opacity(0.08), lineWidth: 16)
                            .blur(radius: glowRadius)
                        
                        // Track Ring
                        Circle()
                            .stroke(Color.white.opacity(0.05), lineWidth: 12)
                        
                        // Active Progress Ring
                        Circle()
                            .trim(from: 0.0, to: CGFloat(timeRemaining) / CGFloat(totalDuration))
                            .stroke(
                                LinearGradient(gradient: currentMode.gradient, startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1.0), value: timeRemaining)
                        
                        // Timer Digital Display
                        VStack(spacing: 4) {
                            Text(timeString(timeRemaining))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(0.5)
                            
                            Text(isRunning ? "FOCUSING" : "PAUSED")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                                .tracking(2.0)
                                .foregroundColor(currentMode.themeColor.opacity(0.8))
                        }
                    }
                    .frame(width: 220, height: 220)
                    .scaleEffect(scaleEffect)
                    .onChange(of: isRunning) { running in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            scaleEffect = running ? 1.03 : 1.0
                            glowRadius = running ? 12.0 : 8.0
                        }
                    }
                    
                    // Category Picker (For Focus Sessions)
                    if currentMode == .focus {
                        Menu {
                            ForEach(categories, id: \.self) { cat in
                                Button(cat) {
                                    currentCategory = cat
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.caption)
                                Text(currentCategory)
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 160)
                    } else {
                        Text(currentMode == .shortBreak ? "Time to recharge" : "Extended recovery time")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.vertical, 6)
                    }
                    
                    // Controls View
                    HStack(spacing: 24) {
                        // Reset Button
                        Button(action: resetTimer) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .help("Reset Timer")
                        
                        // Play/Pause Button
                        Button(action: toggleTimer) {
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.black)
                                .frame(width: 70, height: 70)
                                .background(
                                    Circle()
                                        .fill(LinearGradient(gradient: currentMode.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                )
                                .shadow(color: currentMode.themeColor.opacity(0.35), radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.space, modifiers: [])
                        .help(isRunning ? "Pause Session" : "Start Session")
                        
                        // Skip Button
                        Button(action: skipSession) {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .help("Skip Session")
                    }
                    
                    // Minimal History Panel
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today's Progress")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                        
                        if completedSessions.isEmpty {
                            Text("No completed sessions yet today. Start your first focus block!")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
                        } else {
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 8) {
                                    ForEach(completedSessions.prefix(3)) { session in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(TimerMode.focus.themeColor)
                                            Text(session.category)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text("\(session.durationMinutes)m")
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        .font(.system(.caption, design: .rounded))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                                    }
                                }
                            }
                            .frame(height: 80)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .frame(width: isMiniMode ? 120 : 360, height: isMiniMode ? 120 : 520)
        .onReceive(timer) { _ in
            guard isRunning else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                sessionCompleted()
            }
        }
        .onAppear {
            loadSessions()
            requestNotificationPermission()
        }
        // Listen to window losing focus (didResignKey)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { notification in
            if isRunning && !isMiniMode {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isMiniMode = true
                }
                setWindowFrame(toMini: true)
            }
        }
        // Listen to window gaining focus (didBecomeKey)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
            if isMiniMode {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isMiniMode = false
                }
                setWindowFrame(toMini: false)
            }
        }
    }
    
    // Core Timer Logic
    private func toggleTimer() {
        isRunning.toggle()
    }
    
    private func resetTimer() {
        isRunning = false
        timeRemaining = currentMode.defaultSeconds
        totalDuration = currentMode.defaultSeconds
    }
    
    private func skipSession() {
        isRunning = false
        sessionCompleted(skipped: true)
    }
    
    private func selectMode(_ mode: TimerMode) {
        isRunning = false
        currentMode = mode
        timeRemaining = mode.defaultSeconds
        totalDuration = mode.defaultSeconds
    }
    
    private func sessionCompleted(skipped: Bool = false) {
        isRunning = false
        
        if !skipped && currentMode == .focus {
            // Add completed focus session
            let newSession = FocusSession(
                category: currentCategory,
                durationMinutes: totalDuration / 60,
                timestamp: Date()
            )
            completedSessions.insert(newSession, at: 0)
            saveSessions()
            triggerNotification(title: "Session Completed!", body: "Great job! Take a well-deserved break.")
        } else if !skipped {
            triggerNotification(title: "Break Over!", body: "Ready to get back to work?")
        }
        
        // Auto cycle modes
        if currentMode == .focus {
            selectMode(.shortBreak)
        } else {
            selectMode(.focus)
        }
    }
    
    // Helper formatting
    private func timeString(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Persistence
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(completedSessions) {
            completedSessionsJSON = String(data: encoded, encoding: .utf8) ?? "[]"
        }
    }
    
    private func loadSessions() {
        if let data = completedSessionsJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([FocusSession].self, from: data) {
            completedSessions = decoded
        }
    }
    
    // Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func triggerNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // Programmatic AppKit Window Frame Resizing and Position Animation
    private func setWindowFrame(toMini: Bool) {
        // Find our application window
        guard let window = NSApplication.shared.windows.first(where: { 
            $0.isVisible && !$0.className.contains("NSKVONotifying") && $0.titlebarAppearsTransparent 
        }) else { return }
        
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        
        let miniSize = CGSize(width: 120, height: 120)
        let normalSize = CGSize(width: 360, height: 520)
        
        if toMini {
            // Position in bottom-right corner of the desktop (just above the dock with 24px padding)
            let targetX = screenFrame.maxX - miniSize.width - 24
            let targetY = screenFrame.minY + 24
            let targetFrame = CGRect(x: targetX, y: targetY, width: miniSize.width, height: miniSize.height)
            
            // Set window always on top for elegant multitasking float status
            window.level = .floating
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.45
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0) // smooth cubic out-expo
                window.animator().setFrame(targetFrame, display: true)
            }
        } else {
            // Restore back to original center position on screen
            let targetX = screenFrame.midX - normalSize.width / 2
            let targetY = screenFrame.midY - normalSize.height / 2
            let targetFrame = CGRect(x: targetX, y: targetY, width: normalSize.width, height: normalSize.height)
            
            // Return back to normal window level
            window.level = .normal
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.45
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                window.animator().setFrame(targetFrame, display: true)
            }
        }
    }
}

// macOS Visual Effect / Blur Component
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    ContentView()
}
