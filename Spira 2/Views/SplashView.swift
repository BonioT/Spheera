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
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.05, green: 0.1, blue: 0.2), .black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("Spheera")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundColor(.white.opacity(0.92))
                
                Text("Breath for your soul")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)
            }
            .scaleEffect(fadeOut ? 0.92 : 1.15)
            .opacity(fadeOut ? 0.0 : 1.0)
            .animation(.easeInOut(duration: 1.2), value: fadeOut)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    fadeOut = true
                }
            }
        }
    }
}
