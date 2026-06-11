//
//  TaskScheduler.swift
//  ZapTasks
//
//  Created by Tim Haselaars on 12/01/2025.
//

import Foundation
import SwiftData
import SwiftUI

final class TaskScheduler: ObservableObject {
    private var tasks: [TaskItem] = []
    private var timer: Timer?
    private let executor: TaskExecutor
    private let context: ModelContext
    @Published private(set) var isServiceHealthy: Bool = true // Expose service health status
    
    init(context: ModelContext) {
        self.context = context
        self.executor = TaskExecutor(context: context)
        loadTasks()
    }
    
    func start() {
        stop() // Stop any existing timer before starting a new one
        print("TaskScheduler started.")

        loadTasks()

        // Handle missed tasks
        executeMissedTasks()

        // Start the periodic timer for task execution
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            print("Timer fired at \(Date().formatted())")
            self?.checkServiceHealth()
            self?.executeTasks()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        print("TaskScheduler stopped.")
    }
    
    private func loadTasks() {
        do {
            // Fetch tasks using SwiftData context
            let fetchRequest = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.isScheduled == true })
            self.tasks = try context.fetch(fetchRequest)
            print("Loaded \(tasks.count) task(s) from context.")
        } catch {
            print("Failed to fetch tasks: \(error)")
        }
    }
    
    private func executeTasks() {
        // Ensure the service is healthy before executing tasks
        guard isServiceHealthy else {
            print("Service is unhealthy. Skipping task execution.")
            return
        }
        
        loadTasks()
        print("Triggering executeTasks with \(tasks.count) task(s).")

        let now = Date()
        for task in tasks {
            print("Evaluating task: \(task.name), schedule: \(task.schedule)")
            if isTaskDue(task, at: now) {
                print("Task \(task.name) is due. Executing...")
                executor.execute(task: task)
            } else if let nextRun = calculateNextRun(for: task) {
                print("Task \(task.name) is not due yet. Current time: \(now.formatted()). Next run: \(nextRun.formatted())")
            } else {
                print("Task \(task.name) has an invalid schedule.")
            }
        }
    }
    
    func executeMissedTasks() {
        let now = Date()
        for task in tasks {
            if shouldExecuteMissedTask(task, now: now) {
                print("Missed task \(task.name) should execute now.")
                executor.execute(task: task)
            }
        }
    }

    func shouldExecuteMissedTask(_ task: TaskItem, now: Date) -> Bool {
        guard task.isScheduled else {
            return false
        }

        if let lastRan = task.lastRan {
            return calculateNextRun(for: task, from: lastRan).map { $0 <= now } ?? false
        }

        guard let lookbackStart = missedTaskLookbackStart(for: task, now: now) else {
            return false
        }

        return calculateNextRun(for: task, from: lookbackStart).map { $0 <= now } ?? false
    }
    
    private func checkServiceHealth() {
        guard let url = URL(string: "\(Settings.shared.shaasBaseURL)/health") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            let isHealthy = (response as? HTTPURLResponse)?.statusCode == 200 && error == nil
            DispatchQueue.main.async {
                self?.isServiceHealthy = isHealthy
                if !isHealthy {
                    NotificationHelper.showNotification(
                        title: "Service Unavailable",
                        body: "The task execution service is currently unreachable."
                    )
                }
            }
        }
        task.resume()
    }
    
    private func parseSchedule(_ schedule: String) -> [String: Any]? {
        guard let data = schedule.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            print("Failed to parse schedule JSON: \(schedule)")
            return nil
        }
        print("Parsed schedule for task: \(json)")
        return json
    }
    
    private func isTaskDue(_ task: TaskItem, at date: Date) -> Bool {
        guard let schedule = parseSchedule(task.schedule) else { return false }
        let calendar = Calendar.current
        
        guard let type = schedule["type"] as? String else {
            print("Invalid schedule type for task \(task.name)")
            return false
        }
        
        print("Task \(task.name) schedule type: \(type)")
        
        switch type {
        case "daily":
            guard let time = schedule["time"] as? String else { return false }
            return isTimeMatch(timeString: time, date: date, calendar: calendar)
        case "hourly":
            guard let minute = schedule["minute"] as? Int else { return false }
            return isHourlyTaskDue(minute: minute, date: date)
        case "weekly":
            guard let day = schedule["day"] as? String,
                  let time = schedule["time"] as? String else { return false }
            return isWeeklyTaskDue(day: day, time: time, date: date, calendar: calendar)
        case "monthly":
            guard let day = schedule["day"] as? Int,
                  let time = schedule["time"] as? String else { return false }
            return isMonthlyTaskDue(day: day, time: time, date: date, calendar: calendar)
        case "customMinutes":
            print("customMinutes: \(type)")
            guard let intervalMinutes = schedule["intervalMinutes"] as? Int else { return false }
            return isCustomMinutesTaskDue(intervalMinutes: intervalMinutes, date: date)
        default:
            print("Unknown schedule type: \(type)")
            return false
        }
    }
    
    func calculateNextRun(for task: TaskItem, from startDate: Date = Date()) -> Date? {
        guard let schedule = parseSchedule(task.schedule) else { return nil }
        let calendar = Calendar.current

        switch schedule["type"] as? String {
        case "daily":
            guard let time = schedule["time"] as? String else { return nil }
            return timeToNextDate(time: time, from: startDate)
        case "hourly":
            guard let minute = schedule["minute"] as? Int else { return nil }
            let currentMinute = calendar.component(.minute, from: startDate)
            let minutesToAdd = (minute > currentMinute) ? (minute - currentMinute) : (60 - (currentMinute - minute))
            return calendar.date(byAdding: .minute, value: minutesToAdd, to: startDate)
        case "weekly":
            guard let day = schedule["day"] as? String,
                  let time = schedule["time"] as? String else { return nil }
            return timeToNextWeekday(day: day, time: time, from: startDate)
        case "monthly":
            guard let day = schedule["day"] as? Int,
                  let time = schedule["time"] as? String else { return nil }
            return timeToNextMonthly(day: day, time: time, from: startDate)
        case "customMinutes":
            guard let intervalMinutes = schedule["intervalMinutes"] as? Int else { return nil }
            let elapsedMinutes = calendar.component(.minute, from: startDate) % intervalMinutes
            let minutesUntilNext = intervalMinutes - elapsedMinutes
            return startDate.addingTimeInterval(Double(minutesUntilNext) * 60)
        default:
            return nil
        }
    }

    private func missedTaskLookbackStart(for task: TaskItem, now: Date) -> Date? {
        guard let schedule = parseSchedule(task.schedule),
              let scheduleType = schedule["type"] as? String else {
            return nil
        }

        switch scheduleType {
        case "daily":
            return Calendar.current.date(byAdding: .day, value: -1, to: now)
        case "hourly":
            return Calendar.current.date(byAdding: .hour, value: -1, to: now)
        case "weekly":
            return Calendar.current.date(byAdding: .day, value: -7, to: now)
        case "monthly":
            return Calendar.current.date(byAdding: .month, value: -1, to: now)
        case "customMinutes":
            guard let intervalMinutes = schedule["intervalMinutes"] as? Int else {
                return nil
            }
            return Calendar.current.date(byAdding: .minute, value: -intervalMinutes, to: now)
        default:
            return nil
        }
    }
    
    private func timeToNextDate(time: String, from date: Date) -> Date? {
        let components = time.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return nil }
        let calendar = Calendar.current
        var nextDate = calendar.nextDate(after: date, matching: DateComponents(hour: hour, minute: minute), matchingPolicy: .nextTime)!
        if nextDate < date {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
        }
        return nextDate
    }
    
    private func timeToNextWeekday(day: String, time: String, from date: Date) -> Date? {
        let calendar = Calendar.current
        let weekdayIndex = calendar.weekdaySymbols.firstIndex(of: day) ?? -1
        if weekdayIndex == -1 { return nil } // Invalid day string
        
        // Extract hour and minute from the time string
        let components = time.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return nil } // Invalid time format
        
        // Get the current weekday and calculate days until the next target weekday
        let currentWeekday = calendar.component(.weekday, from: date)
        let targetWeekday = weekdayIndex + 1 // Calendar.weekday is 1-based (Sunday = 1)
        var daysUntilNext = (targetWeekday >= currentWeekday) ?
        (targetWeekday - currentWeekday) : (7 - (currentWeekday - targetWeekday))
        
        // Calculate the next occurrence of the target weekday at the desired time
        var nextDate = calendar.date(byAdding: .day, value: daysUntilNext, to: date)!
        var nextDateComponents = calendar.dateComponents([.year, .month, .day], from: nextDate)
        nextDateComponents.hour = hour
        nextDateComponents.minute = minute
        nextDate = calendar.date(from: nextDateComponents) ?? nextDate

        // If the calculated nextDate is in the past or matches `date`, move to the next week
        if nextDate <= date {
            daysUntilNext += 7
            nextDate = calendar.date(byAdding: .day, value: daysUntilNext, to: date)!
            nextDateComponents = calendar.dateComponents([.year, .month, .day], from: nextDate)
            nextDateComponents.hour = hour
            nextDateComponents.minute = minute
            nextDate = calendar.date(from: nextDateComponents) ?? nextDate
        }

        return nextDate
    }
    
    private func timeToNextMonthly(day: Int, time: String, from date: Date) -> Date? {
        let calendar = Calendar.current
        let components = time.split(separator: ":")
        
        // Ensure valid time format (e.g., "21:14")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return nil }
        
        // Extract current year and month
        var nextComponents = calendar.dateComponents([.year, .month], from: date)
        nextComponents.day = day
        nextComponents.hour = hour
        nextComponents.minute = minute
        
        // Calculate the next date with the desired components
        if let nextDate = calendar.date(from: nextComponents), nextDate > date {
            return nextDate // If it's in the future, return it
        } else {
            // Otherwise, move to the next month
            nextComponents.month = (nextComponents.month ?? 1) + 1
            if nextComponents.month == 13 {
                nextComponents.month = 1
                nextComponents.year = (nextComponents.year ?? 2025) + 1
            }
            return calendar.date(from: nextComponents)
        }
    }
    
    private func isTimeMatch(timeString: String, date: Date, calendar: Calendar) -> Bool {
        let timeComponents = timeString.split(separator: ":")
        
        // Ensure the time string is in the correct format (e.g., "HH:mm")
        guard timeComponents.count == 2,
              let taskHour = Int(timeComponents[0]),
              let taskMinute = Int(timeComponents[1]) else {
            print("Invalid time format: \(timeString). Expected format is HH:mm.")
            return false
        }
        
        // Extract current hour and minute
        let currentHour = calendar.component(.hour, from: date)
        let currentMinute = calendar.component(.minute, from: date)
        
        print("Checking time: Current time is \(currentHour):\(currentMinute). Task time is \(taskHour):\(taskMinute).")
        
        // Check if the task's time matches the current time
        return taskHour == currentHour && taskMinute == currentMinute
    }
    
    private func isHourlyTaskDue(minute: Int, date: Date) -> Bool {
        let currentMinute = Calendar.current.component(.minute, from: date)
        return currentMinute == minute
    }
    
    private func isWeeklyTaskDue(day: String, time: String, date: Date, calendar: Calendar) -> Bool {
        let currentDay = calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
        if currentDay != day { return false }
        return isTimeMatch(timeString: time, date: date, calendar: calendar)
    }
    
    private func isMonthlyTaskDue(day: Int, time: String, date: Date, calendar: Calendar) -> Bool {
        let currentDay = calendar.component(.day, from: date)
        if currentDay != day { return false }
        return isTimeMatch(timeString: time, date: date, calendar: calendar)
    }
    
    private func isCustomMinutesTaskDue(intervalMinutes: Int, date: Date) -> Bool {
        let calendar = Calendar.current
        let currentMinute = calendar.component(.minute, from: date)
        
        // Check if the current minute aligns with the interval
        let isDue = currentMinute % intervalMinutes == 0
        print("CustomMinutes task evaluation: current minute = \(currentMinute), interval = \(intervalMinutes), isDue = \(isDue)")
        
        return isDue
    }
    
}
