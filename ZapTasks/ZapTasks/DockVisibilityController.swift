//
//  DockVisibilityController.swift
//  ZapTasks
//

import AppKit

@MainActor
final class DockVisibilityController {
    private var openWindowIDs: Set<ObjectIdentifier> = []
    private let applyPolicy: (NSApplication.ActivationPolicy) -> Void

    init(applyPolicy: @escaping (NSApplication.ActivationPolicy) -> Void = { policy in
        NSApp.setActivationPolicy(policy)
    }) {
        self.applyPolicy = applyPolicy
    }

    func syncForLaunch() {
        updatePolicy()
    }

    func windowDidOpen(_ window: NSWindow) {
        openWindowIDs.insert(ObjectIdentifier(window))
        updatePolicy()
    }

    func windowDidClose(_ window: NSWindow) {
        openWindowIDs.remove(ObjectIdentifier(window))
        updatePolicy()
    }

    private func updatePolicy() {
        applyPolicy(openWindowIDs.isEmpty ? .accessory : .regular)
    }
}
