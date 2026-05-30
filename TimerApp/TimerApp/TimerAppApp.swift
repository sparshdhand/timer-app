//
//  TimerAppApp.swift
//  TimerApp
//
//  Created by Sparsh on 29/05/26.
//

import SwiftUI
import AppKit

@main
struct TimerAppApp: App {
    @StateObject private var store = TimerStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .background(VisualBackgroundAccessor())
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        // Dynamic Menu Bar Extra (displays ticking countdown & active icons)
        MenuBarExtra {
            Button(store.isRunning ? "Pause" : "Start") {
                store.toggleTimer()
            }
            .keyboardShortcut("p", modifiers: [.control, .option])
            
            Button("Skip") {
                store.skipSession()
            }
            .keyboardShortcut("s", modifiers: [.control, .option])
            
            Button("Reset") {
                store.resetTimer()
            }
            .keyboardShortcut("r", modifiers: [.control, .option])
            
            Divider()
            
            Menu("Interval Profiles") {
                ForEach(store.presets) { preset in
                    Button(action: { store.selectedPresetId = preset.id }) {
                        HStack {
                            if store.selectedPresetId == preset.id {
                                Image(systemName: "checkmark")
                            }
                            Text(preset.name)
                        }
                    }
                }
            }
            
            Menu("Category") {
                ForEach(store.categories, id: \.self) { cat in
                    Button(action: { store.currentCategory = cat }) {
                        HStack {
                            if store.currentCategory == cat {
                                Image(systemName: "checkmark")
                            }
                            Text(cat)
                        }
                    }
                }
            }
            
            Divider()
            
            Button("Quit Timer App") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        } label: {
            HStack(spacing: 4) {
                Image(systemName: store.currentMode == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                Text(timeString(store.timeRemaining))
            }
        }
    }
    
    private func timeString(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Helper to remove titlebar background color for complete glass immersion
struct VisualBackgroundAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.styleMask.insert(.fullSizeContentView)
                window.isMovableByWindowBackground = true
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
