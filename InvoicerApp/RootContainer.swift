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
    @State private var showTemplatePicker = false

    var body: some View {
        Group {
            if app.hasCompletedOnboarding {
                RootTabView()
                    .environmentObject(app)
            } else {
                // ✅ Используем объединённый экран онбординга с пейволлом
                OnboardingView()
                    .environmentObject(app)
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
