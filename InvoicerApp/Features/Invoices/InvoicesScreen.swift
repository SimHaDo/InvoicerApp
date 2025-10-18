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

// MARK: - Sorting Options

enum InvoiceSortOption: String, CaseIterable, Identifiable {
    case newestFirst = "newest_first"
    case oldestFirst = "oldest_first"
    case amountHighToLow = "amount_high_to_low"
    case amountLowToHigh = "amount_low_to_high"
    case customerNameAZ = "customer_name_az"
    case customerNameZA = "customer_name_za"
    case status = "status"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .newestFirst: return "Newest First"
        case .oldestFirst: return "Oldest First"
        case .amountHighToLow: return "Amount: High to Low"
        case .amountLowToHigh: return "Amount: Low to High"
        case .customerNameAZ: return "Customer: A to Z"
        case .customerNameZA: return "Customer: Z to A"
        case .status: return "Status"
        }
    }
    
    var icon: String {
        switch self {
        case .newestFirst: return "arrow.down.circle"
        case .oldestFirst: return "arrow.up.circle"
        case .amountHighToLow: return "arrow.down.square"
        case .amountLowToHigh: return "arrow.up.square"
        case .customerNameAZ: return "textformat.abc"
        case .customerNameZA: return "textformat.abc"
        case .status: return "circle.grid.2x2"
        }
    }
}

// MARK: - ViewModel

final class InvoicesVM: ObservableObject {
    @Published var query = ""
    @Published var sortOption: InvoiceSortOption = .newestFirst

    func filtered(_ invoices: [Invoice]) -> [Invoice] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return sorted(invoices) }
        let filtered = invoices.filter {
            $0.number.lowercased().contains(q) ||
            $0.customer.name.lowercased().contains(q)
        }
        return sorted(filtered)
    }
    
    func sorted(_ invoices: [Invoice]) -> [Invoice] {
        switch sortOption {
        case .newestFirst:
            return invoices.sorted { (invoice1: Invoice, invoice2: Invoice) in
                invoice1.issueDate > invoice2.issueDate
            }
        case .oldestFirst:
            return invoices.sorted { (invoice1: Invoice, invoice2: Invoice) in
                invoice1.issueDate < invoice2.issueDate
            }
        case .amountHighToLow:
            return invoices.sorted { (invoice1: Invoice, invoice2: Invoice) in
                invoice1.total > invoice2.total
            }
        case .amountLowToHigh:
            return invoices.sorted { (invoice1: Invoice, invoice2: Invoice) in
                invoice1.total < invoice2.total
            }
        case .customerNameAZ:
            return invoices.sorted { (invoice1: Invoice, invoice2: Invoice) in
                invoice1.customer.name < invoice2.customer.name
            }
        case .customerNameZA:
            return invoices.sorted { (invoice1: Invoice, invoice2: Invoice) in
                invoice1.customer.name > invoice2.customer.name
            }
        case .status:
            return invoices.sorted { (invoice1: Invoice, invoice2: Invoice) in
                invoice1.status.rawValue < invoice2.status.rawValue
            }
        }
    }

    func totalOutstanding(_ invoices: [Invoice]) -> Decimal {
        invoices.filter { $0.status != .paid }.map(\.total).reduce(0, +)
    }

    func totalPaid(_ invoices: [Invoice]) -> Decimal {
        invoices.filter { $0.status == .paid }.map(\.total).reduce(0, +)
    }
}

// MARK: - Screen

struct InvoicesScreen: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var vm = InvoicesVM()
    @Environment(\.colorScheme) private var scheme

    @State private var showInvoiceCreation = false // Unified state for full-screen flow
    @State private var showPaywall = false
    @State private var floatingElements: [FloatingElement] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // Анимированный фон
                backgroundView()
                
                // Плавающие элементы (статичные)
                ForEach(floatingElements) { element in
                    Circle()
                        .fill(
                            scheme == .dark ? 
                            UI.darkAccent.opacity(0.1) : 
                            Color.primary.opacity(0.05)
                        )
                        .frame(width: 40, height: 40)
                        .scaleEffect(element.scale)
                        .opacity(element.opacity)
                        .rotationEffect(.degrees(element.rotation))
                        .position(x: element.x, y: element.y)
                }
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: UI.largeSpacing) {
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
                .adaptiveContent()
                .padding(.top, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: onNewInvoice) {
                Image(systemName: subscriptionManager.isPro ? "plus.circle.fill" : "lock.circle")
                    .imageScale(.large)
            })
        }
        .onAppear {
            createFloatingElements()
        }
            .fullScreenCover(isPresented: $showInvoiceCreation) {
                InvoiceCreationFlow(onClose: {
                    showInvoiceCreation = false
                })
                    .environmentObject(app)
            }
            // Paywall
            .sheet(isPresented: $showPaywall) {
                PaywallScreen(onClose: {
                    showPaywall = false
                })
                .environmentObject(subscriptionManager)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToMyInfo"))) { _ in
                // Close the invoice creation flow when navigating to MyInfo
                showInvoiceCreation = false
            }
        }
    }

    // MARK: - Actions

    private func onNewInvoice() {
        // если нет подписки — показываем paywall
        guard subscriptionManager.isPro else {
            showPaywall = true
            return
        }
        // Открываем полноэкранный флоу создания инвойса
        showInvoiceCreation = true
    }

    // MARK: - Sections

    private var screenHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Invoices")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: scheme == .dark ? [UI.darkText, UI.darkAccent] : [.primary, .accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: scheme == .dark ? UI.darkAccent.opacity(0.3) : .black.opacity(0.1), radius: 2, y: 1)
                
                Text("Manage all your invoices")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(scheme == .dark ? UI.darkSecondaryText : .secondary)
            }
            Spacer()
            
            // App Logo (справа от заголовка, выровнен по центру)
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 160, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .if(scheme == .dark) { view in
                    view.colorInvert()
                }
                .shadow(
                    color: scheme == .dark ? UI.darkAccent.opacity(0.4) : .black.opacity(0.2), 
                    radius: 8, 
                    y: 4
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            scheme == .dark ? UI.darkAccent.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
            
            if subscriptionManager.isPro { 
                PremiumBadge()
            }
        }
    }

    private var headerCard: some View {
        Group {
            if subscriptionManager.isPro {
                // карточка быстрого создания
                QuickCreateCard(newAction: onNewInvoice)
                    .padding(.top, 2)
            } else {
                PremiumFeatureView(
                    isPremium: subscriptionManager.isPro,
                    title: "Unlimited Invoices",
                    description: "Create unlimited professional invoices with premium templates and advanced features.",
                    icon: "doc.richtext.fill",
                    onUpgrade: { showPaywall = true }
                ) {
                    QuickCreateCard(newAction: onNewInvoice)
                        .padding(.top, 2)
                }
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
        HStack(spacing: 12) {
            SearchBar(text: $vm.query)
            
            // Кнопка сортировки
            Menu {
                ForEach(InvoiceSortOption.allCases) { option in
                    Button(action: {
                        vm.sortOption = option
                    }) {
                        HStack {
                            Image(systemName: option.icon)
                            Text(option.title)
                            if vm.sortOption == option {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: vm.sortOption.icon)
                        .font(.system(size: 16, weight: .medium))
                    Text("Sort")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.top, 2)
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
                        Image(systemName: subscriptionManager.isPro ? "plus.circle" : "lock.circle")
                            .font(.system(size: 36))
                    }
                    Text("No invoices yet").font(.headline)
                    Text(subscriptionManager.isPro
                         ? "Create your first invoice to get started"
                         : "Upgrade to Pro to create unlimited invoices")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, minHeight: 150)

            // CTA снизу с новым дизайном
            if !subscriptionManager.isPro {
                Button(action: { showPaywall = true }) {
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
                    
                    // Статичный shimmer эффект
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .blendMode(.overlay)
                    
                    // Плавающие световые пятна (статичные)
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 200, height: 200)
                            .position(
                                x: CGFloat(100 + i * 150),
                                y: CGFloat(200 + i * 100)
                            )
                            .opacity(0.3)
                    }
                }
            } else {
                ZStack {
                    // Основной градиент для темной темы
                    LinearGradient(
                        colors: [UI.darkBackground, UI.darkGradientStart, UI.darkGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Радиальный градиент с акцентным цветом
                    RadialGradient(
                        colors: [UI.darkAccent.opacity(0.15), UI.darkAccentSecondary.opacity(0.08), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 520
                    )
                    .blendMode(.screen)
                    
                    // Статичный shimmer эффект для темной темы
                    LinearGradient(
                        colors: [.clear, UI.darkAccent.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .blendMode(.overlay)
                    
                    // Плавающие световые пятна для темной темы (статичные)
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [UI.darkAccent.opacity(0.2), UI.darkAccentSecondary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 240, height: 240)
                            .position(
                                x: CGFloat(120 + i * 180),
                                y: CGFloat(180 + i * 120)
                            )
                            .opacity(0.4)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Helper Functions
    
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

