//
//  CameraView.swift
//  SpotOn
//
//  Created by Claude on 11/29/25.
//

import SwiftUI
import AVFoundation

/// CameraView provides a reusable camera interface with medical theme
/// Handles camera preview, capture controls, and error states
struct CameraView: View {

    // MARK: - Dependencies

    let cameraManager: CameraManager
    let imageManager: ImageManager

    // MARK: - State

    @State private var showingPermissionAlert = false
    @State private var showingErrorAlert = false

    // MARK: - Callbacks

    var onPhotoCaptured: ((UIImage) -> Void)?
    var onError: ((Error) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - Initialization

    init(
        cameraManager: CameraManager? = nil,
        imageManager: ImageManager? = nil,
        onPhotoCaptured: ((UIImage) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.cameraManager = cameraManager ?? CameraManager(imageManager: imageManager)
        self.imageManager = imageManager ?? ImageManager()
        self.onPhotoCaptured = onPhotoCaptured
        self.onError = onError
        self.onCancel = onCancel
    }

    // MARK: - Body

    var body: some View {
        VStack {
            Text("Camera Interface")
                .font(.largeTitle)
                .foregroundColor(.primary)

            if cameraManager.isInitialized {
                Text("Camera Ready")
                    .foregroundColor(.green)

                Button("Take Photo") {
                    Task {
                        await capturePhoto()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()

            } else if cameraManager.lastError != nil {
                Text("Camera Error")
                    .foregroundColor(.red)
                Text(cameraManager.lastError?.localizedDescription ?? "Unknown error")
                    .foregroundColor(.secondary)

                Button("Retry") {
                    Task {
                        await retryCameraInitialization()
                    }
                }
                .buttonStyle(.bordered)
                .padding()

            } else {
                Text("Initializing Camera...")
                    .foregroundColor(.blue)
                ProgressView()
            }

            Button("Cancel") {
                onCancel?()
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .onAppear {
            initializeCamera()
        }
        .onDisappear {
            cameraManager.stopCamera()
        }
        .alert("Camera Access Required", isPresented: $showingPermissionAlert) {
            Button("Cancel", role: .cancel) {
                onCancel?()
            }
            Button("Settings") {
                openAppSettings()
            }
        } message: {
            Text("Camera access is required to take medical photos. Please enable it in Settings.")
        }
        .alert("Camera Error", isPresented: $showingErrorAlert) {
            Button("OK") {
                // Handle error acknowledgment
            }
        } message: {
            if let error = cameraManager.lastError {
                Text(error.localizedDescription)
            }
        }
        .onChange(of: cameraManager.capturedImage) { _, newImage in
            if let image = newImage {
                onPhotoCaptured?(image)
            }
        }
        .onChange(of: cameraManager.lastError?.localizedDescription) { _ in
            if cameraManager.lastError != nil {
                onError?(cameraManager.lastError!)
                showingErrorAlert = true
            }
        }
    }

    // MARK: - Camera Actions

    private func initializeCamera() {
        Task {
            do {
                try await cameraManager.initializeCamera()
            } catch {
                await MainActor.run {
                    cameraManager.lastError = error
                }
            }
        }
    }

    private func capturePhoto() async {
        do {
            try await cameraManager.capturePhoto()
        } catch {
            await MainActor.run {
                cameraManager.lastError = error
            }
        }
    }

    private func retryCameraInitialization() async {
        cameraManager.lastError = nil
        await initializeCamera()
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Preview

#Preview {
    CameraView(
        onPhotoCaptured: { _ in },
        onCancel: { }
    )
}