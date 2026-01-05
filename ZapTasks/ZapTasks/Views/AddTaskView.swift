//
//  AddTaskView.swift
//  ZapTasks
//
//  Created by Tim Haselaars on 09/01/2025.
//

import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Binding var task: TaskItem?
    
    @State private var name: String = ""
    @State private var command: String = ""
    @State private var workingDirectory: String = ""
    @State private var isScheduled: Bool = true
    @State private var interval: TaskInterval = .daily
    @State private var dailyTime: Date = Date()
    @State private var hourlyMinute: Int = 0
    @State private var weeklyDay: Int = 0
    @State private var weeklyTime: Date = Date()
    @State private var monthlyDay: Int = 1
    @State private var monthlyTime: Date = Date()
    @State private var customMinutes: Int = 5
    @State private var notificationPreference: NotificationPreference = .both
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(task == nil ? "Add Task" : "Edit Task")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            
            // Task Name
            HStack {
                Text("Name:")
                    .frame(width: 150, alignment: .trailing)
                TextField("Enter task name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
            }
            
            // Task Command
            HStack {
                Text("Command:")
                    .frame(width: 150, alignment: .trailing)
                TextField("Enter command", text: $command)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
                Button("Choose File") {
                    chooseCommandFile()
                }
            }
            
            // Working Directory Picker
            HStack {
                Text("Working Directory:")
                    .frame(width: 150, alignment: .trailing)
                TextField("Select directory", text: $workingDirectory)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
                Button("Choose Folder") {
                    chooseWorkingDirectory()
                }
            }
            
            // Toggle for Scheduling
            HStack {
                Text("Enable Scheduling:")
                    .frame(width: 150, alignment: .trailing)
                Toggle("", isOn: $isScheduled)
                    .toggleStyle(SwitchToggleStyle())
            }

            HStack {
                Text("Notifications:")
                    .frame(width: 150, alignment: .trailing)
                Picker("", selection: $notificationPreference) {
                    ForEach(NotificationPreference.allCases) { preference in
                        Text(preference.label)
                            .tag(preference)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: .infinity)
            }
            
            // Interval Picker and Options (conditionally shown)
            if isScheduled {
                // Interval Picker
                HStack {
                    Text("Interval:")
                        .frame(width: 150, alignment: .trailing)
                    Picker("", selection: $interval) {
                        ForEach(TaskInterval.allCases, id: \.self) { interval in
                            if interval == .customMinutes {
                                Text("Every Minute") // Custom label for customMinutes
                            } else {
                                Text(interval.rawValue.capitalized) // Default label for other intervals
                            }
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: .infinity)
                }
                
                // Dynamic Scheduling Options
                if interval == .daily {
                    HStack {
                        Text("Time:")
                            .frame(width: 150, alignment: .trailing)
                        DatePicker("Select Time", selection: $dailyTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                } else if interval == .hourly {
                    HStack {
                        Text("Minute:")
                            .frame(width: 150, alignment: .trailing)
                        Picker("", selection: $hourlyMinute) {
                            ForEach(0..<60, id: \.self) { minute in
                                Text("\(minute)")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else if interval == .weekly {
                    HStack {
                        Text("Day:")
                            .frame(width: 150, alignment: .trailing)
                        Picker("", selection: $weeklyDay) {
                            let customOrder = [1, 2, 3, 4, 5, 6, 0] // Monday to Sunday order
                            ForEach(customOrder, id: \.self) { index in
//                                let mondayStartIndex = (index + 0) % 7
                                Text(Calendar.current.weekdaySymbols[index])
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    HStack {
                        Text("Time:")
                            .frame(width: 150, alignment: .trailing)
                        DatePicker("Select Time", selection: $weeklyTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                } else if interval == .monthly {
                    HStack {
                        Text("Day:")
                            .frame(width: 150, alignment: .trailing)
                        Picker("", selection: $monthlyDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    HStack {
                        Text("Time:")
                            .frame(width: 150, alignment: .trailing)
                        DatePicker("Select Time", selection: $monthlyTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                } else if interval == .customMinutes {
                    HStack {
                        Text("Every:")
                            .frame(width: 150, alignment: .trailing)
                        Stepper(value: $customMinutes, in: 1...1440) {
                            Text("\(customMinutes) minutes")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            
            Spacer()
            
            // Save Task Button
            Button(action: saveTask) {
                Text("Save Task")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, alignment: .center)
        .onAppear {
            if let task = task {
                name = task.name
                command = task.command
                interval = TaskInterval(rawValue: task.interval) ?? .daily
                workingDirectory = task.workingDirectory ?? ""
                isScheduled = task.isScheduled
                notificationPreference = task.notificationPreference
                
                // Parse the schedule JSON and populate fields
                if let scheduleData = task.schedule.data(using: .utf8),
                   let scheduleDict = try? JSONSerialization.jsonObject(with: scheduleData, options: []) as? [String: Any] {
                    switch interval {
                    case .daily:
                        if let timeString = scheduleDict["time"] as? String,
                           let time = parseTimeString(timeString) {
                            dailyTime = time
                        }
                    case .hourly:
                        if let minute = scheduleDict["minute"] as? Int {
                            hourlyMinute = minute
                        }
                    case .weekly:
                        if let dayString = scheduleDict["day"] as? String,
                           let dayIndex = Calendar.current.weekdaySymbols.firstIndex(of: dayString),
                           let timeString = scheduleDict["time"] as? String,
                           let time = parseTimeString(timeString) {
                            weeklyDay = dayIndex
                            weeklyTime = time
                        }
                    case .monthly:
                        if let day = scheduleDict["day"] as? Int,
                           let timeString = scheduleDict["time"] as? String,
                           let time = parseTimeString(timeString) {
                            monthlyDay = day
                            monthlyTime = time
                        }
                    case .customMinutes:
                        if let intervalMinutes = scheduleDict["intervalMinutes"] as? Int {
                            customMinutes = intervalMinutes
                        }
                    }
                }
            }
        }
        
    }
    
    private func chooseCommandFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let selectedFile = panel.url {
            // Extract the file name
            command = selectedFile.lastPathComponent
            // Extract the directory path
            workingDirectory = selectedFile.deletingLastPathComponent().path
        }
    }
    
    private func chooseWorkingDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            workingDirectory = panel.url?.path ?? ""
        }
    }
    
    private func saveTask() {
        // Schedule string based on interval and dynamic fields
        var scheduleDisplay: String = "Not Scheduled"
        var schedule: [String: Any] = ["type": interval.rawValue]
        
        switch interval {
        case .daily:
            scheduleDisplay = "Daily at \(formattedTime(dailyTime))"
            schedule["time"] = formattedTime(dailyTime)
        case .hourly:
            scheduleDisplay = "Hourly at minute \(hourlyMinute)"
            schedule["minute"] = hourlyMinute
        case .weekly:
            scheduleDisplay = "Weekly on \(Calendar.current.weekdaySymbols[weeklyDay]) at \(formattedTime(weeklyTime))"
            schedule["day"] = Calendar.current.weekdaySymbols[weeklyDay]
            schedule["time"] = formattedTime(weeklyTime)
        case .monthly:
            scheduleDisplay = "Monthly on day \(monthlyDay) at \(formattedTime(monthlyTime))"
            schedule["day"] = monthlyDay
            schedule["time"] = formattedTime(monthlyTime)
        case .customMinutes:
            scheduleDisplay = "Every \(customMinutes) minutes"
            schedule["intervalMinutes"] = customMinutes
        }
        
        let scheduleJSON = try? JSONSerialization.data(withJSONObject: schedule, options: [])
        let scheduleString = String(data: scheduleJSON ?? Data(), encoding: .utf8) ?? "{}"
        
        if let task = task {
            // Update existing task
            task.name = name
            task.command = command
            task.workingDirectory = workingDirectory
            task.interval = interval.rawValue
            task.scheduleDisplay = scheduleDisplay
            task.schedule = scheduleString
            task.isScheduled = isScheduled
            task.notificationPreference = notificationPreference
        } else {
            // Create a new task
            let newTask = TaskItem(
                id: UUID(),
                name: name,
                command: command,
                interval: interval.rawValue,
                schedule: scheduleString,
                scheduleDisplay: scheduleDisplay,
                workingDirectory: workingDirectory,
                lastRan: nil,
                isScheduled: isScheduled,
                notificationPreferenceRaw: notificationPreference.rawValue
            )
            context.insert(newTask)
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save task: \(error.localizedDescription)")
        }
        
        dismiss()
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func parseTimeString(_ timeString: String) -> Date? {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return nil }
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = hour
        dateComponents.minute = minute
        return Calendar.current.date(from: dateComponents)
    }
    
}

// Enum for task intervals
enum TaskInterval: String, CaseIterable {
    case daily
    case hourly
    case weekly
    case monthly
    case customMinutes
}

//#Preview {
//    AddEditTaskView(task: .constant(nil))
//        .modelContainer(for: [TaskItem.self])
//}
