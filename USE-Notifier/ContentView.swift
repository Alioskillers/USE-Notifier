//
//  ContentView.swift
//  USE-Notifier
//
//  Created by Ali Ahmed on 29/08/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var logStore: LogStore
    @AppStorage("alertsEnabled") private var alertsEnabled: Bool = true
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List {
                // Error banner
                if let error = logStore.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                // Empty state or error list
                if logStore.entries.isEmpty {
                    ContentUnavailableView(
                        "No errors yet",
                        systemImage: "checkmark.circle",
                        description: Text("Detected 500 errors will stack up here.")
                    )
                } else {
                    ForEach(Array(logStore.entries.enumerated()), id: \.element.id) { index, entry in
                        NavigationLink(value: entry) {
                            LogRow(entry: entry, isLatestEntry: index == 0)
                        }
                    }
                }
            }
            .navigationDestination(for: LogEntry.self) { entry in
                LogDetailView(entry: entry)
            }
            .navigationTitle("Error Pager")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if logStore.isRefreshing {
                        ProgressView()
                    } else {
                        Button {
                            Task { await logStore.refreshFromBetterStack() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .task {
                await logStore.refreshFromBetterStack()
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(30))
                    await logStore.refreshFromBetterStack()
                }
            }
            .refreshable {
                await logStore.refreshFromBetterStack()
            }
        }
    }
}

private struct LogRow: View {
    let entry: LogEntry
    let isLatestEntry: Bool  // TRUE only for index 0 (most recent error)
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status code badge
            Text("\(entry.statusCode)")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red, in: Capsule())

            VStack(alignment: .leading, spacing: 4) {
                // Source with LATEST badge (only on index 0)
                HStack(spacing: 6) {
                    Text(entry.source)
                        .font(.subheadline.weight(.semibold))
                    
                    // Red LATEST badge - ONLY on the very first (most recent) error
                    if isLatestEntry {
                        Text("LATEST")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red, in: Capsule())
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isLatestEntry)
                
                // Error message
                Text(entry.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // Relative timestamp
                Text(entry.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(LogStore())
}
