//
//  ProductsScreen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/28/25.
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
    @Environment(\.colorScheme) private var scheme

    @State private var showAddProduct = false
    @State private var editingProduct: Product? = nil
    @State private var showInvoiceCreation = false
    @State private var showEmptyPaywall = false
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
                    VStack(alignment: .leading, spacing: UI.largeSpacing) {

                        // Header с анимациями
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Products & Services")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.primary)
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                    .offset(y: showContent ? 0 : -20)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: showContent)
                                
                                Text("Manage your service catalog")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .offset(y: showContent ? 0 : -15)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                            }
                            Spacer()
                        }

                    // Actions с новым дизайном кнопок
                    HStack(spacing: 16) {
                        Button { showAddProduct = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Add Product")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.primary)
                        }
                        .scaleEffect(showContent ? 1.0 : 0.9)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)

                        Button { onCreateInvoice() } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Create Invoice")
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
                        .scaleEffect(showContent ? 1.0 : 0.9)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
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

                    // List
                    if app.products.isEmpty {
                        emptyList
                    } else {
                        VStack(spacing: 10) {
                            ForEach(vm.filtered(app.products)) { p in
                                ProductCard(
                                    product: p,
                                    onEdit: { editingProduct = p }
                                )
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .adaptiveContent()
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
            .fullScreenCover(isPresented: $showInvoiceCreation) {
                InvoiceCreationFlow(onClose: {
                    showInvoiceCreation = false
                })
                .environmentObject(app)
            }
            .sheet(isPresented: $showEmptyPaywall) {
                EmptyScreen()
            }
        }
        .onAppear {
            showContent = true
            pulseAnimation = true
            startShimmerAnimation()
            createFloatingElements()
        }
        }
    }

    // MARK: - Helpers

    private func onCreateInvoice() {
        // если лимит исчерпан и нет подписки — показываем paywall
        guard app.canCreateInvoice else {
            showEmptyPaywall = true
            return
        }
        // Открываем полноэкранный флоу создания инвойса
        showInvoiceCreation = true
    }


    private var emptyList: some View {
        VStack(spacing: 12) {
            Text("No products yet").font(.headline)
            Text("Add services you offer to invoice faster.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button { showAddProduct = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add Product")
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
            .scaleEffect(showContent ? 1.0 : 0.9)
            .opacity(showContent ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: showContent)
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
    var onEdit: () -> Void

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
                            .foregroundStyle(.primary)
                        Text(product.name)
                            .foregroundStyle(.primary)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        Button("Edit", action: onEdit)
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
                        .foregroundStyle(.secondary)
                }

                // Price row
                HStack {
                    Text(Money.fmt(product.rate, code: Locale.current.currency?.identifier ?? "USD"))
                        .bold()
                        .foregroundStyle(.primary)
                    Group {
                        switch kind {
                        case .hourly:            Text("/ hour")
                        case .fixed:             Text("(fixed)")
                        case .perUnit(let u):    Text("/ \(u)")
                        }
                    }
                    .foregroundStyle(.secondary)
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
    @Environment(\.colorScheme) private var scheme
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
    
    private var isAddMode: Bool {
        if case .add = mode { return true }
        return false
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                contentView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        hideKeyboard()
                    }
            )
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                basicInfoSection
                pricingSection
                previewSection
                saveButton
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: isAddMode ? "plus.circle.fill" : "pencil.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    Text(modeTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Text(isAddMode ? "Add a new product or service" : "Edit product details")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("Basic Information")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Essential details about your product")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                ModernTextField(
                    title: "Product Name",
                    text: $name,
                    icon: "shippingbox"
                )

                ModernTextField(
                    title: "Description (Optional)",
                    text: $details,
                    icon: "text.alignleft"
                )

                ModernTextField(
                    title: "Category",
                    text: $category,
                    icon: "folder"
                )
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("Pricing")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Set how this product is priced")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                pricingTypePicker
                if case .perUnit = pricing {
                    unitPicker
                }
                priceInput
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private var pricingTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pricing Type")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

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
        }
    }
    
    private var unitPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unit")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            Menu {
                Picker("Unit", selection: $unit) {
                    Text("Item").tag("item")
                    Text("Day").tag("day")
                    Text("Seat").tag("seat")
                    Text("License").tag("license")
                    Text("Hour").tag("hour")
                    Text("Project").tag("project")
                }
            } label: {
                HStack {
                    Text(unit.capitalized)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(unitPickerBackground)
            }
            .onChange(of: unit) { new in
                pricing = .perUnit(unit: new)
            }
        }
    }
    
    private var unitPickerBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                scheme == .dark ?
                Color(red: 0.12, green: 0.12, blue: 0.16) :
                Color.secondary.opacity(0.08)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        scheme == .dark ?
                        Color.blue.opacity(0.2) :
                        Color.clear,
                        lineWidth: 1
                    )
            )
    }
    
    private var priceInput: some View {
        ModernTextField(
            title: priceTitle,
            text: Binding(
                get: { 
                    if rate == 0 { return "" }
                    return String(format: "%.2f", NSDecimalNumber(decimal: rate).doubleValue)
                },
                set: { newValue in
                    if let decimal = Decimal(string: newValue.replacingOccurrences(of: ",", with: ".")) {
                        rate = decimal
                    } else if newValue.isEmpty {
                        rate = 0
                    }
                }
            ),
            icon: "dollarsign.circle"
        )
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("Preview")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Name:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(name.isEmpty ? "Product Name" : name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }

                HStack {
                    Text("Price:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(rate == 0 ? "$0.00" : Money.fmt(rate, code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Type:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(pricingTypeDisplay)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private var saveButton: some View {
        Button(action: save) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Product")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(saveButtonBackground)
        }
        .disabled(!canSave)
        .padding(.bottom, 32)
    }
    
    private var saveButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                canSave ?
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [.gray, .gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
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
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
    
    private var pricingTypeDisplay: String {
        switch pricing {
        case .hourly:              return "Hourly"
        case .perUnit(let u):      return "Per \(u)"
        case .fixed:               return "Fixed Price"
        }
    }
    
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
                    
                    // Радиальный градиент
                    RadialGradient(
                        colors: [Color.white, Color(white: 0.96), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 520
                    )
                    .blendMode(.screen)
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
                }
            }
        }
        .ignoresSafeArea()
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

// MARK: - Background View

extension ProductsScreen {
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
