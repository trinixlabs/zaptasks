//
//  TaskSchedulerTests.swift
//  ZapTasksTests
//
//  Created by OpenAI on 11/06/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ZapTasks

struct TaskSchedulerTests {

    @Test func neverRunDailyTaskScheduledEarlierTodayCountsAsMissed() throws {
        let scheduler = try makeScheduler()
        let now = makeDate(year: 2026, month: 6, day: 11, hour: 10, minute: 0)
        let task = makeTask(
            name: "daily task",
            interval: .daily,
            schedule: ["type": "daily", "time": "09:00"],
            isScheduled: true,
            lastRan: nil
        )

        #expect(scheduler.shouldExecuteMissedTask(task, now: now))
    }

    @Test func hourlyCatchUpUsesLastRunAsReferencePoint() throws {
        let scheduler = try makeScheduler()
        let lastRan = makeDate(year: 2026, month: 6, day: 11, hour: 10, minute: 50)
        let task = makeTask(
            name: "hourly task",
            interval: .hourly,
            schedule: ["type": "hourly", "minute": 0],
            isScheduled: true,
            lastRan: lastRan
        )

        let nextRun = try #require(scheduler.calculateNextRun(for: task, from: lastRan))

        #expect(nextRun == makeDate(year: 2026, month: 6, day: 11, hour: 11, minute: 0))
    }

    private func makeScheduler() throws -> TaskScheduler {
        let container = try ModelContainer(for: TaskItem.self, ExecutionRecord.self)
        return TaskScheduler(context: container.mainContext)
    }

    private func makeTask(
        name: String,
        interval: TaskInterval,
        schedule: [String: Any],
        isScheduled: Bool,
        lastRan: Date?
    ) -> TaskItem {
        let scheduleData = try! JSONSerialization.data(withJSONObject: schedule)
        let scheduleString = String(data: scheduleData, encoding: .utf8)!
        return TaskItem(
            name: name,
            command: "echo test",
            interval: interval.rawValue,
            schedule: scheduleString,
            scheduleDisplay: "test",
            workingDirectory: nil,
            lastRan: lastRan,
            isScheduled: isScheduled
        )
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(
            calendar: calendar,
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return calendar.date(from: components)!
    }
}
