//
//  DockVisibilityControllerTests.swift
//  ZapTasksTests
//

import AppKit
import Testing
@testable import ZapTasks

struct DockVisibilityControllerTests {

    @MainActor
    @Test func launchWithoutWindowsUsesAccessoryPolicy() async throws {
        var appliedPolicies: [NSApplication.ActivationPolicy] = []
        let controller = DockVisibilityController { policy in
            appliedPolicies.append(policy)
        }

        controller.syncForLaunch()

        #expect(appliedPolicies == [.accessory])
    }

    @MainActor
    @Test func closingLastWindowReturnsToAccessoryPolicy() async throws {
        var appliedPolicies: [NSApplication.ActivationPolicy] = []
        let controller = DockVisibilityController { policy in
            appliedPolicies.append(policy)
        }
        let firstWindow = NSWindow()
        let secondWindow = NSWindow()

        controller.windowDidOpen(firstWindow)
        controller.windowDidOpen(secondWindow)
        controller.windowDidClose(firstWindow)
        controller.windowDidClose(secondWindow)

        #expect(appliedPolicies == [.regular, .regular, .regular, .accessory])
    }
}
