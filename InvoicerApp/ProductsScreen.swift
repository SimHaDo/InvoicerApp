//
//  ProductsScreen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/28/25.
//

import SwiftUI

// MARK: - Internal pricing meta (не меняем модель Product)

private enum PricingKind: Equatable {
    case hourly
    case perUnit(unit: String)     // "item", "day", "license" и т.п.
    case fixed
}

private enum PricingMeta {
    static func encode(kind: PricingKind, details: String) -> String {
        let rest = details.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case .hourly:            return "[HOURLY] " + rest
        case .fixed:             return "[FIXED] "  + rest
        case .perUnit(let u):    return "[UNIT:\(u)] " + rest
        }
    }

    static func decode(from details: String) -> (PricingKind, String) {
        let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("[") else { return (.hourly, details) }

        if trimmed.hasPrefix("[HOURLY]") {
            let rest = String(trimmed.dropFirst("[HOURLY]".count)).trimmingCharacters(in: .whitespaces)
            return (.hourly, rest)
        }
        if trimmed.hasPrefix("[FIXED]") {
            let rest = String(trimmed.dropFirst("[FIXED]".count)).trimmingCharacters(in: .whitespaces)
            return (.fixed, rest)
        }
        if trimmed.hasPrefix("[UNIT:"),
           let colon = trimmed.firstIndex(of: ":"),
           let close = trimmed.firstIndex(of: "]"),
           colon < close
        {
            let unit = String(trimmed[trimmed.index(after: colon)..<close])
            let rest = String(trimmed[trimmed.index(after: close)...]).trimmingCharacters(in: .whitespaces)
            return (.perUnit(unit: unit), rest)
        }
        return (.hourly, details)
    }
}

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
    @State private var editingProduct: Product? = nil
    @State private var showEmptyPaywall = false

    private let mainBlue = Color.blue
    private let secondaryBlue = Color.blue.opacity(0.6)

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
                                ProductCard(
                                    product: p,
                                    mainBlue: mainBlue,
                                    secondaryBlue: secondaryBlue,
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

// MARK: - Card

private struct ProductCard: View {
    let product: Product
    let mainBlue: Color
    let secondaryBlue: Color
    var onEdit: () -> Void
    var onQuickAdd: () -> Void

    private var kind: PricingKind { PricingMeta.decode(from: product.details).0 }
    private var cleanDetails: String { PricingMeta.decode(from: product.details).1 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.15)))

            VStack(alignment: .leading, spacing: 10) {
                // Title row
                HStack(alignment: .firstTextBaseline) {
                    HStack(spacing: 8) {
                        Image(systemName: "shippingbox")
                            .foregroundStyle(mainBlue)
                        Text(product.name)
                            .foregroundStyle(mainBlue)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        Button("Edit", action: onEdit)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.09)))
                        Button("Quick Add", action: onQuickAdd)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black))
                            .foregroundStyle(.white)
                    }
                }

                // Category capsule (под именем)
                Tag(text: product.category)

                // Description
                if !cleanDetails.isEmpty {
                    Text(cleanDetails)
                        .font(.caption)
                        .foregroundStyle(secondaryBlue)
                }

                // Price row
                HStack {
                    Text(Money.fmt(product.rate, code: Locale.current.currency?.identifier ?? "USD"))
                        .bold()
                        .foregroundStyle(mainBlue)
                    Group {
                        switch kind {
                        case .hourly:            Text("/ hour")
                        case .fixed:             Text("(fixed)")
                        case .perUnit(let u):    Text("/ \(u)")
                        }
                    }
                    .foregroundStyle(secondaryBlue)
                    Spacer()
                }
            }
            .padding(14)
        }
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

    @State private var pricing: PricingKind
    @State private var unit: String

    init(mode: Mode, initial: Product? = nil, onSave: @escaping (Product) -> Void) {
        self.mode = mode
        self.initial = initial
        self.onSave = onSave

        let decoded = PricingMeta.decode(from: initial?.details ?? "")
        _name     = State(initialValue: initial?.name ?? "")
        _details  = State(initialValue: decoded.1)
        _rate     = State(initialValue: initial?.rate ?? 0)
        _category = State(initialValue: initial?.category ?? "General")

        switch decoded.0 {
        case .hourly:
            _pricing = State(initialValue: .hourly)
            _unit    = State(initialValue: "item")
        case .fixed:
            _pricing = State(initialValue: .fixed)
            _unit    = State(initialValue: "item")
        case .perUnit(let u):
            _pricing = State(initialValue: .perUnit(unit: u))
            _unit    = State(initialValue: u)
        }
    }

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name).lineLimit(1)
                    TextField("Details", text: $details, axis: .vertical)
                }

                Section("Pricing") {
                    Picker("Type", selection: Binding<Int>(
                        get: {
                            switch pricing {
                            case .hourly: return 0
                            case .perUnit: return 1
                            case .fixed:   return 2
                            }
                        },
                        set: { (idx: Int) in
                            switch idx {
                            case 0: pricing = .hourly
                            case 1: pricing = .perUnit(unit: unit)
                            default: pricing = .fixed
                            }
                        })
                    ) {
                        Text("Hourly").tag(0)
                        Text("Per Unit").tag(1)
                        Text("Fixed Price").tag(2)
                    }
                    .pickerStyle(.segmented)

                    if case .perUnit = pricing {
                        Picker("Unit", selection: $unit) {
                            Text("Item").tag("item")
                            Text("Day").tag("day")
                            Text("Seat").tag("seat")
                            Text("License").tag("license")
                        }
                        .pickerStyle(.menu)
                        .onChange(of: unit) { new in
                            pricing = .perUnit(unit: new)
                        }
                    }

                    DecimalTextField(title: priceTitle, value: $rate)
                }
                Section("Category") {
                    TextField("Category", text: $category)
                }
            }
            .navigationTitle(modeTitle)
        }
        // Верхний тулбар (остался как был)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.disabled(!canSave)
            }
        }
        // Доп. фиксированная кнопка снизу только в режиме добавления
        .safeAreaInset(edge: .bottom) {
            if case .add = mode {
                Button(action: save) {
                    Text("Save")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(canSave ? Color.black : Color.gray.opacity(0.4)))
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                .disabled(!canSave)
            }
        }
    }

    private func save() {
        let encodedDetails = PricingMeta.encode(kind: pricing, details: details)
        let p = Product(
            id: initial?.id ?? UUID(),
            name: name,
            details: encodedDetails,
            rate: rate,
            category: category
        )
        onSave(p)
        dismiss()
    }

    private var priceTitle: String {
        switch pricing {
        case .hourly:              return "Hourly rate"
        case .perUnit(let u):      return "Price per \(u)"
        case .fixed:               return "Fixed price"
        }
    }

    private var modeTitle: String {
        switch mode {
        case .add:  return "Add Product"
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
