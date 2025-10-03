//
//  VeerApp.swift
//  Veer
//
//  Created by Parwez Amini on 29/09/2025.
//

import SwiftUI
import Clerk

@main
struct VeerApp: App {
    // Initialize Clerk Manager with your publishable key
    @StateObject private var clerkManager = ClerkManager(publishableKey: "pk_test_Y2FwYWJsZS1zb2xlLTkyLmNsZXJrLmFjY291bnRzLmRldiQ")
    
    var body: some Scene {
        WindowGroup {
            Group {
                if clerkManager.isAuthenticated {
                    MainView()
                } else {
                    WelcomeView()
                }
            }
            .environment(\.clerkManager, clerkManager)
            .task {
                // Configure Clerk with the publishable key when the app starts
                Clerk.shared.configure(publishableKey: "pk_test_Y2FwYWJsZS1zb2xlLTkyLmNsZXJrLmFjY291bnRzLmRldiQ")
                try? await Clerk.shared.load()
                
                // Update authentication state after Clerk is loaded
                await clerkManager.refreshAuthenticationState()
            }
        }
    }
}
