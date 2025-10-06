import Foundation
import UIKit

// MARK: - All Geometric Abstract Template

struct AllGeometricAbstractTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent

        // Background
        R.fillRect(context: context, rect: page, color: .white)

        // Header (геометрия + фирменный блок)
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 130)
        R.fillRect(context: context, rect: headerRect, color: primary.withAlphaComponent(0.08))

        // Абстрактные «точки»
        context.setFillColor(accent.withAlphaComponent(0.15).cgColor)
        for i in 0..<8 {
            let d: CGFloat = 40
            context.fillEllipse(in: CGRect(x: CGFloat(24 + i*80), y: 20, width: d, height: d))
        }

        // Логотип с рамкой
        let logoRect = CGRect(x: left + 8, y: 40, width: 70, height: 70)
        R.drawLogo(logo, in: logoRect, context: context, corner: 12, stroke: accent)

        // Название компании
        R.draw(R.text(company.name, font: .systemFont(ofSize: 26, weight: .black), color: primary),
               in: CGRect(x: logoRect.maxX + 16, y: 46, width: right - (logoRect.maxX + 16), height: 32))
        R.draw(R.text("GEOMETRIC DESIGN", font: .systemFont(ofSize: 13, weight: .medium), color: accent),
               in: CGRect(x: logoRect.maxX + 16, y: 80, width: right - (logoRect.maxX + 16), height: 18))

        // Блок инвойса (справа)
        let invBox = CGRect(x: right - 140, y: 40, width: 130, height: 80)
        R.fillRect(context: context, rect: invBox, color: accent.withAlphaComponent(0.12))
        R.strokeRect(context: context, rect: invBox, color: accent, width: 3)

        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 18, weight: .bold), color: accent),
               in: CGRect(x: invBox.minX + 8, y: invBox.minY + 8, width: invBox.width - 16, height: 22))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 14, weight: .semibold), color: primary),
               in: CGRect(x: invBox.minX + 8, y: invBox.minY + 32, width: invBox.width - 16, height: 18))
        R.draw(R.text(BaseRenderer.date.string(from: invoice.issueDate), font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
               in: CGRect(x: invBox.minX + 8, y: invBox.minY + 52, width: invBox.width - 16, height: 18))

        // BILL TO
        let billRect = CGRect(x: left, y: headerRect.maxY + 18, width: 300, height: 90)
        R.fillRect(context: context, rect: billRect, color: primary.withAlphaComponent(0.06))
        R.strokeRect(context: context, rect: billRect, color: primary, width: 2)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 14, weight: .bold), color: primary),
               in: CGRect(x: billRect.minX + 10, y: billRect.minY + 8, width: billRect.width - 20, height: 20))

        var by = billRect.minY + 30
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 12, weight: .medium), color: .black),
                   in: CGRect(x: billRect.minX + 10, y: by, width: billRect.width - 20, height: 18))
            by += 18
        }

        // Таблица (пагинация)
        let tableTop = billRect.maxY + 16
        let headers = ["Description", "Qty", "Rate", "Total"]
        let specs: [CGFloat] = [0.58, 0.12, 0.14, 0.16]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .bold), color: .white),
                            in: CGRect(x: x + 10, y: top + 9, width: w - 14, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.08)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 11, weight: .medium), color: .black),
                            in: CGRect(x: x + 10, y: y + 6, width: w - 14, height: 18))
            },
            rowH: 28, headerH: 35,
            continuationNoteColor: accent.withAlphaComponent(0.9)
        )

        // Если есть продолжение — тоталы рисуем на следующей странице
        guard res.hasMore == false else { return }

        // TOTALS (с безопасным переносом)
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 200
        let tx = right - totalsW
        let blockH: CGFloat = 16 + 38
        var tTop = R.placeBlock(below: res.lastY + 12, desiredHeight: blockH, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: tTop, width: 100, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 100, y: tTop, width: 100, height: 16))

        tTop += 20
        let totalBar = CGRect(x: tx, y: tTop, width: totalsW, height: 38)
        R.fillRect(context: context, rect: totalBar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 15, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 10, y: totalBar.minY + 9, width: 90, height: 20))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 15, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 100, y: totalBar.minY + 9, width: 100, height: 20))

        // NOTES (если есть место)
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let notesTop = totalBar.maxY + 20
            let maxH = max(0, (page.height - P.bottom) - (notesTop + 4))
            if maxH >= 16 {
                R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .bold), color: primary),
                       in: CGRect(x: left, y: notesTop, width: right - left, height: 16))
                R.draw(R.text(notes, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                       in: CGRect(x: left, y: notesTop + 18, width: right - left, height: maxH - 18))
            }
        }

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Geometric precision. Abstract beauty.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}

// MARK: - All Vintage Retro Template

struct AllVintageRetroTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent

        R.fillRect(context: context, rect: page, color: .white)

        // Header ретро
        let header = CGRect(x: 0, y: 0, width: page.width, height: 140)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.12))
        context.setFillColor(accent.withAlphaComponent(0.2).cgColor)
        for i in 0..<6 {
            context.fillEllipse(in: CGRect(x: CGFloat(i * 100 + 20), y: 10, width: 15, height: 15))
        }

        let logoRect = CGRect(x: left + 10, y: 40, width: 80, height: 80)
        R.drawLogo(logo, in: logoRect, context: context, corner: 10, stroke: accent)

        R.draw(R.text(company.name, font: .systemFont(ofSize: 30, weight: .bold), color: primary),
               in: CGRect(x: logoRect.maxX + 16, y: 50, width: right - (logoRect.maxX + 16), height: 36))
        R.draw(R.text("VINTAGE SERVICES", font: .systemFont(ofSize: 14, weight: .medium), color: accent),
               in: CGRect(x: logoRect.maxX + 16, y: 90, width: right - (logoRect.maxX + 16), height: 20))

        // Invoice блок
        let inv = CGRect(x: right - 150, y: 50, width: 150, height: 80)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.15))
        R.strokeRect(context: context, rect: inv, color: accent, width: 3)
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 20, weight: .bold), color: accent),
               in: CGRect(x: inv.minX + 8, y: inv.minY + 8, width: inv.width - 16, height: 22))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 16, weight: .semibold), color: primary),
               in: CGRect(x: inv.minX + 8, y: inv.minY + 34, width: inv.width - 16, height: 20))
        R.draw(R.text(DateFormatter.localizedString(from: invoice.issueDate, dateStyle: .medium, timeStyle: .none), font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
               in: CGRect(x: inv.minX + 8, y: inv.minY + 54, width: inv.width - 16, height: 18))

        // BILL TO
        let bill = CGRect(x: left, y: header.maxY + 20, width: 350, height: 100)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.08))
        R.strokeRect(context: context, rect: bill, color: primary, width: 2)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 16, weight: .bold), color: primary),
               in: CGRect(x: bill.minX + 10, y: bill.minY + 10, width: 120, height: 22))

        var by = bill.minY + 34
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 14, weight: .medium), color: .black),
                   in: CGRect(x: bill.minX + 10, y: by, width: bill.width - 20, height: 20))
            by += 22
        }

        // Таблица (пагинация)
        let tableTop = bill.maxY + 18
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let specs: [CGFloat] = [0.58, 0.12, 0.14, 0.16]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 13, weight: .bold), color: .white),
                            in: CGRect(x: x + 12, y: top + 10, width: w - 16, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.1)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 12, weight: .medium), color: .black),
                            in: CGRect(x: x + 12, y: y + 6, width: w - 16, height: 20))
            },
            rowH: 30, headerH: 40,
            continuationNoteColor: accent
           
        )

        guard res.hasMore == false else { return }

        // TOTALS
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 160
        let tx = right - totalsW
        let blockH: CGFloat = 18 + 55
        var ty = R.placeBlock(below: res.lastY + 12, desiredHeight: blockH, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 80, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 80, y: ty, width: 80, height: 16))
        ty += 20

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 55)
        R.fillRect(context: context, rect: totalBar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 18, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 10, y: totalBar.minY + 16, width: 80, height: 22))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 18, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 90, y: totalBar.minY + 16, width: 70, height: 22))

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Vintage charm. Timeless service.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}

// MARK: - All Business Classic Template

struct AllBusinessClassicTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent

        R.fillRect(context: context, rect: page, color: .white)

        // Классический заголовок
        let header = CGRect(x: 0, y: 0, width: page.width, height: 120)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.06))
        R.strokeRect(context: context, rect: header, color: primary, width: 2)

        let logoRect = CGRect(x: left + 8, y: 30, width: 70, height: 70)
        R.drawLogo(logo, in: logoRect, context: context, corner: 10, stroke: primary)

        R.draw(R.text(company.name, font: .systemFont(ofSize: 25, weight: .bold), color: primary),
               in: CGRect(x: logoRect.maxX + 16, y: 40, width: right - (logoRect.maxX + 16), height: 30))
        R.draw(R.text("CLASSIC BUSINESS", font: .systemFont(ofSize: 13, weight: .medium), color: .gray),
               in: CGRect(x: logoRect.maxX + 16, y: 72, width: right - (logoRect.maxX + 16), height: 18))

        // Блок инвойса
        let inv = CGRect(x: right - 140, y: 30, width: 140, height: 80)
        R.fillRect(context: context, rect: inv, color: primary.withAlphaComponent(0.08))
        R.strokeRect(context: context, rect: inv, color: primary, width: 2)
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 18, weight: .bold), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 8, width: inv.width - 20, height: 22))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 14, weight: .semibold), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 34, width: inv.width - 20, height: 18))
        R.draw(R.text(DateFormatter.localizedString(from: invoice.issueDate, dateStyle: .medium, timeStyle: .none), font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 54, width: inv.width - 20, height: 18))

        // BILL TO
        let bill = CGRect(x: left, y: header.maxY + 18, width: 320, height: 90)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.04))
        R.strokeRect(context: context, rect: bill, color: primary, width: 1)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 14, weight: .bold), color: primary),
               in: CGRect(x: bill.minX + 10, y: bill.minY + 8, width: 120, height: 20))

        var by = bill.minY + 30
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: bill.minX + 10, y: by, width: bill.width - 20, height: 18))
            by += 18
        }

        // Таблица
        let tableTop = bill.maxY + 16
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let specs: [CGFloat] = [0.58, 0.12, 0.14, 0.16]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .bold), color: .white),
                            in: CGRect(x: x + 10, y: top + 9, width: w - 14, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: primary.withAlphaComponent(0.05)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                            in: CGRect(x: x + 10, y: y + 6, width: w - 14, height: 18))
            },
            rowH: 28, headerH: 35,
            continuationNoteColor: accent
        )

        guard res.hasMore == false else { return }

        // TOTALS
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 160
        let tx = right - totalsW
        let blockH: CGFloat = 16 + 50
        var ty = R.placeBlock(below: res.lastY + 10, desiredHeight: blockH, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 80, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 80, y: ty, width: 80, height: 16))
        ty += 18

        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 1)
        ty += 8

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 50)
        R.fillRect(context: context, rect: totalBar, color: primary)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 10, y: totalBar.minY + 12, width: 80, height: 22))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 90, y: totalBar.minY + 12, width: 70, height: 22))

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business. Classic service guaranteed.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}

// MARK: - Enterprise Bold Template

struct EnterpriseBoldTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent

        R.fillRect(context: context, rect: page, color: .white)

        // Сильный Enterprise-хедер
        let header = CGRect(x: 0, y: 0, width: page.width, height: 150)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.15))
        context.setFillColor(accent.withAlphaComponent(0.25).cgColor)
        for i in 0..<4 {
            let w: CGFloat = 75
            context.fill(CGRect(x: CGFloat(20 + i*150), y: 0, width: w, height: header.height))
        }

        let logoRect = CGRect(x: left + 10, y: 50, width: 90, height: 90)
        R.drawLogo(logo, in: logoRect, context: context, corner: 12, stroke: accent)

        R.draw(R.text(company.name, font: .systemFont(ofSize: 32, weight: .black), color: primary),
               in: CGRect(x: logoRect.maxX + 20, y: 60, width: right - (logoRect.maxX + 20), height: 40))
        R.draw(R.text("ENTERPRISE SOLUTIONS", font: .systemFont(ofSize: 16, weight: .bold), color: accent),
               in: CGRect(x: logoRect.maxX + 20, y: 100, width: right - (logoRect.maxX + 20), height: 24))

        // Инвойс-правый бокс
        let inv = CGRect(x: right - 200, y: 60, width: 200, height: 80)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.2))
        R.strokeRect(context: context, rect: inv, color: accent, width: 4)
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 24, weight: .black), color: accent),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 8, width: inv.width - 20, height: 28))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 18, weight: .bold), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 38, width: inv.width - 20, height: 22))
        R.draw(R.text(BaseRenderer.date.string(from: invoice.issueDate), font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 60, width: inv.width - 20, height: 20))

        // BILL TO
        let bill = CGRect(x: left, y: header.maxY + 20, width: 400, height: 120)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.08))
        R.strokeRect(context: context, rect: bill, color: primary, width: 3)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 18, weight: .black), color: primary),
               in: CGRect(x: bill.minX + 12, y: bill.minY + 10, width: 140, height: 26))

        var by = bill.minY + 40
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 16, weight: .bold), color: .black),
                   in: CGRect(x: bill.minX + 12, y: by, width: bill.width - 24, height: 24))
            by += 26
        }

        // Таблица
        let tableTop = bill.maxY + 20
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let specs: [CGFloat] = [0.55, 0.15, 0.15, 0.15]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 14, weight: .black), color: .white),
                            in: CGRect(x: x + 12, y: top + 10, width: w - 16, height: 20))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.1)) } },
            rowCell: { c, v, x, w, y, _ in
                let f = (c == 3) ? UIFont.systemFont(ofSize: 13, weight: .bold) : UIFont.systemFont(ofSize: 13, weight: .bold)
                let col: UIColor = (c == 3) ? primary : .black
                self.R.draw(self.R.text(v, font: f, color: col),
                            in: CGRect(x: x + 12, y: y + 8, width: w - 16, height: 20))
            },
            rowH: 32, headerH: 45,
            continuationNoteColor: accent
            
        )

        guard res.hasMore == false else { return }

        // TOTALS
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 200
        let tx = right - totalsW
        let blockH: CGFloat = 18 + 70
        var ty = R.placeBlock(below: res.lastY + 12, desiredHeight: blockH, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 12, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 100, height: 18))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 12, weight: .bold), color: .black),
               in: CGRect(x: tx + 100, y: ty, width: 100, height: 18))
        ty += 20

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 70)
        R.fillRect(context: context, rect: totalBar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 20, weight: .black), color: .white),
               in: CGRect(x: totalBar.minX + 12, y: totalBar.minY + 22, width: 90, height: 26))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 20, weight: .black), color: .white),
               in: CGRect(x: totalBar.minX + 110, y: totalBar.minY + 22, width: 90, height: 26))

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Enterprise-grade service. Bold results guaranteed.", font: .systemFont(ofSize: 12, weight: .bold), color: .gray),
               in: CGRect(x: left, y: fy - 18, width: right - left, height: 18))
    }
}

// MARK: - Consulting Elegant Template

struct ConsultingElegantTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent

        R.fillRect(context: context, rect: page, color: .white)

        // Элегантный заголовок
        let header = CGRect(x: 0, y: 0, width: page.width, height: 130)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.05))

        context.setStrokeColor(accent.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1)
        for i in 0..<10 {
            let y = CGFloat(i * 13)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: page.width, y: y))
        }
        context.strokePath()

        let logoRect = CGRect(x: left + 6, y: 35, width: 75, height: 75)
        R.drawLogo(logo, in: logoRect, context: context, corner: 10, stroke: accent)

        R.draw(R.text(company.name, font: .systemFont(ofSize: 28, weight: .light), color: primary),
               in: CGRect(x: logoRect.maxX + 16, y: 45, width: right - (logoRect.maxX + 16), height: 34))
        R.draw(R.text("ELEGANT CONSULTING", font: .systemFont(ofSize: 14, weight: .medium), color: accent),
               in: CGRect(x: logoRect.maxX + 16, y: 80, width: right - (logoRect.maxX + 16), height: 20))

        // Инвойс бокс
        let inv = CGRect(x: right - 150, y: 40, width: 150, height: 80)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.08))
        R.strokeRect(context: context, rect: inv, color: accent, width: 2)
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 20, weight: .light), color: accent),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 8, width: inv.width - 20, height: 24))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 16, weight: .medium), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 34, width: inv.width - 20, height: 20))
        R.draw(R.text(DateFormatter.localizedString(from: invoice.issueDate, dateStyle: .medium, timeStyle: .none), font: .systemFont(ofSize: 12, weight: .medium), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 54, width: inv.width - 20, height: 18))

        // BILL TO
        let bill = CGRect(x: left, y: header.maxY + 18, width: 350, height: 100)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.03))
        R.strokeRect(context: context, rect: bill, color: primary, width: 1)
        R.draw(R.text("Bill To:", font: .systemFont(ofSize: 16, weight: .light), color: primary),
               in: CGRect(x: bill.minX + 10, y: bill.minY + 10, width: 120, height: 22))

        var by = bill.minY + 34
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 14, weight: .regular), color: .black),
                   in: CGRect(x: bill.minX + 10, y: by, width: bill.width - 20, height: 20))
            by += 22
        }

        // Таблица
        let tableTop = bill.maxY + 16
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let specs: [CGFloat] = [0.58, 0.12, 0.14, 0.16]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
        
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 13, weight: .light), color: .white),
                            in: CGRect(x: x + 10, y: top + 9, width: w - 14, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.05)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                            in: CGRect(x: x + 10, y: y + 6, width: w - 14, height: 18))
            },
            rowH: 28, headerH: 35,
            continuationNoteColor: accent
        )

        guard res.hasMore == false else { return }

        // TOTALS
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 180
        let tx = right - totalsW
        let blockH: CGFloat = 16 + 50
        var ty = R.placeBlock(below: res.lastY + 10, desiredHeight: blockH, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 90, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 90, y: ty, width: 90, height: 16))
        ty += 18

        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 1)
        ty += 8

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 50)
        R.fillRect(context: context, rect: totalBar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 18, weight: .light), color: .white),
               in: CGRect(x: totalBar.minX + 10, y: totalBar.minY + 14, width: 80, height: 22))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 18, weight: .light), color: .white),
               in: CGRect(x: totalBar.minX + 92, y: totalBar.minY + 14, width: 86, height: 22))

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Elegant consulting services. Sophisticated solutions.", font: .systemFont(ofSize: 11, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 16, width: right - left, height: 16))
    }
}
