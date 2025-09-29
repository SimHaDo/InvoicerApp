//
//  InvoicesScreen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

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

    @State private var showCompanySetup = false
    @State private var showTemplatePicker = false
    @State private var showEmptyPaywall = false
    @State private var showWizard = false   // отдельный флаг на визард

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
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
                .padding(.horizontal)
                .padding(.top, 6)
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
            VStack(alignment: .leading, spacing: 2) {
                Text("Invoices").font(.largeTitle).bold()
                Text("Manage all your invoices")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if app.isPremium { ProBadge() }
        }
    }

    private var headerCard: some View {
        Group {
            if app.isPremium {
                // твоя карточка быстрого создания
                QuickCreateCard(newAction: onNewInvoice)
                    .padding(.top, 2)
            } else {
                FreePlanCardCompact(
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
                    InvoiceCard(invoice: inv)
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

            // CTA снизу
            if !app.isPremium {
                if app.remainingFreeInvoices == 0 {
                    Button(action: { showEmptyPaywall = true }) {
                        Text("Upgrade to Create Invoice")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                            .foregroundStyle(.white)
                    }
                } else {
                    Button(action: onNewInvoice) {
                        Text("Create Free Invoice (\(app.remainingFreeInvoices) left)")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Compact free plan card (если она у тебя не в другом файле — оставь тут)

struct FreePlanCardCompact: View {
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
                HStack(spacing: 10) {
                    Button(action: onCreate) {
                        Text("Create Free Invoice").bold().frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                    .foregroundStyle(.white)

                    Button(action: onUpgrade) {
                        Text("Upgrade").bold().frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
                }
            } else {
                Button(action: onUpgrade) {
                    Text("Upgrade to Create Invoice").bold().frame(maxWidth: .infinity)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                .foregroundStyle(.white)
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

// MARK: - Paywall-заглушка (если у тебя уже есть — этот блок можно убрать)

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
