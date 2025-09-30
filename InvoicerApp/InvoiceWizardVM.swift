//
//  InvoiceWizardVM.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//
import SwiftUI
import UIKit

// MARK: - ViewModel

final class InvoiceWizardVM: ObservableObject {
    @Published var step: Int = 1
    @Published var number: String = "INV-" + String(Int.random(in: 100000...999999))
    @Published var status: Invoice.Status = .draft
    @Published var issueDate: Date = .init()
    @Published var dueDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: .init()) ?? .init()
    @Published var customer: Customer? = nil
    @Published var items: [LineItem] = []
    @Published var currency: String = Locale.current.currency?.identifier ?? "USD"

    // Payment step state
    enum PaymentChoice: String, CaseIterable, Identifiable { case saved, custom, none
        var id: String { rawValue }
        var title: String {
            switch self {
            case .saved:  return "Saved methods"
            case .custom: return "Custom for this invoice"
            case .none:   return "Do not include"
            }
        }
    }
    @Published var paymentChoice: PaymentChoice = .saved
    @Published var selectedSaved: Set<UUID> = []              // выбранные из app.paymentMethods
    @Published var customMethods: [PaymentMethod] = []        // кастомные для этого инвойса
    @Published var paymentNotes: String = ""                  // дополнительные примечания (на инвойсе)

    var subtotal: Decimal { items.map { $0.total }.reduce(0, +) }
}

// MARK: - Wizard

struct InvoiceWizardView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = InvoiceWizardVM()

    // Template picker
    @State private var showTemplatePicker = false

    // PDF share
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var shouldDismissAfterShare = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StepHeader(step: vm.step)
                content
            }
            .navigationTitle("Create Invoice")
            .toolbar {
                // Нажимаем на "лейбл" – открываем выбор шаблона
                ToolbarItem(placement: .principal) {
                    Button { showTemplatePicker = true } label: {
                        Label(app.selectedTemplate.name, systemImage: "tag")
                            .labelStyle(.titleAndIcon)
                    }
                    .accessibilityIdentifier("TemplatePickerButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { save() } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .accessibilityIdentifier("SaveInvoiceButton")
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerView { selected in
                    app.selectedTemplate = selected      // сохраняем выбор
                    showTemplatePicker = false           // закрываем ТОЛЬКО пикер
                }
            }
            .onAppear(perform: configureFromAppState)
            .sheet(isPresented: $showShare, onDismiss: {
                if shouldDismissAfterShare { dismiss() }
            }) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url]) { _, _, _, _ in
                        // Пользователь закрыл контроллер шаринга
                        shouldDismissAfterShare = true
                    }
                }
            }
        }
    }

    // Steps routing
    @ViewBuilder private var content: some View {
        switch vm.step {
        case 1:
            StepCompanyInfoView { vm.step = 2 }
        case 2:
            StepClientInfoView(vm: vm, next: { vm.step = 3 }, prev: { vm.step = 1 })
        case 3:
            StepPaymentDetailsView(vm: vm, prev: { vm.step = 2 }, next: { vm.step = 4 })
        default:
            StepItemsPricingView(vm: vm, prev: { vm.step = 3 }, onSaved: save)
        }
    }

    private func configureFromAppState() {
        // если пришли из кнопок "быстрого старта"
        var jumped = false
        if vm.customer == nil, let pre = app.preselectedCustomer {
            vm.customer = pre
            app.preselectedCustomer = nil
            if vm.step < 2 { vm.step = 2 }
            jumped = true
        }
        if let presetItems = app.preselectedItems, !presetItems.isEmpty {
            if vm.items.isEmpty {
                vm.items = presetItems
            } else {
                vm.items.append(contentsOf: presetItems)
            }
            app.preselectedItems = nil
            vm.step = 4
            jumped = true
        }
        if !jumped, vm.customer != nil, vm.step < 2 {
            vm.step = 2
        }
    }

    // Собираем финальный список реквизитов на основе выбора на шаге
    private func resolvedPaymentMethods() -> [PaymentMethod] {
        switch vm.paymentChoice {
        case .none:
            return []
        case .custom:
            return vm.customMethods
        case .saved:
            let all = app.paymentMethods
            return all.filter { vm.selectedSaved.contains($0.id) }
        }
    }

    // Save -> PDF -> Share
    private func save() {
        guard let company = app.company,
              let customer = vm.customer,
              !vm.items.isEmpty
        else { return }

        var invoice = Invoice(
            number: vm.number,
            status: vm.status,
            issueDate: vm.issueDate,
            dueDate: vm.dueDate,
            company: company,
            customer: customer,
            currency: vm.currency,
            items: vm.items
        )

        // Применяем реквизиты и заметки, выбранные на шаге Payment Details
        invoice.paymentMethods = resolvedPaymentMethods()
        invoice.paymentNotes = vm.paymentNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : vm.paymentNotes

        app.invoices.append(invoice)

        do {
            let url = try PDFService.shared.generatePDF(
                invoice: invoice,
                company: company,
                customer: customer,
                currencyCode: vm.currency,
                template: app.selectedTemplate,
                logo: app.logoImage
            )
            shareURL = url
            shouldDismissAfterShare = false
            showShare = true
        } catch {
            print("PDF generation error:", error)
            // если что-то пошло не так — просто остаёмся в визарде
        }
    }
}

// MARK: - Step header

struct StepHeader: View {
    let step: Int
    var body: some View {
        HStack(spacing: 18) {
            stepItem(1, "Company", "Your business details")
            divider
            stepItem(2, "Client", "Client information")
            divider
            stepItem(3, "Payment", "What to show on invoice")
            divider
            stepItem(4, "Items", "Add invoice items")
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    private var divider: some View {
        Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 18, height: 2)
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

// MARK: - Step 1: Company

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
                        TextField("Company Email", text: $company.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .fieldStyle()
                        TextField("Company Phone", text: $company.phone)
                            .keyboardType(.phonePad)
                            .fieldStyle()
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
                        // сохраняем в AppState, чтобы следующие шаги и PDF получили актуальные данные
                        app.company = company
                        next()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(company.name.trimmingCharacters(in: .whitespaces).isEmpty ||
                              company.email.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding()
        }
        // ВАЖНО: автоподстановка сохранённой компании при открытии шага
        .onAppear {
            company = app.company ?? Company()
        }
    }
}

// MARK: - Step 2: Client

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

// MARK: - Step 3: Payment Details

struct StepPaymentDetailsView: View {
    @EnvironmentObject private var app: AppState
    @ObservedObject var vm: InvoiceWizardVM
    var prev: () -> Void
    var next: () -> Void

    @State private var showAddSheet = false
    @State private var editing: PaymentMethod? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Choice
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Details on Invoice").font(.headline)

                        Picker("Show on invoice", selection: $vm.paymentChoice) {
                            ForEach(InvoiceWizardVM.PaymentChoice.allCases) { ch in
                                Text(ch.title).tag(ch)
                            }
                        }
                        .pickerStyle(.segmented)

                        // Saved
                        if vm.paymentChoice == .saved {
                            if app.paymentMethods.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("You have no saved payment methods").foregroundStyle(.secondary)
                                    Button {
                                        showAddSheet = true
                                    } label: {
                                        Label("Add Method", systemImage: "plus")
                                    }
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(app.paymentMethods) { m in
                                        SavedMethodRow(
                                            method: m,
                                            isSelected: vm.selectedSaved.contains(m.id),
                                            onToggle: {
                                                if vm.selectedSaved.contains(m.id) {
                                                    vm.selectedSaved.remove(m.id)
                                                } else {
                                                    vm.selectedSaved.insert(m.id)
                                                }
                                            },
                                            onEdit: { editing = m }
                                        )
                                    }
                                    Button {
                                        showAddSheet = true
                                    } label: {
                                        Label("Add Another", systemImage: "plus")
                                    }
                                }
                            }
                        }

                        // Custom per-invoice
                        if vm.paymentChoice == .custom {
                            // Используем твой общий редактор методов, который уже есть в проекте
                            PaymentMethodsEditor(methods: $vm.customMethods)
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Additional notes (optional)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("Shown below the payment block in PDF",
                                      text: $vm.paymentNotes,
                                      axis: .vertical)
                            .textInputAutocapitalization(.never)
                            .lineLimit(2...5)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.08)))
                        }
                    }
                    .padding(4)
                }

                HStack {
                    Button("Previous", action: prev).buttonStyle(.bordered)
                    Spacer()
                    Button("Next", action: next)
                        .buttonStyle(.borderedProminent)
                        .disabled(!canProceed)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showAddSheet) {
            AddEditPaymentMethodSheet { new in
                // если мы в режиме saved — добавляем в сохранённые и сразу отмечаем выбранным
                if vm.paymentChoice == .saved {
                    app.paymentMethods.append(new)
                    app.savePaymentMethods()
                    vm.selectedSaved.insert(new.id)
                } else {
                    vm.customMethods.append(new)
                }
            }
        }
        .sheet(item: $editing) { m in
            AddEditPaymentMethodSheet(existing: m) { updated in
                if let idx = app.paymentMethods.firstIndex(where: { $0.id == m.id }) {
                    app.paymentMethods[idx] = updated
                    app.savePaymentMethods()
                }
            }
        }
    }

    private var canProceed: Bool {
        switch vm.paymentChoice {
        case .none:   return true
        case .saved:  return !vm.selectedSaved.isEmpty
        case .custom: return !vm.customMethods.isEmpty
        }
    }
}

private struct SavedMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(method.type.title).bold()
                Text(method.type.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Edit", action: onEdit)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15)))
    }
}

// MARK: - Step 4: Items & Pricing

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
                // Add Products/Services
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Add Products/Services", systemImage: "shippingbox")
                            Spacer()
                            Button("+ Add New") { /* TODO */ }
                        }

                        HStack(spacing: 8) {
                            TextField("Search products/services…", text: $search).fieldStyle()
                            Menu {
                                Picker("Category", selection: $category) {
                                    Text("All").tag("All")
                                    ForEach(Array(Set(app.products.map { $0.category })).sorted(), id: \.self) { c in
                                        Text(c).tag(c)
                                    }
                                }
                            } label: {
                                HStack { Text(category); Image(systemName: "chevron.down") }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
                            }
                        }

                        ForEach(filteredProducts) { p in
                            WizardProductRow(p: p) { add(product: p) }
                        }
                    }
                    .padding(4)
                }

                // Invoice Items
                GroupBox {
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
                    .padding(4)
                }

                HStack {
                    Button("Previous", action: prev).buttonStyle(.bordered)
                    Spacer()
                    Button("Generate", action: onSaved)
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
        guard let idx = vm.items.firstIndex(where: { $0.id == item.id }) else {
            return .constant(item)
        }
        return $vm.items[idx]
    }
}

// MARK: - Local product row for wizard

private struct WizardProductRow: View {
    let p: Product
    let onAdd: () -> Void
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack { Text(p.name).bold(); Tag(text: p.category) }
                if !p.details.isEmpty {
                    Text(p.details).font(.caption).foregroundStyle(.secondary)
                }
                Text("\(Money.fmt(p.rate, code: Locale.current.currency?.identifier ?? "USD")) / hour")
                    .font(.caption)
            }
            Spacer()
            Button(action: onAdd) {
                HStack { Image(systemName: "cart.badge.plus"); Text("Add") }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                    .foregroundStyle(.white)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15)))
    }
}

// MARK: - Details (read-only)

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

struct Tag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
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
        TextField(
            title,
            text: Binding(
                get: { NSDecimalNumber(decimal: value).stringValue },
                set: { value = Decimal(string: $0.replacingOccurrences(of: ",", with: ".")) ?? value }
            )
        )
        .keyboardType(.decimalPad)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
    }
}

// MARK: - ShareSheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var completion: UIActivityViewController.CompletionWithItemsHandler? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        vc.completionWithItemsHandler = completion
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
