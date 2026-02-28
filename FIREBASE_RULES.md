# Firebase Security Rules - PRODUCTION READY

## How to Apply These Rules

1. Go to https://console.firebase.google.com/
2. Select your project
3. Go to Firestore Database → Rules tab
4. Copy the Firestore rules below and click "Publish"
5. Go to Storage → Rules tab
6. Copy the Storage rules below and click "Publish"

---

## Firestore Rules (Copy to Firestore Database → Rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ==================== HELPER FUNCTIONS ====================
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }
    
    function isDoctor() {
      return isAuthenticated() && getUserRole() == 'doctor';
    }
    
    function isPatient() {
      return isAuthenticated() && getUserRole() == 'patient';
    }
    
    function isAdmin() {
      return isAuthenticated() && getUserRole() == 'admin';
    }
    
    function isDoctorOrAdmin() {
      return isDoctor() || isAdmin();
    }

    // ==================== USERS COLLECTION ====================
    
    match /users/{userId} {
      // Allow read if authenticated - users can read their own data, doctors can read patient data
      allow read: if isAuthenticated();
      
      // Allow create during sign up
      allow create: if isAuthenticated() 
        && isOwner(userId)
        && request.resource.data.keys().hasAll(['name', 'email', 'role'])
        && request.resource.data.role in ['patient', 'doctor', 'admin'];
      
      // Allow update if owner or admin
      allow update: if isAuthenticated()
        && (isOwner(userId) || isAdmin())
        && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['role']) || isAdmin());
      
      // Allow delete only by admin
      allow delete: if isAdmin();
      
      // Subcollection: user's medical records
      match /records/{recordId} {
        allow read: if isAuthenticated() 
          && (isOwner(userId) || isDoctorOrAdmin());
        allow write: if isAuthenticated() 
          && (isOwner(userId) || isDoctorOrAdmin());
      }
    }

    // ==================== DOCTORS COLLECTION ====================
    
    match /doctors/{doctorId} {
      // Anyone authenticated can read doctor profiles
      allow read: if isAuthenticated();
      
      // Allow create during doctor registration
      allow create: if isAuthenticated() 
        && (isOwner(doctorId) || isAdmin())
        && request.resource.data.keys().hasAll(['userId', 'name', 'specialty']);
      
      // Allow update by the doctor themselves or admin
      allow update: if isAuthenticated()
        && (isOwner(doctorId) || isAdmin());
      
      // Allow delete only by admin
      allow delete: if isAdmin();
      
      // Subcollection: doctor's schedule
      match /schedule/{date} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated()
          && (isOwner(doctorId) || isAdmin());
      }
    }

    // ==================== APPOINTMENTS COLLECTION ====================
    
    match /appointments/{appointmentId} {
      allow read: if isAuthenticated()
        && (
          resource.data.patientId == request.auth.uid ||
          resource.data.doctorId == request.auth.uid ||
          isAdmin()
        );
      
      allow create: if isAuthenticated()
        && request.resource.data.patientId == request.auth.uid;
      
      allow update: if isAuthenticated()
        && (
          resource.data.patientId == request.auth.uid ||
          resource.data.doctorId == request.auth.uid ||
          isAdmin()
        );
      
      allow delete: if isAuthenticated()
        && (
          resource.data.patientId == request.auth.uid ||
          isAdmin()
        );
    }

    // ==================== CHATS COLLECTION ====================
    
    match /chats/{chatId} {
      allow read: if isAuthenticated()
        && (
          resource.data.participants.hasAny([request.auth.uid]) ||
          isAdmin()
        );
      
      allow create: if isAuthenticated()
        && request.resource.data.participants.hasAny([request.auth.uid]);
      
      allow update: if isAuthenticated()
        && (
          resource.data.participants.hasAny([request.auth.uid]) ||
          isAdmin()
        );
      
      // Subcollection: messages
      match /messages/{messageId} {
        allow read: if isAuthenticated()
          && get(/databases/$(database)/documents/chats/$(chatId)).data.participants.hasAny([request.auth.uid]);
        
        allow create: if isAuthenticated()
          && get(/databases/$(database)/documents/chats/$(chatId)).data.participants.hasAny([request.auth.uid])
          && request.resource.data.senderId == request.auth.uid;
        
        allow update, delete: if isAdmin();
      }
    }

    // ==================== PATIENT_DOCTORS COLLECTION ====================
    
    match /patient_doctors/{connectionId} {
      allow read: if isAuthenticated()
        && (
          resource.data.patientId == request.auth.uid ||
          resource.data.doctorId == request.auth.uid ||
          isAdmin()
        );
      
      allow create: if isAuthenticated()
        && request.resource.data.patientId == request.auth.uid;
      
      allow update: if isAuthenticated()
        && (
          resource.data.patientId == request.auth.uid ||
          resource.data.doctorId == request.auth.uid ||
          isAdmin()
        );
      
      allow delete: if isAuthenticated()
        && (
          resource.data.patientId == request.auth.uid ||
          isAdmin()
        );
    }

    // ==================== NOTIFICATIONS COLLECTION ====================
    
    match /notifications/{notificationId} {
      allow read: if isAuthenticated()
        && resource.data.userId == request.auth.uid;
      
      allow create: if isAuthenticated()
        && (isDoctorOrAdmin() || request.resource.data.userId == request.auth.uid);
      
      allow update: if isAuthenticated()
        && resource.data.userId == request.auth.uid;
      
      allow delete: if isAuthenticated()
        && resource.data.userId == request.auth.uid;
    }

    // ==================== RECORDS COLLECTION (Alternative structure) ====================
    
    match /records/{recordId} {
      allow read: if isAuthenticated()
        && (
          resource.data.patientEmail == request.auth.token.email ||
          resource.data.doctorId == request.auth.uid ||
          isAdmin()
        );
      
      allow create: if isAuthenticated()
        && (isDoctor() || isAdmin());
      
      allow update, delete: if isAuthenticated()
        && (
          resource.data.doctorId == request.auth.uid ||
          isAdmin()
        );
    }

    // ==================== SETTINGS COLLECTION ====================
    
    match /settings/{document} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }

    // ==================== DEFAULT DENY ====================
    
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## Storage Rules (Copy to Storage → Rules)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // ==================== HELPER FUNCTIONS ====================
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // ==================== MEDICAL RECORDS ====================
    
    match /medical_records/{userId}/{fileName} {
      allow read: if isAuthenticated() 
        && (isOwner(userId) || request.auth.token.role == 'doctor' || request.auth.token.role == 'admin');
      
      allow write: if isAuthenticated() 
        && isOwner(userId)
        && request.resource.size < 100 * 1024 * 1024 // 100MB max
        && (
          request.resource.contentType.matches('image/.*') ||
          request.resource.contentType.matches('application/pdf') ||
          request.resource.contentType.matches('application/dicom') ||
          request.resource.contentType.matches('text/.*')
        );
    }

    // ==================== PROFILE PICTURES ====================
    
    match /profile_pictures/{userId} {
      allow read: if isAuthenticated();
      
      allow write: if isAuthenticated() 
        && isOwner(userId)
        && request.resource.size < 5 * 1024 * 1024 // 5MB max
        && request.resource.contentType.matches('image/.*');
    }

    // ==================== CHAT ATTACHMENTS ====================
    
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

    // ==================== RECORDS UPLOADS ====================
    
    match /records/{userId}/{recordId}/{fileName} {
      allow read: if isAuthenticated()
        && (isOwner(userId) || request.auth.token.role == 'doctor' || request.auth.token.role == 'admin');
      
      allow write: if isAuthenticated()
        && isOwner(userId)
        && request.resource.size < 100 * 1024 * 1024; // 100MB max
    }

    // ==================== TEMP UPLOADS ====================
    
    match /uploads/{userId}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() 
        && isOwner(userId)
        && request.resource.size < 50 * 1024 * 1024; // 50MB max
    }

    // ==================== RADIOLOGY IMAGES ====================
    
    match /radiology/{patientId}/{fileName} {
      allow read: if isAuthenticated() 
        && (isOwner(patientId) || request.auth.token.role == 'doctor' || request.auth.token.role == 'admin');
      
      allow write: if isAuthenticated() 
        && (isOwner(patientId) || request.auth.token.role == 'doctor')
        && request.resource.size < 50 * 1024 * 1024 // 50MB max
        && (
          request.resource.contentType.matches('image/.*') ||
          request.resource.contentType.matches('application/dicom') ||
          request.resource.contentType.matches('application/octet-stream')
        );
    }

    // ==================== DEFAULT DENY ====================
    
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## Indexes Required

Create these indexes in Firestore Database → Indexes:

### Collection: appointments
| Fields | Query Scope |
|--------|-------------|
| doctorId (Ascending) | Collection |
| doctorId (Ascending), createdAt (Descending) | Collection |
| doctorId (Ascending), date (Ascending) | Collection |
| doctorId (Ascending), date (Ascending), timeSlot (Ascending) | Collection |
| patientId (Ascending), createdAt (Descending) | Collection |

### Collection: records
| Fields | Query Scope |
|--------|-------------|
| patientEmail (Ascending), createdAt (Descending) | Collection |

### Collection: doctors
| Fields | Query Scope |
|--------|-------------|
| isActive (Ascending), specialty (Ascending) | Collection |

---

## Testing Your Rules

After deploying the rules, test them with these operations:

1. **Sign up as a new user** - Should create user document
2. **Update your profile** - Should update user document
3. **Upload a medical record** - Should upload file to storage
4. **View doctor list** - Should read doctor documents
5. **Book an appointment** - Should create appointment document
6. **View appointments** - Should read appointment documents

If any operation fails with "permission-denied", check the browser console for the exact error.
