//
//  Services.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

// MARK: - Services
enum StorageKey: String { case company, customers, products, invoices }

enum Storage {
    static let enc = JSONEncoder(); static let dec = JSONDecoder()
    static func save<T: Encodable>(_ v: T, key: StorageKey) { if let d = try? enc.encode(v) { UserDefaults.standard.set(d, forKey: key.rawValue) } }
    static func load<T: Decodable>(_ t: T.Type, key: StorageKey, fallback: T) -> T { guard let d = UserDefaults.standard.data(forKey: key.rawValue), let v = try? dec.decode(t, from: d) else { return fallback }; return v }
}

extension Decimal { static func + (l: Decimal, r: Decimal) -> Decimal { var a=l,b=r,c=Decimal(); NSDecimalAdd(&c,&a,&b,.plain); return c } ; static func * (l: Decimal, r: Decimal) -> Decimal { var a=l,b=r,c=Decimal(); NSDecimalMultiply(&c,&a,&b,.plain); return c } }

enum Money {
    static func fmt(_ value: Decimal, code: String) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = code
        nf.maximumFractionDigits = 2
        return nf.string(from: value as NSNumber) ?? "\(value)"
    }
}

enum Dates { static let display: DateFormatter = { let df = DateFormatter(); df.dateStyle = .medium; return df }() }
