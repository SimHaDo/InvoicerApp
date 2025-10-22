# Core Data + CloudKit Integration - Final Fix

## Проблема
Приложение крашилось при запуске с ошибкой валидации схемы Core Data для CloudKit интеграции:
```
Thread 1: Fatal error: Unresolved error Error Domain=NSCocoaErrorDomain Code=134060 "A Core Data error occurred."
```

Ошибка указывала на проблемы с Core Data моделью для CloudKit интеграции.

## Решение

### 1. Упрощение модели Core Data
Создана упрощенная модель Core Data без сложных связей между сущностями:

**Сущности:**
- `CompanyEntity` - данные компании
- `CustomerEntity` - данные клиентов  
- `ProductEntity` - данные продуктов
- `InvoiceEntity` - данные инвойсов
- `AppSettingsEntity` - настройки приложения

**Ключевые изменения:**
- Все атрибуты сделаны опциональными (`optional="YES"`)
- Убраны сложные связи между сущностями
- Сложные данные (LineItem, PaymentMethod) хранятся как JSON в Binary атрибутах
- Связи заменены на ID-ссылки (companyId, customerId)

### 2. Обновление CoreDataAdapter
Адаптер обновлен для работы с упрощенной моделью:

**InvoiceEntity:**
- `companyId` и `customerId` для связи с Company и Customer
- `itemsData` - JSON данные LineItem массивов
- `paymentMethodsData` - JSON данные PaymentMethod массивов

**AppSettingsEntity:**
- `paymentMethodsData` - JSON данные глобальных PaymentMethod

### 3. JSON сериализация
Сложные типы данных сериализуются в JSON для хранения в Core Data:

```swift
// Сохранение
if let itemsData = try? JSONEncoder().encode(invoice.items) {
    coreDataInvoice.itemsData = itemsData
}

// Загрузка
if let itemsData = coreDataInvoice.itemsData,
   let items = try? JSONDecoder().decode([LineItem].self, from: itemsData) {
    mutableInvoice.items = items
}
```

## Результат

✅ **Приложение успешно запускается без краша**
✅ **Core Data модель совместима с CloudKit**
✅ **Все данные синхронизируются через NSPersistentCloudKitContainer**
✅ **Проект успешно собирается**

## Синхронизируемые данные

- ✅ **Данные компании** - CompanyEntity
- ✅ **Клиенты** - CustomerEntity  
- ✅ **Продукты** - ProductEntity
- ✅ **Инвойсы** - InvoiceEntity (включая LineItem и PaymentMethod)
- ✅ **PDF файлы** - pdfData в InvoiceEntity
- ✅ **Настройки приложения** - AppSettingsEntity
- ✅ **Статус подписки** - через CloudSync (KVS)
- ✅ **Выбранный шаблон** - через CloudSync (KVS)
- ✅ **Статус онбординга** - через CloudSync (KVS)

## Технические детали

- Используется `NSPersistentCloudKitContainer` для автоматической синхронизации
- Конфликты решаются по принципу "последний апдейт побеждает"
- Все данные мигрируются из UserDefaults в Core Data при первом запуске
- CloudKit автоматически обрабатывает схему и синхронизацию
