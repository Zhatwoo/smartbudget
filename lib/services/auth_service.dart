import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Use web client ID from google-services.json (client_type: 3)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        throw Exception('Sign in was canceled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Handle PlatformException specifically
      final errorMessage = e.toString();
      if (errorMessage.contains('ApiException') || 
          errorMessage.contains('sign_in_failed') ||
          errorMessage.contains('DEVELOPER_ERROR') ||
          errorMessage.contains('PlatformException')) {
        throw Exception(
          'Google Sign-In is not properly configured.\n\n'
          'Please follow these steps:\n'
          '1. Get your SHA-1 fingerprint (see GOOGLE_SIGNIN_FIX.md)\n'
          '2. Add SHA-1 to Firebase Console > Project Settings > Android app\n'
          '3. Enable Google Sign-In in Firebase Console > Authentication\n'
          '4. Download FRESH google-services.json from Firebase Console\n'
          '5. Replace android/app/google-services.json with the new file\n'
          '6. Run: flutter clean && flutter pub get && flutter run\n\n'
          'See GOOGLE_SIGNIN_FIX.md for detailed instructions.'
        );
      }
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Reset password by email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reset password by finding user email from username, mobile, or email
  // This method should be called with FirebaseService instance
  Future<void> resetPasswordByIdentifier({
    required dynamic firebaseService, // FirebaseService instance
    String? username,
    String? mobileNumber,
    String? email,
  }) async {
    try {
      // Find the user's email using FirebaseService
      final userEmail = await firebaseService.findUserEmail(
        username: username,
        mobileNumber: mobileNumber,
        email: email,
      );

      if (userEmail == null) {
        throw Exception('No account found with the provided information. Please check your username, mobile number, or email and try again.');
      }

      // Send password reset email
      await _auth.sendPasswordResetEmail(email: userEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Re-throw other exceptions as-is
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}

