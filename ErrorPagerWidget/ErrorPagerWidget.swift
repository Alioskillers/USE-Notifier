//
//  ErrorPagerWidget.swift
//  ErrorPager Widget
//
//  Created by Ali Ahmed on 29/08/2026.
//

import WidgetKit
import SwiftUI

// Widget Entry
struct ErrorEntry: TimelineEntry {
    let date: Date
    let latestError: LogEntry?
}

// Widget Timeline Provider
struct ErrorProvider: TimelineProvider {
    func placeholder(in context: Context) -> ErrorEntry {
        ErrorEntry(
            date: Date(),
            latestError: LogEntry(
                timestamp: Date(),
                statusCode: 500,
                source: "api.example.com",
                message: "Sample error message",
                rawLog: "{}"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ErrorEntry) -> Void) {
        let entry = ErrorEntry(date: Date(), latestError: loadLatestError())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ErrorEntry>) -> Void) {
        let currentDate = Date()
        let latestError = loadLatestError()
        
        let entry = ErrorEntry(date: currentDate, latestError: latestError)
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func loadLatestError() -> LogEntry? {
        guard
            let data = UserDefaults(suiteName: "group.com.ali.ios.USE-Notifier")?.data(forKey: "com.ali.errorpager.logentries"),
            let entries = try? JSONDecoder().decode([LogEntry].self, from: data),
            let latest = entries.first
        else { return nil }
        
        return latest
    }
}

// Widget View
struct ErrorWidgetView: View {
    let entry: ErrorEntry
    
    var body: some View {
        if let error = entry.latestError {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.red)
                    Text("Latest Error")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(error.statusCode)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red, in: Capsule())
                }
                
                // Error Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(error.source)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    
                    Text(error.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    Text(error.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
            }
            .padding()
        } else {
            // No errors state
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("No Errors")
                    .font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// Widget Configuration
struct ErrorPagerWidget: Widget {
    let kind: String = "ErrorPagerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ErrorProvider()) { entry in
            ErrorWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Error Pager")
        .description("Shows the latest 500 error from your services")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    ErrorPagerWidget()
} timeline: {
    ErrorEntry(date: Date(), latestError: LogEntry(
        timestamp: Date(),
        statusCode: 500,
        source: "api.backend.com",
        message: "Database connection timeout",
        rawLog: "{}"
    ))
    ErrorEntry(date: Date(), latestError: nil)
}
