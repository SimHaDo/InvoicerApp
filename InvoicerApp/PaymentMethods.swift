//
//  PaymentMethods.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

// PaymentMethods.swift
import Foundation

enum CryptoKind: String, CaseIterable, Codable, Identifiable, Hashable {
    case btc = "BTC", eth = "ETH", usdt = "USDT", usdc = "USDC", bnb = "BNB"
    var id: String { rawValue }
    var label: String { rawValue }
}

enum PaymentMethodType: Codable, Equatable, Hashable {
    case bankIBAN(iban: String, swift: String, beneficiary: String?)
    case bankUS(account: String, routing: String, bankName: String?)
    case paypal(email: String)
    case cardLink(url: String)                // Stripe/Checkout/Paylink
    case crypto(kind: CryptoKind, address: String, memo: String?)
    case other(name: String, details: String)

    private enum CodingKeys: String, CodingKey { case kind, payload }
    private enum Kind: String, Codable { case bankIBAN, bankUS, paypal, cardLink, crypto, other }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .bankIBAN(let iban, let swift, let beneficiary):
            try c.encode(Kind.bankIBAN, forKey: .kind)
            try c.encode(["iban": iban, "swift": swift, "beneficiary": beneficiary ?? ""], forKey: .payload)
        case .bankUS(let account, let routing, let bankName):
            try c.encode(Kind.bankUS, forKey: .kind)
            try c.encode(["account": account, "routing": routing, "bankName": bankName ?? ""], forKey: .payload)
        case .paypal(let email):
            try c.encode(Kind.paypal, forKey: .kind)
            try c.encode(["email": email], forKey: .payload)
        case .cardLink(let url):
            try c.encode(Kind.cardLink, forKey: .kind)
            try c.encode(["url": url], forKey: .payload)
        case .crypto(let kind, let addr, let memo):
            try c.encode(Kind.crypto, forKey: .kind)
            try c.encode(["kind": kind.rawValue, "address": addr, "memo": memo ?? ""], forKey: .payload)
        case .other(let name, let details):
            try c.encode(Kind.other, forKey: .kind)
            try c.encode(["name": name, "details": details], forKey: .payload)
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let k = try c.decode(Kind.self, forKey: .kind)
        let p = try c.decode([String:String].self, forKey: .payload)
        switch k {
        case .bankIBAN:
            self = .bankIBAN(
                iban: p["iban"] ?? "",
                swift: p["swift"] ?? "",
                beneficiary: p["beneficiary"].trimmedNonEmpty
            )
        case .bankUS:
            self = .bankUS(
                account: p["account"] ?? "",
                routing: p["routing"] ?? "",
                bankName: p["bankName"].trimmedNonEmpty
            )
        case .paypal:
            self = .paypal(email: p["email"] ?? "")
        case .cardLink:
            self = .cardLink(url: p["url"] ?? "")
        case .crypto:
            let kind = CryptoKind(rawValue: p["kind"] ?? "") ?? .btc
            self = .crypto(kind: kind,
                           address: p["address"] ?? "",
                           memo: p["memo"].trimmedNonEmpty)
        case .other:
            self = .other(name: (p["name"] ?? "Other"), details: p["details"] ?? "")
        }
    }

    // View helpers
    var title: String {
        switch self {
        case .bankIBAN: return "Bank Transfer (IBAN/SWIFT)"
        case .bankUS:   return "Bank Transfer (US ACH/Wire)"
        case .paypal:   return "PayPal"
        case .cardLink: return "Payment Link"
        case .crypto(let kind, _, _): return "Crypto (\(kind.label))"
        case .other(let name, _): return name.trimmedNonEmpty ?? "Other"
        }
    }

    var subtitle: String {
        switch self {
        case .bankIBAN(let iban, let swift, let beneficiary):
            return [beneficiary?.trimmedNonEmpty,
                    (iban.trimmedNonEmpty).map { "IBAN: \($0)" },
                    (swift.trimmedNonEmpty).map { "SWIFT: \($0)" }]
                .compactMap { $0 }
                .joined(separator: " · ")
        case .bankUS(let account, let routing, let bank):
            return [account.trimmedNonEmpty.map { "Acct: \($0)" },
                    routing.trimmedNonEmpty.map { "Routing: \($0)" },
                    bank?.trimmedNonEmpty]
                .compactMap { $0 }
                .joined(separator: " · ")
        case .paypal(let email):
            return email
        case .cardLink(let url):
            return url
        case .crypto(let kind, let addr, let memo):
            return ["\(kind.label): \(addr)".trimmedNonEmpty, memo?.trimmedNonEmpty]
                .compactMap { $0 }
                .joined(separator: " · ")
        case .other(_, let details):
            return details
        }
    }

    var isValid: Bool {
        switch self {
        case .bankIBAN(let iban, let swift, _):
            return !(iban.trimmedNonEmpty ?? "").isEmpty && !(swift.trimmedNonEmpty ?? "").isEmpty
        case .bankUS(let account, let routing, _):
            return !(account.trimmedNonEmpty ?? "").isEmpty && !(routing.trimmedNonEmpty ?? "").isEmpty
        case .paypal(let email):
            return !(email.trimmedNonEmpty ?? "").isEmpty
        case .cardLink(let url):
            return !(url.trimmedNonEmpty ?? "").isEmpty
        case .crypto(_, let address, _):
            return !(address.trimmedNonEmpty ?? "").isEmpty
        case .other(let name, let details):
            return !(name.trimmedNonEmpty ?? "").isEmpty && !(details.trimmedNonEmpty ?? "").isEmpty
        }
    }
}

struct PaymentMethod: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = .init()
    var type: PaymentMethodType
}

// Small helpers
private extension Optional where Wrapped == String {
    var trimmedNonEmpty: String? {
        switch self {
        case .some(let s):
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        case .none:
            return nil
        }
    }
}
private extension String {
    var trimmedNonEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
