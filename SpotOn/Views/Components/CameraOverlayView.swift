//
//  CameraOverlayView.swift
//  SpotOn
//
//  Created by Claude on 12/2/25.
//

import SwiftUI
import AVFoundation
import SwiftData

/// CameraOverlayView provides a camera interface with ghost overlay functionality
/// Enables users to align new photos with previous images for consistent medical tracking
struct CameraOverlayView: View {

    // MARK: - Dependencies

    let spot: Spot
    let cameraManager: CameraManager
    let imageManager: ImageManager

    // MARK: - State

    @State private var previousImage: UIImage?
    @State private var showingPermissionAlert = false
    @State private var showingErrorAlert = false
    @State private var capturedImage: UIImage?
    @State private var showingLogEntryForm = false

    // MARK: - Callbacks

    var onPhotoCaptured: ((UIImage) -> Void)?
    var onError: ((Error) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - Medical Theme Colors

    private let medicalBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    private let ghostOverlayOpacity: Double = 0.4

    // MARK: - Initialization

    init(
        spot: Spot,
        cameraManager: CameraManager? = nil,
        imageManager: ImageManager? = nil,
        onPhotoCaptured: ((UIImage) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.spot = spot
        self.cameraManager = cameraManager ?? CameraManager(imageManager: imageManager)
        self.imageManager = imageManager ?? ImageManager()
        self.onPhotoCaptured = onPhotoCaptured
        self.onError = onError
        self.onCancel = onCancel
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Camera preview
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()

                // Ghost overlay (previous image)
                if let previousImage = previousImage {
                    Image(uiImage: previousImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(ghostOverlayOpacity)
                        .allowsHitTesting(false) // Let touches pass through to camera
                }

                // Camera controls overlay
                VStack {
                    // Top controls
                    HStack {
                        Button("Cancel") {
                            onCancel?()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .padding(.leading)

                        Spacer()

                        // Spot info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(spot.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(spot.bodyPart)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.trailing)
                    }
                    .padding(.top, 50)

                    Spacer()

                    // Bottom controls
                    HStack(spacing: 30) {
                        // Camera switch button
                        Button(action: {
                            Task {
                                await switchCamera()
                            }
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }

                        // Capture button
                        Button(action: {
                            Task {
                                await capturePhoto()
                            }
                        }) {
                            Circle()
                                .fill(medicalBlue)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: 70, height: 70)
                                )
                                .overlay(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 60, height: 60)
                                )
                        }
                        .disabled(cameraManager.isCapturingPhoto)

                        // Ghost overlay toggle
                        Button(action: {
                            previousImage = nil // Hide overlay for now
                        }) {
                            Image(systemName: previousImage == nil ? "photo" : "photo.fill")
                                .font(.title2)
                                .foregroundColor(previousImage == nil ? .white.opacity(0.6) : medicalBlue)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 50)
                }

                // Loading indicator
                if cameraManager.isCapturingPhoto {
                    ProgressView("Capturing...")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            print("🔍 [CameraOverlayView] onAppear - START")
            loadPreviousImage()
            initializeCamera()
            print("🔍 [CameraOverlayView] onAppear - END")
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
                capturedImage = image
                onPhotoCaptured?(image)
                showingLogEntryForm = true
            }
        }
        .onChange(of: cameraManager.lastError?.localizedDescription) { _, _ in
            if cameraManager.lastError != nil {
                onError?(cameraManager.lastError!)
                showingErrorAlert = true
            }
        }
        .sheet(isPresented: $showingLogEntryForm) {
            if let capturedImage = capturedImage {
                LogEntryFormView(
                    spot: spot,
                    capturedImage: capturedImage,
                    cameraManager: cameraManager,
                    imageManager: imageManager
                )
            }
        }
        .accessibilityIdentifier("cameraOverlayView")
    }

    // MARK: - Camera Actions

    @MainActor
    private func initializeCamera() {
        print("🔍 [CameraOverlayView.initializeCamera] START")
        Task { @MainActor in
            print("🔍 [CameraOverlayView.initializeCamera] About to call cameraManager.initializeCamera")
            do {
                try await cameraManager.initializeCamera()
                print("🔍 [CameraOverlayView.initializeCamera] initializeCamera SUCCESS")
            } catch {
                print("❌ [CameraOverlayView.initializeCamera] ERROR: \(error.localizedDescription)")
                cameraManager.lastError = error
            }
        }
        print("🔍 [CameraOverlayView.initializeCamera] END")
    }

    private func capturePhoto() async {
        print("🔍 [CameraOverlayView.capturePhoto] CAPTURE BUTTON PRESSED - Starting capture process")
        do {
            print("🔍 [CameraOverlayView.capturePhoto] About to call cameraManager.capturePhoto()")
            try await cameraManager.capturePhoto()
            print("✅ [CameraOverlayView.capturePhoto] cameraManager.capturePhoto() completed successfully")
        } catch {
            print("❌ [CameraOverlayView.capturePhoto] Capture failed: \(error.localizedDescription)")
            await MainActor.run {
                cameraManager.lastError = error
            }
        }
    }

    private func switchCamera() async {
        do {
            try await cameraManager.switchCamera()
        } catch {
            await MainActor.run {
                cameraManager.lastError = error
            }
        }
    }

    @MainActor
    private func loadPreviousImage() {
        // Get the most recent log entry for this spot
        let logEntries = spot.logEntries.sorted(by: { $0.timestamp > $1.timestamp })
        guard let mostRecentEntry = logEntries.first,
              !mostRecentEntry.imageFilename.isEmpty else {
            return
        }

        // Load image ใน background แต่อัพเดท UI บน main thread
        Task {
            do {
                let image = try imageManager.loadImage(filename: mostRecentEntry.imageFilename)
                await MainActor.run {
                    previousImage = image
                }
            } catch {
                // If we can't load the previous image, continue without overlay
                print("Failed to load previous image: \(error)")
            }
        }
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Camera Preview View

@MainActor
private struct CameraPreviewView: UIViewRepresentable {

    let cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        print("🔍 [CameraPreviewView.makeUIView] Creating preview view")
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        // Wait for camera to be initialized before adding preview layer
        setupPreviewLayer(view: view)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        print("🔍 [CameraPreviewView.updateUIView] Updating preview frame")
        // Update preview layer frame
        updatePreviewLayer(view: uiView)
    }

    private func setupPreviewLayer(view: UIView) {
        // Small delay to ensure camera is fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let previewLayer = self.cameraManager.getPreviewLayer() else {
                print("❌ [CameraPreviewView] No preview layer available")
                return
            }

            print("🔍 [CameraPreviewView] Setting up preview layer")
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill

            // Remove old layers if any
            view.layer.sublayers?.removeAll { $0 is AVCaptureVideoPreviewLayer }

            view.layer.addSublayer(previewLayer)
            print("✅ [CameraPreviewView] Preview layer added successfully")
        }
    }

    private func updatePreviewLayer(view: UIView) {
        guard let previewLayer = cameraManager.getPreviewLayer() else { return }

        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
    }
}

// MARK: - Log Entry Form View

private struct LogEntryFormView: View {

    let spot: Spot
    let capturedImage: UIImage
    let cameraManager: CameraManager
    let imageManager: ImageManager

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var medicalNote: String = ""
    @State private var painScore: Int = 1
    @State private var hasBleeding: Bool = false
    @State private var hasItching: Bool = false
    @State private var isSwollen: Bool = false
    @State private var estimatedSize: String = ""
    @State private var isSaving: Bool = false
    @State private var showingErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationView {
            Form {
                // Captured image preview
                Section {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                } header: {
                    Text("Captured Photo")
                        .font(.headline)
                }

                // Medical note
                Section {
                    TextField("Describe your observations, changes, concerns...", text: $medicalNote, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Medical Note")
                        .font(.headline)
                } footer: {
                    Text("Please provide details about your observations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Pain assessment
                Section {
                    PainScoreSlider(painScore: $painScore)
                } header: {
                    Text("Pain Assessment")
                        .font(.headline)
                }

                // Symptoms
                Section {
                    SymptomChecklist(
                        hasBleeding: $hasBleeding,
                        hasItching: $hasItching,
                        isSwollen: $isSwollen
                    )
                } header: {
                    Text("Current Symptoms")
                        .font(.headline)
                }

                // Estimated size
                Section {
                    HStack {
                        TextField("e.g., 5mm or 1.5cm", text: $estimatedSize)
                            .keyboardType(.decimalPad)

                        if let size = parsedEstimatedSize {
                            Text("\(String(format: "%.1f", size)) mm")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Estimated Size")
                        .font(.headline)
                }
            }
            .navigationTitle("Log Entry Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLogEntry()
                    }
                    .disabled(medicalNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .disabled(isSaving)
            .overlay(savingOverlay)
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var parsedEstimatedSize: Double? {
        let cleanedSize = estimatedSize.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedSize.isEmpty else { return nil }

        let numberString = cleanedSize.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let number = Double(numberString) else { return nil }

        return number > 10 ? number * 10 : number
    }

    private var savingOverlay: some View {
        Group {
            if isSaving {
                ProgressView("Saving...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.8))
            }
        }
        .allowsHitTesting(false)
    }

    @MainActor
    private func saveLogEntry() {
        guard !medicalNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please fill in the medical note field"
            showingErrorAlert = true
            return
        }

        isSaving = true

        Task { @MainActor in
            do {
                _ = try await cameraManager.createLogEntry(
                    spot: spot,
                    note: medicalNote.trimmingCharacters(in: .whitespacesAndNewlines),
                    painScore: painScore,
                    hasBleeding: hasBleeding,
                    hasItching: hasItching,
                    isSwollen: isSwollen,
                    estimatedSize: parsedEstimatedSize
                )

                // dismiss() ทำบน main actor แล้ว ไม่ต้อง MainActor.run
                dismiss()
                // The LogEntry is automatically saved to SwiftData in createLogEntry
            } catch {
                errorMessage = "Failed to save log entry: \(error.localizedDescription)"
                showingErrorAlert = true
            }

            isSaving = false
        }
    }
}

// MARK: - Preview

#Preview {
    // Create sample data container
    let container = try! ModelContainer(
        for: UserProfile.self, Spot.self, LogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    // Create sample user profile
    let userProfile = UserProfile(
        id: UUID(),
        name: "Test User",
        relation: "Self",
        avatarColor: "#FF6B6B",
        createdAt: Date()
    )

    // Create sample spot
    let spot = Spot(
        id: UUID(),
        title: "Test Mole",
        bodyPart: "Left Arm",
        isActive: true,
        createdAt: Date(),
        userProfile: userProfile
    )

    let cameraManager = CameraManager()
    let imageManager = ImageManager()

    return CameraOverlayView(
        spot: spot,
        cameraManager: cameraManager,
        imageManager: imageManager
    )
    .modelContainer(container)
}