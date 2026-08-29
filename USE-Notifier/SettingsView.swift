//
//  SettingsView.swift
//  ErrorPager
//
//  Created by Ali Ahmed on 29/08/2026.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var logStore: LogStore
    @AppStorage("alertsEnabled") private var alertsEnabled = true
    @AppStorage("widgetEnabled") private var widgetEnabled = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                // Notifications Section
                Section {
                    Toggle(isOn: $alertsEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enable Notifications")
                                    .font(.body)
                                Text("Get alerted when new 500 errors occur")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: alertsEnabled ? "bell.fill" : "bell.slash.fill")
                                .foregroundStyle(alertsEnabled ? .blue : .gray)
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Notifications will show when new errors are detected, even when the app is in the background.")
                }
                
                // Widget Section
                Section {
                    Toggle(isOn: $widgetEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enable Widget")
                                    .font(.body)
                                Text("Show latest error on home screen")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "square.grid.2x2.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    if widgetEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Widget Setup")
                                .font(.subheadline.weight(.semibold))
                            
                            Text("1. Long press on your home screen")
                            Text("2. Tap the + button in the top corner")
                            Text("3. Search for \"Error Pager\"")
                            Text("4. Select the widget size")
                            Text("5. Tap \"Add Widget\"")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Widget")
                } footer: {
                    if widgetEnabled {
                        Text("The widget will display the most recent 500 error with its timestamp.")
                    } else {
                        Text("Enable to add a home screen widget showing the latest error.")
                    }
                }
                
                // Background Refresh Section
                Section {
                    HStack {
                        Label("Background Refresh", systemImage: "arrow.clockwise")
                        Spacer()
                        Text("Every 15-30 min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Foreground Polling", systemImage: "clock")
                        Spacer()
                        Text("Every 30 sec")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Refresh Settings")
                } footer: {
                    Text("Background refresh frequency is controlled by iOS based on app usage patterns and battery level. Enable Background App Refresh in Settings for this feature.")
                }
                
                // Data Section
                Section {
                    HStack {
                        Label("Stored Errors", systemImage: "doc.text")
                        Spacer()
                        Text("\(logStore.entries.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button(role: .destructive) {
                        logStore.clearAll()
                    } label: {
                        Label("Clear All Errors", systemImage: "trash")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Clearing errors removes them from the app but doesn't affect your Better Stack logs.")
                }
                
                // About Section
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Source Table", systemImage: "server.rack")
                        Spacer()
                        Text(BetterStackClient.sourceTable)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(LogStore())
}
