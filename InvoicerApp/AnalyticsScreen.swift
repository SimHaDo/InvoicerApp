//
//  AnalyticsScreen.swift
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

final class AnalyticsVM: ObservableObject {
    @Published var isPremium: Bool = false   // позже подключим к paywall

    func totalInvoices(_ invoices: [Invoice]) -> Int { invoices.count }

    func totalRevenue(_ invoices: [Invoice]) -> Decimal {
        invoices.filter { $0.status == .paid }.map(\.subtotal).reduce(0, +)
    }

    func breakdown(_ invoices: [Invoice]) -> (paid: [Invoice], pending: [Invoice], overdue: [Invoice]) {
        let paid = invoices.filter { $0.status == .paid }
        let pending = invoices.filter { $0.status == .draft }
        let overdue = invoices.filter { $0.status == .overdue }
        return (paid, pending, overdue)
    }

    func paymentRate(_ invoices: [Invoice]) -> Double {
        guard !invoices.isEmpty else { return 0 }
        let paidCount = invoices.filter { $0.status == .paid }.count
        return Double(paidCount) / Double(invoices.count)
    }

    func avgInvoice(_ invoices: [Invoice]) -> Decimal {
        guard !invoices.isEmpty else { return 0 }
        let total = invoices.map(\.subtotal).reduce(0, +)
        return total / Decimal(invoices.count)
    }

    func highestInvoice(_ invoices: [Invoice]) -> Decimal {
        invoices.map(\.subtotal).max() ?? 0
    }

    func latestInvoice(_ invoices: [Invoice]) -> Invoice? {
        invoices.sorted(by: { $0.issueDate > $1.issueDate }).first
    }

    func uniqueClients(_ invoices: [Invoice]) -> Int {
        Set(invoices.map { $0.customer.id }).count
    }

    func revenueThisMonth(_ invoices: [Invoice]) -> Decimal {
        let startOfMonth = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        )!
        return invoices.filter { $0.issueDate >= startOfMonth }.map(\.subtotal).reduce(0, +)
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
                    VStack(alignment: .leading, spacing: 20) {
                        // Header с анимациями
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
                                Label("Premium", systemImage: "crown.fill")
                                    .foregroundStyle(.secondary)
                                    .scaleEffect(showContent ? 1.0 : 0.9)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                            }
                        }
                        
                        if vm.isPremium {
                            premiumView
                        } else {
                            freeView
                        }
                    }
                    .padding(.horizontal, 20)
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

    // MARK: - Free Plan

    private var freeView: some View {
        VStack(spacing: 16) {
            HStack {
                StatCard(
                    title: "Total Invoices",
                    value: String(app.invoices.count),
                    tint: .blue.opacity(0.15)
                )
                StatCard(
                    title: "Total Revenue",
                    value: Money.fmt(vm.totalRevenue(app.invoices), code: app.currency),
                    tint: .green.opacity(0.15)
                )
            }

            VStack(spacing: 16) {
                Image(systemName: "crown")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Unlock Advanced Analytics").font(.headline)
                Text("Get detailed insights, trends, and reports to grow your business.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Upgrade to Premium") {
                    // TODO: paywall
                }
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 6) {
                    Label("Revenue trends and projections", systemImage: "checkmark")
                    Label("Client analytics and segmentation", systemImage: "checkmark")
                    Label("Payment performance metrics", systemImage: "checkmark")
                    Label("Detailed financial reports", systemImage: "checkmark")
                    Label("Export analytics data", systemImage: "checkmark")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.15)))
        }
    }

    // MARK: - Premium Plan

    private var premiumView: some View {
        let breakdown = vm.breakdown(app.invoices)
        return VStack(spacing: 16) {

            // Header cards
            HStack {
                StatCard(
                    title: "Total Invoices",
                    value: String(app.invoices.count),
                    tint: .blue.opacity(0.15)
                )
                StatCard(
                    title: "Total Revenue",
                    value: Money.fmt(vm.totalRevenue(app.invoices), code: app.currency),
                    tint: .green.opacity(0.15)
                )
            }

            // Revenue breakdown
            GroupBox("Revenue Breakdown") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("Paid (\(breakdown.paid.count) invoices)")
                        Spacer()
                        Text(Money.fmt(breakdown.paid.map(\.subtotal).reduce(0, +), code: app.currency))
                    }
                    HStack {
                        Circle().fill(Color.blue).frame(width: 8, height: 8)
                        Text("Pending (\(breakdown.pending.count) invoices)")
                        Spacer()
                        Text(Money.fmt(breakdown.pending.map(\.subtotal).reduce(0, +), code: app.currency))
                    }
                    HStack {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                        Text("Overdue (\(breakdown.overdue.count) invoices)")
                        Spacer()
                        Text(Money.fmt(breakdown.overdue.map(\.subtotal).reduce(0, +), code: app.currency))
                    }
                }
            }

            // Metrics
            HStack {
                MetricTile(
                    title: "Payment Rate",
                    value: "\(Int(vm.paymentRate(app.invoices) * 100))%"
                )
                MetricTile(
                    title: "Avg Invoice Value",
                    value: Money.fmt(vm.avgInvoice(app.invoices), code: app.currency)
                )
            }

            // Quick Stats
            GroupBox("Quick Stats") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Highest Invoice")
                        Spacer()
                        Text(Money.fmt(vm.highestInvoice(app.invoices), code: app.currency))
                    }
                    HStack {
                        Text("Latest Invoice")
                        Spacer()
                        Text(
                            vm.latestInvoice(app.invoices)?
                                .issueDate.formatted(date: .abbreviated, time: .omitted) ?? "—"
                        )
                    }
                    HStack {
                        Text("Unique Clients")
                        Spacer()
                        Text("\(vm.uniqueClients(app.invoices))")
                    }
                    HStack {
                        Text("This Month")
                        Spacer()
                        Text(Money.fmt(vm.revenueThisMonth(app.invoices), code: app.currency))
                    }
                }
            }
        }
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

// MARK: - Local UI bits

private struct MetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .bold()
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.15))
        )
    }
}
