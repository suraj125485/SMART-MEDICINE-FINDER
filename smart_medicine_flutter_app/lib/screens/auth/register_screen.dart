import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_role.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _customerFormKey = GlobalKey<FormState>();
  final _pharmacyFormKey = GlobalKey<FormState>();

  UserRole _activeTab = UserRole.customer;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  // Customer Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Pharmacy Controllers
  final _pharmacyNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _pharmacistNameController = TextEditingController();
  final _pharmacyEmailController = TextEditingController();
  final _pharmacyPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _pharmacyPasswordController = TextEditingController();
  final _pharmacyConfirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _pharmacyNameController.dispose();
    _licenseNumberController.dispose();
    _pharmacistNameController.dispose();
    _pharmacyEmailController.dispose();
    _pharmacyPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _pharmacyPasswordController.dispose();
    _pharmacyConfirmPasswordController.dispose();
    super.dispose();
  }

  void _handleCustomerRegister() async {
    if (!_customerFormKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showError('Please accept the Terms of Service & Privacy Policy.');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isLoading = false);

    _showSuccess(
      'Customer account created for ${_nameController.text}. Ready for Phase 3 Firestore persistence!',
    );
  }

  void _handlePharmacyRegister() async {
    if (!_pharmacyFormKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showError('Please accept the Medical Verification Terms.');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _isLoading = false);

    _showSuccess(
      'Registration submitted for ${_pharmacyNameController.text} (License: ${_licenseNumberController.text}). Under verification review.',
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.outOfStock,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.inStock,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Role Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = UserRole.customer),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == UserRole.customer
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Customer / Patient',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _activeTab == UserRole.customer
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = UserRole.pharmacy),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == UserRole.pharmacy
                                ? AppColors.secondary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Pharmacy Store',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _activeTab == UserRole.pharmacy
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form render
              if (_activeTab == UserRole.customer)
                _buildCustomerForm()
              else
                _buildPharmacyForm(),

              const SizedBox(height: 16),

              // Terms & Conditions Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      activeColor: _activeTab == UserRole.customer
                          ? AppColors.primary
                          : AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _agreedToTerms = val ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _activeTab == UserRole.customer
                          ? 'I agree to the Terms of Service, Privacy Policy, and Medical Availability Disclaimer.'
                          : 'I confirm this pharmacy is officially licensed and acknowledge that false inventory reporting will result in account revocation.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              CustomButton(
                label: _activeTab == UserRole.customer
                    ? 'Register as Customer'
                    : 'Submit Pharmacy Registration',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isLoading,
                onPressed: _activeTab == UserRole.customer
                    ? _handleCustomerRegister
                    : _handlePharmacyRegister,
              ),
              const SizedBox(height: 20),

              // Already have account?
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already registered? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In Here',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerForm() {
    return Form(
      key: _customerFormKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Full Name',
            hintText: 'e.g. John Doe',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            hintText: 'john@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email address';
              if (!RegExp(r'^[w-.]+@([w-]+.)+[w-]{2,4}$').hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hintText: '+1 234 567 8900',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().length < 8) ? 'Enter a valid phone number' : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Minimum 6 characters',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: (v) => (v == null || v.length < 6) ? 'Must be at least 6 characters' : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hintText: 'Re-enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm your password';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyForm() {
    return Form(
      key: _pharmacyFormKey,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.bottom(14),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.verified_user_rounded, color: AppColors.secondary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pharmacy accounts are verified by an administrator before listings become publicly visible.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004D40),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CustomTextField(
            controller: _pharmacyNameController,
            label: 'Pharmacy Store Name',
            hintText: 'e.g. CarePlus Community Chemist',
            prefixIcon: Icons.local_pharmacy_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter pharmacy legal name' : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _licenseNumberController,
            label: 'Drug License Number',
            hintText: 'e.g. DL-2024-8849-PH',
            prefixIcon: Icons.badge_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter valid drug license number' : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _pharmacistNameController,
            label: 'Supervising Pharmacist / Owner Name',
            hintText: 'e.g. Dr. Sarah Jenkins, PharmD',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter pharmacist name' : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _pharmacyEmailController,
            label: 'Official Store Email',
            hintText: 'store@careplus.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid store email' : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _pharmacyPhoneController,
            label: 'Pharmacy Contact Phone',
            hintText: '+1 555 987 6543',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.length < 8) ? 'Enter contact phone' : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _addressController,
            label: 'Physical Store Street Address',
            hintText: '104 Healthcare Boulevard, Suite 10',
            prefixIcon: Icons.location_on_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter pharmacy street address' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _cityController,
                  label: 'City',
                  hintText: 'Metropolis',
                  prefixIcon: Icons.location_city_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter city' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _pincodeController,
                  label: 'Pincode / ZIP',
                  hintText: '10001',
                  prefixIcon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter pincode' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _pharmacyPasswordController,
            label: 'Password',
            hintText: 'Minimum 6 characters',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: (v) => (v == null || v.length < 6) ? 'Must be at least 6 characters' : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _pharmacyConfirmPasswordController,
            label: 'Confirm Password',
            hintText: 'Re-enter store password',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm password';
              if (v != _pharmacyPasswordController.text) return 'Passwords do not match';
              return null;
            },
          ),
        ],
      ),
    );
  }
}
