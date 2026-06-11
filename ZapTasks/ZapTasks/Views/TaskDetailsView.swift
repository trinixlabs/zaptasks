//
//  TaskDetailsView.swift
//  ZapTasks
//
//  Created by Tim Haselaars on 11/01/2025.
//

import SwiftUI
import SwiftData

struct TaskDetailsView: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var context
    @State private var showDeleteConfirmation = false
    @State private var selectedExecution: ExecutionRecord?
    
    @Binding var showExecutionRecords: Bool
    @Binding var editingTask: TaskItem?
    @Binding var showAddEditSheet: Bool
    
    private let executor: TaskExecutor
    private let scheduler: TaskScheduler
    
    var onEdit: () -> Void
    var onDelete: (TaskItem) -> Void
    
    init(task: TaskItem,
         onEdit: @escaping () -> Void,
         onDelete: @escaping (TaskItem) -> Void,
         executor: TaskExecutor,
         scheduler: TaskScheduler,
         showExecutionRecords: Binding<Bool>,
         editingTask: Binding<TaskItem?>,
         showAddEditSheet: Binding<Bool>) {
        self._task = Bindable(task)
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.executor = executor
        self.scheduler = scheduler
        self._showExecutionRecords = showExecutionRecords
        self._editingTask = editingTask
        self._showAddEditSheet = showAddEditSheet
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Section
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Task Name
                        Text(task.name)
                            .font(.largeTitle)
                            .bold()
                        
                        // Scheduled Indicator
                        HStack {
                            Button(action: {
                                task.isScheduled.toggle()
                                saveTask()
                            }) {
                                HStack {
                                    Image(systemName: task.isScheduled ? "power.circle.fill" : "power.circle")
                                        .foregroundColor(task.isScheduled ? .green : .red)
                                    Text("Scheduled:")
                                        .font(.subheadline)
                                }
                            }
                            .buttonStyle(.plain)
                            Text(task.scheduleDisplay)
                                .font(.subheadline)
                            Spacer()
                        }
                        
                        // Edit and Delete Buttons
                        HStack(spacing: 16) {
                            Button("Edit Task", action: onEdit)
                                .buttonStyle(.bordered)
                            
                            Button("Delete Task") {
                                showDeleteConfirmation = true
                            }
                            .foregroundColor(.red)
                            .alert("Delete Task", isPresented: $showDeleteConfirmation) {
                                Button("Delete", role: .destructive) {
                                    onDelete(task)
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("Are you sure you want to delete this task? This action cannot be undone.")
                            }
                        }
                    }
                    Spacer()
                    
                    // Run Button
                    Button(action: { executor.execute(task: task) }) {
                        HStack(spacing: 4) {
                            Text("Run")
                            Image(systemName: "play.circle.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Divider()
                
                // Task Details in Two Columns
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Command:")
                                    .bold()
                                    .frame(width: 150, alignment: .leading)
                                Text(task.command)
                                    .font(.subheadline)
                                Spacer()
                            }
                            
                            HStack {
                                Text("Working Directory:")
                                    .bold()
                                    .frame(width: 150, alignment: .leading)
                                Text(task.workingDirectory ?? "/")
                                    .font(.subheadline)
                                Spacer()
                            }
                            
                            HStack {
                                Text("Last Ran:")
                                    .bold()
                                    .frame(width: 150, alignment: .leading)
                                Text(task.executionRecords.max(by: { $0.date < $1.date })?.date.formatted() ?? "Never")
                                    .font(.subheadline)
                                    .frame(width: 150, alignment: .leading)
                                //                                Spacer()
                                Text("Next Run:")
                                    .bold()
                                    .frame(width: 150, alignment: .leading)
                                if let nextRunDate = scheduler.calculateNextRun(for: task) {
                                    Text(nextRunDate.formatted())
                                        .font(.subheadline)
                                } else {
                                    Text("Next Run: Could not determine")
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                    }
                }
                
                Divider()
                
                // Execution History Section
                Text("Execution History")
                    .font(.headline)
                
                if task.executionRecords.isEmpty {
                    Text("No previous executions")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(task.executionRecords.sorted(by: { $0.date > $1.date })) { execution in
                            ExecutionRow(execution: execution) {
                                selectedExecution = execution
                            } onDelete: {
                                deleteExecutionRecord(execution)
                            }
                            Divider()
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("ZapTasks")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Spacer() // Pushes the items to the right
            }
            ToolbarItem(placement: .automatic) {
                Button(action: { showExecutionRecords = true }) {
                    Label("View Execution Records", systemImage: "list.bullet")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    editingTask = nil // Reset editingTask
                    showAddEditSheet = true
                }) {
                    Label("Add Task", systemImage: "plus")
                }
            }
        }
        .sheet(item: $selectedExecution) { execution in
            ExecutionDetailView(execution: execution) {
                selectedExecution = nil
            }
        }
    }
    
    private func saveTask() {
        do {
            try context.save()
        } catch {
            print("Failed to save task: \(error)")
        }
    }
    
    private func deleteExecutionRecord(_ record: ExecutionRecord) {
        context.delete(record)
        do {
            try context.save()
        } catch {
            print("Failed to delete execution record: \(error)")
        }
    }
}

// MARK: - DetailRow View
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .bold()
                .frame(width: 150, alignment: .leading) // Adjust width for alignment
            Text(value)
                .font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - ExecutionRow View
struct ExecutionRow: View {
    let execution: ExecutionRecord
    let onShowOutput: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: execution.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(execution.success ? .green : .red)
            Text(execution.date.formatted())
                .font(.body)
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Text("Delete")
            }
            Button("Show Output", action: onShowOutput)
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ExecutionDetailView
struct ExecutionDetailView: View {
    let execution: ExecutionRecord
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Close Button at the Top-Right
            HStack {
                Spacer()
                Button("Close", action: onClose)
                    .buttonStyle(.borderedProminent)
            }
            
            // Title
            Text("Execution Output")
                .font(.title2)
                .bold()
            
            // Status Row with Icon and Text
            HStack {
                Text("Status:")
                    .font(.subheadline)
                    .frame(width: 80, alignment: .leading)
                    .bold()
                HStack {
                    Image(systemName: execution.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(execution.success ? .green : .red)
                    Text(execution.success ? "Success" : "Failure")
                        .foregroundColor(execution.success ? .green : .red)
                        .font(.subheadline)
                }
            }
            
            // Date Row with Label and Value
            HStack {
                Text("Date:")
                    .font(.subheadline)
                    .frame(width: 80, alignment: .leading)
                    .bold()
                Text(execution.date.formatted())
                    .font(.subheadline)
            }
            
            Divider()
            
            Text("Output:")
                .font(.headline)
            
            // Output Section
            ScrollView {
                Text(execution.output)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black)
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
    }
}


/*#Preview {
    let modelContainer = try! ModelContainer(for: TaskItem.self, ExecutionRecord.self)
    
    let context = modelContainer.mainContext
    let task = TaskItem(
        name: "Backup Files",
        command: "rsync -a ~/Documents /Volumes/BackupDrive",
        interval: "daily",
        schedule: "Daily at 10:00 AM",
        workingDirectory: "~/Documents",
        lastRan: Date()
    )
    let execution1 = ExecutionRecord(date: Date().addingTimeInterval(-3600), success: true, output: "Backup completed successfully.", task: task)
    let execution2 = ExecutionRecord(date: Date().addingTimeInterval(-7200), success: false, output: "Error: Disk not found.", task: task)
    
    context.insert(task)
    context.insert(execution1)
    context.insert(execution2)
    
    let executor = TaskExecutor(context: context)

    return TaskDetailsView(
        task: task,
        onEdit: {},
        onDelete: { _ in },
        executor: executor
    )
    .modelContainer(modelContainer)
}*/
