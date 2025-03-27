// SubscriptionManager.swift
// VybeAI - Shock-Style Content Generator
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI
import Combine
// Note: You'll need to add RevenueCat package via SPM
// import RevenueCat

class SubscriptionManager: ObservableObject {
    enum SubscriptionTier: String, CaseIterable, Identifiable {
        case free
        case monthly
        case yearly
        case lifetime
        
        var id: String { self.rawValue }
        
        var title: String {
            switch self {
            case .free: return "Free Trial"
            case .monthly: return "Monthly Premium"
            case .yearly: return "Yearly Premium"
            case .lifetime: return "Lifetime Access"
            }
        }
        
        var price: String {
            switch self {
            case .free: return "Free"
            case .monthly: return "$4.99/month"
            case .yearly: return "$39.99/year"
            case .lifetime: return "$79.99"
            }
        }
        
        var description: String {
            switch self {
            case .free: return "1 free image generation"
            case .monthly: return "Unlimited generations, cancel anytime"
            case .yearly: return "Unlimited generations, best value"
            case .lifetime: return "Unlimited generations forever"
            }
        }
        
        var productId: String {
            switch self {
            case .free: return ""
            case .monthly: return "com.shockstyle.monthly"
            case .yearly: return "com.shockstyle.yearly"
            case .lifetime: return "com.shockstyle.lifetime"
            }
        }
    }
    
    // Published properties
    @Published var currentSubscription: SubscriptionTier = .free
    @Published var purchaseInProgress: Bool = false
    @Published var errorMessage: String?
    @Published var isSubscribed: Bool = false
    @Published var generationsRemaining: Int = 3
    
    // RevenueCat implementation would go here
    // For now, we'll simulate the subscription functionality
    
    init() {
        // In a real app, we would check for active subscriptions with RevenueCat here
        // For now, we'll simulate a free tier
        currentSubscription = .free
        isSubscribed = false
        generationsRemaining = 3
        
        // Setup RevenueCat (commented out for now)
        // setupRevenueCat()
    }
    
    /* 
    private func setupRevenueCat() {
        // Configure RevenueCat with your public SDK key
        Purchases.configure(withAPIKey: "your_public_sdk_key")
        
        // Setup customer info monitoring
        Purchases.shared.customerInfo { [weak self] (customerInfo, error) in
            self?.updateSubscriptionStatus(with: customerInfo)
        }
    }
    
    private func updateSubscriptionStatus(with customerInfo: CustomerInfo?) {
        // Check for active subscriptions
        if let customerInfo = customerInfo {
            if customerInfo.entitlements["premium"]?.isActive == true {
                self.currentSubscription = .monthly
                self.isSubscribed = true
                // Further logic to determine exact tier
            } else {
                self.currentSubscription = .free
                self.isSubscribed = false
            }
        }
    }
    */
    
    // Methods to handle subscription purchases
    func purchase(tier: SubscriptionTier) {
        guard tier != .free else { return }
        
        purchaseInProgress = true
        errorMessage = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            // In a real app, this would call RevenueCat's purchase method
            // Simulating successful purchase for demo
            self?.currentSubscription = tier
            self?.isSubscribed = tier != .free
            self?.purchaseInProgress = false
        }
        
        /* 
        // Real implementation with RevenueCat would look like:
        Purchases.shared.getOfferings { [weak self] (offerings, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Failed to load offerings: \(error.localizedDescription)"
                self.purchaseInProgress = false
                return
            }
            
            if let offering = offerings?.offering(identifier: "default") {
                if let package = offering.package(identifier: tier.rawValue) {
                    Purchases.shared.purchase(package: package) { (transaction, customerInfo, error, userCancelled) in
                        self.purchaseInProgress = false
                        
                        if let error = error, !userCancelled {
                            self.errorMessage = "Purchase failed: \(error.localizedDescription)"
                        } else if !userCancelled {
                            self.updateSubscriptionStatus(with: customerInfo)
                        }
                    }
                } else {
                    self.errorMessage = "Package not found"
                    self.purchaseInProgress = false
                }
            } else {
                self.errorMessage = "Offerings not found"
                self.purchaseInProgress = false
            }
        }
        */
    }
    
    func restorePurchases() {
        purchaseInProgress = true
        errorMessage = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            // In a real app, this would call RevenueCat's restorePurchases method
            self?.purchaseInProgress = false
        }
        
        /*
        // Real implementation with RevenueCat:
        Purchases.shared.restorePurchases { [weak self] (customerInfo, error) in
            guard let self = self else { return }
            self.purchaseInProgress = false
            
            if let error = error {
                self.errorMessage = "Restore failed: \(error.localizedDescription)"
            } else {
                self.updateSubscriptionStatus(with: customerInfo)
            }
        }
        */
    }
    
    // Helper to check if user can generate images
    func canGenerateImages() -> Bool {
        return isSubscribed || generationsRemaining > 0
    }
    
    // Helper to track first free generation usage
    func useFirstFreeGeneration() {
        if !isSubscribed && generationsRemaining > 0 {
            generationsRemaining -= 1
        }
    }
} 