//
//  Onboarding + Paywall.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.
//

import SwiftUI
import StoreKit

// MARK: - Onboarding

struct OnboardingView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var scheme

    @State private var page = 0
    @State private var appear = false
    @Namespace private var dotsNS

    private let privacyURL = URL(string: "https://simhado.github.io/invoice-maker-pro-site/privacy.html")!
    private let termsURL   = URL(string: "https://simhado.github.io/invoice-maker-pro-site/terms.html")!

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 0) {
                // Контент страниц
                TabView(selection: $page) {
                    OBPage(
                        title: "Create pro invoices in minutes",
                        subtitle: "Add your company, pick a template, share the PDF. No fluff — just invoices.",
                        art: AnyView(OBArtInvoice())
                    )
                    .tag(0)

                    OBPage(
                        title: "30+ stunning templates",
                        subtitle: "Modern, minimal, classic. Tweak colors, add logo, and stand out.",
                        art: AnyView(OBArtTemplates())
                    )
                    .tag(1)

                    OBPage(
                        title: "Smarter workflow",
                        subtitle: "Saved products, customers, and payment details. Auto totals, currencies.",
                        art: AnyView(OBArtworkFlow())
                    )
                    .tag(2)

                    PaywallScreen(onClose: finishOnboarding)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: page)

                // Dots + Footer
                VStack(spacing: 22) {
                    FancyDots(count: 4, index: page, namespace: dotsNS)
                        .padding(.top, 8)

                    FooterLinks(
                        onRestore: { Task { try? await SubscriptionManager.shared.restore() } },
                        onPrivacy: { openURL(privacyURL) },
                        onTerms:   { openURL(termsURL) }
                    )
                }
                .padding(.bottom, 28)
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.35).delay(0.15), value: appear)
            }

            // Плавающая кнопка Next / Continue
            FAB(isLast: page == 3) {
                let h = UIImpactFeedbackGenerator(style: .soft)
                h.impactOccurred()
                if page < 3 {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                        page += 1
                    }
                } else {
                    finishOnboarding()
                }
            }
        }
        .onAppear { appear = true }
    }

    // MARK: Background (Light / Dark)

    private var backgroundView: some View {
        Group {
            if scheme == .light {
                ZStack {
                    LinearGradient(
                        colors: [Color.white, Color(white: 0.97), Color(white: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [Color.white, Color(white: 0.96), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 520
                    )
                    .blendMode(.screen)
                }
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [Color.white.opacity(0.08), .clear],
                        center: .topLeading,
                        startRadius: 30,
                        endRadius: 640
                    )
                    .blendMode(.overlay)
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: Finish

    private func finishOnboarding() {
        let n = UINotificationFeedbackGenerator()
        n.notificationOccurred(.success)
        app.markOnboardingCompleted()
    }
}

// MARK: - Floating Action Button (Next / Continue)

private struct FAB: View {
    let isLast: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Светящееся кольцо
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .blue]),
                            center: .center
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 64, height: 64)
                    .opacity(0.9)
                    .blur(radius: 0.5)

                // Кнопка
                Circle()
                    .fill(scheme == .light ? Color.black : Color.white)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.black.opacity(0.22), radius: 10, y: 6)
                    .scaleEffect(pulse ? 1.0 : 0.98)

                Image(systemName: isLast ? "checkmark" : "arrow.right")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(scheme == .light ? .white : .black)
                    .scaleEffect(isLast ? 1.06 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isLast)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing, 24)
        .padding(.bottom, 68)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .accessibilityLabel(isLast ? "Continue" : "Next")
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
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
        .tint(.blue)
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
    var namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i == index ? Color.blue : Color.gray.opacity(0.35))
                    .frame(width: i == index ? 18 : 6, height: 6)
                    .overlay(
                        Group {
                            if i == index {
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.blue.opacity(0.35), lineWidth: 0.5)
                                    .matchedGeometryEffect(id: "dot", in: namespace)
                            }
                        }
                    )
                    .animation(.spring(response: 0.45, dampingFraction: 0.7), value: index)
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
    @State private var show = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 24)

            art
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .padding(.horizontal, 20)
                .scaleEffect(show ? 1.0 : 0.96)
                .opacity(show ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: show)

            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 28, weight: .heavy))
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .offset(y: show ? 0 : 12)
            .opacity(show ? 1 : 0)
            .animation(.easeOut(duration: 0.35).delay(0.05), value: show)

            Spacer()
        }
        .foregroundColor(scheme == .light ? .black : .white)
        .padding(.vertical, 16)
        .onAppear { show = true }
        .onDisappear { show = false }
    }
}

// MARK: - Simple artworks (performance-friendly)

private struct OBArtInvoice: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(scheme == .light ? Color.black.opacity(0.03) : Color.white.opacity(0.06))

            VStack(spacing: 12) {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(scheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.12))
                        .frame(width: 100, height: 22)
                    Spacer()
                    RoundedRectangle(cornerRadius: 8)
                        .fill(scheme == .light ? Color.black.opacity(0.12) : Color.white.opacity(0.3))
                        .frame(width: 80, height: 22)
                }
                .padding(.horizontal, 16).padding(.top, 16)

                ForEach(0..<5, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(scheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.12))
                            .frame(height: 16)
                        Spacer()
                        RoundedRectangle(cornerRadius: 6)
                            .fill(scheme == .light ? Color.black.opacity(0.12) : Color.white.opacity(0.25))
                            .frame(width: 80, height: 16)
                    }
                    .padding(.horizontal, 16)
                }

                Spacer()

                RoundedRectangle(cornerRadius: 16)
                    .fill(scheme == .light ? Color.black.opacity(0.12) : Color.white.opacity(0.25))
                    .frame(height: 56)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .shadow(color: Color.black.opacity(scheme == .light ? 0.08 : 0.3), radius: 30, y: 12)
        .padding(.horizontal, 16)
        .overlay(
            LinearGradient(colors: [.blue, .purple],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .mask(RoundedRectangle(cornerRadius: 24)
                    .stroke(style: .init(lineWidth: 2)))
        )
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
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill( (scheme == .light ? Color.black : Color.white).opacity(0.05) )

            VStack(spacing: 18) {
                Node(text: "Company")
                    .offset(x: -99, y: -30)
                Connector()
                Node(text: "Customer")
                Connector()
                Node(text: "PDF • Share")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 14, y: 8)
    }
}

private struct Node: View {
    @Environment(\.colorScheme) private var scheme
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill( (scheme == .light ? Color.black : Color.white).opacity(0.12) )
            )
    }
}

private struct Connector: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Image(systemName: "arrow.down")
            .font(.headline)
            .foregroundColor(scheme == .light ? Color.secondary : Color.white.opacity(0.75))
            .transition(.scale.combined(with: .opacity))
    }
}
