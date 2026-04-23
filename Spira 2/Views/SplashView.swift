//
//  SplashView.swift
//  Spheera
//
//  Created by Antonio Bonetti.
//

import SwiftUI

struct SplashView: View {
    @State private var fadeOut = false

    var body: some View {
        ZStack {
            backgroundGradient
            
            splashContent
        }
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(red: 0.05, green: 0.1, blue: 0.2), .black]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var splashContent: some View {
        VStack(spacing: 8) {
            Text("Spheera")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(.white.opacity(0.92))
            
            Text(String(localized: "Breathe for your soul"))
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
        }
        .scaleEffect(fadeOut ? 0.92 : 1.15)
        .opacity(fadeOut ? 0.0 : 1.0)
        .animation(.easeInOut(duration: 1.2), value: fadeOut)
    }
    
    // MARK: - Logic
    
    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                fadeOut = true
            }
        }
    }
}
