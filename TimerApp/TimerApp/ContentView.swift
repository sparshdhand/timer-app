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

struct ContentView: View {
    @ObservedObject var store: TimerStore
    
    // Animation States
    @State private var scaleEffect: CGFloat = 1.0
    @State private var glowRadius: CGFloat = 8.0
    
    // Modal controls
    @State private var showDashboard = false
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Dark Visual Effect Glassmorphic Background
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            if store.isMiniMode {
                // MARK: - Mini Mode UI (Ultra-Minimalist Floating Circle)
                VStack(spacing: 0) {
                    ZStack {
                        // Track
                        Circle()
                            .stroke(Color.white.opacity(0.04), lineWidth: 6)
                        
                        // Active Progress
                        Circle()
                            .trim(from: 0.0, to: CGFloat(store.timeRemaining) / CGFloat(store.totalDuration))
                            .stroke(
                                LinearGradient(gradient: store.currentMode.gradient, startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        
                        // Digital Clock (Compact)
                        VStack(spacing: 2) {
                            Text(timeString(store.timeRemaining))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Image(systemName: store.currentMode == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                                .font(.system(size: 10))
                                .foregroundColor(store.currentMode.themeColor.opacity(0.8))
                        }
                    }
                    .frame(width: 90, height: 90)
                }
                .padding(15)
                .transition(.scale.combined(with: .opacity))
                .help("Focus timer active - Click to expand")
            } else {
                // MARK: - Normal Mode UI
                VStack(spacing: 20) {
                    // Header Bar with analytics & settings
                    HStack {
                        Button(action: { showDashboard = true }) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.06)))
                                .hoverEffect()
                        }
                        .buttonStyle(.plain)
                        .help("Focus Analytics")
                        
                        Spacer()
                        
                        // Header Mode Picker
                        HStack(spacing: 4) {
                            ForEach(TimerMode.allCases) { mode in
                                Button(action: {
                                    store.selectMode(mode)
                                }) {
                                    Text(mode.rawValue)
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(store.currentMode == mode ? mode.themeColor.opacity(0.15) : Color.clear)
                                        )
                                        .foregroundColor(store.currentMode == mode ? mode.themeColor : .white.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.04)))
                        
                        Spacer()
                        
                        Button(action: { showSettings = true }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.06)))
                                .hoverEffect()
                        }
                        .buttonStyle(.plain)
                        .help("Timer Presets")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Ring Timer Visualizer
                    ZStack {
                        // Outer Glow Ring
                        Circle()
                            .stroke(store.currentMode.themeColor.opacity(0.08), lineWidth: 16)
                            .blur(radius: glowRadius)
                        
                        // Track Ring
                        Circle()
                            .stroke(Color.white.opacity(0.05), lineWidth: 10)
                        
                        // Active Progress Ring
                        Circle()
                            .trim(from: 0.0, to: CGFloat(store.timeRemaining) / CGFloat(store.totalDuration))
                            .stroke(
                                LinearGradient(gradient: store.currentMode.gradient, startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1.0), value: store.timeRemaining)
                        
                        // Timer Digital Display
                        VStack(spacing: 4) {
                            Text(timeString(store.timeRemaining))
                                .font(.system(size: 46, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(0.5)
                            
                            Text(store.isRunning ? "FOCUSING" : "PAUSED")
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.bold)
                                .tracking(2.0)
                                .foregroundColor(store.currentMode.themeColor.opacity(0.8))
                        }
                    }
                    .frame(width: 190, height: 190)
                    .scaleEffect(scaleEffect)
                    .onChange(of: store.isRunning) { running in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            scaleEffect = running ? 1.03 : 1.0
                            glowRadius = running ? 12.0 : 8.0
                        }
                    }
                    
                    // Category & Soundscape Panel (Combined Premium Row)
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            // Category Dropdown
                            if store.currentMode == .focus {
                                Menu {
                                    ForEach(store.categories, id: \.self) { cat in
                                        Button(cat) {
                                            store.currentCategory = cat
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "tag.fill")
                                            .font(.caption2)
                                        Text(store.currentCategory)
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 8))
                                    }
                                    .foregroundColor(.white.opacity(0.85))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.white.opacity(0.06)))
                                }
                                .menuStyle(.borderlessButton)
                                .hoverEffect()
                            } else {
                                Text(store.currentMode == .shortBreak ? "Time to recharge" : "Extended recovery time")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            // Audio Preset Menu selector
                            Menu {
                                ForEach(AudioPreset.allCases) { preset in
                                    Button(preset.rawValue) {
                                        store.audioEngine.activePreset = preset
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: store.audioEngine.activePreset == .off ? "speaker.slash.fill" : "waveform.path")
                                        .font(.caption2)
                                        .foregroundColor(store.audioEngine.activePreset == .off ? .white.opacity(0.4) : store.currentMode.themeColor)
                                    Text(store.audioEngine.activePreset.rawValue)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 8))
                                }
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.white.opacity(0.06)))
                            }
                            .menuStyle(.borderlessButton)
                            .hoverEffect()
                        }
                        .padding(.horizontal, 24)
                        
                        // Volume Slider (only displays if an active sound preset is running)
                        if store.audioEngine.activePreset != .off {
                            HStack(spacing: 8) {
                                Image(systemName: "speaker.wave.1.fill")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.4))
                                
                                Slider(value: $store.audioEngine.volume, in: 0...1.0)
                                    .tint(store.currentMode.themeColor)
                                
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(.horizontal, 28)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .frame(height: 70)
                    
                    // Controls View
                    HStack(spacing: 20) {
                        // Reset Button
                        Button(action: store.resetTimer) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.05)))
                                .hoverEffect()
                        }
                        .buttonStyle(.plain)
                        .help("Reset Timer")
                        
                        // Play/Pause Button
                        Button(action: store.toggleTimer) {
                            Image(systemName: store.isRunning ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundColor(.black)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(LinearGradient(gradient: store.currentMode.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                )
                                .shadow(color: store.currentMode.themeColor.opacity(0.35), radius: 8, x: 0, y: 3)
                                .hoverEffect()
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.space, modifiers: [])
                        .help(store.isRunning ? "Pause Session" : "Start Session")
                        
                        // Skip Button
                        Button(action: store.skipSession) {
                            Image(systemName: "forward.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.05)))
                                .hoverEffect()
                        }
                        .buttonStyle(.plain)
                        .help("Skip Session")
                    }
                    
                    // Minimalist History Panel
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today's Logs")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1.0)
                        
                        if store.completedSessions.isEmpty {
                            Text("No completed sessions logged. Start your focus cycle!")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.white.opacity(0.3))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.02)))
                        } else {
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 6) {
                                    ForEach(store.completedSessions.prefix(2)) { session in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption2)
                                                .foregroundColor(TimerMode.focus.themeColor)
                                            Text(session.category)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text("\(session.durationMinutes)m")
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        .font(.system(size: 11, design: .rounded))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.03)))
                                    }
                                }
                            }
                            .frame(height: 60)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .frame(width: store.isMiniMode ? 120 : 360, height: store.isMiniMode ? 120 : 520)
        // Listen to window losing focus (didResignKey)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { notification in
            if store.isRunning && !store.isMiniMode {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    store.isMiniMode = true
                }
                setWindowFrame(toMini: true)
            }
        }
        // Listen to window gaining focus (didBecomeKey)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
            if store.isMiniMode {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    store.isMiniMode = false
                }
                setWindowFrame(toMini: false)
            }
        }
        .sheet(isPresented: $showDashboard) {
            DashboardView(store: store)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(store: store)
        }
    }
    
    // Helper formatting
    private func timeString(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Programmatic AppKit Window Frame Resizing and Position Animation
    private func setWindowFrame(toMini: Bool) {
        guard let window = NSApplication.shared.windows.first(where: { 
            $0.isVisible && !$0.className.contains("NSKVONotifying") && $0.titlebarAppearsTransparent 
        }) else { return }
        
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        
        let miniSize = CGSize(width: 120, height: 120)
        let normalSize = CGSize(width: 360, height: 520)
        
        if toMini {
            let targetX = screenFrame.maxX - miniSize.width - 24
            let targetY = screenFrame.minY + 24
            let targetFrame = CGRect(x: targetX, y: targetY, width: miniSize.width, height: miniSize.height)
            
            window.level = .floating
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.45
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                window.animator().setFrame(targetFrame, display: true)
            }
        } else {
            let targetX = screenFrame.midX - normalSize.width / 2
            let targetY = screenFrame.midY - normalSize.height / 2
            let targetFrame = CGRect(x: targetX, y: targetY, width: normalSize.width, height: normalSize.height)
            
            window.level = .normal
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.45
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                window.animator().setFrame(targetFrame, display: true)
            }
        }
    }
}
