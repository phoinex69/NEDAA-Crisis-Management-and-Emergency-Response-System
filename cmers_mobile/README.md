# نداء (Nidaa) — Flutter Emergency App

تطبيق إبلاغ عن الطوارئ مبني بـ Flutter مع معمارية MVC وإدارة الحالة باستخدام GetX،
يطابق وثيقة المتطلبات (نظام إدارة الأزمات والاستجابة للطوارئ — المتطلبات 4.1 إلى 4.9 و7.2 و7.4).

---

## 🏗️ Project Architecture — MVC + GetX

```
lib/
├── main.dart                          # Entry point (locale + offline + accessibility init)
├── app/
│   └── app.dart                       # GetMaterialApp (localizations, a11y, routing, bindings)
├── core/
│   ├── config/app_config.dart         # baseUrl (off/on switch to real backend)
│   ├── constants/
│   │   ├── app_colors.dart            # Color palette (+ severity/shelter/safe-point colors)
│   │   ├── app_strings.dart           # All strings (Arabic/English via LocaleService)
│   │   └── app_routes.dart            # Named route constants
│   ├── localization/locale_service.dart  # Language toggle (ar/en) — req 7.4
│   └── theme/app_theme.dart           # ThemeData (Cairo font, red/white)
├── models/                            # M — Data layer
│   ├── report_model.dart              # 7 categories + 4 severities + agency/ETA/victims/witness
│   ├── alert_model.dart               # Citizen alerts (req 4.5)
│   ├── shelter_model.dart             # Shelters (req 4.6)
│   ├── safe_point_model.dart          # Safe gathering points (req 4.6)
│   ├── medical_card_model.dart        # Emergency medical card (req 4.7)
│   ├── pending_report_payload.dart    # Offline queue payload (req 4.9)
│   └── …(user, contact, zone, hospital, center)
├── controllers/                       # C — Business logic (GetxController)
│   ├── auth_controller.dart           # Login, OTP, countdown
│   ├── sos_controller.dart            # One-tap SOS + hold-to-report flow (req 4.2)
│   ├── reports_controller.dart        # Reports, severity, victims, voice, witness
│   ├── alerts_controller.dart         # Alerts polling + local notifications
│   ├── accessibility_controller.dart  # Large text + high contrast (req 7.4)
│   ├── profile_controller.dart        # Contacts, medical card, profile
│   └── map_controller.dart            # Zones, hospitals, centers, shelters, safe points
└── views/                             # V — UI layer
    ├── splash/splash_screen.dart
    ├── auth/ (login_screen, otp_screen)
    ├── home/home_screen.dart          # SOS button, alerts banner, witness, offline banner
    ├── alerts/alerts_list_screen.dart # Full alerts list (req 4.5)
    ├── reports/ (list, category, details, tracking)
    ├── profile/profile_screen.dart    # Medical card + language + accessibility
    ├── map/map_screen.dart            # Shelters + safe points + zones + hospitals
    ├── sos/sos_countdown_screen.dart  # Cancellable SOS countdown (one-press flow)
    ├── main_scaffold.dart             # Bottom nav wrapper
    └── widgets/ (report_card, nidaa_app_bar, bottom_nav_bar)
```

---

## 📱 Screens

| Screen | Route |
|--------|-------|
| Splash | `/` |
| Login (Phone) | `/login` |
| OTP Verification | `/otp` |
| Home (SOS + alerts + witness) | `/home` |
| My Reports (filtered list) | `/reports-list` |
| Report Category (7 types) | `/report-category` |
| Report Details (severity + victims + voice + photo) | `/report-details` |
| Report Tracking (agency + ETA + live map) | `/report-tracking` |
| SOS Countdown (one-press, cancellable) | `/sos-countdown` |
| Alerts List (full list from bell icon) | `/alerts-list` |
| Risk Map (zones + shelters + safe points) | Tab |
| Profile (contacts + medical card + language + accessibility) | Tab |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0
- Android Studio / VS Code with Flutter plugin

### Install & Run

```bash
flutter pub get
flutter run
```

### Google Maps Setup
1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Replace `YOUR_GOOGLE_MAPS_API_KEY` in `android/app/src/main/AndroidManifest.xml`

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `get: ^4.6.6` | State management + routing |
| `dio: ^5.4.0` | HTTP client (real backend) |
| `google_maps_flutter: ^2.5.0` | Map, zones, shelters, safe points |
| `geolocator: ^14.0.3` | Location + SOS coordinates |
| `record: ^5.1.2` | Voice report recording (req 4.3) |
| `connectivity_plus: ^6.0.3` | Offline detection (req 4.9) |
| `flutter_local_notifications: ^22.3.0` | Live status notifications |
| `image_picker: ^1.0.4` | Attach photos to reports |
| `flutter_secure_storage: ^11.0.0` | Encrypted tokens + medical card (req 7.2) |
| `pinput: ^3.0.0` | OTP input fields |
| `shared_preferences: ^2.2.2` | Session user data + offline queue + accessibility prefs |
| `url_launcher: ^6.3.2` | Calls + map directions |
| `flutter_localizations` | Localization support (ar/en) |

---

## 🧪 Tests

```bash
flutter test   # model unit tests (categories, severities, JSON contracts, offline payload)
flutter analyze
```

---

## 🎨 Design System

- **Primary color**: `#CC1C2E` (red)
- **Background**: `#F9F5F5` (warm off-white)
- **Font**: Cairo (Arabic-optimized)
- **Languages**: Arabic (default, RTL) + English (LTR) — toggle in Profile (req 7.4)
- **Accessibility**: large text (×1.25) + high-contrast theme toggle in Profile (req 7.4)
- **Security**: tokens & medical card stored encrypted (req 7.2)

See `nidaa_app_use.md` for the full API contract and setup notes.
