//
//  Mock.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

// MARK: - Mock
enum Mock {
    static let customers: [Customer] = [
        Customer(name: "Acme Corporation", email: "billing@acme.com", phone: "+1 555 1010", address: Address(line1: "123 Market St", city: "San Francisco", state: "CA", zip: "94103", country: "USA")),
        Customer(name: "TechStart Inc.", email: "finance@techstart.com", phone: "+1 555 9999", address: Address(line1: "3109 Parkside Ct", city: "Louisville", state: "KY", zip: "40241", country: "USA"))
    ]
    static let products: [Product] = [
        Product(name: "Web Development", details: "Full‑stack web development services", rate: 150, category: "Development"),
        Product(name: "UI/UX Design", details: "User interface and experience design", rate: 120, category: "Design"),
        Product(name: "Mobile App Development", details: "iOS and Android app development", rate: 140, category: "Development")
    ]
    static let templates: [InvoiceTemplate] = [
        .init(name: "Classic Business", summary: "Clean and professional design for all business types", tags: ["Professional layout","Company logo space"], isPremium: false),
        .init(name: "Modern Minimalist", summary: "Sleek contemporary design", tags: ["Minimalist design","Custom colors"], isPremium: true),
        .init(name: "Creative Studio", summary: "Vibrant for agencies", tags: ["Creative layout","Color gradients"], isPremium: true),
        .init(name: "Executive Pro", summary: "Premium professional", tags: ["Executive design","Premium formatting"], isPremium: true),
        .init(name: "Tech Startup", summary: "Modern tech aesthetic", tags: ["Tech aesthetic","Bold typography"], isPremium: true),
        .init(name: "Elegant Premium", summary: "Sophisticated design", tags: ["Luxury design","Elegant typography"], isPremium: true)
    ]
}
