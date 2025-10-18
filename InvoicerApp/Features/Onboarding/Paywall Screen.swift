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

    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var selectedPackage: Package?
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var shimmerOffset: CGFloat = -1
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
            let logoSize: CGFloat = isSmallScreen ? 50 : 60
            let titleSize: CGFloat = isSmallScreen ? 24 : 28
            let subtitleSize: CGFloat = isSmallScreen ? 13 : 15
            let spacing: CGFloat = isSmallScreen ? 12 : 18
            
            ZStack {
                // Background
                backgroundView
                
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
                                .font(.system(size: 14, weight: .medium))
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
        .onAppear {
            Task {
                await subscriptionManager.loadOfferings()
                // Устанавливаем месячный план по умолчанию
                if let monthly = monthlyPackage {
                    selectedPackage = monthly
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private func headerView(logoSize: CGFloat, titleSize: CGFloat, subtitleSize: CGFloat) -> some View {
        VStack(spacing: 16) {
            // Logo
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: logoSize, height: logoSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // Title
            Text("Unlock Premium Features")
                .font(.system(size: titleSize, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text("Get unlimited access to all premium features and templates")
                .font(.system(size: subtitleSize, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Features View
    
    private var featuresView: some View {
        VStack(spacing: 12) {
            FeatureBadge(icon: "infinity", text: "Unlimited Invoices", delay: 0.0)
            FeatureBadge(icon: "doc.richtext.fill", text: "Premium Templates", delay: 0.1)
            FeatureBadge(icon: "chart.bar.fill", text: "Advanced Analytics", delay: 0.2)
            FeatureBadge(icon: "icloud.fill", text: "Cloud Sync", delay: 0.3)
        }
    }
    
    // MARK: - Plans View
    
    private var plansView: some View {
        VStack(spacing: 12) {
            if let weekly = weeklyPackage {
                RevenueCatPlanRow(
                    package: weekly,
                    title: "Weekly",
                    tagText: "3-day free",
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            onClose()
                        }
                    } catch {
                        // Ошибка обрабатывается в SubscriptionManager
                    }
                }
            } label: {
                HStack {
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Start with Pro")
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(subscriptionManager.isLoading || selectedPackage == nil)
            .scaleEffect(pulseAnimation ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
            .onAppear {
                pulseAnimation = true
            }
            
            // Restore Button
            Button {
                Task {
                    do {
                        try await subscriptionManager.restorePurchases()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onClose()
                        }
                    } catch {
                        // Ошибка обрабатывается в SubscriptionManager
                    }
                }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
            }
            .disabled(subscriptionManager.isLoading)
        }
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    scheme == .dark ? Color(.systemBackground) : Color(.systemBackground),
                    scheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
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
                    
                    Text(package.storeProduct.localizedPriceString)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let period = package.storeProduct.subscriptionPeriod {
                        Text(period.localizedDescription)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
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