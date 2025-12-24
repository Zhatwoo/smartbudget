rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User Profile Data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Transactions
      match /transactions/{transactionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        
        allow create: if request.auth != null 
          && request.auth.uid == userId
          && request.resource.data.keys().hasAll(['title', 'category', 'amount', 'date', 'type'])
          && request.resource.data.type is string
          && (request.resource.data.type == 'expense' || request.resource.data.type == 'income')
          && request.resource.data.amount is number
          && request.resource.data.amount > 0;
        
        allow update: if request.auth != null 
          && request.auth.uid == userId
          && !request.resource.data.diff(request.resource.data).affectedKeys().hasAny(['userId']);
      }
      
      // Budgets
      match /budgets/{budgetId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        
        allow create: if request.auth != null 
          && request.auth.uid == userId
          && request.resource.data.keys().hasAll(['userId', 'category', 'limit', 'spent', 'startDate', 'endDate'])
          && request.resource.data.userId == userId
          && request.resource.data.limit is number
          && request.resource.data.limit > 0
          && request.resource.data.spent is number
          && request.resource.data.spent >= 0;
        
        allow update: if request.auth != null 
          && request.auth.uid == userId
          && request.resource.data.userId == userId;
      }
      
      // Inflation Items
      match /inflationItems/{itemId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        
        allow create: if request.auth != null 
          && request.auth.uid == userId
          && request.resource.data.keys().hasAll(['userId', 'name', 'unit', 'currentPrice', 'previousPrice', 'priceHistory', 'predictedPrices', 'colorValue', 'iconCodePoint'])
          && request.resource.data.userId == userId
          && request.resource.data.currentPrice is number
          && request.resource.data.currentPrice > 0
          && request.resource.data.previousPrice is number
          && request.resource.data.previousPrice > 0;
        
        allow update: if request.auth != null 
          && request.auth.uid == userId
          && request.resource.data.userId == userId;
      }
      
      // Notifications
      match /notifications/{notificationId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        
        allow create: if request.auth != null 
          && request.auth.uid == userId
          && request.resource.data.keys().hasAll(['type', 'title', 'message', 'timestamp'])
          && request.resource.data.type is string
          && request.resource.data.title is string
          && request.resource.data.message is string
          && request.resource.data.timestamp is string;
        
        allow update: if request.auth != null 
          && request.auth.uid == userId
          && request.resource.data.diff(request.resource.data).affectedKeys().hasOnly(['isRead']);
      }
      
      // Bills (User-input bills)
      match /bills/{billId} {
        allow read: if request.auth != null && request.auth.uid == userId;
        allow create: if request.auth != null
          && request.auth.uid == userId
          && request.resource.data.keys().hasAll(['title', 'amount', 'dueDate', 'iconCodePoint', 'category', 'createdAt', 'updatedAt'])
          && request.resource.data.title is string
          && request.resource.data.amount is number
          && request.resource.data.amount > 0
          && request.resource.data.dueDate is timestamp
          && request.resource.data.category is string;
        allow update: if request.auth != null
          && request.auth.uid == userId;
        allow delete: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
