//
//  ProductsScreen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/28/25.
//

import SwiftUI

// MARK: - VM

final class ProductsVM: ObservableObject {
    @Published var query: String = ""
    @Published var category: String = "All"

    func filtered(_ products: [Product]) -> [Product] {
        var items = products
        if category != "All" { items = items.filter { $0.category == category } }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return items }
        return items.filter {
            $0.name.lowercased().contains(q) || $0.details.lowercased().contains(q)
        }
    }

    func categories(from products: [Product]) -> [String] {
        ["All"] + Array(Set(products.map { $0.category })).sorted()
    }
}

// MARK: - Screen

struct ProductsScreen: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var vm = ProductsVM()

    @State private var showAddProduct = false
    @State private var editingProduct: Product? = nil   // sheet(item:)
    @State private var showEmptyPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    // Header
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Products & Services").font(.largeTitle).bold()
                            Text("Manage your service catalog")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if app.isPremium { ProBadge() }
                    }

                    // Actions
                    HStack(spacing: 12) {
                        Button { showAddProduct = true } label: {
                            Label("Add Product", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))

                        Button { onCreateInvoice() } label: {
                            Label("Create Invoice", systemImage: "doc.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                        .foregroundStyle(.white)
                    }

                    // Search + Category
                    HStack(spacing: 10) {
                        SearchBar(text: $vm.query)
                        Menu {
                            Picker("Category", selection: $vm.category) {
                                ForEach(vm.categories(from: app.products), id: \.self) { c in
                                    Text(c).tag(c)
                                }
                            }
                        } label: {
                            HStack {
                                Text(vm.category)
                                Image(systemName: "chevron.down")
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
                        }
                    }
                    .padding(.top, 2)

                    // Free banner
                    if !app.isPremium {
                        FreePlanCardCompact(
                            remaining: app.remainingFreeInvoices,
                            onUpgrade: { showEmptyPaywall = true },
                            onCreate: onCreateInvoice
                        )
                    }

                    // List
                    if app.products.isEmpty {
                        emptyList
                    } else {
                        VStack(spacing: 10) {
                            ForEach(vm.filtered(app.products)) { p in
                                ProductRow(
                                    product: p,
                                    onEdit: { editingProduct = p },
                                    onQuickAdd: { quickAdd(p) }
                                )
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 6)
            }
            // Sheets
            .sheet(isPresented: $showAddProduct) {
                ProductFormView(mode: .add) { new in
                    app.products.append(new)
                }
            }
            .sheet(item: $editingProduct) { product in
                ProductFormView(mode: .edit(productID: product.id), initial: product) { updated in
                    if let idx = app.products.firstIndex(where: { $0.id == product.id }) {
                        app.products[idx] = updated
                    }
                }
            }
            .sheet(isPresented: $showEmptyPaywall) { EmptyScreen() }
        }
    }

    // MARK: - Helpers

    private func onCreateInvoice() {
        guard app.canCreateInvoice else { showEmptyPaywall = true; return }
        // подключишь визард — дерни роутер/флаг; временно:
        showEmptyPaywall = true
    }

    private func quickAdd(_ p: Product) {
        guard app.canCreateInvoice else { showEmptyPaywall = true; return }
        // TODO: предзаполнить LineItem и открыть визард
        showEmptyPaywall = true
    }

    private var emptyList: some View {
        VStack(spacing: 12) {
            Text("No products yet").font(.headline)
            Text("Add services you offer to invoice faster.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button { showAddProduct = true } label: {
                Text("Add Product")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.15)))
        .padding(.top, 6)
    }
}

// MARK: - Row

private struct ProductRow: View {
    let product: Product
    var onEdit: () -> Void
    var onQuickAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 8) {
                    Image(systemName: "shippingbox")
                    Text(product.name).font(.headline)
                    Tag(text: product.category)
                }
                Spacer()
                HStack(spacing: 10) {
                    Button("Edit", action: onEdit)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
                    Button("Quick Add", action: onQuickAdd)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                        .foregroundStyle(.white)
                }
            }

            if !product.details.isEmpty {
                Text(product.details).font(.caption).foregroundStyle(.secondary)
            }

            HStack {
                Text(Money.fmt(product.rate, code: Locale.current.currency?.identifier ?? "USD")).bold()
                Text("/ hour").foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.15)))
    }
}

// MARK: - Product form

struct ProductFormView: View {
    enum Mode: Identifiable {
        case add
        case edit(productID: UUID)
        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let id): return "edit-\(id.uuidString)"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    let mode: Mode
    var initial: Product? = nil
    var onSave: (Product) -> Void

    @State private var name: String
    @State private var details: String
    @State private var rate: Decimal
    @State private var category: String

    init(mode: Mode, initial: Product? = nil, onSave: @escaping (Product) -> Void) {
        self.mode = mode
        self.initial = initial
        self.onSave = onSave
        _name = State(initialValue: initial?.name ?? "")
        _details = State(initialValue: initial?.details ?? "")
        _rate = State(initialValue: initial?.rate ?? 0)
        _category = State(initialValue: initial?.category ?? "General")
    }

    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name)
                    TextField("Details", text: $details, axis: .vertical)
                }
                Section("Pricing") {
                    DecimalTextField(title: "Hourly rate", value: $rate)
                }
                Section("Category") {
                    TextField("Category", text: $category)
                }
            }
            .navigationTitle(modeTitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let p = Product(id: initial?.id ?? UUID(),
                                        name: name,
                                        details: details,
                                        rate: rate,
                                        category: category)
                        onSave(p)
                        dismiss()
                    }.disabled(!canSave)
                }
            }
        }
    }

    private var modeTitle: String {
        switch mode {
        case .add: return "Add Product"
        case .edit: return "Edit Product"
        }
    }
}

// MARK: - Small helpers reused

struct ProBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
            Text("Pro").bold()
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.black))
        .foregroundStyle(.white)
    }
}

struct DecimalTextField: View {
    let title: String
    @Binding var value: Decimal
    @State private var text: String = ""

    var body: some View {
        TextField(title, text: Binding(
            get: { text.isEmpty ? NSDecimalNumber(decimal: value).stringValue : text },
            set: { new in
                text = new
                if let d = Decimal(string: new.replacingOccurrences(of: ",", with: ".")) {
                    value = d
                }
            })
        )
        .keyboardType(.decimalPad)
    }
}
