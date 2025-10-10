//
//  SubscriptionManager.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.
//

import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // Помечаем про-статус в iCloud, чтобы не потерялся между устройствами
    @Published private(set) var isPro: Bool = CloudSync.shared.bool(.isProSubscriber) {
        didSet { CloudSync.shared.set(isPro, for: .isProSubscriber) }
    }

    // TODO: подставь реальные product IDs из App Store Connect
    private let defaultProductID = "com.simhado.invoicer.pro.monthly"

    func refreshStatus() async {
        // Здесь можно распарсить текущие подписки из StoreKit 2
        // Для MVP: просто читаем iCloud-флаг
        isPro = CloudSync.shared.bool(.isProSubscriber)
    }

    func purchaseDefault() async throws {
        // Подключишь реальную покупку: let result = try await Product.products(for: [defaultProductID])
        // Для заглушки пометим PRO = true
        isPro = true
    }

    func restore() async throws {
        // В реале: try await AppStore.sync()
        // Заглушка:
        isPro = true
    }
}
