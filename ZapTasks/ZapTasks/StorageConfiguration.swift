//
//  StorageConfiguration.swift
//  ZapTasks
//

import Foundation
import SwiftData

enum StorageConfiguration {
    static let storeDirectoryName = "com.trinix.ZapTasks"
    static let storeFilename = "default.store"
    static let storeSuffixes = ["", "-shm", "-wal"]
    static let legacyContainerPathComponents = [
        "Containers",
        "com.trinix.ZapTasks",
        "Data",
        "Library",
        "Application Support",
        "default.store",
    ]

    static func storeURL(fileManager: FileManager = .default) throws -> URL {
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return try storeURL(appSupportURL: appSupportURL, fileManager: fileManager)
    }

    static func storeURL(appSupportURL: URL, fileManager: FileManager = .default) throws -> URL {
        let directoryURL = appSupportURL.appendingPathComponent(storeDirectoryName, isDirectory: true)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent(storeFilename, isDirectory: false)
    }

    static func modelConfiguration(fileManager: FileManager = .default) throws -> ModelConfiguration {
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        try migrateLegacyStoreIfNeeded(appSupportURL: appSupportURL, fileManager: fileManager)
        return try ModelConfiguration(url: storeURL(fileManager: fileManager))
    }

    static func migrateLegacyStoreIfNeeded(
        appSupportURL: URL,
        fileManager: FileManager = .default
    ) throws {
        let currentBaseURL = try storeURL(appSupportURL: appSupportURL, fileManager: fileManager)
        let legacyCandidates = legacyStoreCandidates(appSupportURL: appSupportURL)

        guard !fileManager.fileExists(atPath: currentBaseURL.path) else {
            return
        }

        guard let sourceBaseURL = legacyCandidates.first(where: { fileManager.fileExists(atPath: $0.path) }) else {
            return
        }

        for suffix in storeSuffixes {
            let sourceURL = URL(fileURLWithPath: sourceBaseURL.path + suffix)
            let targetURL = URL(fileURLWithPath: currentBaseURL.path + suffix)

            guard fileManager.fileExists(atPath: sourceURL.path) else {
                continue
            }

            try fileManager.copyItem(at: sourceURL, to: targetURL)
        }
    }

    private static func legacyStoreCandidates(appSupportURL: URL) -> [URL] {
        let legacyAppSupportURL = appSupportURL.appendingPathComponent(storeFilename, isDirectory: false)
        let libraryRootURL = appSupportURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let legacyContainerURL = legacyContainerPathComponents.reduce(libraryRootURL) { partialURL, component in
            partialURL.appendingPathComponent(component, isDirectory: false)
        }

        return [legacyContainerURL, legacyAppSupportURL]
    }
}
