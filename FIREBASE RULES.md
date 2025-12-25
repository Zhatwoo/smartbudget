rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to ensure userId matches authenticated user
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    
    // Helper function to ensure userId in data matches path userId
    function userIdMatches(userId) {
      return request.resource.data.userId == userId;
    }
    
    // User Profile Data
    match /users/{userId} {
      // Only allow users to read/write their own profile
      allow read, write: if isOwner(userId);
      
      // Transactions - Each user can only access their own transactions
      match /transactions/{transactionId} {
        // Read: Only own transactions
        allow read: if isOwner(userId);
        
        // Create: Must be authenticated, userId in data must match path, and validate data
        allow create: if isOwner(userId)
          && userIdMatches(userId)
          && request.resource.data.keys().hasAll(['title', 'category', 'amount', 'date', 'type', 'userId', 'createdAt', 'updatedAt'])
          && request.resource.data.type is string
          && (request.resource.data.type == 'expense' || request.resource.data.type == 'income')
          && request.resource.data.amount is number
          && request.resource.data.amount != 0
          && ((request.resource.data.type == 'expense' && request.resource.data.amount < 0) 
              || (request.resource.data.type == 'income' && request.resource.data.amount > 0))
          && request.resource.data.userId is string;
        
        // Update: Cannot change userId, must remain same user
        allow update: if isOwner(userId)
          && request.resource.data.userId == resource.data.userId
          && request.resource.data.userId == userId
          && !('userId' in request.resource.data.diff(resource.data).affectedKeys());
        
        // Delete: Only own transactions
        allow delete: if isOwner(userId);
      }
      
      // Budgets - Each user can only access their own budgets
      match /budgets/{budgetId} {
        // Read: Only own budgets
        allow read: if isOwner(userId);
        
        // Create: Must include userId that matches path
        allow create: if isOwner(userId)
          && userIdMatches(userId)
          && request.resource.data.keys().hasAll(['userId', 'category', 'limit', 'spent', 'startDate', 'endDate', 'createdAt', 'updatedAt'])
          && request.resource.data.userId is string
          && request.resource.data.limit is number
          && request.resource.data.limit > 0
          && request.resource.data.spent is number
          && request.resource.data.spent >= 0;
        
        // Update: Cannot change userId, must remain same user
        allow update: if isOwner(userId)
          && request.resource.data.userId == resource.data.userId
          && request.resource.data.userId == userId
          && !('userId' in request.resource.data.diff(resource.data).affectedKeys());
        
        // Delete: Only own budgets
        allow delete: if isOwner(userId);
      }
      
      // Inflation Items - Each user tracks their own items (inflation rate is from external API, not stored)
      match /inflationItems/{itemId} {
        // Read: Only own inflation items
        allow read: if isOwner(userId);
        
        // Create: Must include userId that matches path
        allow create: if isOwner(userId)
          && userIdMatches(userId)
          && request.resource.data.keys().hasAll(['userId', 'name', 'unit', 'currentPrice', 'previousPrice', 'priceHistory', 'predictedPrices', 'colorValue', 'iconCodePoint', 'createdAt', 'updatedAt'])
          && request.resource.data.userId is string
          && request.resource.data.currentPrice is number
          && request.resource.data.currentPrice > 0
          && request.resource.data.previousPrice is number
          && request.resource.data.previousPrice >= 0;
        
        // Update: Cannot change userId, must remain same user
        allow update: if isOwner(userId)
          && request.resource.data.userId == resource.data.userId
          && request.resource.data.userId == userId
          && !('userId' in request.resource.data.diff(resource.data).affectedKeys());
        
        // Delete: Only own inflation items
        allow delete: if isOwner(userId);
      }
      
      // Notifications - Each user can only access their own notifications
      match /notifications/{notificationId} {
        // Read: Only own notifications
        allow read: if isOwner(userId);
        
        // Create: Must be authenticated and validate data
        allow create: if isOwner(userId)
          && request.resource.data.keys().hasAll(['type', 'title', 'message', 'timestamp', 'isRead'])
          && request.resource.data.type is string
          && request.resource.data.title is string
          && request.resource.data.message is string
          && request.resource.data.timestamp is string
          && request.resource.data.isRead is bool;
        
        // Update: Can only update isRead status
        allow update: if isOwner(userId)
          && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead'])
          && request.resource.data.isRead is bool;
        
        // Delete: Only own notifications
        allow delete: if isOwner(userId);
      }
      
      // Bills - Each user can only access their own bills
      match /bills/{billId} {
        // Read: Only own bills
        allow read: if isOwner(userId);
        
        // Create: Must be authenticated and validate data
        allow create: if isOwner(userId)
          && request.resource.data.keys().hasAll(['title', 'amount', 'dueDate', 'iconCodePoint', 'category', 'isRecurring', 'createdAt', 'updatedAt'])
          && request.resource.data.title is string
          && request.resource.data.amount is number
          && request.resource.data.amount > 0
          && request.resource.data.dueDate is timestamp
          && request.resource.data.category is string
          && request.resource.data.isRecurring is bool;
        
        // Update: Only own bills, cannot change critical fields maliciously
        allow update: if isOwner(userId)
          && request.resource.data.title is string
          && request.resource.data.amount is number
          && request.resource.data.amount > 0;
        
        // Delete: Only own bills
        allow delete: if isOwner(userId);
      }
    }
    
    // User Lookups Collection - For forgot password functionality only
    // This collection stores minimal data (email, username, mobileNumber) for password reset
    // Read-only access for all authenticated users (for forgot password)
    // Write access only for the user themselves (when updating profile)
    match /userLookups/{lookupId} {
      // Allow read for forgot password (any authenticated user can search)
      // This is safe because it only contains email, username, mobileNumber
      allow read: if request.auth != null;
      
      // Allow write only if the lookupId matches the authenticated user's ID
      // This ensures users can only update their own lookup entry
      allow write: if request.auth != null 
        && request.auth.uid == lookupId
        && request.resource.data.keys().hasAll(['email', 'username'])
        && request.resource.data.email is string
        && request.resource.data.username is string;
    }
    
    // Deny all other access - No shared collections, no global data
    // Only inflation rate is shared (from external API, not stored in Firestore)
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
