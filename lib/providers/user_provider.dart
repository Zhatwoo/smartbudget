import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';

/// User Profile Provider
/// Streams user profile data from Firestore
final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final userId = ref.watch(currentUserProvider);
  if (userId == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId.uid)
      .snapshots()
      .map((snapshot) => snapshot.data());
});

/// User Display Name Provider
final userDisplayNameProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.value?['displayName'] as String?;
});

/// User Email Provider
final userEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email;
});

/// User Username Provider
final userUsernameProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.value?['username'] as String?;
});

/// User Mobile Number Provider
final userMobileNumberProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.value?['mobileNumber'] as String?;
});

/// User Photo URL Provider
final userPhotoUrlProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.value?['photoUrl'] as String?;
});

/// Onboarding Completed Provider
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.hasCompletedOnboarding();
});

