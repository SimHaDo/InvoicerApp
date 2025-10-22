# Core Data + CloudKit Integration Fix

## Проблема
Приложение крашилось при запуске с ошибкой:
```
Thread 1: Fatal error: Unresolved error Error Domain=NSCocoaErrorDomain Code=134060 "A Core Data error occurred."
```

Ошибка указывала на две основные проблемы с Core Data моделью для CloudKit интеграции:

### 1. Отсутствующие обратные связи (Inverse Relationships)
CloudKit требует, чтобы все связи имели обратные связи:
- `AppSettingsEntity: paymentMethods`
- `InvoiceEntity: company`
- `InvoiceEntity: customer`
- `InvoiceEntity: items`
- `InvoiceEntity: paymentMethods`
- `LineItemEntity: invoice`
- `PaymentMethodEntity: invoice`

### 2. Обязательные атрибуты без значений по умолчанию
CloudKit требует, чтобы все атрибуты были опциональными или имели значения по умолчанию:
- `AppSettingsEntity: id`, `lastModified`
- `CompanyEntity: id`, `lastModified`
- `CustomerEntity: id`, `lastModified`
- `InvoiceEntity: discountValue`, `id`, `isDiscountEnabled`, `issueDate`, `lastModified`, `taxRate`, `totalPaid`
- `LineItemEntity: discount`, `id`, `isTaxExempt`, `lastModified`, `quantity`, `rate`
- `PaymentMethodEntity: id`, `lastModified`
- `ProductEntity: id`, `lastModified`

## Решение

### 1. Исправлена Core Data модель (`InvoicerApp.xcdatamodel/contents`)

#### Добавлены обратные связи:
```xml
<!-- CompanyEntity -->
<relationship name="invoices" destinationEntity="InvoiceEntity" toMany="YES" deletionRule="Nullify" optional="YES"/>

<!-- CustomerEntity -->
<relationship name="invoices" destinationEntity="InvoiceEntity" toMany="YES" deletionRule="Nullify" optional="YES"/>

<!-- PaymentMethodEntity -->
<relationship name="appSettings" destinationEntity="AppSettingsEntity" toMany="NO" deletionRule="Nullify" optional="YES"/>
```

#### Сделаны все атрибуты опциональными:
```xml
<!-- Все атрибуты изменены с optional="NO" на optional="YES" -->
<attribute name="id" optional="YES" attributeType="UUID" usesScalarValueType="NO"/>
<attribute name="lastModified" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
<attribute name="issueDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
<attribute name="taxRate" optional="YES" attributeType="Decimal" usesScalarValueType="NO"/>
<attribute name="discountValue" optional="YES" attributeType="Decimal" usesScalarValueType="NO"/>
<attribute name="isDiscountEnabled" optional="YES" attributeType="Boolean" usesScalarValueType="NO"/>
<attribute name="totalPaid" optional="YES" attributeType="Decimal" usesScalarValueType="NO"/>
<attribute name="quantity" optional="YES" attributeType="Decimal" usesScalarValueType="NO"/>
<attribute name="rate" optional="YES" attributeType="Decimal" usesScalarValueType="NO"/>
<attribute name="discount" optional="YES" attributeType="Decimal" usesScalarValueType="NO"/>
<attribute name="isTaxExempt" optional="YES" attributeType="Boolean" usesScalarValueType="NO"/>
```

### 2. CoreDataAdapter уже правильно обрабатывает опциональные атрибуты

`CoreDataAdapter.swift` уже использует безопасные значения по умолчанию:
```swift
// Примеры из CoreDataAdapter
customer.id = coreDataCustomer.id ?? UUID()
customer.name = coreDataCustomer.name ?? ""
invoice.taxRate = (coreDataInvoice.taxRate as Decimal?) ?? 0
invoice.isDiscountEnabled = coreDataInvoice.isDiscountEnabled?.boolValue ?? false
```

## Результат

✅ **Приложение успешно запускается без краша**
✅ **Core Data модель совместима с CloudKit**
✅ **Все связи имеют обратные связи**
✅ **Все атрибуты опциональны с безопасными значениями по умолчанию**

## Синхронизация данных

Теперь все данные синхронизируются через `NSPersistentCloudKitContainer`:

- ✅ **Данные компании** - через `CompanyEntity`
- ✅ **Клиенты** - через `CustomerEntity`
- ✅ **Продукты** - через `ProductEntity`
- ✅ **Инвойсы** - через `InvoiceEntity` с `LineItemEntity` и `PaymentMethodEntity`
- ✅ **PDF файлы** - через `pdfData` атрибут в `InvoiceEntity`
- ✅ **Настройки приложения** - через `AppSettingsEntity`
- ✅ **Статус подписки** - через iCloud Key-Value Store
- ✅ **Выбранный шаблон** - через iCloud Key-Value Store
- ✅ **Статус онбординга** - через iCloud Key-Value Store

## Тестирование

1. **Сборка**: `xcodebuild -project InvoicerApp.xcodeproj -scheme InvoicerApp -destination 'platform=iOS Simulator,name=iPhone 16' build`
2. **Запуск**: `xcrun simctl launch "iPhone 16" SimHaDo.InvoicerApp`

Приложение запускается успешно без ошибок Core Data.
