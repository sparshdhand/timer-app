//
//  SettingsView.swift
//  TimerApp
//
//  Created by Sparsh on 30/05/26.
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var store: TimerStore
    @Environment(\.dismiss) var dismiss
    
    @State private var newPresetName: String = ""
    @State private var newFocusMin: Int = 25
    @State private var newBreakMin: Int = 5
    @State private var newRestMin: Int = 15
    @State private var isAddingPreset: Bool = false
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Timer Presets")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Customize focus, break, and recovery intervals")
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
                .padding(.bottom, 16)
                
                List {
                    // MARK: - Current Presets Section
                    Section(header: Text("Interval Profiles").foregroundColor(.white.opacity(0.4)).font(.system(.caption, design: .rounded)).fontWeight(.bold).tracking(1.0)) {
                        ForEach(store.presets) { preset in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.name)
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(store.selectedPresetId == preset.id ? TimerMode.focus.themeColor : .white)
                                    
                                    Text("Focus: \(preset.focusMinutes)m  •  Break: \(preset.breakMinutes)m  •  Rest: \(preset.restMinutes)m")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                Spacer()
                                
                                if store.selectedPresetId == preset.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(TimerMode.focus.themeColor)
                                } else {
                                    Button(action: { store.selectedPresetId = preset.id }) {
                                        Text("Activate")
                                            .font(.system(.caption2, design: .rounded))
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(Color.white.opacity(0.08)))
                                            .foregroundColor(.white.opacity(0.8))
                                            .hoverEffect()
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // Delete button (except standard profile to prevent lock out)
                                if store.presets.count > 1 {
                                    Button(action: { store.deletePreset(id: preset.id) }) {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                            .foregroundColor(.red.opacity(0.7))
                                            .padding(6)
                                            .background(Circle().fill(Color.red.opacity(0.05)))
                                            .hoverEffect()
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.leading, 4)
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.white.opacity(0.02))
                        }
                    }
                    
                    // MARK: - Add Custom Preset Section
                    Section(header: Text("Create Custom Profile").foregroundColor(.white.opacity(0.4)).font(.system(.caption, design: .rounded)).fontWeight(.bold).tracking(1.0)) {
                        VStack(alignment: .leading, spacing: 14) {
                            TextField("Profile Name (e.g. Pomodoro 50)", text: $newPresetName)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                customStepper(title: "Focus", value: $newFocusMin, range: 1...180)
                                customStepper(title: "Break", value: $newBreakMin, range: 1...60)
                                customStepper(title: "Rest", value: $newRestMin, range: 1...60)
                            }
                            
                            Button(action: {
                                guard !newPresetName.isEmpty else { return }
                                store.addCustomPreset(name: newPresetName, focus: newFocusMin, breakMin: newBreakMin, restMin: newRestMin)
                                newPresetName = ""
                                isAddingPreset = false
                            }) {
                                Text("Add Custom Profile")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(newPresetName.isEmpty ? Color.white.opacity(0.2) : TimerMode.focus.themeColor)
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(newPresetName.isEmpty)
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Color.white.opacity(0.02))
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(width: 360, height: 520)
    }
    
    private func customStepper(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
            
            HStack(spacing: 8) {
                Button(action: { if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 } }) {
                    Image(systemName: "minus")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                
                Text("\(value.wrappedValue)m")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 32)
                
                Button(action: { if value.wrappedValue < range.upperBound { value.wrappedValue += 1 } }) {
                    Image(systemName: "plus")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
        }
        .frame(maxWidth: .infinity)
    }
}
