# Project Name: SpotOn (Local-First iOS App)

## 1. Executive Summary
We are building a native iOS application named **SpotOn**.
**Concept:** **SpotOn** is a "Visual Medical Journal" designed to track skin conditions (moles, rashes, wounds) over time for multiple family members.
**Core Value:** The app features a **"Ghost Overlay"** camera interface that ensures consistent photo alignment by overlaying the previous image while taking a new one. It also includes a "Doctor Summary" mode to visualize progress.
**Constraint:** 100% Local storage (SwiftData). No cloud backend. No internet requirement.

---

## 2. Tech Stack Requirements
* **Language:** Swift 5.9+
* **UI Framework:** SwiftUI (MVVM Architecture)
* **Database:** SwiftData (Schema-driven)
* **Camera:** AVFoundation (Custom implementation for Overlay logic)
* **Minimum iOS Version:** iOS 17.0

---

## 3. Database Schema (SwiftData Models)
*Context: The app uses a hierarchical structure: Profile -> Spot -> LogEntry.*

### Model 1: `UserProfile`
Represents a family member (e.g., Dad, Mom, Self).
* `id`: UUID (Unique Identifier)
* `name`: String
* `relation`: String (e.g., "Father", "Daughter")
* `avatarColor`: String (Hex code string for UI theme)
* `createdAt`: Date
* **Relationship:** One-to-Many with `Spot` (`@Relationship(deleteRule: .cascade)`)

### Model 2: `Spot`
Represents a specific area/condition on the body being tracked (e.g., "Mole on left arm").
* `id`: UUID
* `title`: String
* `bodyPart`: String (Enum or String, e.g., "Arm", "Back", "Face")
* `isActive`: Bool (Default: true)
* `createdAt`: Date
* **Relationship:** Belongs-to `UserProfile` (Inverse)
* **Relationship:** One-to-Many with `LogEntry` (`@Relationship(deleteRule: .cascade)`)

### Model 3: `LogEntry`
Represents a daily update or a specific check-up record.
* `id`: UUID
* `timestamp`: Date
* `imageFilename`: String (UUID string. **Important:** Do NOT store large binary data in SwiftData. Save the actual image to the App's `.documentsDirectory` and store only the filename here.)
* `note`: String (Free text)
* **Structured Data (Medical Context):**
    * `painScore`: Int (0-10)
    * `hasBleeding`: Bool
    * `hasItching`: Bool
    * `isSwollen`: Bool
    * `estimatedSize`: Double? (in mm, optional)
* **Relationship:** Belongs-to `Spot` (Inverse)

---

## 4. Functional Requirements (User Journey)

### Phase 1: Dashboard & Profile Switching
* **View:** `HomeView`
* **Behavior:**
    * Display a horizontal list of **UserProfiles** at the top.
    * When a profile is selected, fetch and display the list of **Spot** items belonging to that user.
    * Include buttons to [Add New Profile] and [Add New Spot].

### Phase 2: Spot Detail & Timeline
* **View:** `SpotDetailView`
* **Behavior:**
    * Display a chronological list of `LogEntry` items (Sorted: Newest First).
    * Each row item shows: Thumbnail Image + Date + Short Note + Symptom Badges (e.g., 🩸, ⚡️).
    * **Primary Action:** A prominent **"Update / Snap"** button to add a new log.
    * **Secondary Action:** A **"Doctor Summary"** button in the toolbar.

### Phase 3: Camera with Ghost Overlay (The "SpotOn" Feature)
* **View:** `CameraOverlayView`
* **Logic:**
    1.  Check if there is a previous `LogEntry` for the current `Spot`.
    2.  **If Yes:** Fetch the last image, lower its opacity to approx 0.4, and place it as an overlay on top of the live camera feed. This guides the user to align the shot perfectly ("Spot On").
    3.  **If No (First time):** Show only the live camera feed.
    4.  **Action:** Capture photo -> Save to Disk -> Create `LogEntry` -> Navigate to Input Form.

### Phase 4: Structured Data Input
* **View:** `LogEntryFormView`
* **Fields:**
    * Image Preview (With "Retake" option).
    * Note (TextEditor area).
    * Pain Level (Slider 0-10).
    * Symptoms (Toggle Switches: Bleeding, Itching, Swelling).
    * Date Picker (Default to `.now`).

### Phase 5: Doctor Summary Mode
* **View:** `DoctorSummaryView`
* **Layout:**
    * **Header:** Patient Name + Spot Name.
    * **Visual Comparison:** Display the **First Recorded Image** (Left) vs **Latest Image** (Right) side-by-side (50% width each) for immediate assessment.
    * **Stats Summary:** e.g., "Tracked for 45 days. Pain level increased in the last 3 entries."
    * **Compact Timeline:** A dense list of dates and key notes/symptoms for quick scanning by a physician.

---

## 5. Technical Implementation Guidelines (For AI Coder)

1.  **Image Handling (Local Storage):**
    * Implement a `ImageManager` or `FileManager` helper.
    * Function: `saveImage(image: UIImage) -> String` (Returns the unique filename).
    * Function: `loadImage(filename: String) -> UIImage?`.
    * Ensure all images are saved in the app's `.documentsDirectory` to persist between launches.

2.  **SwiftData Architecture:**
    * Initialize `modelContainer` in `SpotOnApp.swift`.
    * Use `@Query` in SwiftUI Views to observe data changes dynamically.
    * Follow MVVM pattern: Keep logic (fetching, saving, deleting) in ViewModels (`SpotListViewModel`, `LogEntryViewModel`).

3.  **Permissions:**
    * **Crucial:** Remind me to add `NSCameraUsageDescription` to the `Info.plist` file, otherwise the app will crash when accessing the camera.

---

### 🛑 End of PRD

**Task for AI:**
Based on the **SpotOn** PRD above, please generate the comprehensive SwiftUI code structure.
**Step 1:** Generate the **Data Models** (`Models.swift`) ensuring all SwiftData relationships are correct.
**Step 2:** Generate the **ImageManager** helper class.
**Step 3:** Generate the `HomeView` and `SpotDetailView` with dummy data logic for testing.
(Wait for my confirmation before generating the complex Camera View).
