//
//  InvoiceWizardVM.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

final class InvoiceWizardVM: ObservableObject {
    @Published var step: Int = 1
    @Published var number: String = "INV-" + String(Int.random(in: 100000...999999))
    @Published var status: Invoice.Status = .draft
    @Published var issueDate: Date = .init()
    @Published var dueDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: .init()) ?? .init()
    @Published var customer: Customer? = nil
    @Published var items: [LineItem] = []
    @Published var currency: String = Locale.current.currency?.identifier ?? "USD"

    var subtotal: Decimal { items.map { $0.total }.reduce(0, +) }
}

struct InvoiceWizardView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = InvoiceWizardVM()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StepHeader(step: vm.step)
                content
            }
            .navigationTitle("Create Invoice")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Label(app.selectedTemplate?.name ?? "Classic Business", systemImage: "tag")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { save() } label: { Label("Save", systemImage: "square.and.arrow.down") }
                }
            }
            .onAppear {
                var jumped = false

                // 1) Если пришёл предвыбранный клиент — подставляем
                if vm.customer == nil, let pre = app.preselectedCustomer {
                    vm.customer = pre
                    app.preselectedCustomer = nil
                    if vm.step < 2 { vm.step = 2 }
                    jumped = true
                }

                // 2) Если пришли предзаполненные позиции — подставляем и идём на шаг 3
                if let presetItems = app.preselectedItems, !presetItems.isEmpty {
                    if vm.items.isEmpty {
                        vm.items = presetItems
                    } else {
                        vm.items.append(contentsOf: presetItems)
                    }
                    app.preselectedItems = nil
                    vm.step = 3
                    jumped = true
                }

                // 3) Если ничего не пришло, оставляем как есть; если пришёл только клиент — шаг 2
                if !jumped, vm.customer != nil, vm.step < 2 {
                    vm.step = 2
                }
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch vm.step {
        case 1:
            StepCompanyInfoView { vm.step = 2 }
        case 2:
            StepClientInfoView(vm: vm, next: { vm.step = 3 }, prev: { vm.step = 1 })
        default:
            StepItemsPricingView(vm: vm, prev: { vm.step = 2 }, onSaved: save)
        }
    }

    private func save() {
        guard let company = app.company, let customer = vm.customer else { return }
        let invoice = Invoice(
            number: vm.number,
            status: vm.status,
            issueDate: vm.issueDate,
            dueDate: vm.dueDate,
            company: company,
            customer: customer,
            currency: vm.currency,
            items: vm.items
        )
        app.invoices.append(invoice)
        dismiss()
    }
}

// Step header

struct StepHeader: View {
    let step: Int
    var body: some View {
        HStack(spacing: 24) {
            stepItem(1, "Company Info", "Your business details")
            divider
            stepItem(2, "Client Info", "Client information")
            divider
            stepItem(3, "Items & Pricing", "Add invoice items")
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    private var divider: some View {
        Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 24, height: 2)
    }
    private func stepItem(_ n: Int, _ title: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                ZStack {
                    Circle().stroke(Color.secondary.opacity(0.3))
                    Text("\(n)").bold()
                }
                .frame(width: 24, height: 24)
                .background(n == step ? Circle().fill(Color.black) : nil)
                .foregroundStyle(n == step ? .white : .primary)
                Text(title).bold()
            }
            Text(sub).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// Step 1: Company

struct CompanySetupCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.12)))
    }
}

struct StepCompanyInfoView: View {
    @EnvironmentObject private var app: AppState
    var next: () -> Void
    @State private var company = Company()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Company Information").font(.headline)
                    TextField("Company Name", text: $company.name).fieldStyle()
                    HStack {
                        TextField("Company Email", text: $company.email).keyboardType(.emailAddress).fieldStyle()
                        TextField("Company Phone", text: $company.phone).fieldStyle()
                    }
                    TextField("Company Address", text: $company.address.line1).fieldStyle()
                }
                .modifier(CompanySetupCard())

                HStack {
                    Button("Previous") {}
                        .buttonStyle(.bordered)
                        .disabled(true)
                    Spacer()
                    Button("Next") {
                        app.company = company
                        next()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(company.name.isEmpty || company.email.isEmpty)
                }
            }
            .padding()
        }
    }
}

// Step 2: Client

struct StepClientInfoView: View {
    @EnvironmentObject private var app: AppState
    @ObservedObject var vm: InvoiceWizardVM
    var next: () -> Void
    var prev: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Select Customer", systemImage: "person.crop.circle")
                        Spacer()
                        Button("Add New") { /* later */ }
                    }
                    TextField("Search customers…", text: .constant(""))
                        .disabled(true)
                        .fieldStyle()

                    ForEach(app.customers) { c in
                        Button {
                            vm.customer = c
                        } label: {
                            HStack {
                                Avatar(initials: initials(for: c.name))
                                VStack(alignment: .leading) {
                                    Text(c.name).bold()
                                    Text(c.email).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if vm.customer?.id == c.id {
                                    Image(systemName: "checkmark").foregroundStyle(.blue)
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15)))
                        }
                    }
                }
                .modifier(CompanySetupCard())

                VStack(alignment: .leading, spacing: 12) {
                    Text("Invoice Details").font(.headline)
                    HStack {
                        TextField("Invoice Number", text: $vm.number).fieldStyle()
                        Picker("Status", selection: $vm.status) {
                            ForEach(Invoice.Status.allCases) { s in
                                Text(s.rawValue.capitalized).tag(s)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    HStack {
                        DatePicker("Invoice Date", selection: $vm.issueDate, displayedComponents: .date)
                        DatePicker("Due Date", selection: $vm.dueDate, displayedComponents: .date)
                    }
                }
                .modifier(CompanySetupCard())

                HStack {
                    Button("Previous", action: prev).buttonStyle(.bordered)
                    Spacer()
                    Button("Next", action: next)
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.customer == nil)
                }
            }
            .padding()
        }
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
    }
}

// Step 3: Items & Pricing

struct StepItemsPricingView: View {
    @EnvironmentObject private var app: AppState
    @ObservedObject var vm: InvoiceWizardVM
    var prev: () -> Void
    var onSaved: () -> Void

    @State private var search = ""
    @State private var category = "All"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Add Products/Services", systemImage: "shippingbox")
                        Spacer()
                        Button("+ Add New") { /* later */ }
                    }
                    HStack {
                        TextField("Search products/services…", text: $search).fieldStyle()
                        Menu(category) {
                            Picker("", selection: $category) {
                                Text("All").tag("All")
                                ForEach(Array(Set(app.products.map { $0.category })), id: \.self) {
                                    Text($0).tag($0)
                                }
                            }
                        }
                    }
                    ForEach(filteredProducts) { p in
                        ProductRow(p: p) { add(product: p) }
                    }
                }
                .modifier(CompanySetupCard())

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Invoice Items").font(.headline)
                        Spacer()
                        Button("+ Add Custom Item") { addCustom() }
                    }
                    ForEach(vm.items) { item in
                        ItemEditor(item: binding(for: item))
                    }
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(Money.fmt(vm.subtotal, code: vm.currency)).bold()
                    }
                }
                .modifier(CompanySetupCard())

                HStack {
                    Button("Previous", action: prev).buttonStyle(.bordered)
                    Spacer()
                    Button("Next", action: onSaved)
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.items.isEmpty)
                }
            }
            .padding()
        }
    }

    private var filteredProducts: [Product] {
        app.products.filter {
            (category == "All" || $0.category == category) &&
            (search.isEmpty || $0.name.lowercased().contains(search.lowercased()))
        }
    }

    private func add(product p: Product) {
        vm.items.append(LineItem(description: p.name, quantity: 1, rate: p.rate))
    }
    private func addCustom() {
        vm.items.append(LineItem(description: "", quantity: 1, rate: 0))
    }
    private func binding(for item: LineItem) -> Binding<LineItem> {
        guard let idx = vm.items.firstIndex(where: { $0.id == item.id }) else { return .constant(item) }
        return $vm.items[idx]
    }
}

// MARK: - Details

struct InvoiceDetailsView: View {
    let invoice: Invoice
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(invoice.company.name).font(.title2).bold()
                    Spacer()
                    StatusChip(status: invoice.status)
                }
                Text(invoice.customer.name).font(.headline)
                HStack {
                    Text("Issue:")
                    Text(Dates.display.string(from: invoice.issueDate))
                    Spacer()
                    Text("Due:")
                    Text(Dates.display.string(from: invoice.dueDate ?? invoice.issueDate))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(invoice.items) { it in
                        HStack {
                            Text(it.description)
                            Spacer()
                            Text(Money.fmt(it.total, code: invoice.currency))
                        }
                        Divider()
                    }
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(Money.fmt(invoice.subtotal, code: invoice.currency)).bold()
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.12)))
            }
            .padding()
        }
        .navigationTitle("Invoice \(invoice.number)")
    }
}

// MARK: - Other tabs (light)



// ============ Products & Services ============

final class ProductsVM: ObservableObject {
    @Published var query = ""
    @Published var category: String = "All"

    func filtered(_ products: [Product]) -> [Product] {
        let q = query.lowercased()
        return products.filter { p in
            (category == "All" || p.category == category) &&
            (q.isEmpty || p.name.lowercased().contains(q) || p.details.lowercased().contains(q))
        }
    }

    func categories(from products: [Product]) -> [String] {
        Array(Set(products.map { $0.category })).sorted()
    }

    func stats(for products: [Product]) -> (count: Int, categories: Int, avgPrice: Decimal) {
        let count = products.count
        let catCount = Set(products.map { $0.category }).count
        let avg: Decimal = count > 0
            ? products.map { $0.rate }.reduce(0, +) / Decimal(count)
            : 0
        return (count, catCount, avg)
    }
}

struct ProductsScreen: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var vm = ProductsVM()
    @State private var sheetMode: ProductFormView.Mode? = nil
    @State private var showAdd = false
    @State private var editingID: UUID? = nil
    @State private var showCompanySetup = false
    @State private var showTemplatePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Title & actions
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Products &").font(.largeTitle).bold()
                        Text("Services").font(.largeTitle).bold()
                        Text("Manage your service catalog")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }

                    HStack(spacing: 10) {
                        Button {
                            showAdd = true
                        } label: {
                            Label("Add Product", systemImage: "plus")
                                .bold().padding(.horizontal, 14).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
                        }

                        Button {
                            onCreateInvoice()
                        } label: {
                            Label("Create Invoice", systemImage: "doc.badge.plus")
                                .bold().padding(.horizontal, 14).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                                .foregroundStyle(.white)
                        }
                    }

                    // Search + Category
                    HStack(spacing: 10) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            TextField("Search products/services...", text: $vm.query)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))

                        Menu {
                            Picker("Category", selection: $vm.category) {
                                Text("All").tag("All")
                                ForEach(vm.categories(from: app.products), id: \.self) { Text($0).tag($0) }
                            }
                        } label: {
                            HStack { Text(vm.category); Image(systemName: "chevron.down") }
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
                        }
                    }

                    // Free Plan card
                    FreePlanProductsCard()

                    // List
                    VStack(spacing: 12) {
                        ForEach(vm.filtered(app.products)) { p in
                            ProductCatalogRow(
                                product: p,
                                onEdit: { editingID = p.id },
                                onQuickAdd: { quickAdd(p) }
                            )
                        }
                    }

                    // Stats row
                    let s = vm.stats(for: vm.filtered(app.products))
                    HStack(spacing: 12) {
                        MetricTile(title: "Total Products", value: "\(s.count)")
                        MetricTile(title: "Categories", value: "\(s.categories)")
                        MetricTile(title: "Avg. Price", value: Money.fmt(s.avgPrice, code: Locale.current.currency?.identifier ?? "USD"))
                    }

                    // Premium features footer
                    PremiumFeaturesCard(
                        title: "Premium Features",
                        subtitle: "Bulk import, advanced pricing tiers, and product analytics"
                    )
                }
                .padding()
            }
            .sheet(isPresented: $showAdd) {
                ProductFormView(mode: .add)
            }
            .sheet(item: $sheetMode) { mode in
                ProductFormView(mode: mode)
            }
            .sheet(isPresented: $showCompanySetup) {
                CompanySetupView {
                    showCompanySetup = false
                    showTemplatePicker = true
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerView()
            }
        }
    }

    private func onCreateInvoice() {
        if app.company == nil { showCompanySetup = true }
        else { showTemplatePicker = true }
    }

    private func quickAdd(_ p: Product) {
        app.preselectedItems = [ LineItem(description: p.name, quantity: 1, rate: p.rate) ]
        onCreateInvoice()
    }
}


// MARK: - Reusable UI

extension View {
    func fieldStyle() -> some View {
        self.padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
    }
}

struct Avatar: View {
    let initials: String
    var body: some View {
        Circle()
            .fill(Color.secondary.opacity(0.15))
            .frame(width: 36, height: 36)
            .overlay(Text(initials).font(.caption).bold())
    }
}

struct ProductRow: View {
    let p: Product
    let onAdd: () -> Void
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack { Text(p.name).bold(); Tag(text: p.category) }
                Text(p.details).font(.caption).foregroundStyle(.secondary)
                Text("$\(NSDecimalNumber(decimal: p.rate))/ hour").font(.caption)
            }
            Spacer()
            Button(action: onAdd) {
                HStack { Image(systemName: "cart.badge.plus"); Text("Add") }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15)))
    }
}

struct Tag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(Color.secondary.opacity(0.1)))
    }
}

struct ItemEditor: View {
    @Binding var item: LineItem
    var body: some View {
        VStack(spacing: 8) {
            TextField("Description", text: $item.description).fieldStyle()
            HStack {
                DecimalField(title: "Quantity", value: $item.quantity)
                DecimalField(title: "Rate", value: $item.rate)
                Spacer()
                Text(Money.fmt(item.total, code: Locale.current.currency?.identifier ?? "USD")).bold()
            }
            .frame(height: 44)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15)))
    }
}

struct DecimalField: View {
    let title: String
    @Binding var value: Decimal
    var body: some View {
        TextField(title,
                  text: Binding(
                    get: { NSDecimalNumber(decimal: value).stringValue },
                    set: { value = Decimal(string: $0) ?? value }
                  )
        )
        .keyboardType(.decimalPad)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
    }
}
struct FreePlanProductsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill").foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Free Plan").bold()
                    Text("Invoice limit reached").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            Button("Upgrade to Create More") { }
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(
                    LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                ))
                .foregroundStyle(.white)

            Button("Create Invoice (Limit Reached)") { }
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.06)))
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                Label("Unlimited invoices", systemImage: "checkmark")
                Label("Premium templates", systemImage: "checkmark")
                Label("Advanced features", systemImage: "checkmark")
            }.font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.4)))
    }
}

struct ProductCatalogRow: View {
    let product: Product
    let onEdit: () -> Void
    let onQuickAdd: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.15)))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "shippingbox")
                    Text(product.name).bold()
                    Tag(text: product.category)
                    Spacer()
                }
                Text(product.details)
                    .font(.caption).foregroundStyle(.secondary)

                HStack {
                    Text(Money.fmt(product.rate, code: Locale.current.currency?.identifier ?? "USD"))
                        .bold()
                    Text("/ hour").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Edit", action: onEdit)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
                    Button("Quick Add", action: onQuickAdd)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                        .foregroundStyle(.white)
                }
            }
            .padding(16)
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3).bold()
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.15)))
    }
}

struct PremiumFeaturesCard: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "crown").foregroundStyle(.yellow)
                Text(title).bold()
                Spacer()
                Button("Upgrade") { }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.yellow))
            }
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.4)))
    }
}
struct ProductFormView: View {
    enum Mode: Identifiable {
        case add
        case edit(productID: UUID)
        var id: String {
            switch self { case .add: return "add"; case .edit(let id): return id.uuidString }
        }
    }

    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    let mode: Mode

    @State private var model = Product(id: UUID(), name: "", details: "", rate: 0, category: "General")
    @State private var title = "Add Product"

    var canSave: Bool { !model.name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $model.name)
                    TextField("Details", text: $model.details, axis: .vertical)
                }
                Section("Pricing") {
                    DecimalField(title: "Hourly rate", value: $model.rate)
                }
                Section("Category") {
                    TextField("Category", text: $model.category)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .onAppear { loadIfNeeded() }
        }
    }

    private func loadIfNeeded() {
        switch mode {
        case .add:
            title = "Add Product"
        case .edit(let id):
            title = "Edit Product"
            if let idx = app.products.firstIndex(where: { $0.id == id }) {
                model = app.products[idx]
            }
        }
    }

    private func save() {
        switch mode {
        case .add:
            app.products.append(model)
        case .edit(let id):
            if let idx = app.products.firstIndex(where: { $0.id == id }) {
                app.products[idx] = model
            }
        }
        dismiss()
    }
}
