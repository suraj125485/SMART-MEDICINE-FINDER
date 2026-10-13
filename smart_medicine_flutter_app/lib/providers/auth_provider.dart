import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  UserRole? get role => _currentUser?.role;

  // Initialize listener on app launch
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _authService.currentFirebaseUser;
      if (firebaseUser != null) {
        _currentUser = await _authService.getUserProfile(firebaseUser.uid);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign In
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register Customer
  Future<bool> registerCustomer({
    required String email,
    required String password,
    required String displayName,
    required String phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.registerCustomer(
        email: email,
        password: password,
        displayName: displayName,
        phone: phone,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register Pharmacy
  Future<bool> registerPharmacy({
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
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.registerPharmacy(
        email: email,
        password: password,
        pharmacyName: pharmacyName,
        licenseNumber: licenseNumber,
        pharmacistName: pharmacistName,
        phone: phone,
        address: address,
        city: city,
        pincode: pincode,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send Password Reset
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
