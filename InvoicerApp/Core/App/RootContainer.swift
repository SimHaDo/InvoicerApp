//
//  RootContainer.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.
//

import SwiftUI
import UIKit

struct RootContainer: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showTemplatePicker = false
    @State private var showLoadingScreen = true

    var body: some View {
        Group {
            if showLoadingScreen {
                LoadingScreen()
                    .onAppear {
                        // Показываем лоадинг скрин на 3 секунды
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showLoadingScreen = false
                            }
                        }
                    }
            } else if app.hasCompletedOnboarding {
                RootTabView()
                    .environmentObject(app)
                    .environmentObject(subscriptionManager)
            } else {
                // ✅ Используем объединённый экран онбординга с пейволлом
                OnboardingView()
                    .environmentObject(app)
                    .environmentObject(subscriptionManager)
            }
        }
        .onChange(of: app.selectedTemplate.id) { _ in
            app.persistSelectedTemplate()
        }
    }

    // Если где-то понадобится открыть URL из корня
    private func open(url: URL) {
        #if os(iOS)
        UIApplication.shared.open(url)
        #endif
    }
}
