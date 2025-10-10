//
//  PermissionManager.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI
import Photos
import AVFoundation
import UIKit

// MARK: - Permission Types

enum PermissionType {
    case photoLibrary
    case camera
    case documents
}

enum PermissionStatus {
    case notDetermined
    case granted
    case denied
    case restricted
}

// MARK: - Permission Manager

@MainActor
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var photoLibraryStatus: PermissionStatus = .notDetermined
    @Published var cameraStatus: PermissionStatus = .notDetermined
    @Published var documentsStatus: PermissionStatus = .notDetermined
    
    private init() {
        checkAllPermissions()
    }
    
    // MARK: - Check Permissions
    
    func checkAllPermissions() {
        checkPhotoLibraryPermission()
        checkCameraPermission()
        checkDocumentsPermission()
    }
    
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            photoLibraryStatus = .notDetermined
        case .authorized, .limited:
            photoLibraryStatus = .granted
        case .denied:
            photoLibraryStatus = .denied
        case .restricted:
            photoLibraryStatus = .restricted
        @unknown default:
            photoLibraryStatus = .notDetermined
        }
        print("PermissionManager: Photo library status: \(status.rawValue) (\(statusDescription(status))), mapped to: \(photoLibraryStatus)")
    }
    
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            cameraStatus = .notDetermined
        case .authorized:
            cameraStatus = .granted
        case .denied:
            cameraStatus = .denied
        case .restricted:
            cameraStatus = .restricted
        @unknown default:
            cameraStatus = .notDetermined
        }
    }
    
    private func checkDocumentsPermission() {
        // Documents permission is always granted for file picker
        documentsStatus = .granted
    }
    
    // MARK: - Request Permissions
    
    func requestPhotoLibraryPermission() async -> PermissionStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            switch status {
            case .authorized, .limited:
                photoLibraryStatus = .granted
            case .denied:
                photoLibraryStatus = .denied
            case .restricted:
                photoLibraryStatus = .restricted
            case .notDetermined:
                photoLibraryStatus = .notDetermined
            @unknown default:
                photoLibraryStatus = .notDetermined
            }
        }
        return photoLibraryStatus
    }
    
    func requestCameraPermission() async -> PermissionStatus {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            cameraStatus = status ? .granted : .denied
        }
        return cameraStatus
    }
    
    // MARK: - Helper Methods
    
    func canAccessPhotoLibrary() -> Bool {
        // Принудительно проверяем текущий статус
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        let isGranted = currentStatus == .authorized || currentStatus == .limited
        
        // Обновляем внутренний статус если он изменился
        if isGranted && photoLibraryStatus != .granted {
            photoLibraryStatus = .granted
        } else if !isGranted && photoLibraryStatus == .granted {
            photoLibraryStatus = .denied
        }
        
        print("PermissionManager: canAccessPhotoLibrary() - current: \(currentStatus.rawValue) (\(statusDescription(currentStatus))), internal: \(photoLibraryStatus), result: \(isGranted)")
        return isGranted
    }
    
    private func statusDescription(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorized: return "authorized"
        case .limited: return "limited"
        @unknown default: return "unknown"
        }
    }
    
    func canAccessCamera() -> Bool {
        return cameraStatus == .granted
    }
    
    func canAccessDocuments() -> Bool {
        return documentsStatus == .granted
    }
    
    // MARK: - Open Settings
    
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Refresh Permissions
    
    func refreshPermissions() {
        print("PermissionManager: Refreshing permissions...")
        checkAllPermissions()
    }
}

// MARK: - Permission Alert

struct PermissionAlert: View {
    let permissionType: PermissionType
    let isPresented: Binding<Bool>
    let onSettings: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            // Buttons
            VStack(spacing: 0) {
                // Settings Button
                Button(action: {
                    onSettings()
                    isPresented.wrappedValue = false
                }) {
                    Text("Open Settings")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                
                // Cancel Button
                Button(action: {
                    onCancel()
                    isPresented.wrappedValue = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .frame(maxWidth: 320)
    }
    
    private var iconName: String {
        switch permissionType {
        case .photoLibrary:
            return "photo.on.rectangle"
        case .camera:
            return "camera"
        case .documents:
            return "folder"
        }
    }
    
    private var title: String {
        switch permissionType {
        case .photoLibrary:
            return "Photo Access Required"
        case .camera:
            return "Camera Access Required"
        case .documents:
            return "File Access Required"
        }
    }
    
    private var description: String {
        switch permissionType {
        case .photoLibrary:
            return "Photo access was denied. To add your company logo and invoice attachments, please allow access to your photo library in Settings.\n\nYou can choose:\n• Full Access - Access to all photos\n• Selected Photos - Choose specific photos to share"
        case .camera:
            return "Camera access was denied. To take photos for your company logo and invoice attachments, please allow camera access in Settings."
        case .documents:
            return "Document access was denied. To save and share invoice PDFs, please allow access to your documents in Settings."
        }
    }
}

// MARK: - Permission Denied View

struct PermissionDeniedView: View {
    let permissionType: PermissionType
    let onRequestPermission: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            VStack(spacing: 12) {
                Button(action: onRequestPermission) {
                    Text("Try Again")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                }
                
                Button(action: onOpenSettings) {
                    Text("Open Settings")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var iconName: String {
        switch permissionType {
        case .photoLibrary:
            return "photo.on.rectangle.angled"
        case .camera:
            return "camera.fill"
        case .documents:
            return "folder.fill"
        }
    }
    
    private var title: String {
        switch permissionType {
        case .photoLibrary:
            return "Photo Access Denied"
        case .camera:
            return "Camera Access Denied"
        case .documents:
            return "File Access Denied"
        }
    }
    
    private var description: String {
        switch permissionType {
        case .photoLibrary:
            return "You can still add logos by choosing files from your device storage."
        case .camera:
            return "You can still add logos by choosing photos from your library or files from your device storage."
        case .documents:
            return "You can still save invoices to your photo library or share them directly."
        }
    }
}
