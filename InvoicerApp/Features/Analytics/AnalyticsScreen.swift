//
//  AnalyticsScreen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI
import Charts

// MARK: - FloatingElement

private struct FloatingElement: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var opacity: Double
    var scale: Double
    var rotation: Double
}

// MARK: - Analytics Data Models

struct RevenueData: Identifiable {
    let id = UUID()
    let month: String
    let revenue: Double
    let invoices: Int
}

struct CustomerSegment: Identifiable {
    let id = UUID()
    let name: String
    let revenue: Double
    let invoices: Int
    let percentage: Double
}

struct PaymentTrend: Identifiable {
    let id = UUID()
    let period: String
    let paid: Double
    let pending: Double
    let overdue: Double
}

// MARK: - ViewModel

final class AnalyticsVM: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var selectedTimeframe: TimeFrame = .month
    @Published var selectedMetric: MetricType = .revenue
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }
    
    enum MetricType: String, CaseIterable {
        case revenue = "Revenue"
        case invoices = "Invoices"
        case customers = "Customers"
        case payments = "Payments"
    }
    
    // MARK: - Basic Metrics (Free)
    
    func totalInvoices(_ invoices: [Invoice]) -> Int { 
        invoices.count 
    }

    func totalRevenue(_ invoices: [Invoice]) -> Decimal {
        invoices.filter { $0.status == .paid }.map(\.subtotal).reduce(0, +)
    }

    func paidInvoices(_ invoices: [Invoice]) -> Int {
        invoices.filter { $0.status == .paid }.count
    }
    
    func pendingInvoices(_ invoices: [Invoice]) -> Int {
        invoices.filter { $0.status == .draft }.count
    }
    
    func overdueInvoices(_ invoices: [Invoice]) -> Int {
        invoices.filter { $0.status == .overdue }.count
    }
    
    func uniqueClients(_ invoices: [Invoice]) -> Int {
        Set(invoices.map { $0.customer.id }).count
    }
    
    func avgInvoiceValue(_ invoices: [Invoice]) -> Decimal {
        guard !invoices.isEmpty else { return 0 }
        let total = invoices.map(\.subtotal).reduce(0, +)
        return total / Decimal(invoices.count)
    }
    
    // MARK: - Advanced Metrics (Premium)

    func paymentRate(_ invoices: [Invoice]) -> Double {
        guard !invoices.isEmpty else { return 0 }
        let paidCount = invoices.filter { $0.status == .paid }.count
        return Double(paidCount) / Double(invoices.count)
    }

    func revenueGrowth(_ invoices: [Invoice]) -> Double {
        let currentMonth = Calendar.current.date(byAdding: .month, value: 0, to: Date())!
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        
        let currentRevenue = invoices.filter { 
            $0.issueDate >= currentMonth && $0.status == .paid 
        }.map(\.subtotal).reduce(0, +)
        
        let previousRevenue = invoices.filter { 
            $0.issueDate >= previousMonth && $0.issueDate < currentMonth && $0.status == .paid 
        }.map(\.subtotal).reduce(0, +)
        
        guard previousRevenue > 0 else { return 0 }
        return Double(truncating: NSDecimalNumber(decimal: currentRevenue - previousRevenue)) / Double(truncating: NSDecimalNumber(decimal: previousRevenue)) * 100
    }
    
    func topCustomers(_ invoices: [Invoice]) -> [CustomerSegment] {
        let customerRevenue = Dictionary(grouping: invoices.filter { $0.status == .paid }) { $0.customer.id }
            .mapValues { invoices in
                (invoices.map(\.subtotal).reduce(0, +), invoices.count)
            }
        
        let totalRevenue = customerRevenue.values.map(\.0).reduce(0, +)
        
        return customerRevenue.compactMap { (customerId, data) in
            guard let customer = invoices.first(where: { $0.customer.id == customerId })?.customer else { return nil }
            let revenueDouble = Double(truncating: NSDecimalNumber(decimal: data.0))
            let totalRevenueDouble = Double(truncating: NSDecimalNumber(decimal: totalRevenue))
            return CustomerSegment(
                name: customer.name,
                revenue: revenueDouble,
                invoices: data.1,
                percentage: totalRevenue > 0 ? revenueDouble / totalRevenueDouble * 100 : 0
            )
        }.sorted { $0.revenue > $1.revenue }.prefix(5).map { $0 }
    }
    
    func monthlyRevenueData(_ invoices: [Invoice]) -> [RevenueData] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<6).compactMap { monthsBack in
            guard let monthStart = calendar.date(byAdding: .month, value: -monthsBack, to: now),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return nil }
            
            let monthInvoices = invoices.filter { 
                $0.issueDate >= monthStart && $0.issueDate < monthEnd && $0.status == .paid 
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            
            let revenue = monthInvoices.map(\.subtotal).reduce(0, +)
            return RevenueData(
                month: formatter.string(from: monthStart),
                revenue: Double(truncating: NSDecimalNumber(decimal: revenue)),
                invoices: monthInvoices.count
            )
        }.reversed()
    }
    
    func paymentTrends(_ invoices: [Invoice]) -> [PaymentTrend] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<4).compactMap { weeksBack in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: now),
                  let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { return nil }
            
            let weekInvoices = invoices.filter { 
                $0.issueDate >= weekStart && $0.issueDate < weekEnd 
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            
            let paidRevenue = weekInvoices.filter { $0.status == .paid }.map(\.subtotal).reduce(0, +)
            let pendingRevenue = weekInvoices.filter { $0.status == .draft }.map(\.subtotal).reduce(0, +)
            let overdueRevenue = weekInvoices.filter { $0.status == .overdue }.map(\.subtotal).reduce(0, +)
            
            return PaymentTrend(
                period: formatter.string(from: weekStart),
                paid: Double(truncating: NSDecimalNumber(decimal: paidRevenue)),
                pending: Double(truncating: NSDecimalNumber(decimal: pendingRevenue)),
                overdue: Double(truncating: NSDecimalNumber(decimal: overdueRevenue))
            )
        }.reversed()
    }
    
    func invoiceVelocity(_ invoices: [Invoice]) -> Double {
        guard invoices.count > 1 else { return 0 }
        let sortedInvoices = invoices.sorted { $0.issueDate < $1.issueDate }
        let firstDate = sortedInvoices.first!.issueDate
        let lastDate = sortedInvoices.last!.issueDate
        let daysBetween = Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 1
        return Double(invoices.count) / Double(daysBetween) * 30 // invoices per month
    }
    
    func customerLifetimeValue(_ invoices: [Invoice]) -> Decimal {
        let customerRevenue = Dictionary(grouping: invoices.filter { $0.status == .paid }) { $0.customer.id }
            .mapValues { invoices in invoices.map(\.subtotal).reduce(0, +) }
        
        guard !customerRevenue.isEmpty else { return 0 }
        let totalRevenue = customerRevenue.values.reduce(0, +)
        return totalRevenue / Decimal(customerRevenue.count)
    }
}

// MARK: - Screen

struct AnalyticsScreen: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var vm = AnalyticsVM()
    @Environment(\.colorScheme) private var scheme
    
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var shimmerOffset: CGFloat = -1
    @State private var floatingElements: [FloatingElement] = []
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
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
                
            ScrollView {
                    VStack(alignment: .leading, spacing: UI.largeSpacing) {
                        // Header с анимациями
                        headerView
                        
                        // Timeframe Selector (Premium)
                        if vm.isPremium {
                            timeframeSelector
                        }
                        
                        // Free Metrics
                        freeMetricsSection
                        
                        // Premium Metrics
                if vm.isPremium {
                            premiumMetricsSection
                } else {
                            premiumUpgradeSection
                        }
                    }
                    .adaptiveContent()
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showPaywall) {
            // PaywallScreen would go here
        }
        .onAppear {
            showContent = true
            pulseAnimation = true
            startShimmerAnimation()
            createFloatingElements()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Analytics")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.primary)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                    .offset(y: showContent ? 0 : -20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: showContent)
                
                Text("Track your business performance")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .offset(y: showContent ? 0 : -15)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
            }
            Spacer()
            
                    if !vm.isPremium {
                Button(action: { showPaywall = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Premium")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primary)
                    )
                    .foregroundColor(scheme == .light ? .white : .black)
                }
                .scaleEffect(showContent ? 1.0 : 0.9)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
            }
        }
    }
    
    // MARK: - Timeframe Selector (Premium)
    
    private var timeframeSelector: some View {
        HStack(spacing: 12) {
            ForEach(AnalyticsVM.TimeFrame.allCases, id: \.self) { timeframe in
                Button(action: { vm.selectedTimeframe = timeframe }) {
                    Text(timeframe.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(vm.selectedTimeframe == timeframe ? Color.primary : Color.clear)
                        )
                        .foregroundColor(vm.selectedTimeframe == timeframe ? (scheme == .light ? .white : .black) : .primary)
                }
            }
        }
        .padding(.horizontal, 4)
        .offset(y: showContent ? 0 : -10)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
    }
    
    // MARK: - Free Metrics Section
    
    private var freeMetricsSection: some View {
        VStack(spacing: 16) {
            // Main Stats Cards
            HStack(spacing: 12) {
                AnalyticsStatCard(
                    title: "Total Invoices",
                    value: String(vm.totalInvoices(app.invoices)),
                    subtitle: "\(vm.paidInvoices(app.invoices)) paid",
                    icon: "doc.text",
                    tint: .blue,
                    isPremium: false
                )
                
                AnalyticsStatCard(
                    title: "Total Revenue",
                    value: Money.fmt(vm.totalRevenue(app.invoices), code: app.currency),
                    subtitle: "From paid invoices",
                    icon: "dollarsign.circle",
                    tint: .green,
                    isPremium: false
                )
            }
            
            // Secondary Stats
            HStack(spacing: 12) {
                AnalyticsStatCard(
                    title: "Unique Clients",
                    value: String(vm.uniqueClients(app.invoices)),
                    subtitle: "Active customers",
                    icon: "person.2",
                    tint: .purple,
                    isPremium: false
                )
                
                AnalyticsStatCard(
                    title: "Avg Invoice",
                    value: Money.fmt(vm.avgInvoiceValue(app.invoices), code: app.currency),
                    subtitle: "Per invoice",
                    icon: "chart.bar",
                    tint: .orange,
                    isPremium: false
                )
            }
            
            // Status Breakdown
            HStack(spacing: 12) {
                StatusCard(
                    title: "Paid",
                    count: vm.paidInvoices(app.invoices),
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                StatusCard(
                    title: "Pending",
                    count: vm.pendingInvoices(app.invoices),
                    color: .blue,
                    icon: "clock.fill"
                )
                
                StatusCard(
                    title: "Overdue",
                    count: vm.overdueInvoices(app.invoices),
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
        .offset(y: showContent ? 0 : 20)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showContent)
    }
    
    // MARK: - Premium Metrics Section
    
    private var premiumMetricsSection: some View {
        VStack(spacing: 20) {
            // Revenue Growth Card
            RevenueGrowthCard(
                growth: vm.revenueGrowth(app.invoices),
                currentRevenue: vm.totalRevenue(app.invoices),
                currency: app.currency
            )
            
            // Revenue Chart
            RevenueChartCard(
                data: vm.monthlyRevenueData(app.invoices),
                currency: app.currency
            )
            
            // Top Customers
            TopCustomersCard(
                customers: vm.topCustomers(app.invoices),
                currency: app.currency
            )
            
            // Payment Trends
            PaymentTrendsCard(
                trends: vm.paymentTrends(app.invoices),
                currency: app.currency
            )
            
            // Advanced Metrics
            HStack(spacing: 12) {
                AdvancedMetricCard(
                    title: "Payment Rate",
                    value: "\(Int(vm.paymentRate(app.invoices) * 100))%",
                    icon: "percent",
                    color: .green
                )
                
                AdvancedMetricCard(
                    title: "Invoice Velocity",
                    value: String(format: "%.1f", vm.invoiceVelocity(app.invoices)),
                    subtitle: "per month",
                    icon: "speedometer",
                    color: .blue
                )
            }
            
            HStack(spacing: 12) {
                AdvancedMetricCard(
                    title: "Customer LTV",
                    value: Money.fmt(vm.customerLifetimeValue(app.invoices), code: app.currency),
                    icon: "person.crop.circle",
                    color: .purple
                )
                
                AdvancedMetricCard(
                    title: "Conversion Rate",
                    value: "\(Int(vm.paymentRate(app.invoices) * 100))%",
                    subtitle: "draft to paid",
                    icon: "arrow.right.circle",
                    color: .orange
                )
            }
        }
        .offset(y: showContent ? 0 : 20)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: showContent)
    }
    
    // MARK: - Premium Upgrade Section
    
    private var premiumUpgradeSection: some View {
        VStack(spacing: 20) {
            // Premium Features Preview
            VStack(spacing: 16) {
                    HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                    Text("Unlock Advanced Analytics")
                        .font(.system(size: 20, weight: .bold))
                        Spacer()
                }
                
                VStack(spacing: 12) {
                    PremiumFeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Revenue Trends & Growth",
                        description: "Track your business growth over time"
                    )
                    
                    PremiumFeatureRow(
                        icon: "person.3.sequence",
                        title: "Customer Analytics",
                        description: "Identify your top customers and segments"
                    )
                    
                    PremiumFeatureRow(
                        icon: "chart.bar.xaxis",
                        title: "Payment Performance",
                        description: "Monitor payment trends and patterns"
                    )
                    
                    PremiumFeatureRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Detailed Reports",
                        description: "Export comprehensive analytics data"
                    )
                }
                
                Button(action: { showPaywall = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Upgrade to Premium")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primary)
                            .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)
                    )
                    .foregroundColor(scheme == .light ? .white : .black)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.primary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .offset(y: showContent ? 0 : 20)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: showContent)
    }
}

// MARK: - Background View

extension AnalyticsScreen {
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

// MARK: - UI Components

private struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let tint: Color
    let isPremium: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(tint)
                
                if isPremium {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(tint.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(tint.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct StatusCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(String(count))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct RevenueGrowthCard: View {
    let growth: Double
    let currentRevenue: Decimal
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(growth >= 0 ? .green : .red)
                
                Text("Revenue Growth")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: growth >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(abs(growth), specifier: "%.1f")%")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(growth >= 0 ? .green : .red)
            }
            
            Text(Money.fmt(currentRevenue, code: currency))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

private struct RevenueChartCard: View {
    let data: [RevenueData]
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
                    HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("Monthly Revenue")
                    .font(.system(size: 16, weight: .semibold))
                
                        Spacer()
            }
            
            if #available(iOS 16.0, *) {
                Chart(data) { item in
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Revenue", item.revenue)
                    )
                    .foregroundStyle(.blue.gradient)
                }
                .frame(height: 200)
            } else {
                // Fallback for iOS < 16
                VStack(spacing: 8) {
                    ForEach(data) { item in
                        HStack {
                            Text(item.month)
                                .font(.system(size: 12, weight: .medium))
                                .frame(width: 40, alignment: .leading)
                            
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                                    .frame(width: max(4, geometry.size.width * (item.revenue / (data.map(\.revenue).max() ?? 1))))
                            }
                            .frame(height: 20)
                            
                            Text(Money.fmt(Decimal(item.revenue), code: currency))
                                .font(.system(size: 12, weight: .medium))
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

private struct TopCustomersCard: View {
    let customers: [CustomerSegment]
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.purple)
                
                Text("Top Customers")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(customers) { customer in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(customer.name)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)
                            
                            Text("\(customer.invoices) invoices")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(Money.fmt(Decimal(customer.revenue), code: currency))
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("\(customer.percentage, specifier: "%.1f")%")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primary.opacity(0.05))
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

private struct PaymentTrendsCard: View {
    let trends: [PaymentTrend]
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.green)
                
                Text("Payment Trends")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(trends) { trend in
                    HStack {
                        Text(trend.period)
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 60, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text(Money.fmt(Decimal(trend.paid), code: currency))
                                    .font(.system(size: 11, weight: .medium))
                            }
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                Text(Money.fmt(Decimal(trend.pending), code: currency))
                                    .font(.system(size: 11, weight: .medium))
                            }
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text(Money.fmt(Decimal(trend.overdue), code: currency))
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

private struct AdvancedMetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    
    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}