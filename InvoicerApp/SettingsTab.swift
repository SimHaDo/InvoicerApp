//
//  SettingsTab.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

import SwiftUI

// MARK: - FloatingElement

private struct FloatingElement: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var opacity: Double
    var scale: Double
    var rotation: Double
}

struct SettingsTab: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var scheme
    
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var shimmerOffset: CGFloat = -1
    @State private var floatingElements: [FloatingElement] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // Анимированный фон
                backgroundView()
                
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: UI.largeSpacing) {
                        // Header с анимациями
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Settings")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.primary)
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                    .offset(y: showContent ? 0 : -20)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: showContent)
                                
                                Text("Manage your account and preferences")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .offset(y: showContent ? 0 : -15)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                            }
                            Spacer()
                        }
                        
                        // My Info Card
                        MyInfoCard()
                            .scaleEffect(showContent ? 1.0 : 0.9)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                        
                        // Account Card
                        AccountCard()
                            .scaleEffect(showContent ? 1.0 : 0.9)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                        
                        // Data Card
                        DataCard()
                            .scaleEffect(showContent ? 1.0 : 0.9)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showContent)
                        
                        // Support Card
                        SupportCard()
                            .scaleEffect(showContent ? 1.0 : 0.9)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: showContent)
                        
                        // Legal Card
                        LegalCard()
                            .scaleEffect(showContent ? 1.0 : 0.9)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: showContent)
                        
                        // About Card
                        AboutCard()
                            .scaleEffect(showContent ? 1.0 : 0.9)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: showContent)
                    }
                    .adaptiveContent()
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            showContent = true
            pulseAnimation = true
            startShimmerAnimation()
            createFloatingElements()
        }
    }
    
    // MARK: - Background View
    
    private func backgroundView() -> some View {
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
    
    // MARK: - Animation Functions
    
    private func startShimmerAnimation() {
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
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
}

// MARK: - Card Components

private struct MyInfoCard: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
                    NavigationLink {
            MyInfoView()
                            .environmentObject(app)
                    } label: {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "building.2")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Info")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Company details and logo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            // Company preview
                        HStack(spacing: 12) {
                // Logo preview
                            if let img = app.logoImage {
                                Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                                    .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                                if let c = app.company, !c.name.isEmpty {
                        Text(c.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.9))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                                    if !c.email.isEmpty {
                            Text(c.email)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary.opacity(0.6))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    } else {
                        Text("Set up your company")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.9))
                        
                        Text("Name, email, address, logo")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary.opacity(0.6))
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(scheme == .light ? 0.05 : 0.2), radius: 8, y: 4)
        )
        }
    }
}

private struct AccountCard: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Account")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Subscription and billing")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                    HStack {
                        Text("Pro Status")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                        Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(app.isPremium ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(app.isPremium ? "Active" : "Free")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(app.isPremium ? .green : .orange)
                    }
                    }

                Button {
                        Task { try? await SubscriptionManager.shared.restore() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("Restore Purchases")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.primary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(scheme == .light ? 0.05 : 0.2), radius: 8, y: 4)
        )
    }
}

private struct DataCard: View {
    @Environment(\.colorScheme) private var scheme
    @State private var showingExportSheet = false
    @State private var showingResetSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Data")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Export and manage your data")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                Button {
                    showingExportSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .medium))
                        Text("Export All Data")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.primary)
                }
                
                Button {
                    showingResetSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                        Text("Reset Local Data")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.red)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(scheme == .light ? 0.05 : 0.2), radius: 8, y: 4)
        )
        .navigationDestination(isPresented: $showingExportSheet) {
            ExportConfirmationView()
        }
        .sheet(isPresented: $showingResetSheet) {
            ResetConfirmationSheet()
        }
    }
}

private struct SupportCard: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Support")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Get help and feedback")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                Button {
                        if let url = URL(string: "mailto:dd925648@gmail.com") {
                            openURL(url)
                        }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope")
                            .font(.system(size: 14, weight: .medium))
                        Text("Contact Support")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.primary)
                }
                
                Button {
                        if let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID?action=write-review") {
                            openURL(url)
                        }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "star")
                            .font(.system(size: 14, weight: .medium))
                        Text("Rate on App Store")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.primary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(scheme == .light ? 0.05 : 0.2), radius: 8, y: 4)
        )
    }
}

private struct LegalCard: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Legal")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Privacy and terms")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                Button {
                        openURL(URL(string: "https://simhado.github.io/invoice-maker-pro-site/privacy.html")!)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.raised")
                            .font(.system(size: 14, weight: .medium))
                        Text("Privacy Policy")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.primary)
                }
                
                Button {
                        openURL(URL(string: "https://simhado.github.io/invoice-maker-pro-site/terms.html")!)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.plaintext")
                            .font(.system(size: 14, weight: .medium))
                        Text("Terms of Use")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.primary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(scheme == .light ? 0.05 : 0.2), radius: 8, y: 4)
        )
    }
}

private struct AboutCard: View {
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("About")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("App information")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
                    HStack {
                        Text("App Version")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                        Spacer()
                
                Text(Bundle.main.appVersion)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(scheme == .light ? 0.05 : 0.2), radius: 8, y: 4)
        )
    }
}

// MARK: - Helper
extension Bundle {
    var appVersion: String {
        let ver = infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(ver) (\(build))"
    }
}