//
//  LogStore.swift
//  ErrorPager
//
//  Created by Ali Ahmed on 29/08/2026.
//

import Foundation
import Combine
import WidgetKit
import SwiftUI

@MainActor
final class LogStore: ObservableObject {
    @Published private(set) var entries: [LogEntry] = []
    @Published var isRefreshing = false
    @Published var lastError: String?
    
    @AppStorage("alertsEnabled") private var alertsEnabled: Bool = true

    private let storageKey = "com.ali.errorpager.logentries"
    private let maxStoredEntries = 200
    
    // Shared app group for widget access
    private let sharedDefaults = UserDefaults(suiteName: "group.com.ali.ios.USE-Notifier")

    init() {
        load()
    }

    func refreshFromBetterStack() async {
        isRefreshing = true
        lastError = nil
        defer { isRefreshing = false }

        do {
            let fetched = try await fetchWithRetry()
            let existingIds = Set(entries.map(\.id))
            let newOnes = fetched.filter { !existingIds.contains($0.id) }

            for entry in newOnes.sorted(by: { $0.timestamp < $1.timestamp }) {
                entries.insert(entry, at: 0)
                if alertsEnabled {
                    NotificationManager.shared.fireNormalAlert(for: entry)
                }
            }
            if entries.count > maxStoredEntries {
                entries.removeLast(entries.count - maxStoredEntries)
            }
            save()
        } catch {
            lastError = "Couldn't reach Better Stack: \(error.localizedDescription)"
        }
    }
    
    /// Retry fetching with exponential backoff
    private func fetchWithRetry(maxAttempts: Int = 3) async throws -> [LogEntry] {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await BetterStackClient.fetchRecent500s()
            } catch {
                lastError = error
                
                // Don't wait after the last attempt
                if attempt < maxAttempts {
                    // Exponential backoff: 1s, 2s, 4s...
                    let delay = TimeInterval(1 << (attempt - 1))
                    try? await Task.sleep(for: .seconds(delay))
                }
            }
        }
        
        throw lastError ?? NSError(domain: "LogStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "All retry attempts failed"])
    }
    
    // Background-safe version that doesn't update UI properties
    nonisolated func refreshFromBetterStackInBackground() async {
        // Check if alerts are enabled (default to true if not set)
        let alertsEnabled = UserDefaults.standard.object(forKey: "alertsEnabled") as? Bool ?? true
        
        do {
            let fetched = try await BetterStackClient.fetchRecent500s()
            
            // Load current entries from disk
            let currentEntries = await loadEntriesFromDisk()
            let existingIds = Set(currentEntries.map(\.id))
            let newOnes = fetched.filter { !existingIds.contains($0.id) }
            
            // Fire notifications for new entries (if enabled)
            if alertsEnabled {
                for entry in newOnes.sorted(by: { $0.timestamp < $1.timestamp }) {
                    await NotificationManager.shared.fireNormalAlert(for: entry)
                }
            }
            
            // Merge and save
            if !newOnes.isEmpty {
                var updatedEntries = newOnes.sorted(by: { $0.timestamp > $1.timestamp })
                updatedEntries.append(contentsOf: currentEntries)
                
                if updatedEntries.count > maxStoredEntries {
                    updatedEntries = Array(updatedEntries.prefix(maxStoredEntries))
                }
                
                await saveEntriesToDisk(updatedEntries)
                
                // Update the in-memory state on main actor
                await updateEntriesFromBackground(updatedEntries)
            }
        } catch {
            // Silently fail - errors are logged in user-facing UI
        }
    }
    
    private nonisolated func loadEntriesFromDisk() async -> [LogEntry] {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([LogEntry].self, from: data)
        else { return [] }
        return decoded
    }
    
    private nonisolated func saveEntriesToDisk(_ entries: [LogEntry]) async {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    private func updateEntriesFromBackground(_ newEntries: [LogEntry]) async {
        self.entries = newEntries
    }

    func clearAll() {
        entries.removeAll()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
        
        // Also save to shared app group for widget access
        sharedDefaults?.set(data, forKey: storageKey)
        
        // Notify widget to update
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([LogEntry].self, from: data)
        else { return }
        entries = decoded
    }
}
