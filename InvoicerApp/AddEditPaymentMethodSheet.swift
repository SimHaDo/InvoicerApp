//
//  AddEditPaymentMethodSheet.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
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

struct AddEditPaymentMethodSheet: View {
    enum Kind: String, CaseIterable, Identifiable {
        case bankIBAN = "Bank • IBAN/SWIFT"
        case bankUS   = "Bank • US ACH/Wire"
        case paypal   = "PayPal"
        case cardLink = "Payment Link"
        case crypto   = "Crypto"
        case other    = "Other"
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .bankIBAN: return "building.columns"
            case .bankUS: return "building.columns"
            case .paypal: return "p.circle"
            case .cardLink: return "link"
            case .crypto: return "bitcoinsign.circle"
            case .other: return "ellipsis.circle"
            }
        }
    }

    private let existing: PaymentMethod?
    var onSave: (PaymentMethod) -> Void

    @State private var kind: Kind = .bankIBAN

    @State private var iban = ""
    @State private var swift = ""
    @State private var beneficiary = ""

    @State private var account = ""
    @State private var routing = ""
    @State private var bankName = ""

    @State private var paypalEmail = ""
    @State private var payURL = ""

    @State private var cryptoKind: CryptoKind = .btc
    @State private var cryptoAddress = ""
    @State private var cryptoMemo = ""

    @State private var otherName = "Other"
    @State private var otherDetails = ""
    
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var shimmerOffset: CGFloat = -1
    @State private var floatingElements: [FloatingElement] = []

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    init(existing: PaymentMethod? = nil, onSave: @escaping (PaymentMethod) -> Void) {
        self.existing = existing
        self.onSave = onSave
        if let ex = existing {
            switch ex.type {
            case .bankIBAN(let i, let s, let b):
                _kind = State(initialValue: .bankIBAN); _iban = State(initialValue: i); _swift = State(initialValue: s); _beneficiary = State(initialValue: b ?? "")
            case .bankUS(let a, let r, let bn):
                _kind = State(initialValue: .bankUS); _account = State(initialValue: a); _routing = State(initialValue: r); _bankName = State(initialValue: bn ?? "")
            case .paypal(let email):
                _kind = State(initialValue: .paypal); _paypalEmail = State(initialValue: email)
            case .cardLink(let url):
                _kind = State(initialValue: .cardLink); _payURL = State(initialValue: url)
            case .crypto(let ck, let addr, let memo):
                _kind = State(initialValue: .crypto); _cryptoKind = State(initialValue: ck); _cryptoAddress = State(initialValue: addr); _cryptoMemo = State(initialValue: memo ?? "")
            case .other(let name, let details):
                _kind = State(initialValue: .other); _otherName = State(initialValue: name); _otherDetails = State(initialValue: details)
            }
        }
    }
    init(initial: PaymentMethod, onSave: @escaping (PaymentMethod) -> Void) { self.init(existing: initial, onSave: onSave) }

    var body: some View {
        NavigationStack {
            ZStack {
                // Анимированный фон
                backgroundView()
                
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
                    VStack(alignment: .leading, spacing: 24) {
                        // Header с анимациями
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(existing == nil ? "Add Payment Method" : "Edit Payment Method")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.primary)
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                    .offset(y: showContent ? 0 : -20)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: showContent)
                                
                                Text("Choose your preferred payment method")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary.opacity(0.7))
                                    .offset(y: showContent ? 0 : -15)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                            }
                            Spacer()
                        }
                        
                        // Payment Method Type Selection
                        PaymentMethodTypeSection(kind: $kind)
                            .scaleEffect(showContent ? 1.0 : 0.9)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                        
                        // Dynamic Form Content
                        DynamicFormContent(
                            kind: $kind,
                            iban: $iban,
                            swift: $swift,
                            beneficiary: $beneficiary,
                            account: $account,
                            routing: $routing,
                            bankName: $bankName,
                            paypalEmail: $paypalEmail,
                            payURL: $payURL,
                            cryptoKind: $cryptoKind,
                            cryptoAddress: $cryptoAddress,
                            cryptoMemo: $cryptoMemo,
                            otherName: $otherName,
                            otherDetails: $otherDetails
                        )
                        .scaleEffect(showContent ? 1.0 : 0.9)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(buildMethod())
                        dismiss()
                    }
                    .disabled(!isValid)
                    .foregroundColor(isValid ? .primary : .primary.opacity(0.3))
                }
            }
        }
        .onAppear {
            showContent = true
            pulseAnimation = true
            startShimmerAnimation()
            createFloatingElements()
        }
    }
    
    // MARK: - Background View
    
    private func backgroundView() -> some View {
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

// MARK: - Payment Method Type Section

private struct PaymentMethodTypeSection: View {
    @Binding var kind: AddEditPaymentMethodSheet.Kind
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "creditcard.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Method Type")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Choose how customers will pay you")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary.opacity(0.7))
                }
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(AddEditPaymentMethodSheet.Kind.allCases) { methodKind in
                    PaymentMethodTypeRow(
                        kind: methodKind,
                        isSelected: kind == methodKind,
                        onTap: { kind = methodKind }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(scheme == .light ? 0.05 : 0.2), radius: 8, y: 4)
        )
    }
}

// MARK: - Payment Method Type Row

private struct PaymentMethodTypeRow: View {
    let kind: AddEditPaymentMethodSheet.Kind
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: kind.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? (scheme == .light ? .white : .black) : .primary)
                    .frame(width: 24)
                
                Text(kind.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? (scheme == .light ? .white : .black) : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(scheme == .light ? .white : .black)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.primary : (scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.primary : Color.primary.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}

// MARK: - Dynamic Form Content

private struct DynamicFormContent: View {
    @Binding var kind: AddEditPaymentMethodSheet.Kind
    @Binding var iban: String
    @Binding var swift: String
    @Binding var beneficiary: String
    @Binding var account: String
    @Binding var routing: String
    @Binding var bankName: String
    @Binding var paypalEmail: String
    @Binding var payURL: String
    @Binding var cryptoKind: CryptoKind
    @Binding var cryptoAddress: String
    @Binding var cryptoMemo: String
    @Binding var otherName: String
    @Binding var otherDetails: String
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Enter the required information")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary.opacity(0.7))
                }
                
                Spacer()
            }
            
            Group {
                switch kind {
                case .bankIBAN:
                    BankIBANForm()
                case .bankUS:
                    BankUSForm()
                case .paypal:
                    PayPalForm()
                case .cardLink:
                    CardLinkForm()
                case .crypto:
                    CryptoForm()
                case .other:
                    OtherForm()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(scheme == .light ? 0.05 : 0.2), radius: 8, y: 4)
        )
    }
    
    // MARK: - Form Components
    
    @ViewBuilder
    private func BankIBANForm() -> some View {
        VStack(spacing: 16) {
            CustomTextField(
                title: "Beneficiary (optional)",
                text: $beneficiary,
                placeholder: "Enter beneficiary name"
            )
            
            CustomTextField(
                title: "IBAN",
                text: $iban,
                placeholder: "Enter IBAN number",
                autocapitalization: .never
            )
            
            CustomTextField(
                title: "SWIFT/BIC",
                text: $swift,
                placeholder: "Enter SWIFT/BIC code",
                autocapitalization: .never
            )
        }
    }
    
    @ViewBuilder
    private func BankUSForm() -> some View {
        VStack(spacing: 16) {
            CustomTextField(
                title: "Bank Name (optional)",
                text: $bankName,
                placeholder: "Enter bank name"
            )
            
            CustomTextField(
                title: "Account Number",
                text: $account,
                placeholder: "Enter account number",
                keyboardType: .numbersAndPunctuation
            )
            
            CustomTextField(
                title: "Routing Number",
                text: $routing,
                placeholder: "Enter routing number",
                keyboardType: .numbersAndPunctuation
            )
        }
    }
    
    @ViewBuilder
    private func PayPalForm() -> some View {
        VStack(spacing: 16) {
            CustomTextField(
                title: "PayPal Email",
                text: $paypalEmail,
                placeholder: "Enter PayPal email address",
                autocapitalization: .never,
                keyboardType: .emailAddress
            )
        }
    }
    
    @ViewBuilder
    private func CardLinkForm() -> some View {
        VStack(spacing: 16) {
            CustomTextField(
                title: "Payment URL",
                text: $payURL,
                placeholder: "Enter Stripe/Checkout URL",
                autocapitalization: .never,
                keyboardType: .URL
            )
        }
    }
    
    @ViewBuilder
    private func CryptoForm() -> some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Cryptocurrency")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Picker("Asset", selection: $cryptoKind) {
                    ForEach(CryptoKind.allCases) { crypto in
                        Text(crypto.label).tag(crypto)
                    }
                }
                .pickerStyle(.segmented)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            
            CustomTextField(
                title: "Wallet Address",
                text: $cryptoAddress,
                placeholder: "Enter wallet address",
                autocapitalization: .never
            )
            
            CustomTextField(
                title: "Memo/Tag (optional)",
                text: $cryptoMemo,
                placeholder: "Enter memo or tag",
                autocapitalization: .never
            )
        }
    }
    
    @ViewBuilder
    private func OtherForm() -> some View {
        VStack(spacing: 16) {
            CustomTextField(
                title: "Method Name",
                text: $otherName,
                placeholder: "Enter payment method name"
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Details")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                TextEditor(text: $otherDetails)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .frame(minHeight: 100)
            }
        }
    }
}

// MARK: - Custom Text Field

private struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var autocapitalization: TextInputAutocapitalization = .sentences
    var keyboardType: UIKeyboardType = .default
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .textInputAutocapitalization(autocapitalization)
                .keyboardType(keyboardType)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Extensions

extension AddEditPaymentMethodSheet {
    private var isValid: Bool {
        switch kind {
        case .bankIBAN: return !iban.isEmpty && !swift.isEmpty
        case .bankUS:   return !account.isEmpty && !routing.isEmpty
        case .paypal:   return paypalEmail.contains("@")
        case .cardLink: return URL(string: payURL) != nil
        case .crypto:   return !cryptoAddress.isEmpty
        case .other:    return !otherName.trimmingCharacters(in: .whitespaces).isEmpty &&
                         !otherDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func buildMethod() -> PaymentMethod {
        let t: PaymentMethodType
        switch kind {
        case .bankIBAN: t = .bankIBAN(iban: iban, swift: swift, beneficiary: beneficiary.isEmpty ? nil : beneficiary)
        case .bankUS:   t = .bankUS(account: account, routing: routing, bankName: bankName.isEmpty ? nil : bankName)
        case .paypal:   t = .paypal(email: paypalEmail)
        case .cardLink: t = .cardLink(url: payURL)
        case .crypto:   t = .crypto(kind: cryptoKind, address: cryptoAddress, memo: cryptoMemo.isEmpty ? nil : cryptoMemo)
        case .other:    t = .other(name: otherName, details: otherDetails)
        }
        return PaymentMethod(id: existing?.id ?? UUID(), type: t)
    }
}