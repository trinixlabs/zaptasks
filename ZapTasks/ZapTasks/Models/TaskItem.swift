//
//  Item.swift
//  ZapTasks
//
//  Created by Tim Haselaars on 09/01/2025.
//

import Foundation
import SwiftData

@Model
final class TaskItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var command: String
    var interval: String
    var schedule: String
    var scheduleDisplay: String
    var workingDirectory: String?
    var lastRan: Date?
    var isScheduled: Bool // New property to control scheduling
    var notificationPreferenceRaw: String = NotificationPreference.both.rawValue
    @Relationship(deleteRule: .cascade) var executionRecords: [ExecutionRecord] = []

    init(
        id: UUID = UUID(),
        name: String,
        command: String,
        interval: String,
        schedule: String,
        scheduleDisplay: String,
        workingDirectory: String? = nil,
        lastRan: Date? = nil,
        isScheduled: Bool = true, // Default to true
        notificationPreferenceRaw: String = NotificationPreference.both.rawValue
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.interval = interval
        self.schedule = schedule
        self.scheduleDisplay = scheduleDisplay
        self.workingDirectory = workingDirectory
        self.lastRan = lastRan
        self.isScheduled = isScheduled
        self.notificationPreferenceRaw = notificationPreferenceRaw
    }

    var notificationPreference: NotificationPreference {
        get {
            NotificationPreference(rawValue: notificationPreferenceRaw) ?? .both
        }
        set {
            notificationPreferenceRaw = newValue.rawValue
        }
    }
}
