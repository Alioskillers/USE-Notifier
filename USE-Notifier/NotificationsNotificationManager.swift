//
//  NotificationManager.swift
//  ErrorPager
//
//  Created by Ali Ahmed on 29/08/2026.
//

import Foundation
import UserNotifications

final class NotificationManager: NSObject {
    static let shared = NotificationManager()
    private override init() { super.init() }

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            #if DEBUG
            if let error {
                print("⚠️ Notification authorization error: \(error)")
            } else {
                print("✅ Notification authorization granted: \(granted)")
            }
            #endif
        }
    }

    // Plain/standard notification — default sound, default interruption
    // level. The loud-vs-quiet (.critical/.timeSensitive/.passive) branching
    // comes back once the enable/disable widget exists.
    func fireNormalAlert(for entry: LogEntry) {
        let content = UNMutableNotificationContent()
        content.title = "🔴 500 Error Detected"
        content.subtitle = entry.source
        content.body = entry.message
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "ERROR_NOTIFICATION"
        content.threadIdentifier = "error-notifications"
        content.userInfo = ["logEntryId": entry.id]
        
        // Target content ID helps iOS show the app icon
        if #available(iOS 15.0, *) {
            content.targetContentIdentifier = entry.id
        }
        
        // Set interruption level
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        // Set relevance score for notification summary
        if #available(iOS 15.0, *) {
            content.relevanceScore = 1.0
        }

        let request = UNNotificationRequest(identifier: entry.id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error {
                print("❌ Failed to schedule notification: \(error)")
            } else {
                print("✅ Notification scheduled for: \(entry.source)")
            }
            #endif
        }
    }
}
