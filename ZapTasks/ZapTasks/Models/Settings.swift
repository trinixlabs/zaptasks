//
//  Settings.swift
//  ZapTasks
//
//  Created by Tim Haselaars on 20/01/2025.
//

final class Settings {
    static let shared = Settings()
    private init() {}
    
    var shaasBaseURL: String = "http://localhost:7575"
}

enum NotificationPreference: String, CaseIterable, Identifiable {
    case successesOnly
    case failuresOnly
    case both
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .failuresOnly:
            return "Failures Only"
        case .successesOnly:
            return "Successes Only"
        case .both:
            return "Both"
        }
    }
}
