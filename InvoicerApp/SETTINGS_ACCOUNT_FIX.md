# Исправление секции Account в SettingsScreen

## Проблема
Секция Account в SettingsScreen всегда показывала "Free", даже если подписка активна, пока не нажмешь "Restore Purchases". Это может сбивать с толку клиентов.

## Причина
AccountCard использовал `app.isPremium` вместо `subscriptionManager.isPro`, что приводило к несинхронизированному отображению статуса подписки.

## Решение

### 1. Добавлен SubscriptionManager в AccountCard

```swift
private struct AccountCard: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager // Добавлено
    @Environment(\.colorScheme) private var scheme
```

### 2. Заменены все использования app.isPremium на subscriptionManager.isPro

```swift
// Было:
Circle()
    .fill(app.isPremium ? Color.green : Color.orange)

Text(app.isPremium ? "Active" : "Free")
    .foregroundColor(app.isPremium ? .green : .orange)

// Стало:
Circle()
    .fill(subscriptionManager.isPro ? Color.green : Color.orange)

Text(subscriptionManager.isPro ? "Active" : "Free")
    .foregroundColor(subscriptionManager.isPro ? .green : .orange)
```

### 3. Обновлена кнопка "Restore Purchases"

```swift
// Было:
Task { try? await SubscriptionManager.shared.restorePurchases() }

// Стало:
Task { try? await subscriptionManager.restorePurchases() }
```

### 4. Добавлена дополнительная информация

При активной подписке теперь показывается "Active Premium" вместо просто "Active".

## Результат

Теперь AccountCard:
- ✅ **Показывает актуальный статус подписки** в реальном времени
- ✅ **Автоматически обновляется** при изменении статуса подписки
- ✅ **Не требует нажатия "Restore Purchases"** для отображения правильного статуса
- ✅ **Синхронизирован** с остальными экранами приложения

## Проверка

После исправления:
1. **Перезапустите приложение**
2. **Перейдите в Settings → Account**
3. **При активной подписке** должно показываться "Active Premium" с зеленым индикатором
4. **При неактивной подписке** должно показываться "Free" с оранжевым индикатором
5. **Статус должен обновляться автоматически** без необходимости нажимать "Restore Purchases"

## Важно

- AccountCard теперь использует единый источник истины (`SubscriptionManager`)
- Статус подписки отображается корректно с первого запуска
- Клиенты больше не будут сбиты с толку неправильным отображением статуса
