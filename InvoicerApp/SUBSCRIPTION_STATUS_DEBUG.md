# Диагностика проблемы с обновлением статуса подписки

## Проблема
После успешной оплаты в тестовом режиме ничего не происходит - оплата проходит, но весь функционал остается закрытым как при неоплаченной подписке, и PaywallScreen не пропадает с экрана.

## Диагностика

### 1. Проверьте логи в Xcode Console

После успешной покупки в логах должны появиться сообщения:

```
🛒 Starting purchase...
🛒 Purchase completed:
   - Transaction: [TRANSACTION_DETAILS]
   - User cancelled: false
✅ Subscription status updated: isPro = true
✅ Previous status: false, New status: true
✅ Pro entitlement details:
   - Is active: true
   - Will renew: true
   - Period type: [PERIOD_TYPE]
   - Expires date: [EXPIRATION_DATE]
✅ All active entitlements: ["pro"]
```

### 2. Если статус не обновляется

Если в логах видно `isPro = false` или `Pro entitlement not found`, проверьте:

#### A. Настройки RevenueCat Dashboard
1. **Войдите в RevenueCat Dashboard**
2. **Перейдите в Products → Entitlements**
3. **Убедитесь, что entitlement "pro" настроен правильно**
4. **Проверьте, что продукты привязаны к entitlement "pro"**

#### B. Настройки App Store Connect
1. **Войдите в App Store Connect**
2. **Перейдите в My Apps → [Your App] → Subscriptions**
3. **Убедитесь, что продукты настроены правильно**
4. **Проверьте, что продукты доступны для покупки**

#### C. Проверка Bundle ID
1. **Убедитесь, что Bundle ID в Xcode совпадает с Bundle ID в App Store Connect**
2. **Убедитесь, что Bundle ID в RevenueCat совпадает с Bundle ID в App Store Connect**

### 3. Если PaywallScreen не закрывается

#### A. Проверьте onChange
PaywallScreen должен автоматически закрываться при изменении `subscriptionManager.isPro` на `true`.

#### B. Проверьте onClose callback
Убедитесь, что `onClose` callback правильно настроен в родительском view.

## Решения

### 1. Принудительное обновление статуса

Добавьте кнопку "Refresh Status" для тестирования:

```swift
Button("Refresh Status") {
    Task {
        await subscriptionManager.checkSubscriptionStatus()
    }
}
```

### 2. Проверка entitlement ID

Убедитесь, что в `SubscriptionManager` используется правильный entitlement ID:

```swift
private let entitlementID = "pro" // Должен совпадать с RevenueCat Dashboard
```

### 3. Проверка offering ID

Убедитесь, что используется правильный offering ID:

```swift
private let offeringID = "default" // Должен совпадать с RevenueCat Dashboard
```

### 4. Тестирование с sandbox аккаунтом

1. **Создайте sandbox аккаунт в App Store Connect**
2. **Войдите в этот аккаунт на устройстве**
3. **Попробуйте покупку снова**

### 5. Очистка кэша

1. **Удалите приложение с устройства**
2. **Перезагрузите устройство**
3. **Переустановите приложение**
4. **Попробуйте покупку снова**

## Дополнительная диагностика

### 1. Проверка CustomerInfo

Добавьте в код для детальной диагностики:

```swift
let customerInfo = try await Purchases.shared.customerInfo()
print("🔍 Full CustomerInfo:")
print("   - Original App User ID: \(customerInfo.originalAppUserId)")
print("   - All entitlements: \(customerInfo.entitlements.all)")
print("   - Active entitlements: \(customerInfo.entitlements.active)")
print("   - Non-subscription purchases: \(customerInfo.nonSubscriptionTransactions)")
```

### 2. Проверка продуктов

```swift
let offerings = try await Purchases.shared.offerings()
print("🔍 Available offerings: \(offerings.all.keys)")
if let current = offerings.current {
    print("🔍 Current offering: \(current.identifier)")
    print("🔍 Available packages: \(current.availablePackages.map { $0.identifier })")
}
```

## Если проблема persists

1. **Проверьте RevenueCat Dashboard → Events** для просмотра логов покупок
2. **Убедитесь, что используется правильный API ключ**
3. **Проверьте, что приложение подписано правильно**
4. **Попробуйте на другом устройстве**

## Контакты

Если проблема не решается:
1. Проверьте RevenueCat документацию
2. Обратитесь в поддержку RevenueCat
3. Проверьте Apple Developer форумы
