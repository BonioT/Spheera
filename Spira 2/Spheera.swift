//
//  Spheera.swift
//  Spheera
//
//  Created by Antonio Bonetti.
//

import SwiftUI
import CoreData

@main
struct Spheera: App {
    private let persistenceController = PersistenceController.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                } else {
                    ContentView()
                        .environment(\.managedObjectContext,
                                      persistenceController.container.viewContext)
                        .transition(.opacity)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
