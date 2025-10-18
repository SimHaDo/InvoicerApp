//
//  InvoicerAppApp.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

// MARK: - InvoicerApp.swift
import SwiftUI
import RevenueCat

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
        
        // Включаем автоматическое восстановление покупок
        try? await Purchases.shared.restorePurchases()
    }
}
