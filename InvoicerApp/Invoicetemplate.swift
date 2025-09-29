//
//  Invoicetemplate.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/28/25.
//

// InvoiceTemplate.swift
import SwiftUI
import UIKit

// Удобный размер под A4 в пунктах (72pt/inch)
public enum Paper {
    // A4: 595×842 pt
    static let a4 = CGSize(width: 595, height: 842)
}

public struct InvoiceTemplateDescriptor: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let style: TemplateStyle
    public let theme: TemplateTheme
}

public enum TemplateStyle: String, CaseIterable {
    case modern, minimal, classic
}

public struct TemplateTheme: Hashable {
    public let name: String
    public let primary: UIColor
    public let background: UIColor
    public let line: UIColor
    public let subtleText: UIColor

    static func palette(name: String, primary: UIColor) -> TemplateTheme {
        TemplateTheme(
            name: name,
            primary: primary,
            background: UIColor { $0.userInterfaceStyle == .dark ? .black : .white },
            line: .init(white: 0.85, alpha: 1),
            subtleText: .secondaryLabel
        )
    }
}

// Реестр 24+ тем (легко расширяем до 30+)
public enum TemplateCatalog {
    public static let themes: [TemplateTheme] = [
        .palette(name: "Ocean", primary: .systemTeal),
        .palette(name: "Emerald", primary: .systemGreen),
        .palette(name: "Violet", primary: .systemPurple),
        .palette(name: "Coral", primary: .systemOrange),
        .palette(name: "Ruby", primary: .systemRed),
        .palette(name: "Indigo", primary: .systemIndigo),
        .palette(name: "Steel", primary: .systemGray),
        .palette(name: "Sky", primary: .systemBlue),

        .palette(name: "Mint", primary: .systemMint),
        .palette(name: "Pink", primary: .systemPink),
        .palette(name: "Cyan", primary: .cyan),
        .palette(name: "Brown", primary: .brown),
        .palette(name: "Yellow", primary: .systemYellow),
        .palette(name: "Magenta", primary: .magenta),
        .palette(name: "Navy", primary: UIColor(red: 0.09, green: 0.12, blue: 0.32, alpha: 1)),
        .palette(name: "Slate", primary: UIColor(red: 0.29, green: 0.33, blue: 0.39, alpha: 1)),

        .palette(name: "Sunset", primary: UIColor(red: 0.98, green: 0.39, blue: 0.27, alpha: 1)),
        .palette(name: "Forest", primary: UIColor(red: 0.10, green: 0.49, blue: 0.33, alpha: 1)),
        .palette(name: "Lavender", primary: UIColor(red: 0.56, green: 0.44, blue: 0.86, alpha: 1)),
        .palette(name: "Grape", primary: UIColor(red: 0.40, green: 0.07, blue: 0.48, alpha: 1)),
        .palette(name: "Rose", primary: UIColor(red: 0.89, green: 0.23, blue: 0.44, alpha: 1)),
        .palette(name: "Aqua", primary: UIColor(red: 0.03, green: 0.74, blue: 0.84, alpha: 1)),
        .palette(name: "Copper", primary: UIColor(red: 0.71, green: 0.39, blue: 0.24, alpha: 1)),
        .palette(name: "Charcoal", primary: UIColor(red: 0.17, green: 0.20, blue: 0.24, alpha: 1)),
    ]

    // 3 стиля × 8 любимых тем = 24 комбинированных шаблона
    public static var all: [InvoiceTemplateDescriptor] {
        var list: [InvoiceTemplateDescriptor] = []
        let styles: [TemplateStyle] = [.modern, .minimal, .classic]
        for style in styles {
            for theme in themes.prefix(8) {
                let id = "\(style.rawValue)-\(theme.name.lowercased())"
                list.append(.init(id: id, name: "\(style.rawValue.capitalized) – \(theme.name)", style: style, theme: theme))
            }
        }
        return list
    }
}
