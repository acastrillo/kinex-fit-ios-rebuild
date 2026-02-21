//
//  Kinex_FitApp.swift
//  Kinex Fit
//
//  Created by Alex Castrillo on 2/20/26.
//

import SwiftUI

@main
struct Kinex_FitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var environment: AppEnvironment

    init() {
        do {
            let env = try AppEnvironment.live()
            _environment = State(initialValue: env)
        } catch {
            // If database initialization fails, fall back to in-memory for debugging.
            // In production, this should never happen.
            print("KinexFitApp: Failed to initialize live environment: \(error)")
            _environment = State(initialValue: .preview())
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appEnvironment, environment)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Process pending sync items when app comes to foreground
                environment.syncEngine.processQueue()
            }
        }
    }
}
