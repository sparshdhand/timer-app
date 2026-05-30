//
//  TimerStore.swift
//  TimerApp
//
//  Created by Sparsh on 30/05/26.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

struct TimerPreset: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var focusMinutes: Int
    var breakMinutes: Int
    var restMinutes: Int
    
    static var defaults: [TimerPreset] {
        [
            TimerPreset(name: "Standard Focus", focusMinutes: 25, breakMinutes: 5, restMinutes: 15),
            TimerPreset(name: "Deep Sprint", focusMinutes: 50, breakMinutes: 10, restMinutes: 20),
            TimerPreset(name: "Micro Blocks", focusMinutes: 15, breakMinutes: 3, restMinutes: 8),
            TimerPreset(name: "Extended Flow", focusMinutes: 90, breakMinutes: 15, restMinutes: 30)
        ]
    }
}

class TimerStore: ObservableObject {
    // Current Timer Execution
    @Published var timeRemaining: Int = 25 * 60
    @Published var totalDuration: Int = 25 * 60
    @Published var isRunning: Bool = false
    @Published var currentMode: TimerMode = .focus
    @Published var currentCategory: String = "Coding"
    
    // Window Modes
    @Published var isMiniMode: Bool = false
    
    // Preset Systems
    @Published var presets: [TimerPreset] = TimerPreset.defaults
    @Published var selectedPresetId: UUID = TimerPreset.defaults[0].id {
        didSet {
            applySelectedPreset()
        }
    }
    
    // Persistent Telemetry
    @Published var completedSessions: [FocusSession] = []
    
    // Audio engine
    @Published var audioEngine = FocusAudioEngine()
    
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    
    let categories = ["Coding", "Design", "Writing", "Learning", "Research"]
    
    // AppStorage backups
    private let sessionsKey = "completedSessionsJSON"
    private let presetsKey = "timerPresetsJSON"
    private let selectedPresetIdKey = "selectedPresetIdString"
    
    init() {
        loadData()
        applySelectedPreset()
        setupTimer()
    }
    
    func setupTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.sessionCompleted()
                }
            }
    }
    
    func applySelectedPreset() {
        guard let preset = presets.first(where: { $0.id == selectedPresetId }) else { return }
        
        let multiplier = 60
        switch currentMode {
        case .focus:
            totalDuration = preset.focusMinutes * multiplier
        case .shortBreak:
            totalDuration = preset.breakMinutes * multiplier
        case .longBreak:
            totalDuration = preset.restMinutes * multiplier
        }
        
        if !isRunning {
            timeRemaining = totalDuration
        }
    }
    
    func selectMode(_ mode: TimerMode) {
        isRunning = false
        currentMode = mode
        applySelectedPreset()
    }
    
    func toggleTimer() {
        isRunning.toggle()
        
        // Turn soundscape on/off depending on focus mode running state to reduce audio fatigue
        if isRunning {
            if currentMode == .focus && audioEngine.activePreset == .off {
                // Auto restore default focus audio if desired, or let user trigger manually
            }
        } else {
            // Keep playing noise on pause if user wants continuous ambient isolation, or pause
        }
    }
    
    func resetTimer() {
        isRunning = false
        applySelectedPreset()
    }
    
    func skipSession() {
        isRunning = false
        sessionCompleted(skipped: true)
    }
    
    func addCustomPreset(name: String, focus: Int, breakMin: Int, restMin: Int) {
        let newPreset = TimerPreset(name: name, focusMinutes: focus, breakMinutes: breakMin, restMinutes: restMin)
        presets.append(newPreset)
        saveData()
        selectedPresetId = newPreset.id
    }
    
    func deletePreset(id: UUID) {
        guard presets.count > 1 else { return } // Keep at least one
        presets.removeAll(where: { $0.id == id })
        saveData()
        if selectedPresetId == id {
            selectedPresetId = presets[0].id
        }
    }
    
    private func sessionCompleted(skipped: Bool = false) {
        isRunning = false
        
        if !skipped && currentMode == .focus {
            let newSession = FocusSession(
                category: currentCategory,
                durationMinutes: totalDuration / 60,
                timestamp: Date()
            )
            completedSessions.insert(newSession, at: 0)
            saveData()
            
            audioEngine.playCompletionChime()
            triggerNotification(title: "Session Completed! ☕️", body: "Brilliant focus. Time to take a break!")
        } else if !skipped {
            audioEngine.playCompletionChime()
            triggerNotification(title: "Break Over! ⚡️", body: "Ready to step back in?")
        }
        
        // Auto-cycle Pomodoro states
        if currentMode == .focus {
            selectMode(.shortBreak)
        } else {
            selectMode(.focus)
        }
    }
    
    // MARK: - Local Persistence Helpers
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(completedSessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
        if let encodedPresets = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(encodedPresets, forKey: presetsKey)
        }
        UserDefaults.standard.set(selectedPresetId.uuidString, forKey: selectedPresetIdKey)
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([FocusSession].self, from: data) {
            completedSessions = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: presetsKey),
           let decoded = try? JSONDecoder().decode([TimerPreset].self, from: data) {
            presets = decoded
        }
        
        if let idString = UserDefaults.standard.string(forKey: selectedPresetIdKey),
           let uuid = UUID(uuidString: idString) {
            selectedPresetId = uuid
        }
    }
    
    private func triggerNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
