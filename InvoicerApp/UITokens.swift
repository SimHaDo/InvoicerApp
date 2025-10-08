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
    
    // iPad-specific spacing
    static let largeSpacing: CGFloat = 16
    static let maxContentWidth: CGFloat = .infinity

    // MARK: - Dark Theme Colors
    static let bgCard   = Color(.secondarySystemBackground)
    static let stroke   = Color.secondary.opacity(0.12)
    static let muted    = Color.secondary.opacity(0.9)
    static let accent   = Color.accentColor
    
    // Dark theme specific colors
    static let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.08) // Deep dark blue-gray
    static let darkCardBackground = Color(red: 0.08, green: 0.08, blue: 0.12) // Slightly lighter card background
    static let darkSecondaryBackground = Color(red: 0.12, green: 0.12, blue: 0.16) // Secondary elements
    static let darkStroke = Color(red: 0.2, green: 0.2, blue: 0.25) // Subtle borders
    static let darkText = Color(red: 0.95, green: 0.95, blue: 0.97) // Almost white text
    static let darkSecondaryText = Color(red: 0.7, green: 0.7, blue: 0.75) // Muted text
    static let darkAccent = Color(red: 0.0, green: 0.8, blue: 1.0) // Bright cyan accent
    static let darkAccentSecondary = Color(red: 0.2, green: 0.6, blue: 0.9) // Secondary accent
    static let darkSuccess = Color(red: 0.0, green: 0.8, blue: 0.4) // Success green
    static let darkWarning = Color(red: 1.0, green: 0.7, blue: 0.0) // Warning orange
    static let darkError = Color(red: 1.0, green: 0.3, blue: 0.3) // Error red
    static let darkGradientStart = Color(red: 0.1, green: 0.1, blue: 0.2) // Gradient start
    static let darkGradientEnd = Color(red: 0.05, green: 0.05, blue: 0.15) // Gradient end
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

struct AdaptiveContent: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: isLargeScreen ? 800 : .infinity)
            .padding(.horizontal, isLargeScreen ? 24 : 20)
    }
    
        private var isLargeScreen: Bool {
            UIDevice.current.userInterfaceIdiom == .pad
        }
}
extension View { func adaptiveContent() -> some View { modifier(AdaptiveContent()) } }

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

// MARK: - Dark Theme Modifiers

struct DarkCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(UI.spacing)
            .background(
                RoundedRectangle(cornerRadius: UI.corner)
                    .fill(UI.darkCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: UI.corner)
                            .stroke(UI.darkStroke, lineWidth: UI.hairline)
                    )
            )
    }
}

struct DarkPrimaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .bold()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [UI.darkAccent, UI.darkAccentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundStyle(UI.darkText)
            .shadow(color: UI.darkAccent.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct DarkSecondaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(UI.darkSecondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(UI.darkStroke, lineWidth: 1)
                    )
            )
            .foregroundStyle(UI.darkText)
    }
}

struct DarkTextField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(UI.darkSecondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(UI.darkStroke, lineWidth: 1)
                    )
            )
            .foregroundStyle(UI.darkText)
    }
}

struct DarkNavigationBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [UI.darkGradientStart, UI.darkGradientEnd],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

struct DarkShimmer: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        UI.darkAccent.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isAnimating ? 200 : -200)
                .animation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Dark Theme Extensions
extension View {
    func darkCard() -> some View { modifier(DarkCard()) }
    func darkPrimaryButton() -> some View { modifier(DarkPrimaryButton()) }
    func darkSecondaryButton() -> some View { modifier(DarkSecondaryButton()) }
    func darkTextField() -> some View { modifier(DarkTextField()) }
    func darkNavigationBar() -> some View { modifier(DarkNavigationBar()) }
    func darkShimmer() -> some View { modifier(DarkShimmer()) }
    
    // Conditional modifier
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
