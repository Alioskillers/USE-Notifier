//
//  USE_NotifierApp.swift
//  USE-Notifier
//
//  Created by Ali Ahmed on 29/08/2026.
//

import SwiftUI

@main
struct USE_NotifierApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var logStore = LogStore()

    init() {
        // Share LogStore instance with AppDelegate for background fetches
        // This is safe because init() is called on the main thread before
        // any background tasks can execute
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(logStore)
                .onAppear {
                    // Set the shared reference after LogStore is created
                    AppDelegate.sharedLogStore = logStore
                }
        }
    }
}
