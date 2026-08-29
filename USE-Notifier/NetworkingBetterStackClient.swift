//
//  BetterStackClient.swift
//  ErrorPager
//
//  Created by Ali Ahmed on 29/08/2026.
//

import Foundation

/// ✅ SECURE: NO HARDCODED SECRETS
/// All credentials loaded from Config.xcconfig → Info.plist → Bundle at runtime
struct BetterStackClient {
    
    // MARK: - Configuration (from Config.xcconfig via Info.plist)
    
    private static let infoDictionary = Bundle.main.infoDictionary
    
    /// Better Stack host (e.g., "eu-central-1a-connect.betterstackdata.com")
    /// Loaded from Config.xcconfig → BETTERSTACK_HOST
    private static let host: String = {
        guard let host = infoDictionary?["BetterStackHost"] as? String else {
            fatalError("""
            ❌ BetterStackHost not found in Info.plist
            
            This means Config.xcconfig isn't linked to your Xcode project.
            
            To fix:
            1. Make sure Config.xcconfig exists in your project
            2. In Xcode: Project (not Target) → Info tab → Configurations
            3. Set Debug → "Config"
            4. Set Release → "Config"
            5. Clean build (Shift+Cmd+K) and build again
            
            See SECURE_SETUP_GUIDE.md for detailed instructions.
            """)
        }
        return host
    }()
    
    /// Better Stack ClickHouse username
    /// Loaded from Config.xcconfig → BETTERSTACK_USERNAME
    static let username: String = {
        guard let username = infoDictionary?["BetterStackUsername"] as? String else {
            fatalError("❌ BetterStackUsername not found in Info.plist. Link Config.xcconfig in Xcode!")
        }
        return username
    }()
    
    /// Better Stack ClickHouse password
    /// Loaded from Config.xcconfig → BETTERSTACK_PASSWORD
    static let password: String = {
        guard let password = infoDictionary?["BetterStackPassword"] as? String else {
            fatalError("❌ BetterStackPassword not found in Info.plist. Link Config.xcconfig in Xcode!")
        }
        return password
    }()
    
    /// Better Stack source table name (e.g., "t492471_onestaffos_logs")
    /// Loaded from Config.xcconfig → BETTERSTACK_SOURCE_TABLE
    static let sourceTable: String = {
        guard let table = infoDictionary?["BetterStackSourceTable"] as? String else {
            fatalError("❌ BetterStackSourceTable not found in Info.plist. Link Config.xcconfig in Xcode!")
        }
        return table
    }()
    
    /// Constructed query URL from host
    static let queryURL = URL(string: "https://\(host)?output_format_pretty_row_numbers=0")!
    
    // MARK: - Error Types
    
    enum ClientError: LocalizedError {
        case badResponse(Int)
        
        var errorDescription: String? {
            switch self {
            case .badResponse(let code):
                return "Better Stack returned status \(code)"
            }
        }
    }
    
    // MARK: - API Methods
    
    /// Test connection to Better Stack with a simple query
    static func testConnection() async throws -> Bool {
        let sql = "SELECT 1 FORMAT JSONEachRow"
        
        var request = URLRequest(url: queryURL)
        request.httpMethod = "POST"
        request.setValue("plain/text", forHTTPHeaderField: "Content-type")
        request.timeoutInterval = 10
        
        let credentials = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.httpBody = sql.data(using: .utf8)
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 20
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config)
        
        let (_, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return false
        }
        
        return true
    }
    
    /// Fetch recent 500 errors from Better Stack
    /// - Parameter limit: Maximum number of logs to fetch (default: 50)
    /// - Returns: Array of LogEntry objects
    /// - Throws: ClientError if the request fails
    static func fetchRecent500s(limit: Int = 50) async throws -> [LogEntry] {
        // Optimized SQL query following Better Stack best practices:
        // - Filter by time range (last 24 hours for performance)
        // - Use LIMIT to prevent excessive data
        // - Use ORDER BY for consistent results
        // - Query for "level" = "error" (based on actual log format)
        let sql = """
        SELECT
          dt,
          raw,
          JSONExtract(raw, 'level', 'Nullable(String)') AS level,
          JSONExtract(raw, 'message', 'Nullable(String)') AS message,
          JSONExtract(raw, 'service', 'Nullable(String)') AS service,
          JSONExtract(raw, 'context', 'Nullable(String)') AS context
        FROM remote(\(sourceTable))
        WHERE JSONExtract(raw, 'level', 'Nullable(String)') = 'error'
          AND dt >= now() - INTERVAL 24 HOUR
        ORDER BY dt DESC
        LIMIT \(limit)
        FORMAT JSONEachRow
        """
        
        // Build HTTP request
        var request = URLRequest(url: queryURL)
        request.httpMethod = "POST"
        request.setValue("plain/text", forHTTPHeaderField: "Content-type")
        
        // Add timeout configuration (increase from default 60s to handle slow queries)
        request.timeoutInterval = 30
        
        // Add Basic Authentication
        let credentials = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = sql.data(using: .utf8)
        
        // Configure URLSession with better timeout handling
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config)
        
        // Execute request
        let (data, response) = try await session.data(for: request)
        
        // Check response status
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw ClientError.badResponse(code)
        }
        
        // Parse JSONEachRow format (one JSON object per line, not an array)
        let text = String(decoding: data, as: UTF8.self)
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return text.split(separator: "\n").compactMap { line -> LogEntry? in
            guard
                let lineData = String(line).data(using: .utf8),
                let object = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
            else { return nil }
            
            // Extract fields
            let dtString = object["dt"] as? String ?? ""
            let timestamp = isoFormatter.date(from: dtString) ?? Date()
            let raw = (object["raw"] as? String) ?? String(line)
            let message = (object["message"] as? String) ?? "Error occurred"
            let service = (object["service"] as? String) ?? "unknown"
            let context = (object["context"] as? String) ?? ""
            
            // Combine service and context for better source display
            let source = context.isEmpty ? service : "\(service) (\(context))"
            
            // Create deterministic ID from timestamp + content hash
            // This prevents duplicate entries when polling repeatedly
            return LogEntry(
                id: "\(dtString)_\(raw.hashValue)",
                timestamp: timestamp,
                statusCode: 500,  // All errors treated as 500
                source: source,
                message: message,
                rawLog: raw
            )
        }
    }
}
