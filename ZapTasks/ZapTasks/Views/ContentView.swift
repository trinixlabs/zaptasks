//
//  ContentView.swift
//  ZapTasks
//
//  Created by Tim Haselaars on 09/01/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var tasks: [TaskItem]
    @Environment(\.modelContext) private var context
    @State private var selectedTask: TaskItem? = nil
    @State private var showAddEditSheet = false
    @State private var editingTask: TaskItem? = nil
    @State private var showExecutionRecords = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar: Task List
            List {
                Section(header: Text("Task List").font(.headline)) {
                    ForEach(tasks.sorted { $0.name < $1.name }, id: \.id) { task in
                        NavigationLink(
                            destination: {
                                let executor = TaskExecutor(context: context)
                                let scheduler = TaskScheduler(context: context)
                                TaskDetailsView(
                                    task: task,
                                    onEdit: {
                                        editingTask = task
                                        showAddEditSheet = true
                                    },
                                    onDelete: { task in
                                        deleteTask(task)
                                    },
                                    executor: executor,
                                    scheduler: scheduler,
                                    showExecutionRecords: $showExecutionRecords,
                                    editingTask: $editingTask,
                                    showAddEditSheet: $showAddEditSheet
                                )
                            }
                        ) {
                            Label(task.name, systemImage: "bolt.horizontal.circle" )
                                .font(.body)
                                .tag(task)
                        }
                    }
                }
            }
            .frame(minWidth: 300)
            
        } detail: {
            // Task Details View
            if let task = selectedTask {
                let executor = TaskExecutor(context: context)
                let scheduler = TaskScheduler(context: context)
                TaskDetailsView(
                    task: task,
                    onEdit: {
                        editingTask = task
                        showAddEditSheet = true
                    },
                    onDelete: { task in
                        deleteTask(task)
                    },
                    executor: executor,
                    scheduler: scheduler,
                    showExecutionRecords: $showExecutionRecords,
                    editingTask: $editingTask,
                    showAddEditSheet: $showAddEditSheet
                )
            } else {
                Text("Select a task to view details.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            // Select the first task when the view appears
            if selectedTask == nil, let firstTask = tasks.first {
                selectedTask = firstTask
            }
        }
        .sheet(isPresented: $showAddEditSheet) {
            AddTaskView(task: $editingTask)
            .frame(minWidth: 600, idealWidth: 700)
        }
        .sheet(isPresented: $showExecutionRecords) {
            ExecutionRecordsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func deleteTask(_ task: TaskItem) {
        print("Deleting task: \(task.name) with \(task.executionRecords.count) execution records.")
        DispatchQueue.main.async {
            self.selectedTask = nil
        }
        context.delete(task)
        do {
            try context.save()
            print("Task and related execution records deleted successfully.")
        } catch {
            print("Failed to delete task: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TaskItem.self)
}
