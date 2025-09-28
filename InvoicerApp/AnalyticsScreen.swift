//
//  AnalyticsScreen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

import SwiftUI

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

    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.isPremium {
                    premiumView
                } else {
                    freeView
                }
            }
            .padding()
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !vm.isPremium {
                        Label("Premium", systemImage: "crown.fill")
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
    }

    // MARK: - Free Plan

    private var freeView: some View {
        return VStack(spacing: 16) {
            HStack {
                StatCard(title: "Total Invoices",
                         value: String(app.invoices.count),
                         tint: .blue.opacity(0.15))
                StatCard(title: "Total Revenue",
                         value: Money.fmt(vm.totalRevenue(app.invoices),
                                          code: app.currency),
                         tint: .green.opacity(0.15))
            }

            VStack(spacing: 16) {
                Image(systemName: "crown")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Unlock Advanced Analytics").font(.headline)
                Text("Get detailed insights, trends, and reports to grow your business.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)

                Button("Upgrade to Premium") {
                    // TODO: подключим к подписке
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
                .font(.caption).foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.15)))
        }
    }

    // MARK: - Premium Plan

    private var premiumView: some View {
        let breakdown = vm.breakdown(app.invoices)
        return  VStack(spacing: 16) {

            // Header cards
            HStack {
                StatCard(title: "Total Invoices",
                         value: String(app.invoices.count),
                         tint: .blue.opacity(0.15))
                StatCard(title: "Total Revenue",
                         value: Money.fmt(vm.totalRevenue(app.invoices),
                                          code: app.currency),
                         tint: .green.opacity(0.15))
            }

            // Revenue breakdown
            GroupBox("Revenue Breakdown") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("Paid (\(breakdown.paid.count) invoices)")
                        Spacer()
                        Text(Money.fmt(breakdown.paid.map(\.subtotal).reduce(0,+), code: app.currency))
                    }
                    HStack {
                        Circle().fill(Color.blue).frame(width: 8, height: 8)
                        Text("Pending (\(breakdown.pending.count) invoices)")
                        Spacer()
                        Text(Money.fmt(breakdown.pending.map(\.subtotal).reduce(0,+), code: app.currency))
                    }
                    HStack {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                        Text("Overdue (\(breakdown.overdue.count) invoices)")
                        Spacer()
                        Text(Money.fmt(breakdown.overdue.map(\.subtotal).reduce(0,+), code: app.currency))
                    }
                }
            }

            // Metrics
            HStack {
                MetricTile(title: "Payment Rate",
                           value: "\(Int(vm.paymentRate(app.invoices)*100))%")
                MetricTile(title: "Avg Invoice Value",
                           value: Money.fmt(vm.avgInvoice(app.invoices), code: app.currency))
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
                        Text(vm.latestInvoice(app.invoices)?
                            .issueDate.formatted(date: .abbreviated, time: .omitted) ?? "—")
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


