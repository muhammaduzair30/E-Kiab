# E-Kitab (ای-کتاب) Learning App 📚🎓

**E-Kitab** is an AI-powered educational platform designed to provide smart, accessible, and interactive learning resources for Pakistani schools. It aims to bridge the digital learning gap by offering a smart tutoring experience and digital resources.

## 🚀 Key Features

* **🤖 AI-Powered Assistant:** Integrates `google_generative_ai` (Gemini) to provide smart tutoring, doubt resolution, and interactive learning experiences.
* **🗣️ Text-to-Speech (TTS):** Integrated `flutter_tts` for reading out lessons and assisting students with pronunciation and accessibility.
* **📄 Interactive Document Viewer:** Built-in PDF reader (`syncfusion_flutter_pdfviewer`) and Markdown support for rich text lessons and digital textbooks.
* **📊 Progress Tracking:** Visual analytics and student progress tracking using interactive charts (`fl_chart` and `percent_indicator`).
* **☁️ Cloud Backend:** Fully powered by Firebase (Authentication, Cloud Firestore, and Cloud Storage) for secure, real-time data sync across devices.
* **📱 Modern UI/UX:** Smooth animations and responsive design built with `flutter_animate`, `shimmer` loading effects, and vector graphics (`flutter_svg`).

## 🛠️ Tech Stack & Architecture

This application is built using modern Flutter best practices and packages:

* **Framework:** [Flutter](https://flutter.dev/) (SDK >=3.2.0)
* **State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod` & `riverpod_generator`) for scalable and reactive state.
* **Routing:** `go_router` for declarative routing and deep linking.
* **Backend:** Firebase (Auth, Firestore, Storage) via `firebase_core`.
* **Networking:** `dio` for robust API calls and `connectivity_plus` for offline awareness.
* **Local Storage:** `hive_flutter`, `shared_preferences`, and `flutter_secure_storage` for caching and secure data persistence.
* **Code Generation:** `freezed` and `json_serializable` for robust immutable data models.

## ⚙️ Getting Started

### Prerequisites

* Flutter SDK (>=3.2.0)
* Dart SDK
* Firebase project configured for Android/iOS/Web
* Gemini API Key

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/ekitab.git
   cd ekitab
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate code (Freezed / Riverpod):**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Environment Setup:**
   Create a `.env` file inside the `scripts/` directory (or the root if reconfigured) and add your API keys:
   ```env
   GEMINI_API_KEY=your_api_key_here
   ```

5. **Run the App:**
   ```bash
   flutter run
   ```

## 📂 Project Structure

The project follows a feature-first architecture to ensure scalability and maintainability, powered by Riverpod state management and Freezed models. Key directories:
- `lib/`: Main application code.
- `assets/`: Images, icons, and fonts.
- `scripts/`: Custom scripts and environment variable configurations.

## 🛡️ License

This project is licensed under the [MIT License](LICENSE).
