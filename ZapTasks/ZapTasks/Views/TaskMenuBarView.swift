//
//  TaskMenuBarView.swift
//  ZapTasks
//
//  Created by Tim Haselaars on 11/01/2025.
//

import SwiftUI
import SwiftData

struct TaskMenuBarView: View {
    @Query private var tasks: [TaskItem] // Fetch tasks from SwiftData storage
    @Environment(\.modelContext) private var context
    let openMainWindow: () -> Void

    init(openMainWindow: @escaping () -> Void = {}) {
        self.openMainWindow = openMainWindow
    }

    var body: some View {
        VStack(spacing: 12) {
            if tasks.isEmpty {
                Text("No tasks available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ForEach(tasks.sorted { $0.name < $1.name }) { task in
                    HStack(spacing: 12) {
                        // Run Button
                        Button(action: { runTask(task) }) {
                            if let latestExecution = task.executionRecords.sorted(by: { $0.date > $1.date }).first {
                                Image(systemName: latestExecution.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(latestExecution.success ? .green : .red)
                            } else {
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            Text(task.name)
                            Image(systemName: "play.circle.fill")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }

            Divider()

            // Manage Tasks Button
            Button("Manage Tasks") {
                openMainWindow()
            }
            .font(.headline)
            .padding(.top, 8)
            
            Divider()
            // Quit Button
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .padding(.top, 4)
        }
        .padding()
        .frame(width: 400) // Increased width
    }
    
    func runTask(_ task: TaskItem) {
        Task {
            let executor = TaskExecutor(context: context)
            executor.execute(task: task)
        }
    }
}
