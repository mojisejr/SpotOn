//
//  ImageTestView.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct ImageTestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageManager = ImageManager()

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSavedImages = false
    @State private var showingClearConfirmation = false
    @State private var showingSaveAlert = false
    @State private var showingErrorAlert = false
    @State private var showingSuccessAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Image Testing Interface")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .accessibilityIdentifier("imageTestTitle")

                        Text("Test image save/load functionality")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Image Preview Section
                    VStack(spacing: 16) {
                        Text("Image Preview")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        ZStack {
                            if let selectedImage = imageManager.selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .cornerRadius(12)
                                    .shadow(radius: 4)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .frame(height: 200)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo")
                                                .font(.system(size: 40))
                                                .foregroundColor(.secondary)

                                            Text("No image selected")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .accessibilityIdentifier("imagePlaceholderText")
                                        }
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .accessibilityIdentifier("imagePreview")

                        // Image Information (only show when image is selected)
                        if let selectedImage = imageManager.selectedImage {
                            ImageInfoView(image: selectedImage, imageManager: imageManager)
                        }
                    }

                    // Image Count Display
                    HStack {
                        Text("Total Saved Images:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(imageManager.getAllSavedImages().count)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .accessibilityIdentifier("imageCountLabel")

                    // Actions Section
                    VStack(spacing: 12) {
                        Text("Actions")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            // Photo Selection Buttons
                            HStack(spacing: 12) {
                                Button(action: {
                                    showingImagePicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "photo.on.rectangle")
                                        Text("Select Photo")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .accessibilityLabel("Select Photo from Library")
                                .accessibilityIdentifier("selectPhotoButton")

                                Button(action: {
                                    checkCameraPermission()
                                }) {
                                    HStack {
                                        Image(systemName: "camera")
                                        Text("Take Photo")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .accessibilityLabel("Take Photo with Camera")
                                .accessibilityIdentifier("takePhotoButton")
                            }
                            .padding(.horizontal)

                            // Image Management Buttons
                            HStack(spacing: 12) {
                                Button(action: {
                                    saveCurrentImage()
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("Save Image")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(imageManager.selectedImage != nil ? Color.orange : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .disabled(imageManager.selectedImage == nil)
                                .accessibilityLabel("Save Image")
                                .accessibilityIdentifier("saveImageButton")

                                Button(action: {
                                    showingSavedImages = true
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Load Image")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(imageManager.getAllSavedImages().count > 0 ? Color.purple : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .disabled(imageManager.getAllSavedImages().count == 0)
                                .accessibilityLabel("Load Saved Image")
                                .accessibilityIdentifier("loadImageButton")
                            }
                            .padding(.horizontal)

                            // Clear Images Button
                            Button(action: {
                                showingClearConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear All Images")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(imageManager.getAllSavedImages().count > 0 ? Color.red : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(imageManager.getAllSavedImages().count == 0)
                            .padding(.horizontal)
                            .accessibilityIdentifier("clearImagesButton")
                        }
                    }

                    // Batch Operations Section
                    if imageManager.getAllSavedImages().count > 1 {
                        VStack(spacing: 12) {
                            Text("Batch Operations")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            Button(action: {
                                // Batch delete implementation would go here
                                showingClearConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.circle")
                                    Text("Select Multiple to Delete")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            .accessibilityIdentifier("deleteSelectedButton")
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Image Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
        )
        .sheet(isPresented: $showingSavedImages) {
            SavedImagesView(imageManager: imageManager) { image in
                imageManager.selectedImage = image
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        imageManager.selectedImage = uiImage
                    }
                }
            }
        }
        .alert("Success", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Clear All Images", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                clearAllImages()
            }
        } message: {
            Text("This will permanently delete all saved images. This action cannot be undone.")
        }
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    } else {
                        alertMessage = "Camera access is required to take photos."
                        showingErrorAlert = true
                    }
                }
            }
        case .denied, .restricted:
            alertMessage = "Camera access has been denied. Please enable it in Settings."
            showingErrorAlert = true
        @unknown default:
            alertMessage = "Unknown camera permission status."
            showingErrorAlert = true
        }
    }

    private func saveCurrentImage() {
        guard let image = imageManager.selectedImage else { return }

        imageManager.isLoading = true

        Task {
            do {
                let filename = "test_image_\(UUID().uuidString).jpg"
                try imageManager.saveImage(image: image, filename: filename)

                await MainActor.run {
                    imageManager.isLoading = false
                    alertMessage = "Image saved successfully as \(filename)"
                    showingSaveAlert = true
                }
            } catch {
                await MainActor.run {
                    imageManager.isLoading = false
                    alertMessage = "Failed to save image: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }

    private func clearAllImages() {
        do {
            try imageManager.deleteAllImages()
            alertMessage = "All images cleared successfully"
            showingSuccessAlert = true
        } catch {
            alertMessage = "Failed to clear images: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

// MARK: - Image Info View

struct ImageInfoView: View {
    let image: UIImage
    let imageManager: ImageManager

    var imageData: Data {
        image.jpegData(compressionQuality: 0.8) ?? Data()
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Size:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .accessibilityIdentifier("imageSizeLabel")

            HStack {
                Text("Format:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("JPEG")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .accessibilityIdentifier("imageFormatLabel")

            HStack {
                Text("Dimensions:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(image.size.width)) × \(Int(image.size.height))")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            HStack {
                Text("Date:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(Date(), format: .dateTime.month().day().year())
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .accessibilityIdentifier("imageDateLabel")

            if let filename = imageManager.getAllSavedImages().first?.filename {
                HStack {
                    Text("File:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(filename)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                .accessibilityIdentifier("imageFileNameLabel")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Saved Images View

struct SavedImagesView: View {
    @Environment(\.dismiss) private var dismiss
    let imageManager: ImageManager
    let onImageSelected: (UIImage) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120))
                ], spacing: 16) {
                    ForEach(imageManager.getAllSavedImages(), id: \.id) { imageInfo in
                        VStack(spacing: 8) {
                            if let image = imageInfo.uiImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipped()
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        onImageSelected(image)
                                        dismiss()
                                    }
                            }

                            Text(imageInfo.filename)
                                .font(.caption2)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)

                            Text(ByteCountFormatter.string(fromByteCount: imageInfo.size, countStyle: .file))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityIdentifier("savedImage_\(imageInfo.filename)")
                    }
                }
                .padding()
            }
            .navigationTitle("Saved Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .accessibilityIdentifier("savedImagePicker")
    }
}

#Preview {
    ImageTestView()
}