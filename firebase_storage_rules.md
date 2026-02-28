# Firebase Storage Security Rules

## التعليمات:
1. اذهب إلى: https://console.firebase.google.com/
2. اختر مشروعك
3. اذهب إلى: Storage → Rules
4. انسخ القواعد التالية واضغط "Publish"

## قواعد التخزين:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isDoctor() {
      return request.auth.token.role == 'doctor';
    }
    
    function isPatient() {
      return request.auth.token.role == 'patient';
    }
    
    function isAdmin() {
      return request.auth.token.role == 'admin';
    }
    
    // Chat attachments (images, files in chat)
    match /chats/{chatId}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() 
        && request.resource.size < 50 * 1024 * 1024 // 50MB max
        && (
          request.resource.contentType.matches('image/.*') ||
          request.resource.contentType.matches('application/pdf') ||
          request.resource.contentType.matches('text/.*') ||
          request.resource.contentType.matches('application/msword') ||
          request.resource.contentType.matches('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
        );
    }
    
    // Profile pictures
    match /profile_pictures/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() 
        && isOwner(userId)
        && request.resource.size < 5 * 1024 * 1024 // 5MB max
        && request.resource.contentType.matches('image/.*');
    }
    
    // Medical records (patient uploads)
    match /medical_records/{patientId}/{fileName} {
      allow read: if isAuthenticated() 
        && (isOwner(patientId) || isDoctor() || isAdmin());
      allow write: if isAuthenticated() 
        && isOwner(patientId)
        && request.resource.size < 100 * 1024 * 1024 // 100MB max
        && (
          request.resource.contentType.matches('image/.*') ||
          request.resource.contentType.matches('application/pdf') ||
          request.resource.contentType.matches('application/dicom') ||
          request.resource.contentType.matches('text/.*')
        );
    }
    
    // Radiology images
    match /radiology/{patientId}/{fileName} {
      allow read: if isAuthenticated() 
        && (isOwner(patientId) || isDoctor() || isAdmin());
      allow write: if isAuthenticated() 
        && (isOwner(patientId) || isDoctor())
        && request.resource.size < 50 * 1024 * 1024 // 50MB max
        && (
          request.resource.contentType.matches('image/.*') ||
          request.resource.contentType.matches('application/dicom') ||
          request.resource.contentType.matches('application/octet-stream')
        );
    }
    
    // General uploads folder (temporary)
    match /uploads/{userId}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() 
        && isOwner(userId)
        && request.resource.size < 50 * 1024 * 1024; // 50MB max
    }
    
    // Default deny all other paths
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

## ملاحظات:
- أقصى حجم للصور: 5 ميجابايت
- أقصى حجم للملفات الطبية: 100 ميجابايت
- أقصى حجم لملفات الدردشة: 50 ميجابايت
- الصور المسموحة: JPG, PNG, GIF, WebP
- الملفات المسموحة: PDF, DOC, DOCX, TXT, DICOM
