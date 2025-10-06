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
    public let design: TemplateDesign
    public let category: TemplateCategory
    public let description: String
    public let isPremium: Bool
    public let previewImage: String // SF Symbol for preview
}

// Complete template with selected theme
public struct CompleteInvoiceTemplate: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let design: TemplateDesign
    public let category: TemplateCategory
    public let description: String
    public let isPremium: Bool
    public let previewImage: String
    public let theme: TemplateTheme
    
    init(template: InvoiceTemplateDescriptor, theme: TemplateTheme) {
        self.id = template.id
        self.name = template.name
        self.design = template.design
        self.category = template.category
        self.description = template.description
        self.isPremium = template.isPremium
        self.previewImage = template.previewImage
        self.theme = theme
    }
}

public enum TemplateDesign: String, CaseIterable {
    // Business Designs
    case modernClean, professionalMinimal, corporateFormal, executiveLuxury, businessClassic,
         enterpriseBold, consultingElegant, financialStructured, legalTraditional, healthcareModern,
         realEstateWarm, insuranceTrust, bankingSecure, accountingDetailed, consultingProfessional,
         
    // Creative Designs  
    creativeVibrant, artisticBold, designStudio, fashionElegant, photographyClean,
    
    // Technology Designs
    techModern,
    
    // Unique Layout Designs
    geometricAbstract, vintageRetro
}

public enum TemplateCategory: String, CaseIterable {
    case business = "Business"
    case creative = "Creative"
    case tech = "Technology"
    case professional = "Professional"
    case artistic = "Artistic"
}

public struct TemplateTheme: Hashable {
    public let name: String
    public let primary: UIColor
    public let secondary: UIColor
    public let accent: UIColor
    public let background: UIColor
    public let line: UIColor
    public let subtleText: UIColor
    public let headerGradient: [UIColor]

    static func palette(name: String, primary: UIColor, secondary: UIColor? = nil, accent: UIColor? = nil) -> TemplateTheme {
        let secondaryColor = secondary ?? primary.withAlphaComponent(0.7)
        let accentColor = accent ?? primary.withAlphaComponent(0.3)
        
        return TemplateTheme(
            name: name,
            primary: primary,
            secondary: secondaryColor,
            accent: accentColor,
            background: UIColor { $0.userInterfaceStyle == .dark ? .black : .white },
            line: .init(white: 0.85, alpha: 1),
            subtleText: .secondaryLabel,
            headerGradient: [primary, secondaryColor]
        )
    }
}

// Расширенный каталог с 30+ уникальными темплейтами
public enum TemplateCatalog {
    // 25 уникальных цветовых схем
    public static let themes: [TemplateTheme] = [
        // Business Colors
        .palette(name: "Ocean Blue", primary: UIColor(red: 0.0, green: 0.48, blue: 0.65, alpha: 1.0), secondary: UIColor(red: 0.0, green: 0.65, blue: 0.85, alpha: 1.0)),
        .palette(name: "Forest Green", primary: UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0), secondary: UIColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1.0)),
        .palette(name: "Royal Purple", primary: UIColor(red: 0.4, green: 0.0, blue: 0.6, alpha: 1.0), secondary: UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0)),
        .palette(name: "Crimson Red", primary: UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0), secondary: UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)),
        .palette(name: "Midnight Blue", primary: UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0), secondary: UIColor(red: 0.2, green: 0.2, blue: 0.5, alpha: 1.0)),
        
        // Creative Colors
        .palette(name: "Sunset Orange", primary: UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0), secondary: UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)),
        .palette(name: "Emerald Green", primary: UIColor(red: 0.0, green: 0.7, blue: 0.4, alpha: 1.0), secondary: UIColor(red: 0.2, green: 0.8, blue: 0.5, alpha: 1.0)),
        .palette(name: "Violet Dream", primary: UIColor(red: 0.6, green: 0.0, blue: 0.8, alpha: 1.0), secondary: UIColor(red: 0.8, green: 0.2, blue: 0.9, alpha: 1.0)),
        .palette(name: "Golden Yellow", primary: UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0), secondary: UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)),
        .palette(name: "Coral Pink", primary: UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0), secondary: UIColor(red: 1.0, green: 0.6, blue: 0.6, alpha: 1.0)),
        
        // Professional Colors
        .palette(name: "Charcoal Gray", primary: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0), secondary: UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)),
        .palette(name: "Navy Blue", primary: UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1.0), secondary: UIColor(red: 0.2, green: 0.2, blue: 0.7, alpha: 1.0)),
        .palette(name: "Steel Blue", primary: UIColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1.0), secondary: UIColor(red: 0.5, green: 0.6, blue: 0.8, alpha: 1.0)),
        .palette(name: "Slate Gray", primary: UIColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0), secondary: UIColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 1.0)),
        .palette(name: "Deep Teal", primary: UIColor(red: 0.0, green: 0.4, blue: 0.4, alpha: 1.0), secondary: UIColor(red: 0.2, green: 0.6, blue: 0.6, alpha: 1.0)),
        
        // Unique Colors
        .palette(name: "Electric Blue", primary: UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0), secondary: UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0)),
        .palette(name: "Lime Green", primary: UIColor(red: 0.5, green: 1.0, blue: 0.0, alpha: 1.0), secondary: UIColor(red: 0.7, green: 1.0, blue: 0.3, alpha: 1.0)),
        .palette(name: "Hot Pink", primary: UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0), secondary: UIColor(red: 1.0, green: 0.3, blue: 0.7, alpha: 1.0)),
        .palette(name: "Turquoise", primary: UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 1.0), secondary: UIColor(red: 0.3, green: 0.9, blue: 0.9, alpha: 1.0)),
        .palette(name: "Amber", primary: UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0), secondary: UIColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0)),
        .palette(name: "Magenta", primary: UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0), secondary: UIColor(red: 1.0, green: 0.3, blue: 1.0, alpha: 1.0)),
        .palette(name: "Cyan", primary: UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0), secondary: UIColor(red: 0.3, green: 1.0, blue: 1.0, alpha: 1.0)),
        .palette(name: "Indigo", primary: UIColor(red: 0.3, green: 0.0, blue: 0.7, alpha: 1.0), secondary: UIColor(red: 0.5, green: 0.2, blue: 0.9, alpha: 1.0)),
        .palette(name: "Maroon", primary: UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0), secondary: UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)),
        .palette(name: "Olive", primary: UIColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 1.0), secondary: UIColor(red: 0.7, green: 0.7, blue: 0.3, alpha: 1.0))
    ]

    public static var all: [InvoiceTemplateDescriptor] {
        // Только 20 действительно реализованных уникальных темплейтов с кардинально разными дизайнами
        return [
            // FREE TEMPLATES (2)
            InvoiceTemplateDescriptor(id: "modern-clean", name: "Modern Clean", design: .modernClean, category: .business, description: "Clean and professional layout with modern typography", isPremium: false, previewImage: "doc.text"),
            InvoiceTemplateDescriptor(id: "minimal-professional", name: "Minimal Professional", design: .professionalMinimal, category: .business, description: "Ultra-clean minimal design for professional use", isPremium: false, previewImage: "doc.plaintext"),
            
            // PREMIUM TEMPLATES - только действительно реализованные уникальные дизайны (18)
            InvoiceTemplateDescriptor(id: "corporate-formal", name: "Corporate Formal", design: .corporateFormal, category: .business, description: "Formal corporate layout with structured sections", isPremium: true, previewImage: "building.2"),
            InvoiceTemplateDescriptor(id: "executive-luxury", name: "Executive Luxury", design: .executiveLuxury, category: .business, description: "Luxury executive design with premium feel", isPremium: true, previewImage: "crown"),
            InvoiceTemplateDescriptor(id: "creative-vibrant", name: "Creative Vibrant", design: .creativeVibrant, category: .creative, description: "Vibrant creative layout with dynamic elements", isPremium: true, previewImage: "paintbrush"),
            InvoiceTemplateDescriptor(id: "tech-modern", name: "Tech Modern", design: .techModern, category: .tech, description: "Modern tech layout with sleek design", isPremium: true, previewImage: "laptopcomputer"),
            InvoiceTemplateDescriptor(id: "geometric-abstract", name: "Geometric Abstract", design: .geometricAbstract, category: .creative, description: "Abstract geometric layout with mathematical precision", isPremium: true, previewImage: "hexagon"),
            InvoiceTemplateDescriptor(id: "vintage-retro", name: "Vintage Retro", design: .vintageRetro, category: .creative, description: "Retro vintage layout with nostalgic charm", isPremium: true, previewImage: "clock"),
            InvoiceTemplateDescriptor(id: "business-classic", name: "Business Classic", design: .businessClassic, category: .business, description: "Classic business layout with traditional elements", isPremium: true, previewImage: "briefcase"),
            InvoiceTemplateDescriptor(id: "enterprise-bold", name: "Enterprise Bold", design: .enterpriseBold, category: .business, description: "Bold enterprise design for large companies", isPremium: true, previewImage: "building.columns"),
            InvoiceTemplateDescriptor(id: "consulting-elegant", name: "Consulting Elegant", design: .consultingElegant, category: .business, description: "Elegant consulting layout with sophisticated design", isPremium: true, previewImage: "person.2"),
            InvoiceTemplateDescriptor(id: "financial-structured", name: "Financial Structured", design: .financialStructured, category: .business, description: "Structured financial layout with detailed sections", isPremium: true, previewImage: "chart.bar"),
            InvoiceTemplateDescriptor(id: "legal-traditional", name: "Legal Traditional", design: .legalTraditional, category: .business, description: "Traditional legal layout with formal structure", isPremium: true, previewImage: "scale.3d"),
            InvoiceTemplateDescriptor(id: "healthcare-modern", name: "Healthcare Modern", design: .healthcareModern, category: .business, description: "Modern healthcare layout with clean design", isPremium: true, previewImage: "cross.case"),
            InvoiceTemplateDescriptor(id: "real-estate-warm", name: "Real Estate Warm", design: .realEstateWarm, category: .business, description: "Warm real estate layout with inviting design", isPremium: true, previewImage: "house"),
            InvoiceTemplateDescriptor(id: "insurance-trust", name: "Insurance Trust", design: .insuranceTrust, category: .business, description: "Trust-building insurance layout with secure feel", isPremium: true, previewImage: "shield"),
            InvoiceTemplateDescriptor(id: "banking-secure", name: "Banking Secure", design: .bankingSecure, category: .business, description: "Secure banking layout with professional trust", isPremium: true, previewImage: "banknote"),
            InvoiceTemplateDescriptor(id: "accounting-detailed", name: "Accounting Detailed", design: .accountingDetailed, category: .business, description: "Detailed accounting layout with precise structure", isPremium: true, previewImage: "calculator"),
            InvoiceTemplateDescriptor(id: "consulting-professional", name: "Consulting Professional", design: .consultingProfessional, category: .business, description: "Professional consulting layout with expertise feel", isPremium: true, previewImage: "person.crop.circle.badge.checkmark"),
            InvoiceTemplateDescriptor(id: "artistic-bold", name: "Artistic Bold", design: .artisticBold, category: .creative, description: "Bold artistic layout with expressive design", isPremium: true, previewImage: "paintpalette"),
            InvoiceTemplateDescriptor(id: "design-studio", name: "Design Studio", design: .designStudio, category: .creative, description: "Studio design layout with creative flair", isPremium: true, previewImage: "pencil.and.outline"),
            InvoiceTemplateDescriptor(id: "fashion-elegant", name: "Fashion Elegant", design: .fashionElegant, category: .creative, description: "Elegant fashion layout with style focus", isPremium: true, previewImage: "tshirt"),
            InvoiceTemplateDescriptor(id: "photography-clean", name: "Photography Clean", design: .photographyClean, category: .creative, description: "Clean photography layout with visual focus", isPremium: true, previewImage: "camera")
        ]
        // 20 действительно реализованных уникальных темплейтов (2 free + 18 premium) - каждый с кардинально разным дизайном
    }
    
    // Get templates by category
    public static func templates(for category: TemplateCategory) -> [InvoiceTemplateDescriptor] {
        return all.filter { $0.category == category }
    }
    
    // Get templates by design
    public static func templates(for design: TemplateDesign) -> [InvoiceTemplateDescriptor] {
        return all.filter { $0.design == design }
    }
    
    // Get popular templates (first 6)
    public static var popular: [InvoiceTemplateDescriptor] {
        return Array(all.prefix(6))
    }
    
    // Get free templates (2 only)
    public static var free: [InvoiceTemplateDescriptor] {
        return all.filter { !$0.isPremium }
    }
    
    // Get premium templates (78 total)
    public static var premium: [InvoiceTemplateDescriptor] {
        return all.filter { $0.isPremium }
    }
    
    // Check if template is premium
    public static func isPremium(_ template: InvoiceTemplateDescriptor) -> Bool {
        return template.isPremium
    }
    
    // Get featured templates (mix of different designs)
    public static var featured: [InvoiceTemplateDescriptor] {
        return [
            all.first { $0.id == "modern-clean" }!,
            all.first { $0.id == "minimal-professional" }!,
            all.first { $0.id == "corporate-formal" }!,
            all.first { $0.id == "creative-vibrant" }!,
            all.first { $0.id == "tech-modern" }!,
            all.first { $0.id == "geometric-abstract" }!,
            all.first { $0.id == "vintage-retro" }!,
            all.first { $0.id == "futuristic-scifi" }!,
            all.first { $0.id == "luxury-gold" }!,
            all.first { $0.id == "industrial-raw" }!
        ]
    }
}