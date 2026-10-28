import Foundation
import AppKit
import SwiftUI

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate {
    public var statusItem: NSStatusItem?
    public var mainWindow: NSWindow?
    private var flagsMonitor: Any?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupKeyboardMonitor()
        setupMainWindow()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "🍊"
            button.toolTip = "Tangerine: Offline File Converter"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Tangerine", action: #selector(showMainWindow), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "⇧ Shift: Convert Formats", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "⌘ Command: File Tools", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "⌃ Control: File Actions", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About Tangerine", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit Tangerine", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func setupKeyboardMonitor() {
        // Monitor modifier key presses to switch wheel mode on the fly!
        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            let flags = event.modifierFlags
            Task { @MainActor in
                if flags.contains(.shift) {
                    AppState.shared.wheelMode = .convert
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                } else if flags.contains(.command) {
                    AppState.shared.wheelMode = .tools
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                } else if flags.contains(.control) {
                    AppState.shared.wheelMode = .actions
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                }
            }
            return event
        }
    }

    private func setupMainWindow() {
        let contentView = FloatingDropZoneView()
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Tangerine"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)

        self.mainWindow = window
    }

    @objc private func showMainWindow() {
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Tangerine for Mac"
        alert.informativeText = "The zero-click offline file converter.\n275+ conversion options, 26 file tools, 6 file actions.\n\nAll conversions run 100% locally on your Mac."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
