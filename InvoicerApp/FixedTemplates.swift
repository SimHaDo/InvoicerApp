//
//  FixedTemplates.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

import SwiftUI
import UIKit

// MARK: - Simple and Reliable Template Renderer

protocol SimpleTemplateRenderer {
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?)
}

// MARK: - Shared base & helpers (печать-безопасные стили)

/// Набор утилит, чтобы все шаблоны выглядели ровно и печатались чисто.
final class BaseRenderer {
    // Поля страницы (A4 595x842 pt)
    struct PageInsets {
        let top: CGFloat = 36
        let left: CGFloat = 32
        let right: CGFloat = 32
        let bottom: CGFloat = 40
    }
    let insets = PageInsets()
    
    // Форматтеры
    static let money: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f
    }()
    
    static let date: DateFormatter = {
        let f = DateFormatter()
        // компактный и нейтральный для печати
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    func cur(_ amount: Decimal, code: String) -> String {
        // Если хочешь жёстко использовать код валюты, а не локаль:
        // BaseRenderer.money.currencyCode = code
        // BaseRenderer.money.currencySymbol = Locale.current.localizedString(forCurrencyCode: code) ?? code
        // Но по умолчанию даём системе решать символ.
        let ns = amount as NSDecimalNumber
        return BaseRenderer.money.string(from: ns) ?? "\(code) \(ns.doubleValue)"
    }
    
    // Типографика
    func text(_ string: String, font: UIFont, color: UIColor, kern: CGFloat = 0.2) -> NSAttributedString {
        NSAttributedString(string: string, attributes: [
            .font: font,
            .foregroundColor: color,
            .kern: kern
        ])
    }
    
    // Рисуем атрибуты в rect с обрезкой
    func draw(_ attr: NSAttributedString, in rect: CGRect) {
        attr.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }
    
    // Безопасный логотип (круг/скругление)
    func drawLogo(_ image: UIImage?, in rect: CGRect, context: CGContext, corner: CGFloat = 12, stroke: UIColor? = nil) {
        guard let img = image else { return }
        context.saveGState()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: corner).cgPath
        context.addPath(path)
        context.clip()
        img.draw(in: rect)
        context.restoreGState()
        if let stroke {
            context.setStrokeColor(stroke.cgColor)
            context.setLineWidth(1)
            context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: corner).cgPath)
            context.strokePath()
        }
    }
    
    // Примитивы
    func strokeLine(context: CGContext, from: CGPoint, to: CGPoint, color: UIColor, width: CGFloat = 1) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(width)
        context.move(to: from)
        context.addLine(to: to)
        context.strokePath()
    }
    
    func fillRect(context: CGContext, rect: CGRect, color: UIColor) {
        context.setFillColor(color.cgColor)
        context.fill(rect)
    }
    
    // Таблица: вычисление колонок от ширины
    func columns(totalWidth: CGFloat, specs: [CGFloat]) -> [CGFloat] {
        // specs — доли (например [0.56, 0.12, 0.14, 0.18])
        let sum = specs.reduce(0, +)
        return specs.map { totalWidth * ($0 / sum) }
    }
    
    // Подсчёты
    func computeSubtotal(from items: [LineItem]) -> Decimal {
        items.reduce(0) { $0 + $1.total }
    }
}

// Тема ожидается из твоей модели
// struct TemplateTheme { let primary: UIColor; let secondary: UIColor; let accent: UIColor }

// MARK: - Clean Modern Template

struct CleanModernTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let P = R.insets
        let primary = theme.primary
        let accent = theme.accent
        
        // Белый фон
        R.fillRect(context: context, rect: page, color: .white)
        
        // Header
        let headerH: CGFloat = 96
        let headerY = P.top
        let contentLeft = P.left
        let contentRight = page.width - P.right
        
        // Лого
        let logoRect = CGRect(x: contentLeft, y: headerY, width: 84, height: 84)
        R.drawLogo(logo, in: logoRect, context: context, corner: 12, stroke: primary.withAlphaComponent(0.15))
        
        // Company
        let name = R.text(company.name, font: .systemFont(ofSize: 28, weight: .black), color: primary, kern: 0.4)
        R.draw(name, in: CGRect(x: logoRect.maxX + 14, y: headerY + 2, width: contentRight - (logoRect.maxX + 14), height: 34))
        
        var y = headerY + 40
        let info = [
            company.address.oneLine,
            company.email
        ].filter { !$0.isEmpty }
        
        for line in info {
            let t = R.text(line, font: .systemFont(ofSize: 11, weight: .regular), color: .black.withAlphaComponent(0.8))
            R.draw(t, in: CGRect(x: logoRect.maxX + 14, y: y, width: contentRight - (logoRect.maxX + 14), height: 16))
            y += 16
        }
        
        // Правый верх: INVOICE + № + дата
        let invoiceTitle = R.text("INVOICE", font: .systemFont(ofSize: 22, weight: .black), color: primary, kern: 0.5)
        let titleW: CGFloat = 160
        R.draw(invoiceTitle, in: CGRect(x: contentRight - titleW, y: headerY, width: titleW, height: 26))
        
        let metaFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        R.draw(R.text("#\(invoice.number)", font: metaFont, color: .black),
               in: CGRect(x: contentRight - titleW, y: headerY + 28, width: titleW, height: 16))
        R.draw(R.text(BaseRenderer.date.string(from: invoice.issueDate), font: metaFont, color: .black),
               in: CGRect(x: contentRight - titleW, y: headerY + 46, width: titleW, height: 16))
        
        // Акцентная линия
        R.strokeLine(context: context,
                     from: CGPoint(x: contentLeft, y: headerY + headerH),
                     to: CGPoint(x: contentRight, y: headerY + headerH),
                     color: accent, width: 2)
        
        // BILL TO
        let billTop = headerY + headerH + 18
        R.draw(R.text("BILL TO", font: .systemFont(ofSize: 12, weight: .bold), color: primary),
               in: CGRect(x: contentLeft, y: billTop, width: 200, height: 16))
        var by = billTop + 18
        let custFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let custLines = [customer.name, customer.address.oneLine, customer.email].filter { !$0.isEmpty }
        for line in custLines {
            R.draw(R.text(line, font: custFont, color: .black),
                   in: CGRect(x: contentLeft, y: by, width: page.width * 0.5, height: 16))
            by += 18
        }
        
        // Таблица
        let tableTop = max(by + 12, billTop + 12)
        let tableLeft = contentLeft
        let tableWidth = contentRight - contentLeft
        let headerH2: CGFloat = 34
        
        // Шапка таблицы
        R.fillRect(context: context, rect: CGRect(x: tableLeft, y: tableTop, width: tableWidth, height: headerH2), color: primary)
        let headers = ["DESCRIPTION", "QTY", "RATE", "AMOUNT"]
        let parts = R.columns(totalWidth: tableWidth, specs: [0.58, 0.12, 0.14, 0.16])
        var zx = tableLeft + 10
        for (i, h) in headers.enumerated() {
            R.draw(R.text(h, font: .systemFont(ofSize: 11, weight: .bold), color: .white, kern: 0.4),
                   in: CGRect(x: zx, y: tableTop + 10, width: parts[i]-14, height: 16))
            zx += parts[i]
        }
        
        // Ряды
        var rowY = tableTop + headerH2
        let rowH: CGFloat = 30
        let rowFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        for (idx, item) in invoice.items.enumerated() {
            // зебра
            if idx % 2 == 0 {
                R.fillRect(context: context,
                           rect: CGRect(x: tableLeft, y: rowY, width: tableWidth, height: rowH),
                           color: UIColor.black.withAlphaComponent(0.03))
            }
            var cx = tableLeft + 10
            R.draw(R.text(item.description, font: rowFont, color: .black),
                   in: CGRect(x: cx, y: rowY + 7, width: parts[0]-14, height: 18))
            cx += parts[0]
            R.draw(R.text("\(item.quantity)", font: rowFont, color: .black),
                   in: CGRect(x: cx, y: rowY + 7, width: parts[1]-14, height: 18))
            cx += parts[1]
            R.draw(R.text(R.cur(item.rate, code: currency), font: rowFont, color: .black),
                   in: CGRect(x: cx, y: rowY + 7, width: parts[2]-14, height: 18))
            cx += parts[2]
            R.draw(R.text(R.cur(item.total, code: currency), font: rowFont, color: .black),
                   in: CGRect(x: cx, y: rowY + 7, width: parts[3]-14, height: 18))
            rowY += rowH
        }
        
        // TOTALS
        let totalsTop = rowY + 10
        let totalsWidth: CGFloat = 220
        let totalsX = contentRight - totalsWidth
        let labelFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let valueFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
        
        var ty = totalsTop
        let subtotal = R.computeSubtotal(from: invoice.items) // или invoice.subtotal если хочешь: замени здесь
        R.draw(R.text("Subtotal", font: labelFont, color: .black),
               in: CGRect(x: totalsX, y: ty, width: 110, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: valueFont, color: .black),
               in: CGRect(x: totalsX + 110, y: ty, width: 110, height: 16))
        ty += 18
        
        // Разделитель
        R.strokeLine(context: context, from: CGPoint(x: totalsX, y: ty + 4), to: CGPoint(x: contentRight, y: ty + 4), color: accent.withAlphaComponent(0.8))
        ty += 12
        
        let totalFont = UIFont.systemFont(ofSize: 16, weight: .black)
        let total = subtotal // + tax - discount (добавь при необходимости)
        R.draw(R.text("TOTAL", font: totalFont, color: accent),
               in: CGRect(x: totalsX, y: ty, width: 110, height: 20))
        R.draw(R.text(R.cur(total, code: currency), font: totalFont, color: accent),
               in: CGRect(x: totalsX + 110, y: ty, width: 110, height: 20))
        
        // Notes
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let notesTop = ty + 34
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .bold), color: primary),
                   in: CGRect(x: contentLeft, y: notesTop, width: 200, height: 16))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: contentLeft, y: notesTop + 18, width: contentRight - contentLeft, height: 60))
        }
        
        // Footer
        let footerY = page.height - P.bottom
        R.draw(R.text("Thank you for your business!", font: .systemFont(ofSize: 9, weight: .regular), color: .gray),
               in: CGRect(x: contentLeft, y: footerY - 12, width: contentRight - contentLeft, height: 12))
    }
}

// MARK: - Simple Minimal Template (ультрамин)

struct SimpleMinimalTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let P = R.insets
        let primary = theme.primary
        let accent = theme.accent
        
        R.fillRect(context: context, rect: page, color: .white)
        
        let left = P.left, right = page.width - P.right
        
        // Заголовок (тонкая типографика + точка-акцент)
        let name = R.text(company.name, font: .systemFont(ofSize: 24, weight: .thin), color: .black, kern: 0.6)
        R.draw(name, in: CGRect(x: left, y: P.top, width: right - left, height: 28))
        
        R.fillRect(context: context, rect: CGRect(x: left, y: P.top + 34, width: 6, height: 6), color: accent)
        R.strokeLine(context: context, from: CGPoint(x: left, y: P.top + 52), to: CGPoint(x: right, y: P.top + 52), color: primary.withAlphaComponent(0.4), width: 0.6)
        
        // Invoice meta (справа)
        let metaX = right - 160
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 11, weight: .light), color: .gray),
               in: CGRect(x: metaX, y: P.top, width: 160, height: 16))
        R.draw(R.text(BaseRenderer.date.string(from: invoice.issueDate), font: .systemFont(ofSize: 11, weight: .light), color: .gray),
               in: CGRect(x: metaX, y: P.top + 16, width: 160, height: 16))
        
        // BILL TO
        let billTop: CGFloat = P.top + 70
        R.draw(R.text("BILL TO", font: .systemFont(ofSize: 10, weight: .light), color: .gray, kern: 0.4),
               in: CGRect(x: left, y: billTop, width: 200, height: 14))
        var y = billTop + 18
        let lines = [customer.name, customer.address.oneLine, customer.email].filter { !$0.isEmpty }
        for line in lines {
            R.draw(R.text(line, font: .systemFont(ofSize: 13, weight: .regular), color: .black),
                   in: CGRect(x: left, y: y, width: page.width * 0.6, height: 18))
            y += 20
        }
        
        // Таблица
        let top = y + 12
        let width = right - left
        let parts = R.columns(totalWidth: width, specs: [0.6, 0.12, 0.14, 0.14])
        
        var cx = left
        let headFont = UIFont.systemFont(ofSize: 10, weight: .light)
        for (i, h) in ["ITEM", "QTY", "RATE", "TOTAL"].enumerated() {
            R.draw(R.text(h, font: headFont, color: .gray, kern: 0.4),
                   in: CGRect(x: cx, y: top, width: parts[i], height: 16))
            cx += parts[i]
        }
        R.strokeLine(context: context, from: CGPoint(x: left, y: top + 20), to: CGPoint(x: right, y: top + 20), color: accent, width: 0.6)
        
        var ry = top + 28
        let rowH: CGFloat = 24
        for item in invoice.items {
            var x = left
            R.draw(R.text(item.description, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: x, y: ry, width: parts[0], height: 18)); x += parts[0]
            R.draw(R.text("\(item.quantity)", font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: x, y: ry, width: parts[1], height: 18)); x += parts[1]
            R.draw(R.text(R.cur(item.rate, code: currency), font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: x, y: ry, width: parts[2], height: 18)); x += parts[2]
            R.draw(R.text(R.cur(item.total, code: currency), font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: x, y: ry, width: parts[3], height: 18))
            ry += rowH
        }
        
        // Totals
        let totalsWidth: CGFloat = 180
        let tx = right - totalsWidth
        let subtotal = R.computeSubtotal(from: invoice.items)
        var ty = ry + 8
        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 10, weight: .light), color: .gray),
               in: CGRect(x: tx, y: ty, width: 90, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 10, weight: .regular), color: .black),
               in: CGRect(x: tx + 90, y: ty, width: 90, height: 16))
        ty += 14
        
        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 3), to: CGPoint(x: right, y: ty + 3), color: accent, width: 0.6)
        ty += 10
        
        let total = subtotal
        let totalFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        R.draw(R.text("TOTAL", font: totalFont, color: accent),
               in: CGRect(x: tx, y: ty, width: 90, height: 18))
        R.draw(R.text(R.cur(total, code: currency), font: totalFont, color: accent),
               in: CGRect(x: tx + 90, y: ty, width: 90, height: 18))
        
        // Notes (по желанию)
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let nTop = ty + 26
            R.draw(R.text(notes, font: .systemFont(ofSize: 10, weight: .light), color: .gray),
                   in: CGRect(x: left, y: nTop, width: right - left, height: 40))
        }
        
        // Footer
        let fY = page.height - P.bottom
        R.draw(R.text("Thank you", font: .systemFont(ofSize: 8, weight: .light), color: .gray),
               in: CGRect(x: left, y: fY - 12, width: right - left, height: 12))
    }
}

// MARK: - Fixed Corporate Formal Template

struct FixedCorporateFormalTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let P = R.insets
        let primary = theme.primary
        let accent = theme.accent
        
        R.fillRect(context: context, rect: page, color: .white)
        
        // Корпоративная рамка шапки
        let headerRect = CGRect(x: P.left, y: P.top, width: page.width - P.left - P.right, height: 96)
        R.fillRect(context: context, rect: headerRect, color: primary.withAlphaComponent(0.05))
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1.5)
        context.stroke(headerRect)
        
        // Лого в квадрате
        let logoRect = CGRect(x: headerRect.minX + 14, y: headerRect.minY + 14, width: 68, height: 68)
        R.drawLogo(logo, in: logoRect, context: context, corner: 8, stroke: primary.withAlphaComponent(0.5))
        
        // Company
        R.draw(R.text(company.name, font: .systemFont(ofSize: 26, weight: .black), color: primary, kern: 0.5),
               in: CGRect(x: logoRect.maxX + 14, y: headerRect.minY + 16, width: headerRect.width - 160, height: 30))
        
        var y = headerRect.minY + 50
        for line in [company.address.oneLine, company.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(line, font: .systemFont(ofSize: 11, weight: .medium), color: .black),
                   in: CGRect(x: logoRect.maxX + 14, y: y, width: headerRect.width - 160, height: 16))
            y += 16
        }
        
        // Правый блок INVOICE
        let invBox = CGRect(x: headerRect.maxX - 170, y: headerRect.minY + 14, width: 156, height: 68)
        R.fillRect(context: context, rect: invBox, color: primary.withAlphaComponent(0.08))
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1)
        context.stroke(invBox)
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 18, weight: .black), color: primary),
               in: CGRect(x: invBox.minX + 10, y: invBox.minY + 8, width: invBox.width - 20, height: 20))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
               in: CGRect(x: invBox.minX + 10, y: invBox.minY + 30, width: invBox.width - 20, height: 16))
        R.draw(R.text(BaseRenderer.date.string(from: invoice.issueDate), font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
               in: CGRect(x: invBox.minX + 10, y: invBox.minY + 48, width: invBox.width - 20, height: 16))
        
        // Разделитель
        R.strokeLine(context: context,
                     from: CGPoint(x: headerRect.minX, y: headerRect.maxY + 12),
                     to: CGPoint(x: headerRect.maxX, y: headerRect.maxY + 12),
                     color: accent, width: 1.2)
        
        // BILL TO бокс
        let billRect = CGRect(x: headerRect.minX, y: headerRect.maxY + 24, width: 340, height: 86)
        R.fillRect(context: context, rect: billRect, color: primary.withAlphaComponent(0.03))
        context.setStrokeColor(primary.cgColor)
        context.stroke(billRect)
        R.draw(R.text("BILL TO", font: .systemFont(ofSize: 11, weight: .bold), color: primary),
               in: CGRect(x: billRect.minX + 10, y: billRect.minY + 10, width: 100, height: 16))
        var by = billRect.minY + 28
        for line in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(line, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: billRect.minX + 10, y: by, width: billRect.width - 20, height: 16))
            by += 18
        }
        
        // Таблица
        let left = headerRect.minX
        let right = headerRect.maxX
        let tableTop = billRect.maxY + 18
        let tableW = right - left
        let parts = R.columns(totalWidth: tableW, specs: [0.58, 0.12, 0.14, 0.16])
        
        let headRect = CGRect(x: left, y: tableTop, width: tableW, height: 36)
        R.fillRect(context: context, rect: headRect, color: primary)
        var hx = left + 12
        for (i, h) in ["DESCRIPTION", "QTY", "RATE", "AMOUNT"].enumerated() {
            R.draw(R.text(h, font: .systemFont(ofSize: 11, weight: .bold), color: .white),
                   in: CGRect(x: hx, y: tableTop + 10, width: parts[i]-16, height: 18))
            hx += parts[i]
        }
        var ry = headRect.maxY
        let rowH: CGFloat = 30
        for (idx, it) in invoice.items.enumerated() {
            if idx % 2 == 0 {
                R.fillRect(context: context, rect: CGRect(x: left, y: ry, width: tableW, height: rowH), color: primary.withAlphaComponent(0.03))
            }
            var x = left + 12
            R.draw(R.text(it.description, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: x, y: ry + 7, width: parts[0]-16, height: 18)); x += parts[0]
            R.draw(R.text("\(it.quantity)", font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: x, y: ry + 7, width: parts[1]-16, height: 18)); x += parts[1]
            R.draw(R.text(R.cur(it.rate, code: currency), font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: x, y: ry + 7, width: parts[2]-16, height: 18)); x += parts[2]
            R.draw(R.text(R.cur(it.total, code: currency), font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: x, y: ry + 7, width: parts[3]-16, height: 18))
            ry += rowH
        }
        
        // Totals (обрамление)
        let totalsW: CGFloat = 240
        let totalsX = right - totalsW
        let subtotal = R.computeSubtotal(from: invoice.items)
        var ty = ry + 10
        
        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: totalsX, y: ty, width: 120, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: totalsX + 120, y: ty, width: 120, height: 16))
        ty += 18
        
        R.strokeLine(context: context,
                     from: CGPoint(x: totalsX, y: ty + 4),
                     to:   CGPoint(x: right,   y: ty + 4),
                     color: accent, width: 1)
        ty += 12
        
        let total = subtotal
        let tFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        R.draw(R.text("TOTAL", font: tFont, color: .white),
               in: CGRect(x: totalsX + 10, y: ty + 8, width: 90, height: 20))
        R.draw(R.text(R.cur(total, code: currency), font: tFont, color: .white),
               in: CGRect(x: totalsX + 110, y: ty + 8, width: 120, height: 20))
        // фон плашки
        R.fillRect(context: context, rect: CGRect(x: totalsX, y: ty, width: totalsW, height: 38), color: primary)
        
        // Notes
        if let n = invoice.paymentNotes, !n.isEmpty {
            let notesTop = ty + 54
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 12, weight: .bold), color: primary),
                   in: CGRect(x: left, y: notesTop, width: 120, height: 18))
            R.draw(R.text(n, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: left, y: notesTop + 20, width: right - left, height: 60))
        }
        
        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business. Payment terms: Net 30 days.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 16, width: right - left, height: 16))
    }
}

// MARK: - Fixed Creative Vibrant Template

struct FixedCreativeVibrantTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let P = R.insets
        let primary = theme.primary
        let accent = theme.accent
        
        R.fillRect(context: context, rect: page, color: .white)
        
        // «Креативная» шапка с мягким градиентом (имитация через два слоя)
        let header = CGRect(x: 0, y: 0, width: page.width, height: 110)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.12))
        R.fillRect(context: context, rect: header.divided(atDistance: header.height*0.5, from: .minYEdge).remainder,
                   color: accent.withAlphaComponent(0.08))
        
        // Декоративные круги
        context.setFillColor(accent.withAlphaComponent(0.25).cgColor)
        for i in 0..<6 {
            let d: CGFloat = 18
            context.fillEllipse(in: CGRect(x: CGFloat(24 + i*60), y: 20 + CGFloat(i % 2)*10, width: d, height: d))
        }
        
        // Лого (круглая рамка)
        R.drawLogo(logo, in: CGRect(x: P.left, y: 28, width: 54, height: 54), context: context, corner: 27, stroke: accent)
        
        // Название + слоган
        R.draw(R.text(company.name, font: .systemFont(ofSize: 26, weight: .black), color: primary),
               in: CGRect(x: P.left + 70, y: 30, width: page.width - (P.left + 90), height: 28))
        R.draw(R.text("CREATIVE SOLUTIONS", font: .systemFont(ofSize: 12, weight: .semibold), color: accent),
               in: CGRect(x: P.left + 70, y: 60, width: page.width - (P.left + 90), height: 18))
        
        // INVOICE мета
        let metaX = page.width - P.right - 160
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 18, weight: .bold), color: accent),
               in: CGRect(x: metaX, y: 28, width: 160, height: 20))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 12, weight: .semibold), color: primary),
               in: CGRect(x: metaX, y: 50, width: 160, height: 18))
        
        // BILL TO (чип)
        let chipY = header.maxY + 16
        R.fillRect(context: context, rect: CGRect(x: P.left, y: chipY, width: 64, height: 22), color: primary.withAlphaComponent(0.1))
        R.draw(R.text("BILL TO", font: .systemFont(ofSize: 11, weight: .bold), color: primary),
               in: CGRect(x: P.left + 8, y: chipY + 3, width: 56, height: 16))
        
        var by = chipY + 28
        for line in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(line, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: P.left, y: by, width: page.width * 0.55, height: 18))
            by += 20
        }
        
        // Таблица (цветная шапка)
        let left = P.left, right = page.width - P.right
        let top = by + 12
        let w = right - left
        let parts = R.columns(totalWidth: w, specs: [0.55, 0.13, 0.14, 0.18])
        R.fillRect(context: context, rect: CGRect(x: left, y: top, width: w, height: 34), color: accent)
        var hx = left + 10
        for (i, h) in ["Item", "Qty", "Rate", "Total"].enumerated() {
            R.draw(R.text(h, font: .systemFont(ofSize: 11, weight: .bold), color: .white),
                   in: CGRect(x: hx, y: top + 9, width: parts[i]-14, height: 16))
            hx += parts[i]
        }
        var ry = top + 34
        let rowH: CGFloat = 26
        for (idx, it) in invoice.items.enumerated() {
            if idx % 2 == 0 {
                R.fillRect(context: context, rect: CGRect(x: left, y: ry, width: w, height: rowH), color: primary.withAlphaComponent(0.06))
            }
            var x = left + 10
            R.draw(R.text(it.description, font: .systemFont(ofSize: 11, weight: .medium), color: .black),
                   in: CGRect(x: x, y: ry + 5, width: parts[0]-14, height: 18)); x += parts[0]
            R.draw(R.text("\(it.quantity)", font: .systemFont(ofSize: 11, weight: .medium), color: .black),
                   in: CGRect(x: x, y: ry + 5, width: parts[1]-14, height: 18)); x += parts[1]
            R.draw(R.text(R.cur(it.rate, code: currency), font: .systemFont(ofSize: 11, weight: .medium), color: .black),
                   in: CGRect(x: x, y: ry + 5, width: parts[2]-14, height: 18)); x += parts[2]
            R.draw(R.text(R.cur(it.total, code: currency), font: .systemFont(ofSize: 11, weight: .bold), color: primary),
                   in: CGRect(x: x, y: ry + 5, width: parts[3]-14, height: 18))
            ry += rowH
        }
        
        // Total (яркая плашка)
        let totalsW: CGFloat = 200
        let subtotal = R.computeSubtotal(from: invoice.items)
        let total = subtotal
        let totalsX = right - totalsW
        let tTop = ry + 12
        
        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: totalsX, y: tTop, width: 100, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: totalsX + 100, y: tTop, width: 100, height: 16))
        
        R.fillRect(context: context, rect: CGRect(x: totalsX, y: tTop + 24, width: totalsW, height: 38), color: accent)
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 15, weight: .bold), color: .white),
               in: CGRect(x: totalsX + 10, y: tTop + 30, width: 90, height: 18))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 15, weight: .bold), color: .white),
               in: CGRect(x: totalsX + 100, y: tTop + 30, width: 100, height: 18))
        
        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("✨ Thank you for choosing our creative services! ✨", font: .systemFont(ofSize: 9, weight: .regular), color: .gray),
               in: CGRect(x: P.left, y: fy - 16, width: right - left, height: 16))
    }
}

// MARK: - Fixed Executive Luxury Template

struct FixedExecutiveLuxuryTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let P = R.insets
        let primary = theme.primary
        let accent = theme.accent
        
        R.fillRect(context: context, rect: page, color: .white)
        
        // «Люксовая» рамка
        let header = CGRect(x: 0, y: 0, width: page.width, height: 130)
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(header)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.05))
        
        R.drawLogo(logo, in: CGRect(x: P.left + 8, y: 26, width: 78, height: 78), context: context, corner: 12, stroke: accent)
        R.draw(R.text(company.name, font: .systemFont(ofSize: 28, weight: .bold), color: primary),
               in: CGRect(x: P.left + 100, y: 38, width: page.width - 240, height: 32))
        R.draw(R.text("EXECUTIVE SERVICES", font: .systemFont(ofSize: 13, weight: .medium), color: accent),
               in: CGRect(x: P.left + 100, y: 72, width: page.width - 240, height: 18))
        
        // INVOICE мета
        let metaX = page.width - P.right - 170
        R.fillRect(context: context, rect: CGRect(x: metaX, y: 38, width: 160, height: 60), color: accent.withAlphaComponent(0.12))
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 20, weight: .bold), color: accent),
               in: CGRect(x: metaX + 10, y: 44, width: 140, height: 22))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 14, weight: .semibold), color: primary),
               in: CGRect(x: metaX + 10, y: 68, width: 140, height: 18))
        
        // BILL TO box
        let bill = CGRect(x: P.left, y: header.maxY + 20, width: 360, height: 96)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.03))
        context.setStrokeColor(primary.cgColor); context.setLineWidth(1.2); context.stroke(bill)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 14, weight: .bold), color: primary),
               in: CGRect(x: bill.minX + 12, y: bill.minY + 10, width: 100, height: 20))
        var y = bill.minY + 32
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 13, weight: .medium), color: .black),
                   in: CGRect(x: bill.minX + 12, y: y, width: bill.width - 24, height: 18))
            y += 20
        }
        
        // Таблица
        let left = P.left, right = page.width - P.right
        let top = bill.maxY + 18
        let w = right - left
        let parts = R.columns(totalWidth: w, specs: [0.55, 0.15, 0.15, 0.15])
        R.fillRect(context: context, rect: CGRect(x: left, y: top, width: w, height: 36), color: primary)
        var hx = left + 12
        for (i, h) in ["Description", "Qty", "Unit Price", "Total"].enumerated() {
            R.draw(R.text(h, font: .systemFont(ofSize: 12, weight: .bold), color: .white),
                   in: CGRect(x: hx, y: top + 10, width: parts[i]-16, height: 18))
            hx += parts[i]
        }
        var ry = top + 36
        let rowH: CGFloat = 32
        for (idx, it) in invoice.items.enumerated() {
            if idx % 2 == 0 {
                R.fillRect(context: context, rect: CGRect(x: left, y: ry, width: w, height: rowH), color: accent.withAlphaComponent(0.06))
            }
            var x = left + 12
            R.draw(R.text(it.description, font: .systemFont(ofSize: 12, weight: .medium), color: .black),
                   in: CGRect(x: x, y: ry + 8, width: parts[0]-16, height: 18)); x += parts[0]
            R.draw(R.text("\(it.quantity)", font: .systemFont(ofSize: 12, weight: .medium), color: .black),
                   in: CGRect(x: x, y: ry + 8, width: parts[1]-16, height: 18)); x += parts[1]
            R.draw(R.text(R.cur(it.rate, code: currency), font: .systemFont(ofSize: 12, weight: .medium), color: .black),
                   in: CGRect(x: x, y: ry + 8, width: parts[2]-16, height: 18)); x += parts[2]
            R.draw(R.text(R.cur(it.total, code: currency), font: .systemFont(ofSize: 12, weight: .bold), color: accent),
                   in: CGRect(x: x, y: ry + 8, width: parts[3]-16, height: 18))
            ry += rowH
        }
        
        // Totals (золотистая плашка)
        let totalsW: CGFloat = 220
        let tx = right - totalsW
        let subtotal = R.computeSubtotal(from: invoice.items)
        var ty = ry + 12
        
        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 110, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 110, y: ty, width: 110, height: 16))
        ty += 20
        
        R.fillRect(context: context, rect: CGRect(x: tx, y: ty, width: totalsW, height: 42), color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: tx + 10, y: ty + 10, width: 90, height: 22))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: tx + 110, y: ty + 10, width: 100, height: 22))
        
        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business. Premium service guaranteed.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: P.left, y: fy - 16, width: right - P.left, height: 16))
    }
}

// MARK: - Fixed Tech Modern Template

struct FixedTechModernTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let P = R.insets
        let primary = theme.primary
        let accent = theme.accent
        
        R.fillRect(context: context, rect: page, color: .white)
        
        // Техно-шапка с геометрией
        let header = CGRect(x: 0, y: 0, width: page.width, height: 118)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.08))
        context.setFillColor(accent.withAlphaComponent(0.16).cgColor)
        for i in 0..<5 {
            let w: CGFloat = 56
            context.fill(CGRect(x: CGFloat(20 + i*110), y: 0, width: w, height: header.height))
        }
        
        R.drawLogo(logo, in: CGRect(x: P.left, y: 28, width: 60, height: 60), context: context, corner: 10, stroke: .white)
        R.draw(R.text(company.name, font: .systemFont(ofSize: 24, weight: .bold), color: primary),
               in: CGRect(x: P.left + 76, y: 36, width: page.width - 220, height: 26))
        R.draw(R.text("TECHNOLOGY SOLUTIONS", font: .systemFont(ofSize: 12, weight: .medium), color: accent),
               in: CGRect(x: P.left + 76, y: 62, width: page.width - 220, height: 18))
        
        let metaX = page.width - P.right - 170
        R.fillRect(context: context, rect: CGRect(x: metaX, y: 34, width: 160, height: 56), color: accent.withAlphaComponent(0.12))
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 16, weight: .bold), color: accent),
               in: CGRect(x: metaX + 10, y: 40, width: 140, height: 18))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 14, weight: .semibold), color: primary),
               in: CGRect(x: metaX + 10, y: 60, width: 140, height: 18))
        
        // BILL TO
        let billTop = header.maxY + 18
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 13, weight: .bold), color: primary),
               in: CGRect(x: P.left, y: billTop, width: 200, height: 18))
        var y = billTop + 20
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 12, weight: .medium), color: .black),
                   in: CGRect(x: P.left, y: y, width: page.width * 0.55, height: 18))
            y += 20
        }
        
        // Таблица
        let left = P.left, right = page.width - P.right
        let top = y + 14
        let w = right - left
        let parts = R.columns(totalWidth: w, specs: [0.58, 0.12, 0.14, 0.16])
        R.fillRect(context: context, rect: CGRect(x: left, y: top, width: w, height: 34), color: primary)
        var hx = left + 10
        for (i, h) in ["Description", "Qty", "Rate", "Amount"].enumerated() {
            R.draw(R.text(h, font: .systemFont(ofSize: 12, weight: .bold), color: .white),
                   in: CGRect(x: hx, y: top + 9, width: parts[i]-14, height: 18))
            hx += parts[i]
        }
        var ry = top + 34
        let rowH: CGFloat = 28
        for (idx, it) in invoice.items.enumerated() {
            if idx % 2 == 0 {
                R.fillRect(context: context, rect: CGRect(x: left, y: ry, width: w, height: rowH), color: accent.withAlphaComponent(0.06))
            }
            var x = left + 10
            R.draw(R.text(it.description, font: .systemFont(ofSize: 11, weight: .medium), color: .black),
                   in: CGRect(x: x, y: ry + 6, width: parts[0]-14, height: 18)); x += parts[0]
            R.draw(R.text("\(it.quantity)", font: .systemFont(ofSize: 11, weight: .medium), color: .black),
                   in: CGRect(x: x, y: ry + 6, width: parts[1]-14, height: 18)); x += parts[1]
            R.draw(R.text(R.cur(it.rate, code: currency), font: .systemFont(ofSize: 11, weight: .medium), color: .black),
                   in: CGRect(x: x, y: ry + 6, width: parts[2]-14, height: 18)); x += parts[2]
            R.draw(R.text(R.cur(it.total, code: currency), font: .systemFont(ofSize: 11, weight: .bold), color: primary),
                   in: CGRect(x: x, y: ry + 6, width: parts[3]-14, height: 18))
            ry += rowH
        }
        
        // Totals
        let subtotal = R.computeSubtotal(from: invoice.items)
        let total = subtotal
        let totalsW: CGFloat = 200
        let tx = right - totalsW
        var ty = ry + 10
        
        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 100, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 100, y: ty, width: 100, height: 16))
        ty += 18
        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 1)
        ty += 12
        R.fillRect(context: context, rect: CGRect(x: tx, y: ty, width: totalsW, height: 36), color: accent)
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: tx + 10, y: ty + 8, width: 90, height: 20))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: tx + 100, y: ty + 8, width: 100, height: 20))
        
        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Powered by technology. Innovation delivered.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: P.left, y: fy - 16, width: right - P.left, height: 16))
    }
}

// MARK: - Fixed Template Factory (как у тебя, но без изменений интерфейса)

class FixedTemplateFactory {
    static func createTemplate(for design: TemplateDesign, theme: TemplateTheme) -> SimpleTemplateRenderer {
        switch design {
        case .modernClean:
            return CleanModernTemplate(theme: theme)
        case .professionalMinimal:
            return SimpleMinimalTemplate(theme: theme)
        case .corporateFormal:
            return FixedCorporateFormalTemplate(theme: theme)
        case .creativeVibrant:
            return FixedCreativeVibrantTemplate(theme: theme)
        case .executiveLuxury:
            return FixedExecutiveLuxuryTemplate(theme: theme)
        case .techModern:
            return FixedTechModernTemplate(theme: theme)
        case .geometricAbstract:
            return AllGeometricAbstractTemplate(theme: theme)
        case .vintageRetro:
            return AllVintageRetroTemplate(theme: theme)
        case .businessClassic:
            return AllBusinessClassicTemplate(theme: theme)
        case .enterpriseBold:
            return EnterpriseBoldTemplate(theme: theme)
        case .consultingElegant:
            return ConsultingElegantTemplate(theme: theme)
        case .financialStructured:
            return FinancialStructuredTemplate(theme: theme)
        case .legalTraditional:
            return LegalTraditionalTemplate(theme: theme)
        case .healthcareModern:
            return HealthcareModernTemplate(theme: theme)
        case .realEstateWarm:
            return RealEstateWarmTemplate(theme: theme)
        case .insuranceTrust:
            return InsuranceTrustTemplate(theme: theme)
        case .bankingSecure:
            return BankingSecureTemplate(theme: theme)
        case .accountingDetailed:
            return AccountingDetailedTemplate(theme: theme)
        case .consultingProfessional:
            return ConsultingProfessionalTemplate(theme: theme)
        case .artisticBold:
            return ArtisticBoldTemplate(theme: theme)
        case .designStudio:
            return DesignStudioTemplate(theme: theme)
        case .fashionElegant:
            return FashionElegantTemplate(theme: theme)
        case .photographyClean:
            return PhotographyCleanTemplate(theme: theme)
        default:
            return CleanModernTemplate(theme: theme)
        }
    }
}
