//
//  StorageConfigurationTests.swift
//  ZapTasksTests
//

import Foundation
import Testing
@testable import ZapTasks

struct StorageConfigurationTests {

    @Test func storeURLUsesBundleScopedApplicationSupportDirectory() throws {
        let rootURL = URL(fileURLWithPath: "/tmp/ZapTasksTests", isDirectory: true)
        let storeURL = try StorageConfiguration.storeURL(appSupportURL: rootURL)

        #expect(storeURL.path == "/tmp/ZapTasksTests/com.trinix.ZapTasks/default.store")
    }

    @Test func migratesLegacyStoreIntoNamespacedDirectory() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)

        let legacyBaseURL = rootURL.appendingPathComponent("default.store")
        try Data("legacy".utf8).write(to: legacyBaseURL)
        try Data("shm".utf8).write(to: URL(fileURLWithPath: legacyBaseURL.path + "-shm"))
        try Data().write(to: URL(fileURLWithPath: legacyBaseURL.path + "-wal"))

        try StorageConfiguration.migrateLegacyStoreIfNeeded(appSupportURL: rootURL)

        let migratedBaseURL = try StorageConfiguration.storeURL(appSupportURL: rootURL)
        #expect(FileManager.default.fileExists(atPath: migratedBaseURL.path))
        #expect(FileManager.default.fileExists(atPath: migratedBaseURL.path + "-shm"))
        #expect(FileManager.default.fileExists(atPath: migratedBaseURL.path + "-wal"))
    }

    @Test func migratesLegacyContainerStoreIntoNamespacedDirectory() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let appSupportURL = rootURL.appendingPathComponent("Library/Application Support", isDirectory: true)
        let legacyContainerURL = rootURL
            .appendingPathComponent("Library/Containers/com.trinix.ZapTasks/Data/Library/Application Support", isDirectory: true)

        try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: legacyContainerURL, withIntermediateDirectories: true)

        let legacyBaseURL = legacyContainerURL.appendingPathComponent("default.store")
        try Data("container".utf8).write(to: legacyBaseURL)
        try Data("shm".utf8).write(to: URL(fileURLWithPath: legacyBaseURL.path + "-shm"))
        try Data().write(to: URL(fileURLWithPath: legacyBaseURL.path + "-wal"))

        try StorageConfiguration.migrateLegacyStoreIfNeeded(appSupportURL: appSupportURL)

        let migratedBaseURL = try StorageConfiguration.storeURL(appSupportURL: appSupportURL)
        let contents = try Data(contentsOf: migratedBaseURL)
        #expect(String(decoding: contents, as: UTF8.self) == "container")
    }

    @Test func doesNotOverwriteExistingNamespacedStore() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)

        let legacyBaseURL = rootURL.appendingPathComponent("default.store")
        try Data("legacy".utf8).write(to: legacyBaseURL)

        let currentBaseURL = try StorageConfiguration.storeURL(appSupportURL: rootURL)
        try Data("current".utf8).write(to: currentBaseURL)

        try StorageConfiguration.migrateLegacyStoreIfNeeded(appSupportURL: rootURL)

        let contents = try Data(contentsOf: currentBaseURL)
        #expect(String(decoding: contents, as: UTF8.self) == "current")
    }
}
