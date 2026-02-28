# دليل نشر تطبيق MedicalAI

## ⚠️ خطوات مهمة يجب اتباعها قبل إرسال التطبيق للأصدقاء

---

## 1️⃣ تحديث قواعد Firestore Security Rules

### الخطوات:
1. افتح [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروع MedicalAI
3. اذهب إلى **Firestore Database** → **Rules**
4. انسخ الكود التالي والصقه:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    function isDoctor() {
      return isAuthenticated() && getUserData().role == 'doctor';
    }
    
    function isAdmin() {
      return isAuthenticated() && getUserData().role == 'admin';
    }

    // Users Collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isOwner(userId);
      allow update: if isAuthenticated() && (isOwner(userId) || isAdmin());
      allow delete: if isAdmin();
    }

    // Doctors Collection
    match /doctors/{doctorId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && (isOwner(doctorId) || isAdmin());
      allow update: if isAuthenticated() && (isOwner(doctorId) || isAdmin());
      allow delete: if isAdmin();
    }

    // Appointments Collection
    match /appointments/{appointmentId} {
      allow read: if isAuthenticated() && (
        resource.data.patientId == request.auth.uid ||
        resource.data.doctorId == request.auth.uid ||
        isAdmin()
      );
      allow create: if isAuthenticated() && request.resource.data.patientId == request.auth.uid;
      allow update: if isAuthenticated() && (
        resource.data.patientId == request.auth.uid ||
        resource.data.doctorId == request.auth.uid ||
        isAdmin()
      );
    }

    // Medical Records Collection
    match /records/{recordId} {
      allow read: if isAuthenticated() && (
        resource.data.patientEmail == request.auth.token.email ||
        resource.data.doctorId == request.auth.uid ||
        isAdmin()
      );
      allow create: if isAuthenticated() && (
        request.resource.data.doctorId == request.auth.uid ||
        isAdmin() ||
        request.auth.token.role == 'doctor'
      );
      allow update, delete: if isAuthenticated() && (
        resource.data.doctorId == request.auth.uid ||
        isAdmin()
      );
    }

    // Chats Collection
    match /chats/{chatId} {
      allow read: if isAuthenticated() && (
        request.auth.uid in resource.data.participants ||
        isAdmin()
      );
      allow create: if isAuthenticated() && request.auth.uid in request.resource.data.participants;
      allow update: if isAuthenticated() && (
        request.auth.uid in resource.data.participants ||
        isAdmin()
      );
      
      match /messages/{messageId} {
        allow read: if isAuthenticated() && (
          request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants ||
          isAdmin()
        );
        allow create: if isAuthenticated() && (
          request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants
        ) && request.resource.data.senderId == request.auth.uid;
      }
    }

    // Default deny
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

5. اضغط **Publish**

---

## 2️⃣ تحديث قواعد Firebase Storage

### الخطوات:
1. في Firebase Console، اذهب إلى **Storage** → **Rules**
2. انسخ الكود التالي:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // Chat attachments
    match /chats/{chatId}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() 
        && request.resource.size < 50 * 1024 * 1024;
    }

    // Medical records
    match /medical_records/{userId}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isOwner(userId);
    }

    // Profile pictures
    match /profile_pictures/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isOwner(userId);
    }

    // Default deny
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

3. اضغط **Publish**

---

## 3️⃣ إنشاء Indexes في Firestore

### Indexes مطلوبة:

#### 1. Collection: appointments
| الحقول | ترتيب |
|--------|-------|
| doctorId | Ascending |
| date | Ascending |
| timeSlot | Ascending |

#### 2. Collection: records
| الحقول | ترتيب |
|--------|-------|
| patientEmail | Ascending |
| createdAt | Descending |

#### 3. Collection: chats (messages subcollection)
| الحقول | ترتيب |
|--------|-------|
| timestamp | Descending |

### كيفية الإنشاء:
1. اذهب إلى **Firestore Database** → **Indexes**
2. اضغط **Add Index**
3. اختر الـ Collection
4. أضف الحقول بالترتيب المطلوب
5. اضغط **Create Index**

**ملاحظة:** يمكنك أيضاً تشغيل التطبيق مرة واحدة، وعند ظهور خطأ index، سيعطيك Firebase رابطاً مباشراً لإنشاء الـ Index المطلوب.

---

## 4️⃣ بناء واختبار التطبيق

### قبل البناء:
```bash
# تنظيف البناء السابق
flutter clean

# الحصول على الحزم
flutter pub get

# تحليل الكود
flutter analyze
```

### بناء APK:
```bash
# بناء APK للتجربة
flutter build apk --debug

# أو بناء APK للإصدار
flutter build apk --release
```

### ملف APK سيكون في:
```
build/app/outputs/flutter-apk/app-debug.apk
# أو
build/app/outputs/flutter-apk/app-release.apk
```

---

## 5️⃣ اختبار الميزات الأساسية

### ✅ قائمة التحقق قبل الإرسال:

#### التسجيل والدخول:
- [ ] تسجيل حساب جديد (مريض)
- [ ] تسجيل حساب جديد (طبيب)
- [ ] تسجيل الدخول
- [ ] استعادة كلمة المرور

#### للمريض:
- [ ] مشاهدة السجلات الطبية
- [ ] رفع ملف طبي
- [ ] فتح دردشة مع الطبيب
- [ ] البحث عن الأطباء
- [ ] حجز موعد

#### للطبيب:
- [ ] مشاهدة Dashboard
- [ ] مشاهدة الملف الشخصي
- [ ] إدارة المواعيد
- [ ] فتح دردشة مع المريض
- [ ] مشاهدة إحصائيات

#### الدردشة:
- [ ] إرسال رسالة نصية
- [ ] إرسال ملف
- [ ] قراءة الرسائل

---

## 6️⃣ حل المشاكل الشائعة

### المشكلة 1: "Error loading records" (Permission Denied)
**الحل:** تأكد من نشر قواعد Firestore المذكورة في الخطوة 1

### المشكلة 2: "Failed to load profile"
**الحل:** 
1. تأكد من أن المستخدم لديه role = 'doctor' في collection users
2. تأكد من وجود مستند الطبيب في collection doctors
3. جرب تسجيل الخروج وإعادة الدخول

### المشكلة 3: "Failed to send message"
**الحل:** 
1. تأكد من أن chat document موجود
2. تأكد من أن المستخدم في قائمة participants

### المشكلة 4: "Failed to upload file"
**الحل:** تأكد من نشر قواعد Storage المذكورة في الخطوة 2

### المشكلة 5: "This query requires an index"
**الحل:** اتبع الرابط الموجود في رسالة الخطأ لإنشاء الـ Index المطلوب

---

## 7️⃣ إعدادات إضافية (اختياري)

### تفعيل Analytics:
1. في Firebase Console، اذهب إلى **Analytics**
2. فعّل Google Analytics

### تفعيل Crashlytics:
1. في Firebase Console، اذهب إلى **Crashlytics**
2. فعّل Crashlytics

---

## 📞 دعم فني

إذا واجهت مشاكل:
1. راجع سجلات الأخطاء في Firebase Console → **Functions** → **Logs**
2. افتح تطبيقك في وضع debug للحصول على تفاصيل أكثر

---

**بالتوفيق! 🎉**
