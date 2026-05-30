//
//  TimerMode.swift
//  TimerApp
//
//  Created by Sparsh on 30/05/26.
//

import SwiftUI

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
