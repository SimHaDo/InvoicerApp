//
//  SubscriptionManager.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.
//

import Foundation
import RevenueCat
import StoreKit

@MainActor
final class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()

    // MARK: - Published Properties
    @Published private(set) var isPro: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var offerings: Offerings?
    @Published private(set) var customerInfo: CustomerInfo?
    
    // MARK: - Private Properties
    private let entitlementID = "Invoice Maker: Pro - Premium Subscription"
    private let offeringID = "default"
    
    // MARK: - Initialization
    override init() {
        super.init()
        // Sync with iCloud for cross-platform compatibility
        isPro = CloudSync.shared.bool(.isProSubscriber)
    }

    // MARK: - Public Methods
    
    /// Checks subscription status
    func checkSubscriptionStatus() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            print("✅ Customer Info loaded for user: \(customerInfo.originalAppUserId)")
            print("✅ Active entitlements: \(customerInfo.entitlements.active.keys)")
            updateSubscriptionStatus(from: customerInfo)
        } catch {
            errorMessage = "Error checking subscription status: \(error.localizedDescription)"
            print("❌ RevenueCat error: \(error)")
        }
        
        isLoading = false
    }
    
    /// Loads available offerings
    func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
        } catch {
            errorMessage = "Error loading offerings: \(error.localizedDescription)"
            print("❌ RevenueCat offerings error: \(error)")
        }
    }
    
    /// Forces user authorization (if anonymous)
    func ensureUserAuthenticated() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            if customerInfo.originalAppUserId == "$RCAnonymousID" {
                print("🔍 User is anonymous, attempting to authenticate...")
                // Try to restore purchases for authorization
                _ = try await Purchases.shared.restorePurchases()
                print("✅ Authentication attempt completed")
            } else {
                print("✅ User is already authenticated: \(customerInfo.originalAppUserId)")
            }
        } catch {
            print("❌ Authentication error: \(error)")
        }
    }
    
    /// Purchases subscription package
    func purchase(package: Package) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Check StoreKit status
            print("🔍 Checking StoreKit status...")
            
            // Ensure user is authenticated
            await ensureUserAuthenticated()
            
            let currentCustomerInfo = try await Purchases.shared.customerInfo()
            print("✅ Current user: \(currentCustomerInfo.originalAppUserId)")
            print("✅ User is anonymous: \(currentCustomerInfo.originalAppUserId == "$RCAnonymousID")")
            
            // Check if user already has active subscription
            let hasActiveSubscription = currentCustomerInfo.entitlements.active.keys.contains(entitlementID)
            print("🔍 User has active subscription: \(hasActiveSubscription)")
            
            if hasActiveSubscription {
                print("⚠️ User already has active subscription - trial may not be available")
            }
            
            // Check product availability
            print("🔍 Product ID: \(package.storeProduct.productIdentifier)")
            print("🔍 Product price: \(package.storeProduct.localizedPriceString)")
            
            // Check for trial period
            if let introDiscount = package.storeProduct.introductoryDiscount {
                print("🔍 Introductory discount found: \(introDiscount.price)")
                print("🔍 Trial period: \(introDiscount.subscriptionPeriod.value) \(introDiscount.subscriptionPeriod.unit)")
                print("🔍 Trial type: \(introDiscount.paymentMode)")
            } else {
                print("⚠️ No introductory discount found for product: \(package.storeProduct.productIdentifier)")
            }
            
            // Check StoreKit settings
            if #available(iOS 15.0, *) {
                _ = StoreKit.Transaction.currentEntitlements
                print("🔍 StoreKit entitlements available")
            }
            
            print("🛒 Starting purchase...")
            let (transaction, purchaseCustomerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)
            
            print("🛒 Purchase completed:")
            print("   - Transaction: \(transaction?.description ?? "nil")")
            print("   - User cancelled: \(userCancelled)")
            
            // Update subscription status
            updateSubscriptionStatus(from: purchaseCustomerInfo)
            
            // Additionally check status after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    await self.checkSubscriptionStatus()
                }
            }
        } catch {
            isLoading = false
            if let rcError = error as? RevenueCat.ErrorCode {
                switch rcError {
                case .purchaseCancelledError:
                    // User cancelled purchase - don't show error
                    return
                case .storeProblemError:
                    errorMessage = "App Store issue. Please try again later."
                case .purchaseNotAllowedError:
                    errorMessage = "Purchases not allowed on this device."
                case .purchaseInvalidError:
                    errorMessage = "Invalid purchase."
                case .productNotAvailableForPurchaseError:
                    errorMessage = "Product not available for purchase."
                case .productAlreadyPurchasedError:
                    errorMessage = "Product already purchased."
                case .receiptAlreadyInUseError:
                    errorMessage = "Receipt already used by another account."
                case .invalidReceiptError:
                    errorMessage = "Invalid receipt."
                case .missingReceiptFileError:
                    errorMessage = "Receipt file missing."
                case .networkError:
                    errorMessage = "Network error. Check internet connection."
                case .invalidCredentialsError:
                    errorMessage = "Invalid credentials."
                case .unexpectedBackendResponseError:
                    errorMessage = "Unexpected server response."
                case .receiptInUseByOtherSubscriberError:
                    errorMessage = "Receipt used by another subscriber."
                case .invalidAppUserIdError:
                    errorMessage = "Invalid user ID."
                case .unknownBackendError:
                    errorMessage = "Unknown server error."
                case .invalidSubscriberAttributesError:
                    errorMessage = "Invalid subscriber attributes."
                case .ineligibleError:
                    errorMessage = "Not available for purchase."
                case .insufficientPermissionsError:
                    errorMessage = "Insufficient permissions."
                case .paymentPendingError:
                    errorMessage = "Payment confirmation pending."
                case .logOutAnonymousUserError:
                    errorMessage = "Cannot log out of anonymous account."
                case .customerInfoError:
                    errorMessage = "Customer information error."
                case .systemInfoError:
                    errorMessage = "System information error."
                case .beginRefundRequestError:
                    errorMessage = "Refund request initiation error."
                case .apiEndpointBlockedError:
                    errorMessage = "API endpoint blocked."
                case .invalidAppleSubscriptionKeyError:
                    errorMessage = "Invalid Apple subscription key."
                case .unsupportedError:
                    errorMessage = "Unsupported operation."
                case .productDiscountMissingIdentifierError:
                    errorMessage = "Product discount identifier missing."
                case .productDiscountMissingSubscriptionGroupIdentifierError:
                    errorMessage = "Product discount subscription group identifier missing."
                default:
                    errorMessage = "Purchase error: \(rcError.localizedDescription)"
                }
            } else {
                errorMessage = "Purchase error: \(error.localizedDescription)"
            }
            throw error
        }
        
        isLoading = false
    }
    
    /// Restores purchases
    func restorePurchases() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateSubscriptionStatus(from: customerInfo)
        } catch {
            isLoading = false
            errorMessage = "Error restoring purchases: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    /// Gets package by identifier
    func getPackage(identifier: String) -> Package? {
        return offerings?.offering(identifier: offeringID)?.package(identifier: identifier)
    }
    
    /// Gets all available packages
    func getAvailablePackages() -> [Package] {
        return offerings?.offering(identifier: offeringID)?.availablePackages ?? []
    }
    
    // MARK: - Private Methods
    
    private func updateSubscriptionStatus(from customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        
        // Check access to "pro" entitlement
        let hasProAccess = customerInfo.entitlements[entitlementID]?.isActive == true
        let previousStatus = isPro
        isPro = hasProAccess
        
        // Sync with iCloud
        CloudSync.shared.set(isPro, for: .isProSubscriber)
        
        print("✅ Subscription status updated: isPro = \(isPro)")
        print("✅ Previous status: \(previousStatus), New status: \(isPro)")
        
        // Log entitlement details
        if let proEntitlement = customerInfo.entitlements[entitlementID] {
            print("✅ Pro entitlement details:")
            print("   - Is active: \(proEntitlement.isActive)")
            print("   - Will renew: \(proEntitlement.willRenew)")
            print("   - Period type: \(proEntitlement.periodType)")
            print("   - Expires date: \(proEntitlement.expirationDate?.description ?? "Never")")
        } else {
            print("❌ Pro entitlement not found in customer info")
        }
        
        // Log all active entitlements
        print("✅ All active entitlements: \(customerInfo.entitlements.active.keys)")
        print("✅ All entitlements (active + inactive): \(customerInfo.entitlements.all.keys)")
        
        // Log details of all entitlements
        for (key, entitlement) in customerInfo.entitlements.all {
            print("✅ Entitlement '\(key)': isActive=\(entitlement.isActive), willRenew=\(entitlement.willRenew)")
        }
    }
}

// MARK: - PurchasesDelegate
extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updateSubscriptionStatus(from: customerInfo)
        }
    }
}
