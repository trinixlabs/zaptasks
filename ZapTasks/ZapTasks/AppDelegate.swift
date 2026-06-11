//
//  AppDelegate.swift
//  ZapTasks
//
//  Created by Tim Haselaars on 09/01/2025.
//

import Cocoa
import SwiftData
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let dockVisibilityController = DockVisibilityController()
    private var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        dockVisibilityController.syncForLaunch()
    }

    func showMainWindow(modelContainer: ModelContainer) {
        let window = mainWindow ?? buildMainWindow(modelContainer: modelContainer)
        dockVisibilityController.windowDidOpen(window)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window == mainWindow else {
            return
        }

        dockVisibilityController.windowDidClose(window)
    }

    private func buildMainWindow(modelContainer: ModelContainer) -> NSWindow {
        let contentView = ContentView()
            .modelContainer(modelContainer)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Manage Tasks"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        mainWindow = window
        return window
    }
}
