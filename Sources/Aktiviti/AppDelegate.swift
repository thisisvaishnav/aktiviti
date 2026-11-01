import AppKit
import SystemMetrics

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "Aktiviti"
        }

        let menu = NSMenu()
        let quitItem = NSMenuItem(
            title: "Quit Aktiviti",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
        statusItem.menu = menu

        // Proves wiring to SystemMetrics package
        _ = systemMetricsPlaceholder()
    }
}
