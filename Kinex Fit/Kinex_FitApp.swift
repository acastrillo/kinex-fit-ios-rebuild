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
    }
}
