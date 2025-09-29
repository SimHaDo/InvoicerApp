//
//  UITokens.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/28/25.
//

import SwiftUI
import Foundation
import UIKit
// Design tokens
enum UI {
    static let spacing: CGFloat = 12
    static let corner: CGFloat  = 14
    static let hairline: CGFloat = 0.75

    static let bgCard   = Color(.secondarySystemBackground)
    static let stroke   = Color.secondary.opacity(0.12)
    static let muted    = Color.secondary.opacity(0.9)
    static let accent   = Color.accentColor
}

struct Card: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(UI.spacing)
            .background(RoundedRectangle(cornerRadius: UI.corner).fill(UI.bgCard))
            .overlay(RoundedRectangle(cornerRadius: UI.corner).stroke(UI.stroke, lineWidth: UI.hairline))
    }
}
extension View { func card() -> some View { modifier(Card()) } }

struct PrimaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .bold()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(UI.accent))
            .foregroundStyle(.white)
    }
}
extension View { func primaryButton() -> some View { modifier(PrimaryButton()) } }

struct SecondaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .bold()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
    }
}
extension View { func secondaryButton() -> some View { modifier(SecondaryButton()) } }

struct Chip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2).fontWeight(.semibold)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(Color.secondary.opacity(0.12)))
    }
}

struct StatusDot: View {
    var color: Color = .green.opacity(0.9)
    var body: some View {
        Circle().fill(color).frame(width: 8, height: 8)
    }
}
