import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/pharmacy_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of user authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get currently signed-in Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  // Sign In with email and password
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw 'Authentication failed: User is null.';
      }

      // Fetch user profile from Firestore users collection
      final appUser = await getUserProfile(user.uid);
      if (appUser == null) {
        throw 'User record not found in database. Contact support.';
      }

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Register Customer (Patient)
  Future<AppUser> registerCustomer({
    required String email,
    required String password,
    required String displayName,
    required String phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) throw 'Failed to create user account.';

      // Update Firebase Auth display name
      await user.updateDisplayName(displayName);

      // Create AppUser object
      final appUser = AppUser(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        phoneNumber: phone.trim(),
        role: UserRole.customer,
        isVerified: true, // Customers do not require drug license verification
        createdAt: DateTime.now(),
      );

      // Save user to Firestore users collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(appUser.toFirestore());

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Register Pharmacy Owner
  Future<AppUser> registerPharmacy({
    required String email,
    required String password,
    required String pharmacyName,
    required String licenseNumber,
    required String pharmacistName,
    required String phone,
    required String address,
    required String city,
    required String pincode,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) throw 'Failed to create pharmacy account.';

      await user.updateDisplayName(pharmacyName);

      // Create user record in 'users' collection
      // IMPORTANT: isVerified is false by default until Admin verifies drug license in Phase 9!
      final appUser = AppUser(
        uid: user.uid,
        email: email.trim(),
        displayName: pharmacyName.trim(),
        phoneNumber: phone.trim(),
        role: UserRole.pharmacy,
        isVerified: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(appUser.toFirestore());

      // Create pharmacy profile record in 'pharmacies' collection
      final pharmacy = PharmacyModel(
        id: user.uid,
        ownerUid: user.uid,
        name: pharmacyName.trim(),
        licenseNumber: licenseNumber.trim(),
        pharmacistName: pharmacistName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        address: address.trim(),
        city: city.trim(),
        pincode: pincode.trim(),
        isVerified: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('pharmacies')
          .doc(user.uid)
          .set(pharmacy.toFirestore());

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Fetch user profile from Firestore
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e) {
      throw 'Error loading user profile: $e';
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Beginner-friendly Firebase Auth error mapper
  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No registered account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please verify and try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'The email format is invalid.';
      case 'user-disabled':
        return 'This user account has been deactivated by administrator.';
      case 'network-request-failed':
        return 'Network error: Check your internet connection.';
      default:
        return e.message ?? 'An unexpected authentication error occurred.';
    }
  }
}
