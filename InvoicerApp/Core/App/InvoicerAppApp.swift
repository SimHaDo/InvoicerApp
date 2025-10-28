//
//  InvoicerAppApp.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

// MARK: - InvoicerApp.swift
import SwiftUI
import RevenueCat
import StoreKit

@main
struct InvoicerApp: App {
    @StateObject private var app = AppState()
    @StateObject private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            // Container decides what to show: onboarding or tabs
            RootContainer()
                .environmentObject(app)
                .environmentObject(subscriptionManager)
                .task {
                    // Start sync immediately for faster data loading
                    app.syncFromCloud()
                    
                    // Initialize RevenueCat
                    await initializeRevenueCat()
                    // Update subscription status on startup
                    await subscriptionManager.checkSubscriptionStatus()
                    // Explicit KVS sync (just in case)
                    CloudSync.shared.synchronize()
                }
        }
    }
    
    private func initializeRevenueCat() async {
        // Initialize RevenueCat with your SDK key
        Purchases.logLevel = .debug // For development
        Purchases.configure(withAPIKey: "appl_JGiIBARoOJHTuWxhsyMmLdHaoMM")
        
        // Setup delegate for receiving updates
        Purchases.shared.delegate = subscriptionManager
        
        // Check device settings
        print("🔍 Device settings check:")
        print("🔍 Can make payments: \(SKPaymentQueue.canMakePayments())")
        
        // Set user (if needed)
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            print("✅ RevenueCat initialized for user: \(customerInfo.originalAppUserId)")
            print("✅ User is anonymous: \(customerInfo.originalAppUserId == "$RCAnonymousID")")
        } catch {
            print("❌ RevenueCat initialization error: \(error)")
        }
        
        // Enable automatic purchase restoration
        _ = try? await Purchases.shared.restorePurchases()
    }
}
