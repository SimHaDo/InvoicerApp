import Foundation
import UIKit

// Общие утилиты форматирования
private func money(_ dec: Decimal, code: String) -> String {
    let n = NSDecimalNumber(decimal: dec)
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = code
    // если у вас уже передаётся символ, можно заменить на currencySymbol
    if f.currencySymbol == code { f.currencySymbol = code + " " }
    return f.string(from: n) ?? "\(code) \(n.doubleValue)"
}

private func line(_ ctx: CGContext, from a: CGPoint, to b: CGPoint, width: CGFloat = 1, color: UIColor = .lightGray) {
    ctx.setStrokeColor(color.cgColor)
    ctx.setLineWidth(width)
    ctx.move(to: a)
    ctx.addLine(to: b)
    ctx.strokePath()
}

private func drawText(_ text: String, _ rect: CGRect, font: UIFont, color: UIColor, align: NSTextAlignment = .left) {
    let style = NSMutableParagraphStyle()
    style.alignment = align
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: style]
    NSAttributedString(string: text, attributes: attrs).draw(in: rect)
}

// MARK: - PHOTOGRAPHY CLEAN (референс #1 — волнистая левая лента)

struct PhotographyCleanTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let primary = theme.primary
        let accent = theme.accent
        let left: CGFloat = 36
        let right: CGFloat = page.width - 36

        // Фон — белый
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)

        // Левая «волнистая» полоса (3 слоя, мягкие прозрачности)
        func wave(_ color: UIColor, x: CGFloat, w: CGFloat, alpha: CGFloat) {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addCurve(to: CGPoint(x: x + w, y: 0),
                          controlPoint1: CGPoint(x: x + w * 0.25, y: 60),
                          controlPoint2: CGPoint(x: x + w * 0.75, y: -60))
            path.addLine(to: CGPoint(x: x + w, y: page.height))
            path.addCurve(to: CGPoint(x: x, y: page.height),
                          controlPoint1: CGPoint(x: x + w * 0.75, y: page.height - 80),
                          controlPoint2: CGPoint(x: x + w * 0.25, y: page.height + 80))
            path.close()
            color.withAlphaComponent(alpha).setFill()
            path.fill()
        }
        wave(primary, x: -40, w: 160, alpha: 0.12)
        wave(accent,  x:  10, w: 120, alpha: 0.10)
        wave(primary.withAlphaComponent(0.6), x: 70, w: 90, alpha: 0.08)

        // Крупный заголовок INVOICE
        drawText("INVOICE",
                 CGRect(x: left, y: 24, width: 300, height: 44),
                 font: .systemFont(ofSize: 40, weight: .heavy),
                 color: primary)

        // Лого
        if let logo {
            let r = CGRect(x: right - 80, y: 24, width: 64, height: 64)
            context.setStrokeColor(primary.cgColor)
            context.setLineWidth(2)
            context.stroke(r)
            logo.draw(in: r)
        }

        // Информация о компании (слева)
        let infoY: CGFloat = 84
        drawText(company.name, CGRect(x: left, y: infoY, width: 260, height: 22), font: .systemFont(ofSize: 14, weight: .semibold), color: .black)
        let addr = [company.address.oneLine, company.phone, company.email].compactMap{$0}.filter{!$0.isEmpty}.joined(separator: "\n")
        drawText(addr, CGRect(x: left, y: infoY + 22, width: 260, height: 60), font: .systemFont(ofSize: 11, weight: .regular), color: .black)

        // Блок BILL TO / Реквизиты инвойса (две колонки)
        let colW = (right - left) / 2 - 8
        let blockTop: CGFloat = 170

        drawText("BILL TO", CGRect(x: left, y: blockTop, width: colW, height: 16), font: .systemFont(ofSize: 12, weight: .bold), color: primary)
        let billLines = [customer.name, customer.address.oneLine, customer.email].filter{ !$0.isEmpty }.joined(separator: "\n")
        drawText(billLines, CGRect(x: left, y: blockTop + 18, width: colW, height: 60), font: .systemFont(ofSize: 12), color: .black)

        drawText("INVOICE #", CGRect(x: left + colW + 16, y: blockTop, width: colW/2, height: 16), font: .systemFont(ofSize: 12, weight: .bold), color: primary)
        drawText(invoice.number, CGRect(x: left + colW + 16 + 90, y: blockTop, width: colW - 90, height: 16), font: .systemFont(ofSize: 12, weight: .regular), color: .black)
        drawText("INVOICE DATE", CGRect(x: left + colW + 16, y: blockTop + 18, width: colW/2, height: 16), font: .systemFont(ofSize: 12, weight: .bold), color: primary)
        let df = DateFormatter(); df.dateStyle = .short
        drawText(df.string(from: invoice.issueDate), CGRect(x: left + colW + 16 + 90, y: blockTop + 18, width: colW - 90, height: 16), font: .systemFont(ofSize: 12), color: .black)

        // Горизонтальная линия перед таблицей
        line(context, from: CGPoint(x: left, y: blockTop + 92), to: CGPoint(x: right, y: blockTop + 92), width: 1, color: primary.withAlphaComponent(0.4))

        // Таблица
        let tTop = blockTop + 100
        let cols: [CGFloat] = [0.12, 0.58, 0.15, 0.15] // QTY / DESC / UNIT / AMOUNT
        let widths = cols.map { (right - left) * $0 }
        let titles = ["QTY", "DESCRIPTION", "UNIT PRICE", "AMOUNT"]

        // Шапка
        var x = left
        for (i, t) in titles.enumerated() {
            drawText(t, CGRect(x: x + 6, y: tTop, width: widths[i] - 12, height: 18), font: .systemFont(ofSize: 11, weight: .semibold), color: primary)
            x += widths[i]
        }
        line(context, from: CGPoint(x: left, y: tTop + 20), to: CGPoint(x: right, y: tTop + 20), width: 1, color: primary.withAlphaComponent(0.4))

        // Строки
        var rowY = tTop + 22
        for (i, it) in invoice.items.enumerated() {
            if i % 2 == 0 {
                context.setFillColor(accent.withAlphaComponent(0.06).cgColor)
                context.fill(CGRect(x: left, y: rowY - 2, width: right - left, height: 24))
            }
            x = left
            drawText("\(it.quantity)", CGRect(x: x + 6, y: rowY, width: widths[0]-12, height: 18), font: .systemFont(ofSize: 11), color: .black)
            x += widths[0]
            drawText(it.description, CGRect(x: x + 6, y: rowY, width: widths[1]-12, height: 18), font: .systemFont(ofSize: 11), color: .black)
            x += widths[1]
            drawText(money(it.rate, code: currency), CGRect(x: x + 6, y: rowY, width: widths[2]-12, height: 18), font: .systemFont(ofSize: 11), color: .black, align: .right)
            x += widths[2]
            drawText(money(it.total, code: currency), CGRect(x: x + 6, y: rowY, width: widths[3]-12, height: 18), font: .systemFont(ofSize: 11, weight: .semibold), color: .black, align: .right)
            rowY += 24
        }

        line(context, from: CGPoint(x: left, y: rowY + 4), to: CGPoint(x: right, y: rowY + 4), width: 1, color: primary.withAlphaComponent(0.4))

        // Итоги справа
        let subtotal = invoice.items.map{$0.total}.reduce(0, +)
        drawText("Subtotal", CGRect(x: right - 180, y: rowY + 12, width: 100, height: 18), font: .systemFont(ofSize: 11), color: .darkGray, align: .right)
        drawText(money(subtotal, code: currency), CGRect(x: right - 80, y: rowY + 12, width: 80, height: 18), font: .systemFont(ofSize: 11), color: .black, align: .right)

        drawText("TOTAL", CGRect(x: right - 180, y: rowY + 36, width: 100, height: 22), font: .systemFont(ofSize: 14, weight: .bold), color: primary, align: .right)
        drawText(money(subtotal, code: currency), CGRect(x: right - 80, y: rowY + 36, width: 80, height: 22), font: .systemFont(ofSize: 14, weight: .bold), color: primary, align: .right)

        // Terms & Conditions (снизу слева)
        drawText("TERMS & CONDITIONS", CGRect(x: left, y: page.height - 120, width: right - left, height: 16), font: .systemFont(ofSize: 12, weight: .semibold), color: primary)
        let terms = "Payment is due within 15 days.\nPlease make checks payable to: \(company.name)."
        drawText(terms, CGRect(x: left, y: page.height - 100, width: right - left, height: 60), font: .systemFont(ofSize: 11), color: .darkGray)
    }
}

// MARK: - FASHION ELEGANT (референс #2 — минимализм, синяя шапка таблицы)

struct FashionElegantTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let accent = theme.accent
        let left: CGFloat = 40
        let right: CGFloat = page.width - 40

        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)

        // Заголовок по центру
        drawText("INVOICE", CGRect(x: 0, y: 28, width: page.width, height: 36), font: .systemFont(ofSize: 28, weight: .bold), color: .black, align: .center)

        // Компания (слева) + Лого (справа)
        drawText(company.name, CGRect(x: left, y: 80, width: right - left - 120, height: 20), font: .systemFont(ofSize: 16, weight: .semibold), color: .black)
        let details = [company.address.oneLine, company.phone, company.email].compactMap{$0}.filter{!$0.isEmpty}.joined(separator: "\n")
        drawText(details, CGRect(x: left, y: 104, width: right - left - 120, height: 60), font: .systemFont(ofSize: 12), color: .black)

        if let logo {
            let r = CGRect(x: right - 64, y: 84, width: 48, height: 48)
            logo.draw(in: r)
        }

        // Bill To / Invoice meta
        let top: CGFloat = 170
        let mid = (left + right) / 2 + 10
        drawText("Bill To", CGRect(x: left, y: top, width: 200, height: 16), font: .systemFont(ofSize: 12, weight: .semibold), color: .black)
        let bill = [customer.name, customer.address.oneLine, customer.email].filter{!$0.isEmpty}.joined(separator: "\n")
        drawText(bill, CGRect(x: left, y: top + 18, width: 260, height: 56), font: .systemFont(ofSize: 12), color: .black)

        drawText("Invoice No :", CGRect(x: mid, y: top, width: 120, height: 16), font: .systemFont(ofSize: 12, weight: .semibold), color: .black)
        drawText(invoice.number, CGRect(x: mid + 120, y: top, width: 160, height: 16), font: .systemFont(ofSize: 12), color: .black)
        let df = DateFormatter(); df.dateStyle = .medium
        drawText("Invoice Date :", CGRect(x: mid, y: top + 20, width: 120, height: 16), font: .systemFont(ofSize: 12, weight: .semibold), color: .black)
        drawText(df.string(from: invoice.issueDate), CGRect(x: mid + 120, y: top + 20, width: 160, height: 16), font: .systemFont(ofSize: 12), color: .black)

        // Разделительная линия
        line(context, from: CGPoint(x: left, y: top + 86), to: CGPoint(x: right, y: top + 86), width: 1, color: .lightGray)

        // Таблица — яркая синяя шапка
        let tableTop = top + 98
        let headers = ["Sl.", "Description", "Qty", "Rate", "Amount"]
        let widths: [CGFloat] = [50, (right-left) - 50 - 80 - 120 - 120, 80, 120, 120]
        context.setFillColor(primary.cgColor)
        context.fill(CGRect(x: left, y: tableTop, width: right - left, height: 28))
        var x = left
        for (i, h) in headers.enumerated() {
            drawText(h, CGRect(x: x + 8, y: tableTop + 6, width: widths[i] - 16, height: 16), font: .systemFont(ofSize: 12, weight: .semibold), color: .white)
            x += widths[i]
        }

        // Ряды
        var rowY = tableTop + 28
        for (index, it) in invoice.items.enumerated() {
            // тонкие разделители
            line(context, from: CGPoint(x: left, y: rowY), to: CGPoint(x: right, y: rowY), width: 0.6, color: UIColor(white: 0.9, alpha: 1))
            x = left
            drawText("\(index+1)", CGRect(x: x + 8, y: rowY + 6, width: widths[0]-16, height: 16), font: .systemFont(ofSize: 12), color: .black)
            x += widths[0]
            drawText(it.description, CGRect(x: x + 8, y: rowY + 6, width: widths[1]-16, height: 16), font: .systemFont(ofSize: 12), color: .black)
            x += widths[1]
            drawText("\(it.quantity)", CGRect(x: x + 8, y: rowY + 6, width: widths[2]-16, height: 16), font: .systemFont(ofSize: 12), color: .black)
            x += widths[2]
            drawText(money(it.rate, code: currency), CGRect(x: x, y: rowY + 6, width: widths[3]-8, height: 16), font: .systemFont(ofSize: 12), color: .black, align: .right)
            x += widths[3]
            drawText(money(it.total, code: currency), CGRect(x: x, y: rowY + 6, width: widths[4]-8, height: 16), font: .systemFont(ofSize: 12, weight: .semibold), color: .black, align: .right)
            rowY += 28
        }
        line(context, from: CGPoint(x: left, y: rowY), to: CGPoint(x: right, y: rowY), width: 1, color: .lightGray)

        // Сводка справа (Subtotal / Total / Balance Due)
        let subtotal = invoice.items.map{$0.total}.reduce(0, +)
        let boxX = right - 260
        drawText("Subtotal", CGRect(x: boxX, y: rowY + 12, width: 120, height: 18), font: .systemFont(ofSize: 12), color: .black)
        drawText(money(subtotal, code: currency), CGRect(x: right - 120, y: rowY + 12, width: 120, height: 18), font: .systemFont(ofSize: 12), color: .black, align: .right)

        drawText("Total", CGRect(x: boxX, y: rowY + 36, width: 120, height: 20), font: .systemFont(ofSize: 14, weight: .semibold), color: .black)
        drawText(money(subtotal, code: currency), CGRect(x: right - 120, y: rowY + 36, width: 120, height: 20), font: .systemFont(ofSize: 14, weight: .semibold), color: .black, align: .right)

        line(context,
             from: CGPoint(x: boxX, y: rowY + 62),
             to:   CGPoint(x: right, y: rowY + 62),
             width: 1,
             color: .lightGray)

        drawText("Payment Instructions", CGRect(x: left, y: rowY + 20, width: 300, height: 18), font: .systemFont(ofSize: 12, weight: .semibold), color: .black)
        drawText("Pay Cheque to\n\(company.name)", CGRect(x: left, y: rowY + 40, width: 300, height: 50), font: .systemFont(ofSize: 12), color: .darkGray)
    }
}

// MARK: - DESIGN STUDIO (референс #3 — оранжевые карточки)

struct DesignStudioTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let primary = theme.primary
        let accent = theme.accent
        let left: CGFloat = 36
        let right: CGFloat = page.width - 36

        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)

        // Верхняя панель с логотипом и номером инвойса справа
        if let logo {
            logo.draw(in: CGRect(x: left, y: 24, width: 72, height: 72))
        }
        drawText(company.name, CGRect(x: left + 88, y: 36, width: right - left - 200, height: 28), font: .systemFont(ofSize: 24, weight: .semibold), color: primary)
        drawText("Invoice \(invoice.number)", CGRect(x: right - 180, y: 36, width: 180, height: 20), font: .systemFont(ofSize: 16, weight: .bold), color: .black, align: .right)
        drawText("Tax invoice", CGRect(x: right - 180, y: 58, width: 180, height: 16), font: .systemFont(ofSize: 11, weight: .regular), color: .darkGray, align: .right)

        // Карточки (оранжевые) — Invoice No / Issue / Due / Total Due
        let cardH: CGFloat = 48
        let labels = ["Invoice No.", "Issue date", "Due date", "Total due (\(currency))"]
        let values = [
            invoice.number,
            DateFormatter.localizedString(from: invoice.issueDate, dateStyle: .short, timeStyle: .none),
            DateFormatter.localizedString(from: invoice.dueDate ?? invoice.issueDate, dateStyle: .short, timeStyle: .none),
            money(invoice.items.map{$0.total}.reduce(0,+), code: currency)
        ]
        let cardW = (right - left) / 4 - 6
        for i in 0..<4 {
            let x = left + CGFloat(i) * (cardW + 8)
            let r = CGRect(x: x, y: 120, width: cardW, height: cardH)
            context.setFillColor(UIColor.systemOrange.withAlphaComponent(i == 3 ? 0.9 : 0.75).cgColor)
            context.fill(r)
            drawText(labels[i], CGRect(x: r.minX + 10, y: r.minY + 6, width: r.width - 20, height: 16), font: .systemFont(ofSize: 11, weight: .semibold), color: .white)
            drawText(values[i], CGRect(x: r.minX + 10, y: r.minY + 22, width: r.width - 20, height: 20), font: .systemFont(ofSize: 14, weight: .bold), color: .white)
        }

        // BILL TO (слева) + даты (справа, тонким текстом)
        drawText("BILL TO", CGRect(x: left, y: 190, width: 200, height: 16), font: .systemFont(ofSize: 12, weight: .semibold), color: primary)
        let bill = [customer.name, customer.address.oneLine, customer.email].filter{!$0.isEmpty}.joined(separator: "\n")
        drawText(bill, CGRect(x: left, y: 210, width: right-left-220, height: 54), font: .systemFont(ofSize: 12), color: .black)

        drawText("Issue date:", CGRect(x: right - 220, y: 190, width: 90, height: 16), font: .systemFont(ofSize: 11, weight: .regular), color: .darkGray)
        drawText(DateFormatter.localizedString(from: invoice.issueDate, dateStyle: .short, timeStyle: .none),
                 CGRect(x: right - 120, y: 190, width: 120, height: 16), font: .systemFont(ofSize: 11), color: .black, align: .right)
        if let due = invoice.dueDate {
            drawText("Due date:", CGRect(x: right - 220, y: 208, width: 90, height: 16), font: .systemFont(ofSize: 11, weight: .regular), color: .darkGray)
            drawText(DateFormatter.localizedString(from: due, dateStyle: .short, timeStyle: .none),
                     CGRect(x: right - 120, y: 208, width: 120, height: 16), font: .systemFont(ofSize: 11), color: .black, align: .right)
        }

        // Таблица (тонкие серые линии)
        let tTop: CGFloat = 260
        line(context, from: CGPoint(x: left, y: tTop), to: CGPoint(x: right, y: tTop), width: 1, color: .lightGray)
        let headers = ["Description", "Quantity", "Unit price (\(currency))", "Amount (\(currency))"]
        let widths: [CGFloat] = [0.56, 0.14, 0.15, 0.15].map{ (right-left)*$0 }

        var x = left
        for (i, h) in headers.enumerated() {
            drawText(h, CGRect(x: x + 8, y: tTop + 6, width: widths[i] - 16, height: 18), font: .systemFont(ofSize: 12, weight: .semibold), color: .darkGray)
            x += widths[i]
        }
        line(context, from: CGPoint(x: left, y: tTop + 28), to: CGPoint(x: right, y: tTop + 28), width: 1, color: .lightGray)

        var rowY = tTop + 32
        for (i, it) in invoice.items.enumerated() {
            if i % 2 == 1 {
                context.setFillColor(UIColor(white: 0.97, alpha: 1).cgColor)
                context.fill(CGRect(x: left, y: rowY - 2, width: right-left, height: 24))
            }
            x = left
            drawText(it.description, CGRect(x: x + 8, y: rowY, width: widths[0]-16, height: 18), font: .systemFont(ofSize: 12), color: .black)
            x += widths[0]
            drawText("\(it.quantity)", CGRect(x: x, y: rowY, width: widths[1]-8, height: 18), font: .systemFont(ofSize: 12), color: .black, align: .right)
            x += widths[1]
            drawText(money(it.rate, code: currency), CGRect(x: x, y: rowY, width: widths[2]-8, height: 18), font: .systemFont(ofSize: 12), color: .black, align: .right)
            x += widths[2]
            drawText(money(it.total, code: currency), CGRect(x: x, y: rowY, width: widths[3]-8, height: 18), font: .systemFont(ofSize: 12, weight: .semibold), color: .black, align: .right)
            rowY += 24
        }
        line(context, from: CGPoint(x: left, y: rowY + 4), to: CGPoint(x: right, y: rowY + 4), width: 1, color: .lightGray)

        // Итоговая тёмная плашка TOTAL (как на референсе справа)
        let totalBox = CGRect(x: right - 260, y: rowY + 16, width: 260, height: 46)
        context.setFillColor(UIColor(white: 0.2, alpha: 1).cgColor)
        context.fill(totalBox)
        drawText("TOTAL DUE (\(currency))", CGRect(x: totalBox.minX + 12, y: totalBox.minY + 8, width: 150, height: 14), font: .systemFont(ofSize: 11, weight: .semibold), color: .white)
        let total = invoice.items.map{$0.total}.reduce(0,+)
        drawText(money(total, code: currency), CGRect(x: totalBox.minX + 12, y: totalBox.minY + 22, width: totalBox.width - 24, height: 18), font: .systemFont(ofSize: 16, weight: .bold), color: .white, align: .right)
    }
}

// MARK: - ARTISTIC BOLD (контрастный тёмный хедер, диагональная полоса)

struct ArtisticBoldTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let primary = theme.primary
        let accent = theme.accent
        let left: CGFloat = 34
        let right: CGFloat = page.width - 34

        // Фон
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)

        // Тёмный хедер с диагональным акцентом
        let header = CGRect(x: 0, y: 0, width: page.width, height: 120)
        context.setFillColor(UIColor(white: 0.12, alpha: 1).cgColor)
        context.fill(header)

        let stripe = UIBezierPath()
        stripe.move(to: CGPoint(x: page.width * 0.55, y: 0))
        stripe.addLine(to: CGPoint(x: page.width, y: 0))
        stripe.addLine(to: CGPoint(x: page.width, y: 120))
        stripe.addLine(to: CGPoint(x: page.width * 0.45, y: 120))
        stripe.close()
        accent.withAlphaComponent(0.6).setFill()
        stripe.fill()

        drawText("INVOICE", CGRect(x: left, y: 36, width: 240, height: 32), font: .systemFont(ofSize: 28, weight: .black), color: .white)
        drawText(company.name, CGRect(x: left, y: 72, width: right-left-160, height: 18), font: .systemFont(ofSize: 13, weight: .medium), color: UIColor(white: 0.9, alpha: 1))

        if let logo {
            logo.draw(in: CGRect(x: right - 70, y: 25, width: 45, height: 45))
        }

        // Метаданные справа под хедером
        let top: CGFloat = 136
        drawText("Invoice #", CGRect(x: right - 220, y: top, width: 90, height: 16), font: .systemFont(ofSize: 12, weight: .semibold), color: .darkGray, align: .right)
        drawText(invoice.number, CGRect(x: right - 120, y: top, width: 120, height: 16), font: .systemFont(ofSize: 12), color: .black, align: .right)
        drawText("Date", CGRect(x: right - 220, y: top + 18, width: 90, height: 16), font: .systemFont(ofSize: 12, weight: .semibold), color: .darkGray, align: .right)
        drawText(DateFormatter.localizedString(from: invoice.issueDate, dateStyle: .medium, timeStyle: .none), CGRect(x: right - 120, y: top + 18, width: 120, height: 16), font: .systemFont(ofSize: 12), color: .black, align: .right)

        // Bill To (карточка)
        let billBox = CGRect(x: left, y: top, width: 300, height: 90)
        context.setFillColor(primary.withAlphaComponent(0.06).cgColor)
        context.fill(billBox)
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1)
        context.stroke(billBox)
        drawText("BILL TO", CGRect(x: billBox.minX + 10, y: billBox.minY + 8, width: billBox.width - 20, height: 16), font: .systemFont(ofSize: 12, weight: .bold), color: primary)
        let bill = [customer.name, customer.address.oneLine, customer.email].filter{!$0.isEmpty}.joined(separator: "\n")
        drawText(bill, CGRect(x: billBox.minX + 10, y: billBox.minY + 28, width: billBox.width - 20, height: 54), font: .systemFont(ofSize: 12), color: .black)

        // Таблица — зебра
        let tTop = billBox.maxY + 20
        let headers = ["Description", "Qty", "Rate", "Amount"]
        let widths: [CGFloat] = [0.58, 0.12, 0.15, 0.15].map{ (right-left)*$0 }

        context.setFillColor(UIColor(white: 0.96, alpha: 1).cgColor)
        context.fill(CGRect(x: left, y: tTop, width: right-left, height: 32))
        var x = left
        for (i,h) in headers.enumerated() {
            drawText(h, CGRect(x: x + 8, y: tTop + 8, width: widths[i]-16, height: 16), font: .systemFont(ofSize: 12, weight: .bold), color: .black)
            x += widths[i]
        }

        var rowY = tTop + 32
        for (i, it) in invoice.items.enumerated() {
            if i % 2 == 0 {
                context.setFillColor(UIColor(white: 0.985, alpha: 1).cgColor)
                context.fill(CGRect(x: left, y: rowY, width: right-left, height: 26))
            }
            x = left
            drawText(it.description, CGRect(x: x + 8, y: rowY + 5, width: widths[0]-16, height: 16), font: .systemFont(ofSize: 11), color: .black)
            x += widths[0]
            drawText("\(it.quantity)", CGRect(x: x, y: rowY + 5, width: widths[1]-8, height: 16), font: .systemFont(ofSize: 11, weight: .medium), color: .black, align: .right)
            x += widths[1]
            drawText(money(it.rate, code: currency), CGRect(x: x, y: rowY + 5, width: widths[2]-8, height: 16), font: .systemFont(ofSize: 11), color: .black, align: .right)
            x += widths[2]
            drawText(money(it.total, code: currency), CGRect(x: x, y: rowY + 5, width: widths[3]-8, height: 16), font: .systemFont(ofSize: 11, weight: .semibold), color: primary, align: .right)
            rowY += 26
        }
        line(context, from: CGPoint(x: left, y: rowY + 2), to: CGPoint(x: right, y: rowY + 2), width: 1, color: .lightGray)

        // Карточка TOTAL справа
        let total = invoice.items.map{$0.total}.reduce(0,+)
        let totalCard = CGRect(x: right - 240, y: rowY + 14, width: 240, height: 60)
        context.setFillColor(primary.cgColor)
        context.fill(totalCard)
        drawText("TOTAL", CGRect(x: totalCard.minX + 12, y: totalCard.minY + 12, width: 100, height: 18), font: .systemFont(ofSize: 13, weight: .bold), color: .white)
        drawText(money(total, code: currency), CGRect(x: totalCard.minX + 12, y: totalCard.minY + 30, width: totalCard.width - 24, height: 22), font: .systemFont(ofSize: 17, weight: .black), color: .white, align: .right)

        // Низ страницы — контактная полоса
        let footerY = page.height - 40
        line(context, from: CGPoint(x: left, y: footerY - 8), to: CGPoint(x: right, y: footerY - 8), width: 1, color: UIColor(white: 0.9, alpha: 1))
        let footer = [company.phone, company.website, company.email].compactMap{$0}.filter{!$0.isEmpty}.joined(separator: "   •   ")
        drawText(footer, CGRect(x: left, y: footerY, width: right-left, height: 16), font: .systemFont(ofSize: 10), color: .gray, align: .center)
    }
}
