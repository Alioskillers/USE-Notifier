//
//  AppDelegate.swift
//  ErrorPager
//
//  Created by Ali Ahmed on 29/08/2026.
//

import UIKit
import UserNotifications
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static let backgroundRefreshTaskIdentifier = "com.ali.ios.USE-Notifier.refresh"
    
    // Store a reference to LogStore for background fetches
    static var sharedLogStore: LogStore?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.requestAuthorizationIfNeeded()
        
        // Register background task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundRefreshTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Schedule the first background refresh
        scheduleBackgroundRefresh()
        
        return true
    }

    // Handle notifications while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }

    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Could navigate to specific log entry here based on response.notification.request.content.userInfo["logEntryId"]
        completionHandler()
    }
    
    // MARK: - Background Refresh
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh before we do anything else
        scheduleBackgroundRefresh()
        
        // Set expiration handler
        task.expirationHandler = {
            // iOS is killing us, cancel any ongoing work
            task.setTaskCompleted(success: false)
        }
        
        // Perform the fetch using background-safe method
        Task {
            guard let logStore = Self.sharedLogStore else {
                task.setTaskCompleted(success: false)
                return
            }
            
            // Use the background-safe version that doesn't require @MainActor
            await logStore.refreshFromBetterStackInBackground()
            
            // Always report success (errors are logged internally)
            task.setTaskCompleted(success: true)
        }
    }
    
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundRefreshTaskIdentifier)
        
        // Earliest time iOS should wake us (15 minutes from now)
        // iOS may delay this significantly based on usage patterns, battery, etc.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            #if DEBUG
            print("✅ Background refresh scheduled for: \(request.earliestBeginDate!)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to schedule background refresh: \(error)")
            #endif
        }
    }
    
    // Called when app enters background
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleBackgroundRefresh()
    }
}
