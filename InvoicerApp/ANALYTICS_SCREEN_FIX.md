# Исправление экрана Analytics

## Проблема
На экране Analytics по-прежнему показывается "Upgrade to Premium", хотя подписка активна.

## Причина
AnalyticsScreen использовал собственный `AnalyticsVM` с `isPremium`, но не был подключен к `SubscriptionManager`.

## Решение

### 1. Добавлен SubscriptionManager в AnalyticsScreen

```swift
struct AnalyticsScreen: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager // Добавлено
    @StateObject private var vm = AnalyticsVM()
    @Environment(\.colorScheme) private var scheme
```

### 2. Заменены все использования vm.isPremium на subscriptionManager.isPro

- `if vm.isPremium` → `if subscriptionManager.isPro`
- `if !vm.isPremium` → `if !subscriptionManager.isPro`

### 3. Обновлен PaywallScreen

```swift
.sheet(isPresented: $showPaywall) {
    PaywallScreen(onClose: { showPaywall = false })
        .environmentObject(subscriptionManager)
}
```

## Результат

Теперь AnalyticsScreen:
- ✅ Использует актуальный статус подписки из `SubscriptionManager`
- ✅ Автоматически обновляется при изменении статуса подписки
- ✅ Показывает премиум-функции при активной подписке
- ✅ Показывает PaywallScreen при неактивной подписке

## Проверка

После исправления:
1. **Перезапустите приложение**
2. **Перейдите на экран Analytics**
3. **При активной подписке** должны отображаться все премиум-функции
4. **При неактивной подписке** должна показываться кнопка "Upgrade to Premium"

## Важно

- AnalyticsScreen теперь синхронизирован с остальными экранами
- Все экраны используют единый источник истины (`SubscriptionManager`)
- Статус подписки обновляется автоматически на всех экранах
