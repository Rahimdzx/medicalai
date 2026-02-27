# Firebase Security Rules

## Firestore Rules - انسخ هذا الكود إلى Firebase Console

### قواعد Firestore:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user is the owner
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isOwner(userId);
      allow update: if isAuthenticated() && isOwner(userId);
      allow delete: if false;
    }
    
    // Doctors collection
    match /doctors/{doctorId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && 
        (resource == null || request.auth.uid == doctorId || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      
      // Doctor schedule subcollection
      match /schedule/{date} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated() && 
          (request.auth.uid == doctorId || 
           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      }
    }
    
    // Appointments collection
    match /appointments/{appointmentId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && 
        (resource.data.patientId == request.auth.uid || 
         resource.data.doctorId == request.auth.uid ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow delete: if false;
    }
    
    // Chats collection
    match /chats/{chatId} {
      allow read: if isAuthenticated() && 
        (resource.data.patientId == request.auth.uid || 
         resource.data.doctorId == request.auth.uid);
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && 
        (resource.data.patientId == request.auth.uid || 
         resource.data.doctorId == request.auth.uid);
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated();
      }
    }
    
    // Medical records collection
    match /medical_records/{recordId} {
      allow read: if isAuthenticated() && 
        (resource.data.patientId == request.auth.uid || 
         resource.data.doctorId == request.auth.uid ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow write: if isAuthenticated() && 
        (resource.data.doctorId == request.auth.uid ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Patient-doctors connections
    match /patient_doctors/{connectionId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Calls collection
    match /calls/{callId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
  }
}
```

## كيفية التطبيق:

1. اذهب إلى: https://console.firebase.google.com/
2. اختر مشروعك
3. اذهب إلى: Firestore Database → Rules
4. انسخ القواعد أعلاه
5. اضغط "Publish"

## ملاحظة أمنية:
هذه القواعد تسمح للمستخدمين المسجلين بـ:
- قراءة البيانات العامة
- إنشاء مواعيد جديدة
- تحديث بياناتهم الخاصة
- الدردشة مع أطبائهم

للإنتاج، يمكنك تقييد الصلاحيات أكثر حسب احتياجاتك.
