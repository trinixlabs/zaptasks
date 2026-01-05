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
    @State private var mainWindow: NSWindow?
    private let executor: TaskExecutor

    init() {
        // Pass variadic arguments instead of an array
        let context = try! ModelContainer(for: TaskItem.self, ExecutionRecord.self).mainContext
        self.executor = TaskExecutor(context: context)
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
    
    func openMainWindow() {
        if let window = mainWindow {
            // Ensure the window is visible and focused
            if !window.isVisible {
                window.makeKeyAndOrderFront(nil)
            }
        } else {
            let contentView = ContentView()
                .modelContainer(for: TaskItem.self)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1200, height: 600),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Manage Tasks"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: contentView)
            window.center()
            window.makeKeyAndOrderFront(nil)
            mainWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}
