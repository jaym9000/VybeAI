import SwiftUI

struct PaywallView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                            .padding(8)
                    }
                }
                
                // Icon
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                    .padding()
                    .background(
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 140, height: 140)
                    )
                
                // Title and subtitle
                Text("Unlock Premium Features")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Get unlimited access to all premium features and generate high-quality AI images without restrictions.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 32)
            
            // Features list
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "photo.stack", title: "High-quality images", description: "Generate stunning images in high resolution")
                FeatureRow(icon: "bolt.fill", title: "Faster generation", description: "Priority access to our AI servers")
                FeatureRow(icon: "infinity", title: "Unlimited generations", description: "Create as many images as you want")
                FeatureRow(icon: "rectangle.on.rectangle", title: "Advanced editing", description: "Advanced tools for perfect results")
            }
            .padding(.bottom, 32)
            
            // Subscription options
            VStack(spacing: 16) {
                SubscriptionButton(
                    title: "Monthly",
                    price: "$9.99/month",
                    description: "Billed monthly",
                    isRecommended: false
                ) {
                    subscriptionManager.purchase(tier: .monthly)
                    isPresented = false
                }
                
                SubscriptionButton(
                    title: "Annual",
                    price: "$69.99/year",
                    description: "Save 40% (just $5.83/month)",
                    isRecommended: true
                ) {
                    subscriptionManager.purchase(tier: .yearly)
                    isPresented = false
                }
                
                // Restore purchases button
                Button {
                    subscriptionManager.restorePurchases()
                } label: {
                    Text("Restore Purchases")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary.opacity(0.8))
                }
                .padding(.top, 8)
            }
            
            // Terms and privacy
            Text("By subscribing, you agree to our Terms of Service and Privacy Policy. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 24)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(hex: "1A1A1A") : Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .padding(24)
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.purple)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SubscriptionButton: View {
    let title: String
    let price: String
    let description: String
    let isRecommended: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if isRecommended {
                    Text("BEST VALUE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.purple)
                        )
                        .padding(.bottom, 4)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                        
                        Text(price)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Spacer()
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isRecommended
                          ? LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color.purple.opacity(0.6) : Color.purple.opacity(0.2),
                                colorScheme == .dark ? Color.purple.opacity(0.3) : Color.purple.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                          : LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7"),
                                colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isRecommended ? Color.purple : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallView(isPresented: .constant(true))
        .environmentObject(SubscriptionManager())
} 