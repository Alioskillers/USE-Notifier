//
//  LogDetailView.swift
//  ErrorPager
//
//  Created by Ali Ahmed on 29/08/2026.
//

import SwiftUI

struct LogDetailView: View {
    let entry: LogEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(entry.statusCode)")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red, in: Capsule())

                        Spacer()

                        Text(entry.timestamp, style: .time)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(entry.source)
                        .font(.title3.weight(.semibold))

                    Text(entry.message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))

                Divider()

                // Raw log
                VStack(alignment: .leading, spacing: 8) {
                    Text("Raw Log")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(entry.rawLog)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
                .padding()
            }
        }
        .navigationTitle("Error Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: entry.rawLog) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LogDetailView(entry: LogEntry(
            timestamp: Date(),
            statusCode: 500,
            source: "api.example.com",
            message: "Internal Server Error",
            rawLog: #"{"timestamp":"2026-08-29T12:34:56Z","status":500,"message":"Internal Server Error","source":"api.example.com","stack":"Error: Something went wrong\n  at handler (/app/src/handler.js:42:15)"}"#
        ))
    }
}
