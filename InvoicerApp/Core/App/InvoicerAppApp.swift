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
            // Контейнер сам решает, что показать: онбординг или табы
            RootContainer()
                .environmentObject(app)
                .environmentObject(subscriptionManager)
                .task {
                    // Инициализируем RevenueCat
                    await initializeRevenueCat()
                    // Обновляем статус подписки на старте
                    await subscriptionManager.checkSubscriptionStatus()
                    // Явный sync KVS (на всякий случай)
                    CloudSync.shared.synchronize()
                }
        }
    }
    
    private func initializeRevenueCat() async {
        // Инициализируем RevenueCat с вашим SDK ключом
        Purchases.logLevel = .debug // Для разработки
        Purchases.configure(withAPIKey: "appl_JGiIBARoOJHTuWxhsyMmLdHaoMM")
        
        // Настраиваем делегат для получения обновлений
        Purchases.shared.delegate = subscriptionManager
        
        // Проверяем настройки устройства
        print("🔍 Device settings check:")
        print("🔍 Can make payments: \(SKPaymentQueue.canMakePayments())")
        
        // Устанавливаем пользователя (если нужно)
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            print("✅ RevenueCat initialized for user: \(customerInfo.originalAppUserId)")
            print("✅ User is anonymous: \(customerInfo.originalAppUserId == "$RCAnonymousID")")
        } catch {
            print("❌ RevenueCat initialization error: \(error)")
        }
        
        // Включаем автоматическое восстановление покупок
        _ = try? await Purchases.shared.restorePurchases()
    }
}
