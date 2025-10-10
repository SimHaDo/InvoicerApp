//
//  InvoicerAppApp.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

// MARK: - InvoicerApp.swift
import SwiftUI

@main
struct InvoicerApp: App {
    @StateObject private var app = AppState()

    var body: some Scene {
        WindowGroup {
            // Контейнер сам решает, что показать: онбординг или табы
            RootContainer()
                .environmentObject(app)
                .task {
                    // Обновляем статус подписки на старте
                    await SubscriptionManager.shared.refreshStatus()
                    // Явный sync KVS (на всякий случай)
                    CloudSync.shared.synchronize()
                }
        }
    }
}
