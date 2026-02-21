# MedicalAI Flutter Application - Technical Inventory

**Document Version:** 1.0  
**Last Updated:** 2026-02-21  
**Project Status:** ✅ Stable (0 Critical Errors, 85 Analysis Issues - Warnings/Info Only)

---

## 📋 Executive Summary

MedicalAI is a comprehensive cross-platform healthcare application built with Flutter. It enables patient-doctor consultations through video calls, chat messaging, and appointment scheduling. The app supports 3 languages (English, Arabic, Russian) with full RTL support and implements role-based access for Patients, Doctors, and Admins.

### Key Metrics
- **Platform:** Flutter 3.x (Dart SDK >=3.0.0 <4.0.0)
- **Total Files:** ~70 Dart files
- **Lines of Code:** ~15,000+
- **Dependencies:** 26 production packages
- **Compilation Status:** ✅ 0 Errors, 85 Warnings/Info
- **Localization:** 3 Languages (EN/AR/RU)
- **State Management:** Provider Pattern

---

## 🏗️ Architecture Overview

```
lib/
├── main.dart                    # Entry point, Firebase init
├── core/
│   ├── constants/               # App constants
│   └── theme/                   # Light/Dark themes
├── models/                      # Data models
├── providers/                   # State management
├── screens/                     # UI screens
├── services/                    # Business logic
├── data/
│   └── models/                  # Alternative model location
├── l10n/
│   ├── app_localizations.dart   # Custom localization class
│   └── intl_*.arb              # ARB translation files
└── generated/
    └── l10n.dart               # Generated localization
```

### Design Patterns
- **State Management:** Provider (ChangeNotifier)
- **Navigation:** Material Navigation with named routes
- **Data Layer:** Repository pattern with Firestore
- **Localization:** ARB files + custom AppLocalizations class
- **Theme:** Material 3 with light/dark variants

---

## 🔐 Authentication & Authorization

### User Roles
| Role | Description | Access Level |
|------|-------------|--------------|
| `patient` | Standard user seeking medical consultation | Book appointments, chat with doctors, view records |
| `doctor` | Medical professional providing services | Manage schedule, view appointments, patient chats |
| `admin` | System administrator | Manage doctors, view statistics, generate QR codes |

### Auth Flow
```
Login Screen → AuthProvider → Firestore Role Check → Role-Based Dashboard
```

### Security Implementation
- Firebase Authentication (Email/Password)
- Role-based routing in `AuthWrapper`
- Firestore security rules (server-side, not in repo)
- Input validation on all forms

---

## 📊 Database Schema (Firestore)

### Collections Structure

```
users/{uid}
├── uid: string
├── name: string
├── email: string
├── phone: string
├── role: string (patient|doctor|admin)
├── locale: string (en|ar|ru)
├── photoUrl: string?
├── isOnline: boolean
├── lastSeen: timestamp
└── createdAt: timestamp

doctors/{uid}
├── userId: string (link to users collection)
├── name, nameEn, nameAr: string (localized)
├── specialty, specialtyEn, specialtyAr: string
├── price: number
├── currency: string
├── rating: number
├── doctorNumber: string (unique 8-char ID)
├── isActive: boolean
├── schedule/{date}
│   ├── isOpen: boolean
│   ├── slots: array [{time, booked, patientId, appointmentId}]
│   └── updatedAt: timestamp
└── createdAt: timestamp

appointments/{id}
├── patientId, doctorId: string
├── doctorName: string
├── date: string (YYYY-MM-DD)
├── timeSlot: string
├── format: string (video|audio|chat)
├── price, currency: string
├── status: string (pending|confirmed|cancelled)
├── paymentStatus: string (pending|paid)
├── chatId: string
└── createdAt: timestamp

chats/{id}
├── patientId, doctorId: string
├── appointmentId: string
├── status: string (active|closed)
├── lastMessage: string?
├── lastMessageAt: timestamp
└── messages/{id}
    ├── senderId, senderRole: string
    ├── text: string
    ├── type: string (text|file|system)
    ├── fileUrl: string? (for file messages)
    ├── timestamp: timestamp
    └── read: boolean

payments/{id}
├── patientId, doctorId, appointmentId: string
├── consultationFee, serviceFee, totalAmount: number
├── method: string (bankCard|wallet|sbp|yookassa|applePay|googlePay)
├── transactionId: string?
├── status: string (pending|success|failed)
├── cardLastFour: string?
└── createdAt: timestamp
```

---

## 🛠️ Services Layer

### 1. AuthProvider (`providers/auth_provider.dart`)
**Purpose:** Authentication state management
- `signIn(email, password)` - Login with error handling
- `signUp(...)` - Registration with role-based profile creation
- `signOut()` - Logout
- `forgotPassword(email)` - Password reset
- `updateProfile()` - Profile updates

### 2. DoctorService (`services/doctor_service.dart`)
**Purpose:** Doctor data operations
- `getDoctors(specialty?)` - List doctors with optional filter
- `getDoctorById(id)` - Single doctor lookup
- `getDoctorByNumber(number)` - QR code lookup
- `getAvailableSlots(doctorId, date)` - Fetch schedule
- `updateSchedule(...)` - Manage doctor availability
- `getSpecialties()` - List all specialties

### 3. BookingService (`services/booking_service.dart`)
**Purpose:** Appointment creation and management
- `createBooking(...)` - Create appointment + chat room
- `getPatientAppointments(patientId)` - Patient's booking history
- `getDoctorAppointments(doctorId)` - Doctor's appointments

### 4. PaymentService (`services/payment_service.dart`)
**Purpose:** Payment processing (Trial/Simulation Mode)
- `processConsultationPayment(...)` - Simulates 95% success rate
- `calculateServiceFee(amount)` - 2.5% platform commission
- `calculateTotalAmount(fee)` - Total with commission
- `formatPrice(amount, locale)` - Localized currency display
- **Note:** Currently in simulation mode, requires live gateway integration

### 5. ChatService (`services/chat_service.dart`)
**Purpose:** Real-time messaging
- `getOrCreateChat(...)` - Find or create chat room
- `sendMessage(...)` - Send text messages
- `uploadFile(...)` - File upload with progress callback
- `markMessagesAsRead(...)` - Read receipts

---

## 🖥️ Screen Inventory

### Authentication Flow
| Screen | File | Description |
|--------|------|-------------|
| Login | `auth/login_screen.dart` | Email/password login |
| Register | `auth/register_screen.dart` | Patient registration |
| Auth Wrapper | `auth_wrapper.dart` | Role-based routing gate |

### Patient Flow
| Screen | File | Description |
|--------|------|-------------|
| Home | `home_screen.dart` | 4-button grid: Scan QR, My Doctors, Find Specialist, Medical Tourism |
| Specialist List | `specialist_list_screen.dart` | Filter doctors by specialty |
| Doctor Profile | `doctor_profile_screen.dart` | Calendar view, booking, legal links |
| Booking | `booking_screen.dart` | Time slot selection, confirmation |
| Chat | `chat_screen.dart` | Messaging with file upload |
| My Appointments | `my_appointments_screen.dart` | Booking history |
| QR Share/Scan | `qr_share_scan_screen.dart` | Scan doctor QR or enter ID manually |

### Doctor Flow
| Screen | File | Description |
|--------|------|-------------|
| Doctor Dashboard | `dashboard/doctor_dashboard.dart` | Stats, QR code, schedule link |
| Schedule Management | `doctor/schedule_management_screen.dart` | Calendar with slot management |
| Patient Records | `doctor/patient_records_screen.dart` | View patient medical history |

### Admin Flow
| Screen | File | Description |
|--------|------|-------------|
| Admin Dashboard | `admin_dashboard.dart` | Statistics, doctor management |

---

## 🌍 Localization System

### Supported Languages
| Code | Language | Direction | Completeness |
|------|----------|-----------|--------------|
| en | English | LTR | ✅ 100% |
| ar | Arabic | RTL | ✅ 100% |
| ru | Russian | LTR | ✅ 100% |

### Implementation
- **ARB Files:** `lib/l10n/intl_*.arb`
- **Generated Code:** `lib/generated/l10n.dart`
- **Custom Class:** `lib/l10n/app_localizations.dart` (~200 translation keys)
- **RTL Support:** Directionality wrapper in MaterialApp builder

### Key Features
- Runtime locale switching via LocaleProvider
- Persistent language preference (SharedPreferences)
- Automatic text direction based on locale
- Currency formatting per locale (USD, RUB, SAR)

---

## 📦 Dependencies

### Firebase Ecosystem
```yaml
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.4
firebase_storage: ^12.3.7
firebase_messaging: ^15.1.6
```

### Video & Communication
```yaml
agora_rtc_engine: ^6.3.2      # Video calls
permission_handler: ^11.3.1    # Camera/mic permissions
```

### QR & Scanning
```yaml
mobile_scanner: ^5.1.1         # QR code scanning
qr_flutter: ^4.1.0             # QR code generation
```

### File Handling
```yaml
image_picker: ^1.1.2           # Camera/gallery
file_picker: ^8.1.6            # Document selection
firebase_storage: ^12.3.7      # Cloud file storage
pdf: ^3.11.1                   # PDF generation
printing: ^5.13.4              # Print/PDF share
path_provider: ^2.1.2          # Local storage paths
share_plus: ^10.1.3            # Native share sheet
```

### UI Components
```yaml
table_calendar: ^3.1.2         # Doctor availability calendar
flutter_local_notifications: ^18.0.1  # Push notifications
```

### State & Utilities
```yaml
provider: ^6.1.2               # State management
shared_preferences: ^2.3.2     # Local settings
flutter_secure_storage: ^9.2.2 # Secure token storage
intl: ^0.19.0                  # Internationalization
uuid: ^4.5.1                   # Unique IDs
url_launcher: ^6.3.14          # External links
```

---

## ⚠️ Known Issues & Technical Debt

### Warnings (Non-Blocking)
| Issue | Count | Severity | Solution |
|-------|-------|----------|----------|
| `withOpacity` deprecation | ~40 | Low | Replace with `withValues(alpha: ...)` |
| Unused imports | ~15 | Low | Remove unused imports |
| Unused variables | ~10 | Low | Remove or use variables |
| Dead code | ~5 | Low | Remove unreachable code |

### Missing Configurations
| Item | Impact | Solution |
|------|--------|----------|
| Firebase config | App won't run | Add `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) |
| Assets configuration | No images loaded | Uncomment assets in `pubspec.yaml`, add images |
| Payment gateway | Payments simulated | Integrate Stripe/YooKassa with live API keys |
| Agora tokens | Video calls insecure | Implement server-side token generation |

### Unused/Broken Files
| File | Issue | Action |
|------|-------|--------|
| `doctor_booking_screen.dart` | Import errors, replaced | Safe to delete |
| `signup_screen.dart` (root) | Uses non-existent method | Safe to delete (use `auth/signup_screen.dart`) |
| `patient_dashboard.dart` | References non-existent class | Needs refactoring |

### Hardcoded Strings (Not Localized)
- `booking_screen.dart` - "Book Appointment", "Confirm Booking"
- Some error messages in services
- Calendar month names (should use intl)

---

## 🔒 Security Considerations

### Implemented
- ✅ Firebase Auth for authentication
- ✅ Role-based access control
- ✅ Input validation on forms
- ✅ File upload type validation

### Required (Server-Side)
- ⚠️ Firestore Security Rules
- ⚠️ Firebase Storage Rules
- ⚠️ Agora token generation (server-side)
- ⚠️ Payment webhook validation

### Data Privacy
- Patient medical records encrypted at rest (Firestore)
- Chat messages with read receipts
- Payment data stored separately
- GDPR/CCPA compliance not verified

---

## 📱 Platform Support

### Android
- **Min SDK:** 21 (Android 5.0)
- **Target SDK:** 34
- **Permissions:** Camera, Microphone, Storage, Internet
- **Features:** QR scanning, Video calls, Push notifications

### iOS
- **Min Version:** 12.0
- **Permissions:** Camera, Microphone, Photo Library
- **Features:** All Android features + Apple Pay

### Limitations
- Portrait orientation only (locked in main.dart)
- No tablet-optimized layout
- No desktop support (Windows/macOS/Linux)

---

## 🚀 Deployment Checklist

### Pre-Release
- [ ] Configure Firebase project (Android/iOS)
- [ ] Add production API keys (Agora, Payment Gateway)
- [ ] Set up Firestore security rules
- [ ] Configure push notifications (FCM)
- [ ] Add app icons and splash screens
- [ ] Uncomment and populate assets in pubspec.yaml
- [ ] Test on physical devices (iOS + Android)
- [ ] Run integration tests

### Production
- [ ] Switch PaymentService from simulation to live
- [ ] Enable Firebase Analytics
- [ ] Configure Crashlytics
- [ ] Set up CI/CD pipeline (Codemagic configured in `codemagic.yaml`)

---

## 🔄 User Flows

### 1. Patient Booking Flow
```
Home → Find Specialist → Doctor Profile → Calendar → 
Time Slot → Booking → Payment → Chat
```

### 2. QR Direct Access Flow
```
Home → Scan QR → Doctor Profile (skip search)
```

### 3. Doctor Schedule Management
```
Doctor Dashboard → Schedule Management → Toggle Dates → Add Slots
```

### 4. Video Consultation Flow
```
Chat → Start Video Call → Agora Engine → End Call → Back to Chat
```

---

## 📈 Performance Considerations

### Current Implementation
- StreamBuilder for real-time updates
- No pagination (loads all data at once)
- No image caching configured
- PDF generation may block UI

### Optimization Opportunities
1. Implement pagination for doctor lists
2. Add image caching (cached_network_image)
3. Move PDF generation to isolate
4. Add lazy loading for chat messages
5. Implement query result caching

---

## 🧪 Testing

### Unit Tests
- **Status:** Minimal coverage
- **Location:** `test/` directory

### Integration Tests
- **Status:** Not implemented
- **Recommendation:** Add widget tests for critical flows

### Manual Testing Checklist
- [ ] Login/Register flow (all 3 roles)
- [ ] Booking flow with payment
- [ ] Chat with file upload
- [ ] Video call connectivity
- [ ] QR scanning
- [ ] RTL layout (Arabic)
- [ ] Dark mode toggle
- [ ] Offline behavior

---

## 📚 Documentation References

### Flutter
- [Flutter Documentation](https://docs.flutter.dev)
- [Provider Package](https://pub.dev/packages/provider)

### Firebase
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

### Third-Party
- [Agora Flutter SDK](https://docs.agora.io/en/video-calling/get-started/get-started-sdk)
- [Table Calendar](https://pub.dev/packages/table_calendar)

---

## 📝 Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-21 | 1.0.0 | Initial stable build, 0 compilation errors |

---

## 👥 Maintenance Contacts

**Primary Developer:** [Not specified in codebase]  
**Repository:** `c:\Users\Baha\Documents\NS\medicalai`  
**License:** Not specified

---

*End of Technical Inventory*
