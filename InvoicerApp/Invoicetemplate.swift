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
    // 12 тем (можно расширять)
    public static let themes: [TemplateTheme] = [
        .palette(name: "Ocean",   primary: .systemTeal),
        .palette(name: "Emerald", primary: .systemGreen),
        .palette(name: "Violet",  primary: .systemPurple),
        .palette(name: "Coral",   primary: .systemOrange),
        .palette(name: "Ruby",    primary: .systemRed),
        .palette(name: "Indigo",  primary: .systemIndigo),
        .palette(name: "Steel",   primary: .systemGray),
        .palette(name: "Sky",     primary: .systemBlue),
        .palette(name: "Slate",   primary: UIColor(red: 0.29, green: 0.33, blue: 0.39, alpha: 1)),
        .palette(name: "Aqua",    primary: UIColor(red: 0.03, green: 0.74, blue: 0.84, alpha: 1)),
        .palette(name: "Copper",  primary: UIColor(red: 0.71, green: 0.39, blue: 0.24, alpha: 1)),
        .palette(name: "Charcoal",primary: UIColor(red: 0.17, green: 0.20, blue: 0.24, alpha: 1)),
    ]

    public static var all: [InvoiceTemplateDescriptor] {
        var list: [InvoiceTemplateDescriptor] = []
        let styles: [TemplateStyle] = [.modern, .minimal, .classic]
        for style in styles {
            for theme in themes {
                let id = "\(style.rawValue)-\(theme.name.lowercased())"
                list.append(.init(id: id, name: "\(style.rawValue.capitalized) — \(theme.name)", style: style, theme: theme))
            }
        }
        return list // 36
    }
}
