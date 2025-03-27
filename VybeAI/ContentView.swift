//
//  ContentView.swift
//  VybeAI
//
//  Created by JM Mahoro on 2025-03-26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var openAIService = OpenAIService()
    @StateObject private var imageCaptureService = ImageCaptureService()
    
    var body: some View {
        MainView()
            .environmentObject(appSettings)
            .environmentObject(subscriptionManager)
            .environmentObject(openAIService)
            .environmentObject(imageCaptureService)
    }
}

#Preview {
    ContentView()
}
