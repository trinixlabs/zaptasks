//
//  ZapTasksApp.swift
//  ZapTasks
//
//  Created by Tim Haselaars on 09/01/2025.
//

import SwiftUI
import SwiftData

@main
struct ZapTasksApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var scheduler: TaskScheduler
    private let modelContainer: ModelContainer

    init() {
        do {
            let configuration = try StorageConfiguration.modelConfiguration()
            self.modelContainer = try ModelContainer(
                for: TaskItem.self,
                ExecutionRecord.self,
                configurations: configuration
            )
            let context = modelContainer.mainContext
            _scheduler = StateObject(wrappedValue: TaskScheduler(context: context))
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        MenuBarExtra {
            TaskMenuBarView(openMainWindow: {
                appDelegate.showMainWindow(modelContainer: modelContainer)
            })
                .onAppear {
                    print("Starting scheduler...")
                    scheduler.start()
                }
                .onDisappear {
                    print("Stopping scheduler...")
                    scheduler.stop()
                }
        } label: {
            Image("ZapTasksIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18) // Size to fit the menu bar
        }
        .modelContainer(modelContainer) // Pass the shared ModelContainer
    }
}
