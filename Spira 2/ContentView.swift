//
//  ContentView.swift
//  Spheera
//
//  Created by Antonio Bonetti.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                Label("Breathe", systemImage: "waveform.path.ecg")
                }

            TipsView()
                .tabItem {
                Label("Tips", systemImage: "lightbulb.fill")
                }
        }
        .accentColor(.cyan)
    }
}

#Preview {
    ContentView()
}
