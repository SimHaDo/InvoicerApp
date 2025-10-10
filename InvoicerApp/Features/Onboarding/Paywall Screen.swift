//
//  Paywall Screen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.


//
//  Paywall Screen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.
//

import SwiftUI
import StoreKit

struct PaywallScreen: View {
    var onClose: () -> Void = {}

    @Environment(\.colorScheme) private var scheme
    @State private var isPurchasing = false
    @State private var errorText: String?
    @State private var selected: Int = 1 // по умолчанию Monthly
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var shimmerOffset: CGFloat = -1
    @State private var floatingElements: [FloatingElement] = []

    private struct Plan: Identifiable { 
        let id: Int
        let title: String
        let price: String
        let originalPrice: String?
        let tag: String?
        let savings: String?
    }
    
    private let plans: [Plan] = [
        .init(id: 0, title: "Weekly", price: "$4.99/week", originalPrice: nil, tag: nil, savings: nil),
        .init(id: 1, title: "Monthly", price: "$9.99/month", originalPrice: "$12.99", tag: "Best Value", savings: "Save 23%"),
        .init(id: 2, title: "Annual", price: "$59.99/year", originalPrice: "$119.88", tag: "Super Deal", savings: "Save 50%")
    ]
    
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
            let horizontalPadding: CGFloat = isSmallScreen ? 16 : 20
            
            ZStack {
                // Анимированный фон
                backgroundView
                
                // Плавающие элементы
                ForEach(floatingElements) { element in
                    Circle()
                        .fill(Color.primary.opacity(0.05))
                        .frame(width: 40, height: 40)
                        .scaleEffect(element.scale)
                        .opacity(element.opacity)
                        .rotationEffect(.degrees(element.rotation))
                        .position(x: element.x, y: element.y)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: element.scale)
                }
                
        ScrollView(showsIndicators: false) {
                    VStack(spacing: spacing) {
                        // MARK: Header с улучшенными анимациями
                        VStack(spacing: isSmallScreen ? 10 : 14) {
                            // Логотип
                    ZStack {
                                // Внешнее кольцо
                        Circle()
                                    .stroke(Color.primary.opacity(0.3), lineWidth: 2.5)
                                    .frame(width: logoSize, height: logoSize)
                                    .opacity(0.7)
                                
                                // Внутреннее кольцо
                        Circle()
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1.5)
                                    .frame(width: logoSize - 10, height: logoSize - 10)
                                
                                // Основной круг
                                Circle()
                                    .fill(Color.primary)
                                    .frame(width: logoSize - 20, height: logoSize - 20)
                                    .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)
                                
                                Image(systemName: "doc.richtext.fill")
                                    .font(.system(size: isSmallScreen ? 16 : 20, weight: .bold))
                                    .foregroundColor(scheme == .light ? .white : .black)
                            }
                            .padding(.top, isSmallScreen ? 4 : 8)
                            .offset(y: showContent ? 0 : -20)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: showContent)

                            // Анимированный заголовок
                            VStack(spacing: isSmallScreen ? 5 : 7) {
                                Text("Invoice Maker Pro")
                                    .font(.system(size: titleSize, weight: .black))
                                    .foregroundColor(.primary)
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                    .offset(y: showContent ? 0 : -15)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2), value: showContent)

                    Text("Unlimited invoices • 30+ templates • iCloud sync • Priority updates")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                                    .font(.system(size: subtitleSize, weight: .medium))
                                    .padding(.horizontal, isSmallScreen ? 24 : 32)
                                    .lineSpacing(2)
                                    .offset(y: showContent ? 0 : -10)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                            }

                        // Анимированные бейджи преимуществ
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            FeatureBadge(icon: "infinity", text: "Unlimited", delay: 0.4)
                            FeatureBadge(icon: "doc.text.fill", text: "30+ Templates", delay: 0.5)
                            FeatureBadge(icon: "icloud.fill", text: "iCloud Sync", delay: 0.6)
                            FeatureBadge(icon: "star.fill", text: "Priority", delay: 0.7)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .offset(y: showContent ? 0 : 15)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                    }

                    // MARK: Plans с улучшенными анимациями
                VStack(spacing: 12) {
                        ForEach(Array(plans.enumerated()), id: \.element.id) { index, p in
                            EnhancedPlanRow(
                            title: p.title,
                            price: p.price,
                                originalPrice: p.originalPrice,
                            tagText: p.tag,
                                savings: p.savings,
                                selected: selected == p.id,
                                delay: Double(index) * 0.1
                        )
                        .onTapGesture {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                selected = p.id
                                }
                            }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.8), value: showContent)

                    // MARK: CTA с улучшенными эффектами
                    VStack(spacing: 12) {
                Button {
                            let impact = UIImpactFeedbackGenerator(style: .heavy)
                            impact.impactOccurred()
                            
                    Task {
                        isPurchasing = true
                                
                                defer { 
                                    isPurchasing = false
                                }
                                
                        do {
                            try await SubscriptionManager.shared.purchaseDefault()
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            onClose()
                                    }
                        } catch {
                            errorText = error.localizedDescription
                        }
                    }
                } label: {
                            ZStack {
                                // Фон кнопки
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.primary)
                                    .frame(height: 50)
                                
                                // Контент кнопки
                                HStack(spacing: 12) {
                                    if isPurchasing {
                                        ProgressView()
                                            .tint(scheme == .light ? .white : .black)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    
                                    Text(isPurchasing ? "Processing..." : "Start with Pro")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(scheme == .light ? .white : .black)
                            }
                            .shadow(color: Color.black.opacity(0.2), radius: 15, y: 8)
                            .scaleEffect(isPurchasing ? 0.98 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPurchasing)
                }
                .disabled(isPurchasing)
                        .padding(.horizontal, horizontalPadding)
                        
                        // Дополнительная информация
                        Text("Cancel anytime")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(1.2), value: showContent)
                    }
                    .offset(y: showContent ? 0 : 25)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: showContent)

                if let e = errorText {
                    Text(e)
                            .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .scale))
                }

                // MARK: Legal + Later
                    VStack(spacing: 10) {
                Text("Payment will be charged to your Apple ID. Subscription auto-renews unless cancelled at least 24 hours before the end of the period. Manage or cancel in Settings → Apple ID → Subscriptions.")
                            .font(.system(size: isSmallScreen ? 11 : 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                            .padding(.horizontal, isSmallScreen ? 20 : 24)
                            .lineSpacing(2)

                        Button("Maybe later") { 
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            onClose() 
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(1.4), value: showContent)
                    }
                    .padding(.vertical, isSmallScreen ? 12 : 18)
                    .padding(.bottom, isSmallScreen ? 12 : 16)
                    .foregroundColor(scheme == .light ? .black : .white)
                }
            }
        }
        .onAppear {
            showContent = true
            pulseAnimation = true
            startShimmerAnimation()
            createFloatingElements()
        }
    }

    // MARK: Background View
    
    private var backgroundView: some View {
        Group {
            if scheme == .light {
                ZStack {
                    // Основной градиент
                    LinearGradient(
                        colors: [Color.white, Color(white: 0.97), Color(white: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Радиальный градиент с анимацией
                    RadialGradient(
                        colors: [Color.white, Color(white: 0.96), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 520
                    )
                    .blendMode(.screen)
                    
                    // Анимированный shimmer эффект
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * 400)
                    .blendMode(.overlay)
                    
                    // Плавающие световые пятна
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 200, height: 200)
                            .position(
                                x: CGFloat(100 + i * 150),
                                y: CGFloat(200 + i * 100)
                            )
                            .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                            .opacity(pulseAnimation ? 0.6 : 0.3)
                            .animation(
                                .easeInOut(duration: 3.0 + Double(i) * 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3),
                                value: pulseAnimation
                            )
                    }
                }
            } else {
                ZStack {
                    // Основной градиент для темной темы
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Радиальный градиент
                    RadialGradient(
                        colors: [Color.white.opacity(0.08), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 520
                    )
                    .blendMode(.screen)
                    
                    // Анимированный shimmer эффект для темной темы
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * 400)
                    .blendMode(.overlay)
                    
                    // Плавающие световые пятна для темной темы
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.primary.opacity(0.08))
                            .frame(width: 240, height: 240)
                            .position(
                                x: CGFloat(120 + i * 180),
                                y: CGFloat(180 + i * 120)
                            )
                            .scaleEffect(pulseAnimation ? 1.3 : 0.7)
                            .opacity(pulseAnimation ? 0.8 : 0.4)
                            .animation(
                                .easeInOut(duration: 4.0 + Double(i) * 0.7)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.4),
                                value: pulseAnimation
                            )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: Animation Functions
    
    private func startShimmerAnimation() {
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            shimmerOffset = 1
        }
    }
    
    private func createFloatingElements() {
        floatingElements = (0..<5).map { _ in
            FloatingElement(
                x: Double.random(in: 50...350),
                y: Double.random(in: 100...600),
                opacity: Double.random(in: 0.3...0.7),
                scale: Double.random(in: 0.8...1.2),
                rotation: Double.random(in: 0...360)
            )
        }
    }

    // MARK: Components

    private struct FeatureBadge: View {
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
    
    private struct EnhancedPlanRow: View {
        let title: String
        let price: String
        let originalPrice: String?
        let tagText: String?
        let savings: String?
        let selected: Bool
        let delay: Double
        @Environment(\.colorScheme) private var scheme
        @State private var show = false

        var body: some View {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Чекбокс
                ZStack {
                    Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 24, height: 24)
                        
                    if selected {
                        Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(scheme == .light ? .white : .black)
                            .padding(6)
                                .background(
                                    Circle()
                                        .fill(Color.primary)
                                )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(width: 28)

                    // Контент
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if let tag = tagText {
                                Text(tag)
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.primary)
                                    )
                                    .foregroundColor(scheme == .light ? .white : .black)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Text(price)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            if let original = originalPrice {
                                Text(original)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .strikethrough()
                            }
                            
                Spacer()
                            
                            if let savings = savings {
                                Text(savings)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                        .background(
                            Capsule()
                                            .fill(Color.green.opacity(0.1))
                        )
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            .overlay(
                        RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        selected
                                ? AnyShapeStyle(Color.primary)
                                : AnyShapeStyle(Color.primary.opacity(0.1)),
                        lineWidth: selected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: Color.black.opacity(scheme == .light ? 0.08 : 0.3),
                radius: selected ? 15 : 8,
                y: selected ? 10 : 5
            )
            .scaleEffect(selected ? 1.02 : 1.0)
            .scaleEffect(show ? 1.0 : 0.9)
            .opacity(show ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: show)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selected)
            .onAppear { show = true }
        }
    }

}
