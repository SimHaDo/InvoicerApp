//
//  Paywall Screen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.
//

import SwiftUI
import RevenueCat

struct PaywallScreen: View {
    var onClose: () -> Void = {}
    var useCustomBackground: Bool = true

    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var selectedPackage: Package?
    @State private var floatingElements: [FloatingElement] = []
    
    // Маппинг пакетов RevenueCat на наши планы
    private var packages: [Package] {
        subscriptionManager.getAvailablePackages()
    }
    
    private var weeklyPackage: Package? {
        packages.first { $0.identifier == "$rc_weekly" }
    }
    
    private var monthlyPackage: Package? {
        packages.first { $0.identifier == "$rc_monthly" }
    }
    
    private var annualPackage: Package? {
        packages.first { $0.identifier == "$rc_annual" }
    }
    
    // Check if trial is available (not used before)
    private var isTrialAvailable: Bool {
        // If user already has active subscription, trial is not available
        if subscriptionManager.isPro {
            return false
        }
        
        // Check if weekly package has introductory discount
        if let weekly = weeklyPackage {
            return weekly.storeProduct.introductoryDiscount != nil
        }
        
        return false
    }
    
    private struct FloatingElement: Identifiable {
        let id = UUID()
        var x: Double
        var y: Double
        var opacity: Double
        var scale: Double
        var rotation: Double
    }

    var body: some View {
        GeometryReader { geometry in
            let isSmallScreen = geometry.size.height < 700
            let isLargeScreen = geometry.size.width >= 430 || UIDevice.current.userInterfaceIdiom == .pad
            let logoSize: CGFloat = isSmallScreen ? 40 : 50
            let titleSize: CGFloat = isSmallScreen ? 20 : 24
            let subtitleSize: CGFloat = isSmallScreen ? 12 : 14
            let spacing: CGFloat = isSmallScreen ? 8 : 12
            
            ZStack {
                // Background - только если useCustomBackground = true
                if useCustomBackground {
                    backgroundView
                }
                
                if isLargeScreen {
                    // Для больших экранов - кнопка внизу
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(spacing: spacing) {
                                // Header
                                headerView(logoSize: logoSize, titleSize: titleSize, subtitleSize: subtitleSize)
                                
                                // Features
                                featuresView
                                
                                // Plans
                                plansView
                                
                                // Error message
                                if let errorMessage = subscriptionManager.errorMessage {
                                    Text(errorMessage)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 8)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                        }
                        
                        // Кнопка внизу для больших экранов
                        VStack(spacing: 12) {
                            buttonsView
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .background(
                            Color(.systemBackground)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                        )
                    }
                } else {
                    // Для маленьких экранов - обычная структура
                    ScrollView {
                        VStack(spacing: spacing) {
                            // Header
                            headerView(logoSize: logoSize, titleSize: titleSize, subtitleSize: subtitleSize)
                            
                            // Features
                            featuresView
                            
                            // Plans
                            plansView
                            
                            // Buttons
                            buttonsView
                            
                            // Error message
                            if let errorMessage = subscriptionManager.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await subscriptionManager.loadOfferings()
                // Устанавливаем недельный план с пробной версией по умолчанию
                if let weekly = weeklyPackage {
                    selectedPackage = weekly
                } else if let monthly = monthlyPackage {
                    selectedPackage = monthly
                }
            }
        }
        .onChange(of: subscriptionManager.isPro) { isPro in
            // Автоматически закрываем paywall при активации подписки
            if isPro {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onClose()
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private func headerView(logoSize: CGFloat, titleSize: CGFloat, subtitleSize: CGFloat) -> some View {
        VStack(spacing: 8) {
            // Title - большой и привлекательный
            Text("Unlock Premium Features")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Subtitle
            Text("Get unlimited access to all premium features and templates")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Features View
    
    private var featuresView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            FeatureBadge(icon: "infinity", text: "Unlimited Invoices", delay: 0.0)
            FeatureBadge(icon: "doc.richtext.fill", text: "Premium Templates", delay: 0.1)
            FeatureBadge(icon: "chart.bar.fill", text: "Advanced Analytics", delay: 0.2)
            FeatureBadge(icon: "icloud.fill", text: "Cloud Sync", delay: 0.3)
        }
        .padding(.horizontal, 10)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Plans View
    
    private var plansView: some View {
        VStack(spacing: 12) {
            if let weekly = weeklyPackage {
                RevenueCatPlanRow(
                    package: weekly,
                    title: "Weekly",
                    tagText: isTrialAvailable ? "3-day free trial" : nil,
                    selected: selectedPackage?.identifier == weekly.identifier,
                    delay: 0.0
                )
                .onTapGesture { selectPackage(weekly) }
            }
            
            if let monthly = monthlyPackage {
                RevenueCatPlanRow(
                    package: monthly,
                    title: "Monthly",
                    tagText: nil,
                    selected: selectedPackage?.identifier == monthly.identifier,
                    delay: 0.1
                )
                .onTapGesture { selectPackage(monthly) }
            }
            
            if let annual = annualPackage {
                RevenueCatPlanRow(
                    package: annual,
                    title: "Annual",
                    tagText: "Best Value",
                    selected: selectedPackage?.identifier == annual.identifier,
                    delay: 0.2
                )
                .onTapGesture { selectPackage(annual) }
            }
        }
    }
    
    // MARK: - Buttons View
    
    private var buttonsView: some View {
        VStack(spacing: 12) {
            // Continue Button
            Button {
                guard let package = selectedPackage else { return }
                Task {
                    do {
                        try await subscriptionManager.purchase(package: package)
                        
                        // Проверяем статус подписки после покупки
                        await subscriptionManager.checkSubscriptionStatus()
                        
                        // Закрываем paywall только при успешной покупке
                        // (onChange(of: subscriptionManager.isPro) уже обрабатывает это)
                    } catch {
                        // Ошибка обрабатывается в SubscriptionManager
                        // НЕ закрываем paywall при ошибке или отмене
                        print("Purchase failed or cancelled: \(error)")
                    }
                }
            } label: {
                HStack {
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        // Show different text based on selected package and trial availability
                        if selectedPackage?.identifier == "$rc_weekly" && isTrialAvailable {
                            Text("Start Free Trial")
                                .font(.system(size: 16, weight: .bold))
                        } else {
                            Text("Start with Pro")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor)
                )
                .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .disabled(subscriptionManager.isLoading || selectedPackage == nil)
            
            // Maybe Later Button
            Button {
                onClose()
            } label: {
                Text("Maybe Later")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        ZStack {
            // Base background - единый цвет для темной темы
            if scheme == .dark {
                Color(.systemBackground)
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            
            // Floating elements
            ForEach(floatingElements) { element in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .position(x: element.x, y: element.y)
                    .opacity(element.opacity)
                    .scaleEffect(element.scale)
                    .rotationEffect(.degrees(element.rotation))
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: element.rotation)
            }
        }
        .onAppear {
            generateFloatingElements()
        }
    }
    
    // MARK: - Helper Methods
    
    private func selectPackage(_ package: Package) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            selectedPackage = package
        }
    }
    
    private func generateFloatingElements() {
        floatingElements = (0..<8).map { _ in
            FloatingElement(
                x: Double.random(in: 0...UIScreen.main.bounds.width),
                y: Double.random(in: 0...UIScreen.main.bounds.height),
                opacity: Double.random(in: 0.3...0.7),
                scale: Double.random(in: 0.8...1.2),
                rotation: Double.random(in: 0...360)
            )
        }
    }
}

// MARK: - Components

struct FeatureBadge: View {
    let icon: String
    let text: String
    let delay: Double
    @State private var show = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(show ? 1.0 : 0.8)
        .opacity(show ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: show)
        .onAppear { show = true }
    }
}

struct RevenueCatPlanRow: View {
    let package: Package
    let title: String
    let tagText: String?
    let selected: Bool
    let delay: Double
    @Environment(\.colorScheme) private var scheme
    @State private var show = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if let tagText = tagText {
                            Text(tagText)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.orange)
                                )
                        }
                    }
                    
                    // Price information
                    VStack(alignment: .leading, spacing: 2) {
                        Text(package.storeProduct.localizedPriceString)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if let period = package.storeProduct.subscriptionPeriod {
                            Text(period.localizedDescription)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(selected ? .blue : .gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(scheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selected ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(show ? 1.0 : 0.9)
        .opacity(show ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: show)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selected)
        .onAppear { show = true }
    }
}

// MARK: - Extensions

extension SubscriptionPeriod {
    var localizedDescription: String {
        switch unit {
        case .day:
            return value == 1 ? "day" : "\(value) days"
        case .week:
            return value == 1 ? "week" : "\(value) weeks"
        case .month:
            return value == 1 ? "month" : "\(value) months"
        case .year:
            return value == 1 ? "year" : "\(value) years"
        @unknown default:
            return "period"
        }
    }
}