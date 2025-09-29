//
//  AddEditPaymentMethodSheet.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

// AddEditPaymentMethodSheet.swift
import SwiftUI

struct AddEditPaymentMethodSheet: View {
    enum Kind: String, CaseIterable, Identifiable {
        case bankIBAN = "Bank • IBAN/SWIFT"
        case bankUS   = "Bank • US ACH/Wire"
        case paypal   = "PayPal"
        case cardLink = "Payment Link"
        case crypto   = "Crypto"
        case other    = "Other"
        var id: String { rawValue }
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

    @Environment(\.dismiss) private var dismiss

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
            Form {
                Section("Type") {
                    Picker("Payment method", selection: $kind) {
                        ForEach(Kind.allCases) { Text($0.rawValue).tag($0) }
                    }
                }

                switch kind {
                case .bankIBAN:
                    Section("Bank (IBAN/SWIFT)") {
                        TextField("Beneficiary (optional)", text: $beneficiary)
                        TextField("IBAN", text: $iban).textInputAutocapitalization(.never)
                        TextField("SWIFT/BIC", text: $swift).textInputAutocapitalization(.never)
                    }
                case .bankUS:
                    Section("Bank (US)") {
                        TextField("Bank name (optional)", text: $bankName)
                        TextField("Account number", text: $account).keyboardType(.numbersAndPunctuation)
                        TextField("Routing number", text: $routing).keyboardType(.numbersAndPunctuation)
                    }
                case .paypal:
                    Section("PayPal") {
                        TextField("PayPal email", text: $paypalEmail)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    }
                case .cardLink:
                    Section("Payment Link") {
                        TextField("URL (Stripe/Checkout)", text: $payURL)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                    }
                case .crypto:
                    Section("Crypto") {
                        Picker("Asset", selection: $cryptoKind) {
                            ForEach(CryptoKind.allCases) { Text($0.label).tag($0) }
                        }.pickerStyle(.segmented)
                        TextField("Address", text: $cryptoAddress).textInputAutocapitalization(.never)
                        TextField("Memo / Tag (optional)", text: $cryptoMemo).textInputAutocapitalization(.never)
                    }
                case .other:
                    Section("Custom method") {
                        TextField("Method name", text: $otherName)
                        TextEditor(text: $otherDetails).frame(minHeight: 90)
                    }
                }
            }
            .navigationTitle(existing == nil ? "Add Method" : "Edit Method")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(buildMethod())
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

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
