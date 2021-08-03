//
//  OrderInnServiceApp.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI
import Firebase

@main
struct OrderInnServiceApp: App {
    init() {
        #if DEBUG && targetEnvironment(simulator)
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil {
            // Skip configuring Firebase if the app is being run as an Xcode Live
            // Preview so that it starts up slightly faster.
            FirebaseApp.configure()
        }
        #else
        FirebaseApp.configure()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            LaunchScreen()
                .environmentObject(AuthManager.shared)
        }
    }
}
