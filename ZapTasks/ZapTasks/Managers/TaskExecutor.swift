//
//  TaskExecutor.swift
//  ZapTasks
//
//  Created by Tim Haselaars on 13/01/2025.
//

import Foundation
import SwiftData

final class TaskExecutor {
    private weak var context: ModelContext?
    private let shaasBaseURL = Settings.shared.shaasBaseURL
    
    init(context: ModelContext) {
        self.context = context
        NotificationHelper.requestAuthorization()
    }
    
    func execute(task: TaskItem) {
        guard let context = context else {
            print("Context is no longer valid. Cannot execute task.")
            return
        }
        
        print("Executing task via SHAAS: \(task.name)")
        
        // Construct the URL by appending the working directory to the base URL if it exists
        var urlPath = shaasBaseURL
        if let workingDirectory = task.workingDirectory,
           !workingDirectory.isEmpty {
            urlPath += workingDirectory.hasPrefix("/") ? workingDirectory : "/\(workingDirectory)"
        }
        
        // Ensure the URL is valid
        guard let url = URL(string: urlPath) else {
            print("Invalid SHAAS URL path: \(urlPath)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        
        // Add the command as the request body
        request.httpBody = task.command.data(using: .utf8)
        
        // Perform the HTTP request
        let taskExecution = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to execute task via SHAAS: \(error.localizedDescription)")
                self.handleTaskCompletion(task: task, success: false, output: "Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                print("Failed to get a valid response from SHAAS")
                self.handleTaskCompletion(task: task, success: false, output: "Error: \(error)")
                return
            }
            
            let output = String(data: data, encoding: .utf8) ?? "Unknown output"
            if httpResponse.statusCode == 200 {
                print("Task \(task.name) output: \(output)")
                self.handleTaskCompletion(task: task, success: true, output: output)
            } else {
                print("SHAAS returned an error: \(httpResponse.statusCode) - \(output)")
                self.handleTaskCompletion(task: task, success: false, output: output)
            }
        }
        
        taskExecution.resume()
    }
    
    private func handleTaskCompletion(task: TaskItem, success: Bool, output: String) {
        recordExecution(task: task, success: success, output: output)
        if shouldNotify(task: task, success: success) {
            NotificationHelper.showNotification(
                title: "\(task.name) \(success ? "Completed" : "Failed")",
                body: output.prefix(100) + (output.count > 100 ? "..." : "")
            )
        }
    }
    
    private func shouldNotify(task: TaskItem, success: Bool) -> Bool {
        switch task.notificationPreference {
        case .failuresOnly:
            return !success
        case .successesOnly:
            return success
        case .both:
            return true
        }
    }
    
    private func recordExecution(task: TaskItem, success: Bool, output: String) {
        guard let context = context else { return }
        let newExecution = ExecutionRecord(
            date: Date(),
            success: success,
            output: output,
            task: task
        )
        do {
            context.insert(newExecution)
            task.lastRan = Date()
            try context.save()
        } catch {
            print("Failed to save execution record: \(error.localizedDescription)")
        }
    }
}
