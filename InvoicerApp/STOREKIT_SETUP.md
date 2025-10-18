# Настройка StoreKit для автоматической авторизации

## Проблема
При каждой покупке система запрашивает ввод Apple ID вручную, хотя должна автоматически использовать уже авторизованный аккаунт.

## Решения

### 1. Настройка симулятора (для тестирования)

1. **Откройте Settings в симуляторе**
2. **Перейдите в App Store**
3. **Войдите в свой Apple ID** (используйте sandbox аккаунт)
4. **Убедитесь, что "Sign In Automatically" включен**

### 2. Настройка StoreKit в Xcode

1. **Откройте Xcode**
2. **Перейдите в Product → Scheme → Edit Scheme**
3. **Выберите Run → Options**
4. **В разделе StoreKit Configuration выберите:**
   - "Use StoreKit Configuration File" (если есть)
   - Или "Use Sandbox StoreKit"

### 3. Создание StoreKit Configuration File (рекомендуется)

1. **В Xcode создайте новый файл:**
   - File → New → File
   - StoreKit → StoreKit Configuration File
   - Назовите его `Products.storekit`

2. **Добавьте ваши продукты:**
   ```json
   {
     "identifier": "weekly_premium",
     "referenceName": "Weekly Premium",
     "productId": "weekly_premium",
     "type": "RecurringSubscription",
     "subscriptionPeriod": "P1W",
     "subscriptionTrialPeriod": "P3D"
   }
   ```

3. **Настройте схему:**
   - Product → Scheme → Edit Scheme
   - Run → Options
   - StoreKit Configuration: выберите `Products.storekit`

### 4. Настройка на реальном устройстве

1. **Войдите в Settings → [Your Name] → Media & Purchases**
2. **Убедитесь, что вы авторизованы**
3. **Включите "Automatic Downloads"**

### 5. Проверка в коде

Убедитесь, что в `SubscriptionManager` правильно настроена авторизация:

```swift
// Проверяем статус авторизации перед покупкой
let customerInfo = try await Purchases.shared.customerInfo()
print("Current user: \(customerInfo.originalAppUserId)")
```

### 6. Отладка

Добавьте логирование для отслеживания проблем:

```swift
Purchases.logLevel = .debug
```

### 7. Альтернативное решение

Если проблема persists, попробуйте:

1. **Очистить Derived Data:**
   - Xcode → Window → Organizer → Projects
   - Delete Derived Data

2. **Переустановить приложение на симуляторе**

3. **Использовать реальное устройство для тестирования**

## Важные замечания

- **Sимулятор**: Может требовать повторной авторизации
- **Реальное устройство**: Обычно работает автоматически
- **Sandbox**: Используйте тестовые аккаунты из App Store Connect
- **Production**: Убедитесь, что App Store Connect настроен правильно

## Проверка

После настройки:
1. Запустите приложение
2. Попробуйте купить подписку
3. Система должна автоматически использовать авторизованный аккаунт
4. Проверьте логи в Xcode Console
