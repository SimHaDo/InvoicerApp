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
        // Синхронизируем с iCloud для кроссплатформенности
        isPro = CloudSync.shared.bool(.isProSubscriber)
    }

    // MARK: - Public Methods
    
    /// Проверяет статус подписки
    func checkSubscriptionStatus() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            print("✅ Customer Info loaded for user: \(customerInfo.originalAppUserId)")
            print("✅ Active entitlements: \(customerInfo.entitlements.active.keys)")
            updateSubscriptionStatus(from: customerInfo)
        } catch {
            errorMessage = "Ошибка при проверке статуса подписки: \(error.localizedDescription)"
            print("❌ RevenueCat error: \(error)")
        }
        
        isLoading = false
    }
    
    /// Загружает доступные предложения
    func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
        } catch {
            errorMessage = "Ошибка при загрузке предложений: \(error.localizedDescription)"
            print("❌ RevenueCat offerings error: \(error)")
        }
    }
    
    /// Принудительно авторизует пользователя (если он анонимный)
    func ensureUserAuthenticated() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            if customerInfo.originalAppUserId == "$RCAnonymousID" {
                print("🔍 User is anonymous, attempting to authenticate...")
                // Попробуем восстановить покупки для авторизации
                _ = try await Purchases.shared.restorePurchases()
                print("✅ Authentication attempt completed")
            } else {
                print("✅ User is already authenticated: \(customerInfo.originalAppUserId)")
            }
        } catch {
            print("❌ Authentication error: \(error)")
        }
    }
    
    /// Покупает пакет подписки
    func purchase(package: Package) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Проверяем статус StoreKit
            print("🔍 Checking StoreKit status...")
            
            // Убеждаемся, что пользователь авторизован
            await ensureUserAuthenticated()
            
            let currentCustomerInfo = try await Purchases.shared.customerInfo()
            print("✅ Current user: \(currentCustomerInfo.originalAppUserId)")
            print("✅ User is anonymous: \(currentCustomerInfo.originalAppUserId == "$RCAnonymousID")")
            
            // Проверяем доступность продукта
            print("🔍 Product ID: \(package.storeProduct.productIdentifier)")
            print("🔍 Product price: \(package.storeProduct.localizedPriceString)")
            
            // Проверяем настройки StoreKit
            if #available(iOS 15.0, *) {
                _ = StoreKit.Transaction.currentEntitlements
                print("🔍 StoreKit entitlements available")
            }
            
            print("🛒 Starting purchase...")
            let (transaction, purchaseCustomerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)
            
            print("🛒 Purchase completed:")
            print("   - Transaction: \(transaction?.description ?? "nil")")
            print("   - User cancelled: \(userCancelled)")
            
            // Обновляем статус подписки
            updateSubscriptionStatus(from: purchaseCustomerInfo)
            
            // Дополнительно проверяем статус через небольшую задержку
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
                    // Пользователь отменил покупку - не показываем ошибку
                    return
                case .storeProblemError:
                    errorMessage = "Проблема с App Store. Попробуйте позже."
                case .purchaseNotAllowedError:
                    errorMessage = "Покупки не разрешены на этом устройстве."
                case .purchaseInvalidError:
                    errorMessage = "Недействительная покупка."
                case .productNotAvailableForPurchaseError:
                    errorMessage = "Продукт недоступен для покупки."
                case .productAlreadyPurchasedError:
                    errorMessage = "Продукт уже куплен."
                case .receiptAlreadyInUseError:
                    errorMessage = "Чек уже используется другим аккаунтом."
                case .invalidReceiptError:
                    errorMessage = "Недействительный чек."
                case .missingReceiptFileError:
                    errorMessage = "Файл чека отсутствует."
                case .networkError:
                    errorMessage = "Ошибка сети. Проверьте подключение к интернету."
                case .invalidCredentialsError:
                    errorMessage = "Недействительные учетные данные."
                case .unexpectedBackendResponseError:
                    errorMessage = "Неожиданный ответ сервера."
                case .receiptInUseByOtherSubscriberError:
                    errorMessage = "Чек используется другим подписчиком."
                case .invalidAppUserIdError:
                    errorMessage = "Недействительный ID пользователя."
                case .unknownBackendError:
                    errorMessage = "Неизвестная ошибка сервера."
                case .invalidSubscriberAttributesError:
                    errorMessage = "Недействительные атрибуты подписчика."
                case .ineligibleError:
                    errorMessage = "Недоступно для покупки."
                case .insufficientPermissionsError:
                    errorMessage = "Недостаточно прав."
                case .paymentPendingError:
                    errorMessage = "Ожидается подтверждение платежа."
                case .logOutAnonymousUserError:
                    errorMessage = "Нельзя выйти из анонимного аккаунта."
                case .customerInfoError:
                    errorMessage = "Ошибка информации о клиенте."
                case .systemInfoError:
                    errorMessage = "Ошибка системной информации."
                case .beginRefundRequestError:
                    errorMessage = "Ошибка начала запроса возврата."
                case .apiEndpointBlockedError:
                    errorMessage = "API endpoint заблокирован."
                case .invalidAppleSubscriptionKeyError:
                    errorMessage = "Недействительный ключ подписки Apple."
                case .unsupportedError:
                    errorMessage = "Неподдерживаемая операция."
                case .productDiscountMissingIdentifierError:
                    errorMessage = "Отсутствует идентификатор скидки продукта."
                case .productDiscountMissingSubscriptionGroupIdentifierError:
                    errorMessage = "Отсутствует идентификатор группы подписки скидки продукта."
                default:
                    errorMessage = "Ошибка покупки: \(rcError.localizedDescription)"
                }
            } else {
                errorMessage = "Ошибка покупки: \(error.localizedDescription)"
            }
            throw error
        }
        
        isLoading = false
    }
    
    /// Восстанавливает покупки
    func restorePurchases() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateSubscriptionStatus(from: customerInfo)
        } catch {
            isLoading = false
            errorMessage = "Ошибка при восстановлении покупок: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    /// Получает пакет по идентификатору
    func getPackage(identifier: String) -> Package? {
        return offerings?.offering(identifier: offeringID)?.package(identifier: identifier)
    }
    
    /// Получает все доступные пакеты
    func getAvailablePackages() -> [Package] {
        return offerings?.offering(identifier: offeringID)?.availablePackages ?? []
    }
    
    // MARK: - Private Methods
    
    private func updateSubscriptionStatus(from customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        
        // Проверяем доступ к entitlement "pro"
        let hasProAccess = customerInfo.entitlements[entitlementID]?.isActive == true
        let previousStatus = isPro
        isPro = hasProAccess
        
        // Синхронизируем с iCloud
        CloudSync.shared.set(isPro, for: .isProSubscriber)
        
        print("✅ Subscription status updated: isPro = \(isPro)")
        print("✅ Previous status: \(previousStatus), New status: \(isPro)")
        
        // Логируем детали entitlement
        if let proEntitlement = customerInfo.entitlements[entitlementID] {
            print("✅ Pro entitlement details:")
            print("   - Is active: \(proEntitlement.isActive)")
            print("   - Will renew: \(proEntitlement.willRenew)")
            print("   - Period type: \(proEntitlement.periodType)")
            print("   - Expires date: \(proEntitlement.expirationDate?.description ?? "Never")")
        } else {
            print("❌ Pro entitlement not found in customer info")
        }
        
        // Логируем все активные entitlements
        print("✅ All active entitlements: \(customerInfo.entitlements.active.keys)")
        print("✅ All entitlements (active + inactive): \(customerInfo.entitlements.all.keys)")
        
        // Логируем детали всех entitlements
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
