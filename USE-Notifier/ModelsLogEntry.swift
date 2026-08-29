//
//  LogEntry.swift
//  ErrorPager
//
//  Created by Ali Ahmed on 29/08/2026.
//

import Foundation

struct LogEntry: Identifiable, Codable, Hashable {
    let id: String
    let timestamp: Date
    let statusCode: Int
    let source: String
    let message: String
    let rawLog: String

    init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        statusCode: Int,
        source: String,
        message: String,
        rawLog: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.statusCode = statusCode
        self.source = source
        self.message = message
        self.rawLog = rawLog
    }
}
