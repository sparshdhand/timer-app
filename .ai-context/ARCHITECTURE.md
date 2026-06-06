# ARCHITECTURE

## Tech Stack
- **Core Framework:** SwiftUI (macOS 13.0+), AppKit, Combine.
- **Audio Synthesis:** `AVAudioEngine` and `AVAudioSourceNode` for real-time mathematical soundscape generation.
- **Visual Analytics:** Native SwiftUI `Charts` framework.
- **Styling:** Premium modern visual effect blurs (`NSVisualEffectView` HUD and under-window materials), customized HSL-aligned SwiftUI gradients, and spring animations.

## Core Definitions & State Flow
- **TimerStore (Central Store):** Shared `ObservableObject` holding the running countdown, preset profiles, historical session metrics, and category choices. Ensures 100% synchronized state between the floating main window and the menu bar.
- **FocusAudioEngine:** Audio synthesizer node that runs on a separate thread, dynamically computing samples for Brown Noise (low-pass white noise integration), White Noise (even distribution), and Binaural Beats (offset sine waves generating target 5Hz Theta brainwave differences).
- **MenuBarExtra:** Native system status item scene rendering live ticks and drop-down selectors.
- **VisualEffectView:** Standard declarative wrapper of `NSVisualEffectView` for translucent window backing.

## Walkthrough
1. **Bootup:** The application initializes the single `@StateObject` `TimerStore` in `TimerAppApp.swift`. It loads completed sessions and custom presets from `UserDefaults`.
2. **Visual Ticking:** `TimerStore` runs a continuous `Combine` publisher timer ticking every second, keeping both the main floating circular ring and the Menu Bar countdown synchronized.
3. **Multitasking Corner Snap:** If the window loses focus while a focus block is active, `ContentView` triggers an AppKit animator group, reducing window dimensions to an ultra-minimal `120x120` circular progress ring and snapping it smoothly to the bottom-right corner of the active screen (`NSWindow.level = .floating`). Focus restore switches it back.
4. **Analytical Visualization:** Clicking the analytics drawer triggers `DashboardView`, running instant database operations on `completedSessions` logs to draw responsive weekly trend bars and donut breakdown charts.
