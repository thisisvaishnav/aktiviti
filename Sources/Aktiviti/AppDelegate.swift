import AppKit
import Foundation
import ServiceManagement
import SystemMetrics

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var headerMenuItem: NSMenuItem!
    private var launchAtLoginMenuItem: NSMenuItem!

    private let cpuSampler = CPUSampler(prewarm: true)
    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.yourname.aktiviti.timer", qos: .utility)
    private var isTimerRunning = false
    private var lastButtonTitle: String = ""
    private let monospacedFont = NSFont.monospacedDigitSystemFont(ofSize: 12.0, weight: .regular)

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupMenu()
        setupSleepWakeNotifications()
        startMetricsTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopMetricsTimer()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Status Item & Menu Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.font = monospacedFont
            button.title = "Aktiviti"
            lastButtonTitle = button.title
        }
    }

    private func setupMenu() {
        menu = NSMenu()
        menu.delegate = self

        // 1. Disabled header line with current CPU and RAM
        headerMenuItem = NSMenuItem(title: "CPU --% · RAM --%", action: nil, keyEquivalent: "")
        headerMenuItem.isEnabled = false
        menu.addItem(headerMenuItem)

        // 2. Open Dashboard item (logs message for now)
        let openDashboardItem = NSMenuItem(
            title: "Open Dashboard",
            action: #selector(openDashboard),
            keyEquivalent: "o"
        )
        openDashboardItem.target = self
        menu.addItem(openDashboardItem)

        // 3. Launch at Login toggle using SMAppService.mainApp
        launchAtLoginMenuItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginMenuItem.target = self
        updateLaunchAtLoginState()
        menu.addItem(launchAtLoginMenuItem)

        // 4. Separator
        menu.addItem(NSMenuItem.separator())

        // 5. Quit Aktiviti item
        let quitItem = NSMenuItem(
            title: "Quit Aktiviti",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func openDashboard() {
        NSLog("[Aktiviti] Open Dashboard requested")
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("[Aktiviti] Failed to toggle Launch at Login: %@", error.localizedDescription)
        }
        updateLaunchAtLoginState()
    }

    private func updateLaunchAtLoginState() {
        let isEnabled = (SMAppService.mainApp.status == .enabled)
        launchAtLoginMenuItem?.state = isEnabled ? .on : .off
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateLaunchAtLoginState()
    }

    // MARK: - Metrics Sampling & DispatchSourceTimer

    private func startMetricsTimer() {
        guard timer == nil else { return }

        let timerSource = DispatchSource.makeTimerSource(flags: [], queue: timerQueue)
        timerSource.schedule(
            deadline: .now(),
            repeating: .seconds(3),
            leeway: .milliseconds(500)
        )

        timerSource.setEventHandler { [weak self] in
            self?.sampleMetrics()
        }

        self.timer = timerSource
        self.isTimerRunning = true
        timerSource.resume()
    }

    private func pauseMetricsTimer() {
        guard let timer = timer, isTimerRunning else { return }
        timer.suspend()
        isTimerRunning = false
    }

    private func resumeMetricsTimer() {
        guard let timer = timer, !isTimerRunning else { return }
        timer.resume()
        isTimerRunning = true
    }

    private func stopMetricsTimer() {
        guard let timer = timer else { return }
        if !isTimerRunning {
            timer.resume()
        }
        timer.cancel()
        self.timer = nil
        self.isTimerRunning = false
    }

    private func sampleMetrics() {
        let cpu = cpuSampler.sample()
        let ram = RAMReader.read()

        let cpuPercent = min(max(round(cpu.totalUsage), 0), 100)
        let ramPercent = min(max(round(ram.usedPercent), 0), 100)
        let formattedText = String(format: "CPU %.0f%% · RAM %.0f%%", cpuPercent, ramPercent)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Only write to the button when the text actually changed
            if self.lastButtonTitle != formattedText {
                self.lastButtonTitle = formattedText
                if let button = self.statusItem.button {
                    button.title = formattedText
                    button.font = self.monospacedFont
                }
            }

            self.headerMenuItem.title = formattedText
        }
    }

    // MARK: - Sleep & Wake Notifications

    private func setupSleepWakeNotifications() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(
            self,
            selector: #selector(handleWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(handleDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func handleWillSleep() {
        pauseMetricsTimer()
    }

    @objc private func handleDidWake() {
        resumeMetricsTimer()
    }
}
