# Simple Currency

A modern, cross-platform currency converter application built with Flutter. This app allows users to track real-time exchange rates, manage a personal wallet with multiple currencies, and view conversion analytics.

## ✨ Features

*   **Real-time Currency Conversion:** Instantly convert between a wide range of currencies using up-to-date exchange rates.
*   **Live Exchange Rates:** View a list of the latest exchange rates for various currency pairs.
*   **Personal Wallet:** Manage a virtual wallet with balances in multiple currencies. Add or remove funds and see your total portfolio value.
*   **Analytics Dashboard:** Visualize your conversion history and spending habits with interactive charts.
*   **User Authentication:** Securely sign in to sync your wallet and preferences across devices using Firebase Authentication.
*   **Cross-Platform:** A single codebase that runs on Android, iOS, Web, Windows, macOS, and Linux.

## 🚀 Technologies Used

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Language:** [Dart](https://dart.dev/)
*   **Backend & Cloud:**
    *   **Firebase Authentication:** For user management and sign-in.
    *   **Cloud Firestore:** As a NoSQL database for storing wallet and user data.
    *   **Firebase Analytics:** For usage tracking and insights.
*   **State Management:** (Please specify - e.g., Provider, BLoC, GetX)
*   **Charting:** [fl_chart](https://pub.dev/packages/fl_chart)
*   **API Communication:** [http](https://pub.dev/packages/http)
*   **Local Storage:** [shared_preferences](https://pub.dev/packages/shared_preferences)

## 📦 Getting Started

### Prerequisites

*   Flutter SDK: Make sure you have the Flutter SDK installed. [Installation Guide](https://flutter.dev/docs/get-started/install)
*   Firebase Account: You will need a Firebase project to connect the app.

### Installation & Setup

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/Resquezz/SimpleCurrency.git
    cd SimpleCurrency
    ```

2.  **Set up Firebase:**
    *   Create a new project on the [Firebase Console](https://console.firebase.google.com/).
    *   Follow the instructions to add Flutter to your Firebase project.
    *   Download the `google-services.json` file for Android and place it in `android/app/`.
    *   Configure the iOS, Web, and other platforms as needed by following the Firebase setup wizard. You will need to replace the placeholder configuration files.

3.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

4.  **Run the application:**
    ```sh
    flutter run
    ```

## 📂 Project Structure

The project follows a feature-driven architecture to keep the codebase organized and scalable.

```
lib/
├── data/
│   ├── models/         # Data models (e.g., Rate, Wallet)
│   └── repositories/   # Handles data operations (API, DB)
├── presentation/
│   ├── controllers/    # Business logic for screens
│   ├── screens/        # UI for each feature
│   └── widgets/        # Shared widgets used across the app
├── core/
│   ├── app_theme.dart  # Theme and styling
│   └── app_utils.dart  # Utility functions
├── main.dart           # App entry point
└── app.dart            # Main app widget and routing
```