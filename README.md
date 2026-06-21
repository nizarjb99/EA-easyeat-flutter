<div align="center">

# 🍽️ EasyEat — Flutter App

holaaa

**A modern restaurant loyalty & management platform built with Flutter**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey?style=for-the-badge)](https://flutter.dev/multi-platform)

</div>

---

## 📋 Overview

**EasyEat** is a cross-platform mobile and web application that connects customers, employees, and restaurant owners through a unified loyalty and management experience. Customers earn and redeem points at restaurants, while employees and owners manage visits, rewards, and restaurant data — all in real time.

---

## ✨ Features

### 👤 Customer
- 🔍 **Discover** restaurants by name, city, or category
- 🗺️ **Interactive map** view of nearby restaurants
- 🎟️ **QR Code** to earn and redeem points at restaurants
- 💰 **Points Wallet** with full transaction history
- 🏆 **Rewards** redemption system
- 💬 **In-app chat** with restaurant staff

### 👨‍💼 Employee / Staff
- 📷 **QR Scanner** to identify customers and assign points
- ✅ **Add visits** and assign loyalty points instantly
- 🎁 **Approve reward redemptions** via QR scan
- 📊 **Dashboard** with real-time activity feed and KPIs
- 🔔 **Alerts & Insights** on daily activity

### 🏠 Owner
- 🏪 Full **restaurant configuration** and management
- 👥 **Customer & employee stats** at a glance
- 📈 **Revenue and visit analytics**
- ⚙️ **Settings** panel for restaurant customization

### 🌐 Global
- 🌍 **Multilingual** support: English, Spanish (ES), Catalan (CA)
- 🌙 **Light / Dark theme** (system-aware)
- 🔄 **Real-time updates** via Socket.IO
- 📍 **Geolocation** integration

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x / Dart 3.x |
| **State Management** | Provider |
| **HTTP Client** | `http` |
| **Real-time** | Socket.IO (`socket_io_client`) |
| **Maps** | Google Maps Flutter |
| **Geolocation** | Geolocator |
| **QR Code** | `qr_flutter` + `mobile_scanner` |
| **Localization** | Easy Localization |
| **Persistence** | Shared Preferences |

---

## 📁 Project Structure

```
lib/
├── main.dart                   # App entry point, routing, providers
├── models/                     # Data models (Restaurant, Customer, Employee, Dish, …)
├── providers/                  # State management (Auth, Restaurant, Location, Chat)
├── screens/
│   ├── _auth/                  # Landing, Login, Register, Legal Notice
│   ├── _common/                # Shared screens: Navigation, Discover, Map, Profile, Chat
│   ├── _customer/              # Customer Home, Points Wallet, QR Code
│   └── _employee/              # Employee Home, Add Visit, QR Scanner, Reward Exchange
├── services/                   # API & socket services (Auth, Restaurant, Customer, …)
├── utils/                      # Theme, styles, constants
└── widgets/                    # Reusable UI components
assets/
└── translations/               # i18n JSON files (en, es, ca)
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.x`
- Dart SDK `^3.11.4`
- Android Studio / Xcode (for mobile builds)
- A running instance of the [EasyEat Backend](https://github.com/nizarjb99/EA-easyeat-backend2)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/nizarjb99/EA-easyeat-flutter.git
   cd EA-easyeat-flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure the backend URL**

   Open `lib/utils/` (or the relevant constants file) and update the API base URL to point to your backend instance:
   ```dart
   const String baseUrl = 'http://YOUR_BACKEND_HOST:PORT';
   ```

4. **Configure Google Maps** *(required for the map feature)*

   - Add your Google Maps API key in:
     - **Android**: `android/app/src/main/AndroidManifest.xml`
     - **iOS**: `ios/Runner/AppDelegate.swift`

5. **Run the app**
   ```bash
   flutter run
   ```
   Or target a specific platform:
   ```bash
   flutter run -d chrome       # Web
   flutter run -d android
   flutter run -d ios
   ```

---

## 🌍 Localization

The app supports three languages out of the box:

| Language | Code | File |
|---|---|---|
| English | `en` | `assets/translations/en.json` |
| Spanish | `es` | `assets/translations/es.json` |
| Catalan | `ca` | `assets/translations/ca.json` |

Language follows the device locale automatically, with English as the fallback.

To add a new language, create a new JSON file in `assets/translations/` and register the locale in `main.dart`.

---

## 👥 User Roles

EasyEat uses a **role-based** navigation system. After login, users are routed to a role-specific dashboard:

| Role | Access |
|---|---|
| `customer` | Discover, Wallet, QR, Chat |
| `staff` | Add Visit, QR Scanner, Reward Approval, Dashboard |
| `owner` | Full Dashboard, Restaurant Settings, Analytics |

---

## 🔗 Related Repositories

| Project | Description |
|---|---|
| [EA-easyeat-backend2](https://github.com/nizarjb99/EA-easyeat-backend2) | Node.js / TypeScript REST API + Socket.IO backend |

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

<div align="center">
Made with ❤️ and Flutter
</div>