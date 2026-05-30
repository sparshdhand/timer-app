# ⚠️ Project Deprecated & Archived

> [!WARNING]
> **This project is officially deprecated and is no longer under active development or maintenance.**
> The repository has been archived. The codebase remains publicly available as-is for reference, cloning, or educational purposes. Thank you to everyone who supported this project!

---

# GitHub Timer App

An elegant, premium timer application designed for macOS developers and power users, with deep visual storytelling, high-craft aesthetics, and robust local persistence. The app enables users to track time, build focus habits, and visualize their productivity.

## ✨ Core Features (Implemented)

- **Visual Timer:** Premium countdown and stopwatch experience with smooth gradients, micro-animations, and glassmorphism.
- **AppKit Corner Snap Mini-Mode:** Intelligently transforms into an ultra-minimal floating circle and snaps to the bottom-right corner when the main window loses focus.
- **Ambient Focus Audio Engine:** Continuous real-time synthesized soundscapes (Brown Noise, White Noise, 5Hz Theta Binaural Beats) generated mathematically via `AVAudioEngine` for distraction isolation.
- **Native Analytical Dashboard:** Premium visual drawer utilizing high-performance SwiftUI `Charts` to display weekly focus trends, logged sessions, and category distribution.
- **Custom Interval Presets:** Complete settings drawer to create, delete, and switch between customized focus/break/rest interval profiles.
- **macOS Menu Bar Integration:** Interactive `MenuBarExtra` showing a live ticking countdown in the system status bar, with drop-down control selectors.
- **Keyboard-First Design:** Fully keyboard-navigable interface.

## 🛠 Tech Stack

- **Framework:** SwiftUI & AppKit (macOS Native)
- **Audio Synthesis:** `AVAudioEngine`, `AVAudioSourceNode`
- **Charts:** Native SwiftUI `Charts` framework
- **State Management:** Centralized `TimerStore` (ObservableObject)

## 📁 Repository Structure

- `/TimerApp`: Full macOS native project source files.
- `.ai-context`: Rich AI-readable documentation mapping the project's architecture, design decisions, and log history.

---

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.