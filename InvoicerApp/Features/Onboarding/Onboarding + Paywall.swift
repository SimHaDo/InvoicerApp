//
//  Onboarding + Paywall.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.
//

import SwiftUI
import StoreKit

// MARK: - Particle System
struct Particle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var opacity: Double
    var scale: Double
    var rotation: Double
    var velocity: CGSize
}

// MARK: - Onboarding

struct OnboardingView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var scheme

    @State private var page = 0
    @State private var appear = false
    @State private var showCelebration = false
    @State private var particles: [Particle] = []
    @Namespace private var heroNS

    private let privacyURL = URL(string: "https://simhado.github.io/invoice-maker-pro-site/privacy.html")!
    private let termsURL   = URL(string: "https://simhado.github.io/invoice-maker-pro-site/terms.html")!
    
    // Animation timers
    @State private var pulseAnimation = false
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        ZStack {
            backgroundView
            
            // Particles for effect
            ForEach(particles) { particle in
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.6), .purple.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 4, height: 4)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(x: particle.x, y: particle.y)
                    .animation(.easeOut(duration: 2.0), value: particle.opacity)
            }

            VStack(spacing: 0) {
                // Page content with improved animations
                TabView(selection: $page) {
                    OBPage(
                        title: "Create pro invoices in minutes",
                        subtitle: "Add your company, pick a template, share the PDF. No fluff — just invoices.",
                        art: AnyView(OBArtInvoice()),
                        pageIndex: 0,
                        currentPage: page
                    )
                    .tag(0)

                    OBPage(
                        title: "30+ stunning templates",
                        subtitle: "Modern, minimal, classic. Tweak colors, add logo, and stand out.",
                        art: AnyView(OBArtTemplates()),
                        pageIndex: 1,
                        currentPage: page
                    )
                    .tag(1)

                    OBPage(
                        title: "Smarter workflow",
                        subtitle: "Saved products, customers, and payment details. Auto totals, currencies.",
                        art: AnyView(OBArtworkFlow()),
                        pageIndex: 2,
                        currentPage: page
                    )
                    .tag(2)

                    PaywallScreen(onClose: finishOnboarding)
                        .environmentObject(subscriptionManager)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Dots + Footer with improved animations
                VStack(spacing: 28) {
                    FancyDots(count: 4, index: page)
                        .padding(.top, 8)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appear)

                    FooterLinks(
                        onRestore: { Task { try? await subscriptionManager.restorePurchases() } },
                        onPrivacy: { openURL(privacyURL) },
                        onTerms:   { openURL(termsURL) }
                    )
                }
                .padding(.bottom, 32)
            }

            // Floating Next / Continue button with improved effects
            if page < 3 {
                FAB(isLast: page == 3, showCelebration: showCelebration) {
                    let h = UIImpactFeedbackGenerator(style: .medium)
                    h.impactOccurred()
                    
                    // Page transition
                    page += 1
                    createParticles()
                }
            }
        }
        .onAppear { 
            appear = true
            pulseAnimation = true
            startShimmerAnimation()
        }
    }

    // MARK: Background (Light / Dark) with improved effects

    private var backgroundView: some View {
        Group {
            if scheme == .light {
                ZStack {
                    // Main gradient
                    LinearGradient(
                        colors: [Color.white, Color(white: 0.97), Color(white: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Radial gradient with animation
                    RadialGradient(
                        colors: [Color.white, Color(white: 0.96), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 520
                    )
                    .blendMode(.screen)
                    
                    // Animated shimmer effect
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * 400)
                    .blendMode(.overlay)
                    
                    // Floating light spots
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
                    // Main gradient для темной темы
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Радиальный градиент
                    RadialGradient(
                        colors: [Color.white.opacity(0.08), .clear],
                        center: .topLeading,
                        startRadius: 30,
                        endRadius: 640
                    )
                    .blendMode(.overlay)
                    
                    // Animated shimmer effect для темной темы
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * 400)
                    .blendMode(.overlay)
                    
                    // Floating light spots для темной темы
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
    
    // MARK: Animation functions
    
    private func createParticles() {
        let newParticles = (0..<8).map { _ in
            Particle(
                x: Double.random(in: 100...300),
                y: Double.random(in: 200...400),
                opacity: 1.0,
                scale: Double.random(in: 0.5...1.5),
                rotation: Double.random(in: 0...360),
                velocity: CGSize(
                    width: Double.random(in: -50...50),
                    height: Double.random(in: -50...50)
                )
            )
        }
        
        particles.append(contentsOf: newParticles)
        
        // Remove particles after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            particles.removeAll { particle in
                newParticles.contains { $0.id == particle.id }
            }
        }
    }
    
    private func startShimmerAnimation() {
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            shimmerOffset = 1
        }
    }

    // MARK: Finish

    private func finishOnboarding() {
        let n = UINotificationFeedbackGenerator()
        n.notificationOccurred(.success)
        
        // Create celebration effect
        showCelebration = true
        createParticles()
        
        // Delay before completing onboarding
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            app.markOnboardingCompleted()
        }
    }
}

// MARK: - Floating Action Button (Next / Continue)

private struct FAB: View {
    let isLast: Bool
    let showCelebration: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme
    @State private var pulse = false
    @State private var celebrationScale: CGFloat = 1.0
    @State private var celebrationRotation: Double = 0

    var body: some View {
        Button(action: action) {
            ZStack {
                // Внешнее кольцо
                Circle()
                    .stroke(Color.primary.opacity(0.3), lineWidth: 2.5)
                    .frame(width: 64, height: 64)
                    .opacity(0.7)
                    .scaleEffect(celebrationScale)
                    .rotationEffect(.degrees(celebrationRotation))
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: celebrationScale)

                // Внутреннее кольцо
                Circle()
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 58, height: 58)
                    .opacity(0.8)

                // Основная кнопка
                Circle()
                    .fill(isLast ? Color.green : Color.primary)
                    .frame(width: 52, height: 52)
                    .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)
                    .scaleEffect(pulse ? 1.0 : 0.96)
                    .scaleEffect(showCelebration ? 1.05 : 1.0)

                // Иконка
                Image(systemName: isLast ? "checkmark" : "arrow.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(scheme == .light ? .white : .black)
                    .scaleEffect(isLast ? 1.05 : 1.0)
                    .scaleEffect(showCelebration ? 1.1 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isLast)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showCelebration)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .accessibilityLabel(isLast ? "Continue" : "Next")
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                celebrationScale = 1.1
            }
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                celebrationRotation = 360
            }
        }
        .onChange(of: showCelebration) { celebrating in
            if celebrating {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    celebrationScale = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                        celebrationScale = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Footer (Restore / Privacy / Terms)

private struct FooterLinks: View {
    let onRestore: () -> Void
    let onPrivacy: () -> Void
    let onTerms: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button("Restore", action: onRestore)
            Bullet()
            Button("Privacy Policy", action: onPrivacy)
            Bullet()
            Button("Terms of Use", action: onTerms)
        }
        .font(.footnote)
        .tint(.secondary)
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().stroke(Color.primary.opacity(0.06))
        )
    }
}

private struct Bullet: View {
    var body: some View {
        Circle()
            .fill(Color.secondary.opacity(0.6))
            .frame(width: 3, height: 3)
    }
}

// MARK: - Fancy Dots

private struct FancyDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i == index ? Color.primary : Color.gray.opacity(0.35))
                    .frame(width: i == index ? 18 : 6, height: 6)
                    .overlay(
                        Group {
                            if i == index {
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.primary.opacity(0.35), lineWidth: 0.5)
                            }
                        }
                    )
            }
        }
    }
}

// MARK: - Pages

private struct OBPage: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let subtitle: String
    let art: AnyView
    let pageIndex: Int
    let currentPage: Int
    @State private var show = false
    @State private var titleOffset: CGFloat = 30
    @State private var subtitleOffset: CGFloat = 20
    @State private var artRotation: Double = 0
    @State private var artScale: CGFloat = 0.8

    var body: some View {
        GeometryReader { geometry in
            let isSmallScreen = geometry.size.height < 700
            let artHeight: CGFloat = isSmallScreen ? 180 : 220
            let titleSize: CGFloat = isSmallScreen ? 22 : 26
            let subtitleSize: CGFloat = isSmallScreen ? 15 : 17
            let spacing: CGFloat = isSmallScreen ? 48 : 56
            
            VStack(spacing: spacing) {
                Spacer(minLength: isSmallScreen ? 8 : 12)

                // Анимированное искусство
                art
                    .frame(maxWidth: .infinity)
                    .frame(height: artHeight)
                    .padding(.horizontal, isSmallScreen ? 20 : 32)
                    .scaleEffect(show ? artScale : 0.8)
                    .opacity(show ? 1 : 0)
                    .rotationEffect(.degrees(artRotation))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: show)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: artScale)
                    .animation(.easeInOut(duration: 0.5), value: artRotation)

                // Анимированный текст
                VStack(spacing: isSmallScreen ? 16 : 20) {
                    Text(title)
                        .font(.system(size: titleSize, weight: .black))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                        .offset(y: show ? 0 : titleOffset)
                        .opacity(show ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2), value: show)
                    
                    Text(subtitle)
                        .font(.system(size: subtitleSize, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, isSmallScreen ? 28 : 36)
                        .lineSpacing(2)
                        .shadow(color: .black.opacity(0.05), radius: 1, y: 0.5)
                        .offset(y: show ? 0 : subtitleOffset)
                        .opacity(show ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: show)
                }

                Spacer(minLength: isSmallScreen ? 20 : 30)
            }
            .foregroundColor(scheme == .light ? .black : .white)
            .padding(.vertical, isSmallScreen ? 12 : 16)
        }
        .onAppear { 
            show = true
            artScale = 1.0
            artRotation = 0
        }
        .onDisappear { 
            show = false
            artScale = 0.8
        }
        .onChange(of: currentPage) { newPage in
            if newPage == pageIndex {
                // Анимация входа на страницу
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    artScale = 1.0
                }
                withAnimation(.easeInOut(duration: 0.8)) {
                    artRotation = 0
                }
            } else {
                // Анимация выхода со страницы
                withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                    artScale = 0.9
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    artRotation = Double.random(in: -5...5)
                }
            }
        }
    }
}

// MARK: - Simple artworks (performance-friendly)

private struct OBArtInvoice: View {
    @Environment(\.colorScheme) private var scheme
    @State private var invoiceScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Основной инвойс
            RoundedRectangle(cornerRadius: 24)
                .fill(scheme == .light ? Color.black.opacity(0.03) : Color.white.opacity(0.06))
                .scaleEffect(invoiceScale)
                .shadow(color: Color.black.opacity(scheme == .light ? 0.08 : 0.3), radius: 30, y: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                )

            // Содержимое инвойса
            VStack(spacing: 12) {
                // Заголовок инвойса
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ACME Corp")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(scheme == .light ? .black : .white)
                        Text("123 Business St")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(scheme == .light ? .black.opacity(0.6) : .white.opacity(0.7))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("INVOICE")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(scheme == .light ? .black : .white)
                        Text("#INV-2024-001")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(scheme == .light ? .black.opacity(0.7) : .white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 16).padding(.top, 16)

                // Строки инвойса
                VStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(index == 0 ? "Web Design Services" : 
                                     index == 1 ? "Logo Design" : 
                                     index == 2 ? "Brand Guidelines" : "Consultation")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(scheme == .light ? .black : .white)
                                if index == 0 {
                                    Text("Complete website redesign")
                                        .font(.system(size: 9, weight: .regular))
                                        .foregroundColor(scheme == .light ? .black.opacity(0.5) : .white.opacity(0.6))
                                }
                            }
                            Spacer()
                            Text(index == 0 ? "$2,500" : 
                                 index == 1 ? "$800" : 
                                 index == 2 ? "$1,200" : "$500")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(scheme == .light ? .black : .white)
                        }
                        .padding(.horizontal, 16)
                    }
                }

                Spacer()

                // Итоговая строка
                HStack {
                    Text("TOTAL")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(scheme == .light ? .black : .white)
                    Spacer()
                    Text("$5,000")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(scheme == .light ? .black : .white)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scaleEffect(invoiceScale)
        }
        .padding(.horizontal, 16)
        .onAppear {
            // Анимация инвойса
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                invoiceScale = 1.02
            }
        }
    }
}


private struct OBArtTemplates: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { row in
                        let base = scheme == .light ? Color.black : Color.white
                        RoundedRectangle(cornerRadius: 14)
                            .fill(base.opacity((scheme == .light ? 0.05 : 0.06) + Double(row) * 0.03))
                            .frame(width: 90, height: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(scheme == .light ? 0.06 : 0.15))
                            )
                            .shadow(color: Color.black.opacity(scheme == .light ? 0.06 : 0.3),
                                    radius: 12, y: 6)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

private struct OBArtworkFlow: View {
    @Environment(\.colorScheme) private var scheme
    @State private var animateSteps = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(scheme == .light ? Color.black.opacity(0.03) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                )

            VStack(spacing: 12) {
                // Шаг 1: Company Setup
                WorkflowStep(
                    icon: "building.2",
                    title: "Company Setup",
                    description: "Add your business details",
                    isActive: animateSteps,
                    delay: 0.0
                )
                
                // Стрелка
                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .opacity(animateSteps ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.5).delay(0.3), value: animateSteps)
                
                // Шаг 2: Customer & Products
                WorkflowStep(
                    icon: "person.2",
                    title: "Customer & Products",
                    description: "Manage clients and items",
                    isActive: animateSteps,
                    delay: 0.2
                )
                
                // Стрелка
                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .opacity(animateSteps ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.5).delay(0.5), value: animateSteps)
                
                // Шаг 3: Generate & Share
                WorkflowStep(
                    icon: "doc.richtext",
                    title: "Generate & Share",
                    description: "Create PDF and send",
                    isActive: animateSteps,
                    delay: 0.4
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .shadow(color: Color.black.opacity(scheme == .light ? 0.08 : 0.3), radius: 30, y: 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateSteps = true
            }
        }
    }
}

private struct WorkflowStep: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let title: String
    let description: String
    let isActive: Bool
    let delay: Double
    @State private var show = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Иконка
            ZStack {
                Circle()
                    .fill(scheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .scaleEffect(show ? 1.0 : 0.8)
            .opacity(show ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: show)
            
            // Текст
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .offset(x: show ? 0 : 20)
            .opacity(show ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay + 0.1), value: show)
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            show = isActive
        }
        .onChange(of: isActive) { active in
            if active {
                show = true
            }
        }
    }
}
