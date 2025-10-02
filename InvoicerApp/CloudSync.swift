//
//  CloudSync.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.
//

import Foundation

/// Лёгкая синхронизация небольших флагов/настроек через iCloud KVS.
/// Не храните здесь большие бинарники (например, логотип). Лимит ~1 МБ.
final class CloudSync {
    static let shared = CloudSync()
    private let store = NSUbiquitousKeyValueStore.default

    private init() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store, queue: .main
        ) { _ in
            // Только подтягиваем изменения — подписчики слушают свои нотификации.
        }
        store.synchronize()
    }

    enum Key: String {
        case hasCompletedOnboarding
        case selectedTemplateID
        case isProSubscriber
        case lastActiveThemeName
    }

    // MARK: Setters

    func set(_ value: Bool, for key: Key) {
        store.set(value, forKey: key.rawValue)
        store.synchronize()
    }

    func set(_ value: String, for key: Key) {
        store.set(value, forKey: key.rawValue)
        store.synchronize()
    }

    // MARK: Getters

    /// Возвращает Bool, по умолчанию false если ключа нет.
    func bool(_ key: Key) -> Bool { store.bool(forKey: key.rawValue) }

    /// Возвращает String? (nil если ключа нет).
    func string(_ key: Key) -> String? { store.string(forKey: key.rawValue) }

    // MARK: Manual sync

    /// Публичный метод для явной синхронизации (используется при старте приложения).
    func synchronize() {
        store.synchronize()
    }
}
