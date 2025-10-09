//
//  Services.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

// MARK: - Services / Storage

enum StorageKey: String {
    case company, customers, products, invoices, settings   // ← убрали logoData
}

enum Storage {
    static let enc = JSONEncoder()
    static let dec = JSONDecoder()

    static func save<T: Encodable>(_ v: T, key: StorageKey) {
        if let d = try? enc.encode(v) {
            UserDefaults.standard.set(d, forKey: key.rawValue)
        }
    }
    static func load<T: Decodable>(_ t: T.Type, key: StorageKey, fallback: T) -> T {
        guard let d = UserDefaults.standard.data(forKey: key.rawValue),
              let v = try? dec.decode(t, from: d) else { 
            print("Storage: Loading \(key.rawValue) - using fallback data")
            return fallback 
        }
        print("Storage: Loading \(key.rawValue) - found saved data")
        return v
    }
    
    // MARK: - Logo Storage (File System)
    
    static func saveLogo(_ imageData: Data?) {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Storage: Failed to get documents directory")
            return
        }
        
        let logoURL = documentsURL.appendingPathComponent("company_logo.png")
        
        // Сначала удаляем старый файл если он существует
        if FileManager.default.fileExists(atPath: logoURL.path) {
            do {
                try FileManager.default.removeItem(at: logoURL)
                print("Storage: Old logo removed")
            } catch {
                print("Storage: Failed to remove old logo: \(error)")
            }
        }
        
        if let imageData = imageData {
            // Compress the image before saving
            if let image = UIImage(data: imageData),
               let compressedData = image.jpegData(compressionQuality: 0.7) {
                do {
                    try compressedData.write(to: logoURL)
                    print("Storage: Logo saved successfully, size: \(compressedData.count) bytes")
                } catch {
                    print("Storage: Failed to save logo: \(error)")
                }
            } else {
                print("Storage: Failed to compress image")
            }
        } else {
            print("Storage: Logo data is nil, file removed")
        }
    }
    
    static func loadLogo() -> Data? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Storage: Failed to get documents directory")
            return nil
        }
        
        let logoURL = documentsURL.appendingPathComponent("company_logo.png")
        
        guard FileManager.default.fileExists(atPath: logoURL.path) else {
            print("Storage: No logo file found")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: logoURL)
            print("Storage: Logo loaded successfully, size: \(data.count) bytes")
            return data
        } catch {
            print("Storage: Failed to load logo: \(error)")
            return nil
        }
    }
}

// MARK: - Money / Dates / Decimal ops

extension Decimal {
    static func + (l: Decimal, r: Decimal) -> Decimal {
        var a = l, b = r, c = Decimal()
        NSDecimalAdd(&c, &a, &b, .plain); return c
    }
    static func * (l: Decimal, r: Decimal) -> Decimal {
        var a = l, b = r, c = Decimal()
        NSDecimalMultiply(&c, &a, &b, .plain); return c
    }
}

enum Money {
    static func fmt(_ value: Decimal, code: String) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = code
        nf.maximumFractionDigits = 2
        return nf.string(from: value as NSNumber) ?? "\(value)"
    }
}

enum Dates {
    static let display: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
}
