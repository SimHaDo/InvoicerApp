//
//  InvoicesScreen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

// MARK: - InvoicesScreen
final class InvoicesVM: ObservableObject {
    @Published var query = ""
    func filtered(_ invoices: [Invoice]) -> [Invoice] { let q = query.lowercased(); guard !q.isEmpty else { return invoices }; return invoices.filter{ $0.number.lowercased().contains(q) || $0.customer.name.lowercased().contains(q) } }
    func totalOutstanding(_ invoices: [Invoice]) -> Decimal { invoices.filter{ $0.status != .paid }.map{ $0.subtotal }.reduce(0,+) }
    func totalPaid(_ invoices: [Invoice]) -> Decimal { invoices.filter{ $0.status == .paid }.map{ $0.subtotal }.reduce(0,+) }
}

struct InvoicesScreen: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var vm = InvoicesVM()
    @State private var showCompanySetup = false
    @State private var showTemplatePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    statsRow
                    searchField
                    if app.invoices.isEmpty { emptyState } else { invoiceList }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle("Invoices")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { onNewInvoice() } label: { Image(systemName: "plus.circle.fill").imageScale(.large) } } }
            .sheet(isPresented: $showCompanySetup) { CompanySetupView(onContinue: { showCompanySetup = false; showTemplatePicker = true }) }
            .sheet(isPresented: $showTemplatePicker) { TemplatePickerView() }
        }
    }

    private var headerCard: some View {
        Group {
            if app.invoices.isEmpty {
                FreePlanCard()
            } else {
                QuickCreateCard(newAction: onNewInvoice)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(title: "Total Outstanding", value: Money.fmt(vm.totalOutstanding(app.invoices), code: app.invoices.first?.currency ?? "USD"), tint: .blue.opacity(0.15))
            StatCard(title: "Total Paid", value: Money.fmt(vm.totalPaid(app.invoices), code: app.invoices.first?.currency ?? "USD"), tint: .green.opacity(0.15))
        }
    }

    private var searchField: some View {
        SearchBar(text: $vm.query).padding(.top, 4)
    }

    private var invoiceList: some View {
        VStack(spacing: 12) {
            ForEach(vm.filtered(app.invoices)) { inv in
                NavigationLink { InvoiceDetailsView(invoice: inv) } label: {
                    InvoiceCard(invoice: inv)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.15))
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.05)))
                VStack(spacing: 12) {
                    Button(action: onNewInvoice) {
                        Image(systemName: "plus.circle").font(.system(size: 40))
                    }
                    Text("No invoices found").font(.headline)
                    Text("Create your first invoice to get started").font(.subheadline).foregroundStyle(.secondary)
                }.padding(28)
            }.frame(maxWidth: .infinity, minHeight: 180)
            Button {
                // placeholder for paywall
            } label: {
                Text("Upgrade to Create").bold().frame(maxWidth: .infinity).padding().background(RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.3)))
            }
        }
        .padding(.vertical, 8)
    }

    private func onNewInvoice() {
        if app.company == nil { showCompanySetup = true } else { showTemplatePicker = true }
    }
}
