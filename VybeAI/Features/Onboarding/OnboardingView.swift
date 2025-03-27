// OnboardingView.swift
// VybeAI
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            title: "Welcome to VybeAI",
            description: "Transform your ordinary photos into viral, AI-generated images",
            imageName: "wand.and.stars",
            backgroundColor: .purple
        ),
        OnboardingPage(
            title: "Select & Transform",
            description: "Choose a photo from your library or take a new one, then transform it with AI",
            imageName: "photo.on.rectangle.angled",
            backgroundColor: Color(hex: "4A66FB")
        ),
        OnboardingPage(
            title: "Share Anywhere",
            description: "Save your creations and share them on social media",
            imageName: "square.and.arrow.up",
            backgroundColor: Color(hex: "5D3FD3")
        ),
        OnboardingPage(
            title: "First One's Free",
            description: "Try your first image transformation for free, then unlock unlimited generations with a subscription",
            imageName: "star.circle",
            backgroundColor: Color(hex: "FB2576")
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color transitions with the pages
                pages[currentPage].backgroundColor
                    .ignoresSafeArea()
                    .animation(.easeInOut, value: currentPage)
                
                // Animated background elements
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: geometry.size.width * 0.6)
                    .blur(radius: 30)
                    .offset(x: -geometry.size.width * 0.3, y: -geometry.size.height * 0.2)
                
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: geometry.size.width * 0.7)
                    .blur(radius: 35)
                    .offset(x: geometry.size.width * 0.4, y: geometry.size.height * 0.4)
                
                // Content
                VStack(spacing: 0) {
                    // Skip button
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Skip")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, geometry.safeAreaInsets.top + 16)
                    }
                    
                    // Page content
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            VStack(spacing: 32) {
                                Spacer()
                                
                                // Icon
                                Image(systemName: pages[index].imageName)
                                    .font(.system(size: 70, weight: .light))
                                    .foregroundColor(.white)
                                    .padding(35)
                                    .background(
                                        ZStack {
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .frame(width: 160, height: 160)
                                            
                                            Circle()
                                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                                                .frame(width: 180, height: 180)
                                        }
                                    )
                                
                                // Text content
                                VStack(spacing: 20) {
                                    Text(pages[index].title)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(pages[index].description)
                                        .font(.system(size: 17))
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.horizontal, 32)
                                }
                                
                                Spacer()
                                
                                // Only show get started button on last page
                                if index == pages.count - 1 {
                                    Button(action: completeOnboarding) {
                                        Text("Get Started")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(pages[index].backgroundColor)
                                            .frame(height: 56)
                                            .frame(maxWidth: .infinity)
                                            .background(Capsule().fill(Color.white))
                                            .padding(.horizontal, 48)
                                    }
                                    .padding(.bottom, 60)
                                } else {
                                    // Spacer to align pages
                                    Spacer()
                                        .frame(height: 116)
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .interactive))
                }
            }
        }
    }
    
    private func completeOnboarding() {
        withAnimation {
            appSettings.hasCompletedOnboarding = true
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let backgroundColor: Color
}

#Preview {
    OnboardingView()
        .environmentObject(AppSettings())
} 