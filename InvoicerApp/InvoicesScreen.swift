//
//  InvoicesScreen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
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

// MARK: - ViewModel

final class InvoicesVM: ObservableObject {
    @Published var query = ""

    func filtered(_ invoices: [Invoice]) -> [Invoice] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return invoices }
        return invoices.filter {
            $0.number.lowercased().contains(q) ||
            $0.customer.name.lowercased().contains(q)
        }
    }

    func totalOutstanding(_ invoices: [Invoice]) -> Decimal {
        invoices.filter { $0.status != .paid }.map(\.subtotal).reduce(0, +)
    }

    func totalPaid(_ invoices: [Invoice]) -> Decimal {
        invoices.filter { $0.status == .paid }.map(\.subtotal).reduce(0, +)
    }
}

// MARK: - Screen

struct InvoicesScreen: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var vm = InvoicesVM()
    @Environment(\.colorScheme) private var scheme

    @State private var showCompanySetup = false
    @State private var showTemplatePicker = false
    @State private var showEmptyPaywall = false
    @State private var showWizard = false
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
                    VStack(alignment: .leading, spacing: 20) {
                        screenHeader
                        headerCard
                        statsRow
                        searchField

                    if app.invoices.isEmpty {
                        emptyState
                    } else {
                        invoiceList
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onNewInvoice) {
                        Image(systemName: app.canCreateInvoice ? "plus.circle.fill" : "lock.circle")
                            .imageScale(.large)
                    }
                }
            }
        }
        .onAppear {
            showContent = true
            pulseAnimation = true
            startShimmerAnimation()
            createFloatingElements()
        }
            // 1) Company setup (если нет компании)
            .sheet(isPresented: $showCompanySetup) {
                CompanySetupView(onContinue: {
                    showCompanySetup = false
                    showTemplatePicker = true
                })
            }
            // 2) Template picker -> после выбора открываем визард
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerView { _ in
                    // закрываем пикер
                    showTemplatePicker = false
                    // открываем визард в следующем тике
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showWizard = true
                    }
                }
            }
            // 3) Визард создания инвойса
            .sheet(isPresented: $showWizard) {
                InvoiceWizardView()
            }
            // Paywall-заглушка
            .sheet(isPresented: $showEmptyPaywall) {
                EmptyScreen()
            }
        }
    }

    // MARK: - Actions

    private func onNewInvoice() {
        // если лимит исчерпан и нет подписки — показываем paywall
        guard app.canCreateInvoice else {
            showEmptyPaywall = true
            return
        }
        // если компания не настроена — сначала CompanySetup
        if app.company == nil {
            showCompanySetup = true
        } else {
            showTemplatePicker = true
        }
    }

    // MARK: - Sections

    private var screenHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Invoices")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.primary)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                    .offset(y: showContent ? 0 : -20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: showContent)
                
                Text("Manage all your invoices")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .offset(y: showContent ? 0 : -15)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
            }
            Spacer()
            if app.isPremium { 
                ProBadge()
                    .scaleEffect(showContent ? 1.0 : 0.9)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
            }
        }
    }

    private var headerCard: some View {
        Group {
            if app.isPremium {
                // карточка быстрого создания (если у тебя уже есть реальная реализация — она подставится)
                QuickCreateCard(newAction: onNewInvoice)
                    .padding(.top, 2)
            } else {
                FreePlanCardCompact(                    // ← карточка Free/Upgrade возвращена
                    remaining: app.remainingFreeInvoices,
                    onUpgrade: { showEmptyPaywall = true },
                    onCreate: onNewInvoice
                )
                .padding(.top, 2)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total Outstanding",
                value: Money.fmt(vm.totalOutstanding(app.invoices),
                                 code: app.invoices.first?.currency ?? app.currency),
                tint: .blue.opacity(0.15)
            )
            StatCard(
                title: "Total Paid",
                value: Money.fmt(vm.totalPaid(app.invoices),
                                 code: app.invoices.first?.currency ?? app.currency),
                tint: .green.opacity(0.15)
            )
        }
    }

    private var searchField: some View {
        SearchBar(text: $vm.query).padding(.top, 2)
    }

    private var invoiceList: some View {
        VStack(spacing: 10) {
            ForEach(vm.filtered(app.invoices)) { inv in
                NavigationLink { InvoiceDetailsView(invoice: inv) } label: {
                    InvoiceCard(invoice: inv) // твоя карточка счета
                }
            }
        }
        .padding(.top, 2)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.secondary.opacity(0.15))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondary.opacity(0.05))
                    )
                VStack(spacing: 10) {
                    Button(action: onNewInvoice) {
                        Image(systemName: app.canCreateInvoice ? "plus.circle" : "lock.circle")
                            .font(.system(size: 36))
                    }
                    Text("No invoices yet").font(.headline)
                    Text(app.isPremium
                         ? "Create your first invoice to get started"
                         : app.remainingFreeInvoices > 0
                            ? "You can create \(app.remainingFreeInvoices) free invoice."
                            : "Free limit reached. Upgrade to create more.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, minHeight: 150)

            // CTA снизу с новым дизайном
            if !app.isPremium {
                if app.remainingFreeInvoices == 0 {
                    Button(action: { showEmptyPaywall = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Upgrade to Create Invoice")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.primary)
                                .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)
                        )
                        .foregroundColor(scheme == .light ? .white : .black)
                    }
                    .scaleEffect(showContent ? 1.0 : 0.9)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: showContent)
                } else {
                    Button(action: onNewInvoice) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Create Invoice (\(app.remainingFreeInvoices) left)")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.primary)
                                .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)
                        )
                        .foregroundColor(scheme == .light ? .white : .black)
                    }
                    .scaleEffect(showContent ? 1.0 : 0.9)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: showContent)
                }
            }
        }
        .padding(.vertical, 6)
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

// MARK: - Small UI pieces used here

struct FreePlanCardCompact: View {
    @Environment(\.colorScheme) private var scheme
    let remaining: Int
    var onUpgrade: () -> Void
    var onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "crown")
                Text("Free Plan").bold()
                Spacer()
                Text(remaining > 0 ? "\(remaining) free left" : "Limit reached")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if remaining > 0 {
                HStack(spacing: 16) {
                    Button(action: onCreate) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Create Invoice")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.primary)
                                .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)
                        )
                        .foregroundColor(scheme == .light ? .white : .black)
                    }

                    Button(action: onUpgrade) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Upgrade")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.primary)
                    }
                }
            } else {
                Button(action: onUpgrade) {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Upgrade to Create Invoice")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primary)
                            .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)
                    )
                    .foregroundColor(scheme == .light ? .white : .black)
                }
            }

            HStack(spacing: 20) {
                Label("Unlimited invoices", systemImage: "checkmark")
                Label("Premium templates", systemImage: "checkmark")
                Label("Advanced features", systemImage: "checkmark")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.15))
        )
    }
}

struct EmptyScreen: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "crown.fill").font(.largeTitle)
                Text("Subscription Coming Soon").font(.title3).bold()
                Text("Upgrade to create unlimited invoices and unlock premium features.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Close") { }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                    .foregroundStyle(.white)
            }
            .padding()
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
