# CloudKit Setup Guide

## Настройка CloudKit для синхронизации данных

### 1. CloudKit Container Configuration

В Xcode необходимо настроить CloudKit контейнер:

1. Откройте проект в Xcode
2. Выберите target приложения
3. Перейдите в "Signing & Capabilities"
4. Добавьте "iCloud" capability
5. Выберите "CloudKit" и укажите контейнер: `iCloud.SimHaDo.InvoicerApp`

### 2. CloudKit Schema Setup

В CloudKit Dashboard необходимо создать следующие Record Types:

#### Company Record Type
- **Record Type**: `Company`
- **Fields**:
  - `data` (Asset) - JSON данные компании
  - `lastModified` (Date/Time) - время последнего изменения

#### Customer Record Type
- **Record Type**: `Customer`
- **Fields**:
  - `data` (Asset) - JSON данные клиента
  - `lastModified` (Date/Time) - время последнего изменения

#### Product Record Type
- **Record Type**: `Product`
- **Fields**:
  - `data` (Asset) - JSON данные продукта
  - `lastModified` (Date/Time) - время последнего изменения

#### Invoice Record Type
- **Record Type**: `Invoice`
- **Fields**:
  - `data` (Asset) - JSON данные инвойса
  - `lastModified` (Date/Time) - время последнего изменения

#### PaymentMethod Record Type
- **Record Type**: `PaymentMethod`
- **Fields**:
  - `data` (Asset) - JSON данные метода оплаты
  - `lastModified` (Date/Time) - время последнего изменения

#### Settings Record Type
- **Record Type**: `Settings`
- **Fields**:
  - `data` (Asset) - JSON данные настроек
  - `lastModified` (Date/Time) - время последнего изменения

#### Attachment Record Type
- **Record Type**: `Attachment`
- **Fields**:
  - `fileName` (String) - имя файла
  - `fileType` (String) - тип файла (pdf, png, etc.)
  - `fileSize` (Int64) - размер файла
  - `fileData` (Asset) - данные файла
  - `associatedRecordID` (String) - ID связанной записи
  - `lastModified` (Date/Time) - время последнего изменения

### 3. Entitlements Configuration

Убедитесь, что в `InvoicerApp.entitlements` настроены:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.SimHaDo.InvoicerApp</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
</dict>
</plist>
```

### 4. Info.plist Configuration

Добавьте в `Info.plist`:

```xml
<key>NSUbiquitousKeyValueStoreDidChangeExternallyNotification</key>
<true/>
```

### 5. Testing CloudKit Setup

1. Запустите приложение на устройстве с включенным iCloud
2. Перейдите в Settings > iCloud Sync
3. Проверьте статус подключения
4. Создайте тестовые данные и проверьте синхронизацию

### 6. Troubleshooting

#### Проблемы с синхронизацией:
1. Убедитесь, что устройство подключено к интернету
2. Проверьте, что пользователь вошел в iCloud
3. Проверьте настройки iCloud в системных настройках
4. Убедитесь, что приложение имеет разрешения на доступ к iCloud

#### Проблемы с CloudKit Dashboard:
1. Убедитесь, что контейнер создан правильно
2. Проверьте, что все Record Types созданы
3. Убедитесь, что поля имеют правильные типы данных

### 7. Production Considerations

1. **Rate Limits**: CloudKit имеет ограничения на количество запросов
2. **Data Size**: Максимальный размер записи - 1MB
3. **Sync Frequency**: Синхронизация происходит автоматически при изменениях
4. **Conflict Resolution**: Реализована стратегия "последний апдейт побеждает"

### 8. Security

- Все данные хранятся в приватной базе данных CloudKit
- Доступ только для пользователя, вошедшего в iCloud
- Данные шифруются при передаче и хранении
