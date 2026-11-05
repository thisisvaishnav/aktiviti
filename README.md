<div align="center">

<img src="website/icon.png" width="96" height="96" alt="Aktiviti Logo" />

# Aktiviti

**The lightweight, developer-first activity monitor and system telemetry dashboard for macOS.**

[![Platform: macOS 14.0+](https://img.shields.io/badge/Platform-macOS%2014.0%2B-black?style=flat&logo=apple)](https://apple.com)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat&logo=swift&logoColor=white)](https://swift.org)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-Zero-00C7B7?style=flat)]()
[![Offline & Private](https://img.shields.io/badge/Privacy-100%25%20Offline-success?style=flat)]()
[![Tests Passing](https://img.shields.io/badge/Tests-Passing-brightgreen?style=flat)]()

[Features](#-features) • [Architecture](#-architecture) • [Getting Started](#-getting-started) • [Building from Source](#-building-from-source) • [Roadmap](#-roadmap)

</div>

---

## ⚡ Overview

**Aktiviti** is a native macOS menu bar app and system telemetry dashboard built for developers, engineers, and power users who need instant, actionable insight into their Mac’s performance without the bloat, battery drain, or noise of conventional utilities.

Unlike standard tools that bombard you with thousands of obscure system threads, Aktiviti surfaces the processes, developer servers, git worktrees, and hardware telemetry that matter most to your daily workflow.

### 🌟 Key Highlights

- **Native & Lightweight:** Built in pure Swift, SwiftUI, and AppKit. Zero third-party dependencies.
- **Privacy-First & 100% Local:** No analytics, no network calls, no background daemons, and no SQLite database.
- **Battery-Conscious:** Metrics polling automatically pauses when the dashboard window is occluded or during display sleep, resuming instantly upon wake.
- **Developer-Aware:** Integrated project and workspace scanner linking active resource usage to Git repositories, tech stacks, and build artifacts.
- **Apple Silicon Optimized:** Tailored metrics for unified memory pressure, Performance vs. Efficiency core clusters, and Metal GPU utilization.

---

## 🖥 Features

### 📍 Menu Bar Status
- Live, monospaced digit readouts for real-time **CPU%** and **RAM%** directly in the menu bar.
- Lightweight dropdown menu with quick telemetry overview, one-click dashboard toggle, and launch-at-login control via `SMAppService`.

### 📊 System Telemetry Tabs
- **Overview:** Live system snapshot cards featuring smooth sparkline history graphs and top active workloads.
- **CPU:** Breakdown of user, system, and idle processor times, multi-core cluster metrics (P-cores / E-cores), and system load averages (`1m`, `5m`, `15m`).
- **Memory (RAM):** Comprehensive memory distribution (Active, Wired, Compressed, and Free), live memory pressure status gauge, and top RAM-consuming apps.
- **Disk & Storage:** Real-time read/write throughput (MB/s), total and available volume capacity, and active I/O monitoring.
- **GPU:** Real-time Apple Silicon GPU core utilization percentage and Metal graphics engine status via IOKit.
- **Network:** Instant upload and download bandwidth rates (KB/s & MB/s), active network interface monitoring (`en0` / Wi-Fi / Ethernet), and throughput sparkline charts.
- **Battery & Power:** Live State of Charge (%), charging and power adapter state, power draw in Watts, and high-energy app attribution via `IOPowerSources`.
- **Projects:** Automated workspace discovery scanning local directories for Git branch states, tech stacks (Xcode, SwiftPM, Python/Flask, etc.), and derived data cache footprints.

---

## 🏗 Architecture

Aktiviti is designed around a strict separation of concerns between low-level Mach/Darwin samplers and high-level SwiftUI presentations:

```
aktiviti/
├── Sources/
│   └── Aktiviti/              # Native macOS App (SwiftUI + AppKit)
│       ├── AktivitiApp.swift  # App entry point (LSUIElement / Menu Bar Agent)
│       ├── AppDelegate.swift  # StatusItem management, menu lifecycle, timers
│       ├── DashboardView.swift # Main window interface & tab switching
│       ├── DashboardViewModel.swift # Observable state, samplers, and sparkline histories
│       ├── ProjectScanner.swift     # Local Git project & workspace analyzer
│       └── Views/             # Modular tab views (CPU, Memory, Disk, GPU, Network, etc.)
├── Packages/
│   └── SystemMetrics/         # Standalone, dependency-free metrics engine
│       ├── Sources/
│       │   ├── SystemMetrics/ # Mach kernel, IOKit, libproc, & statfs samplers
│       │   └── metrics-cli/   # CLI executable target for terminal metrics
│       └── Tests/
│           └── SystemMetricsTests/ # Unit tests validating math, deltas, and sampling logic
├── docs/                      # Architectural documentation and plans
├── website/                   # Product documentation, guides, and comparison pages
└── project.yml                # Declarative XcodeGen project specification
```

### Core Design Rules
1. **No External Dependencies:** Zero third-party Swift packages or CocoaPods. All system readings use native Darwin and macOS APIs (`host_processor_info`, `mach_host_self`, `proc_pidinfo`, `IOKit`, `statfs`).
2. **Package Isolation:** All metric-gathering logic lives in `Packages/SystemMetrics`. The application UI simply consumes published metrics.
3. **No Project File Churn:** The `.xcodeproj` file is generated deterministically from `project.yml` using XcodeGen.

---

## 🚀 Getting Started

### Prerequisites
- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ or Xcode Command Line Tools
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Building from Source

1. **Clone the repository:**
   ```bash
   git clone https://github.com/thisisvaishnav/aktiviti.git
   cd aktiviti
   ```

2. **Generate the Xcode project:**
   ```bash
   xcodegen generate
   ```

3. **Build the macOS App:**
   ```bash
   xcodebuild -project Aktiviti.xcodeproj -scheme Aktiviti -configuration Debug build
   ```

4. **Run SystemMetrics Package Unit Tests:**
   ```bash
   swift test --package-path Packages/SystemMetrics
   ```

5. **Run the CLI Metrics Tool:**
   ```bash
   swift run --package-path Packages/SystemMetrics metrics-cli
   ```

---

## 🗺 Roadmap

- [x] High-precision CPU, RAM, Disk, GPU, Network, and Battery samplers
- [x] Smooth sparkline trend charts and donut distribution visualizations
- [x] Developer project workspace scanner (`ProjectScanner`)
- [x] CLI metrics tool (`metrics-cli`)
- [ ] Zombie dev server & listening port manager ("Port Doctor")
- [ ] Coding agent & local LLM telemetry (Claude Code, Cursor, Ollama memory tracking)
- [ ] Sleep vampire diagnostics (post-sleep background power assertion analyzer)
- [ ] Incident flight recorder (5-minute rolling performance anomaly log)

---

## 📄 License

Copyright © 2026 Vaishnav Verma. All rights reserved.
