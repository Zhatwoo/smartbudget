import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../services/auth_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Gmail Registration
  final _gmailNameController = TextEditingController();
  final _gmailEmailController = TextEditingController();
  final _gmailUsernameController = TextEditingController();
  bool _gmailDataLoaded = false;
  
  // Email/Username Registration
  final _emailFormKey = GlobalKey<FormState>();
  final _emailNameController = TextEditingController();
  final _emailEmailController = TextEditingController();
  final _emailUsernameController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  final _emailConfirmPasswordController = TextEditingController();
  bool _emailObscurePassword = true;
  bool _emailObscureConfirmPassword = true;
  
  // Mobile Registration
  final _mobileFormKey = GlobalKey<FormState>();
  final _mobileNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _mobileUsernameController = TextEditingController();
  final _mobilePasswordController = TextEditingController();
  final _mobileConfirmPasswordController = TextEditingController();
  bool _mobileObscurePassword = true;
  bool _mobileObscureConfirmPassword = true;
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gmailNameController.dispose();
    _gmailEmailController.dispose();
    _gmailUsernameController.dispose();
    _emailNameController.dispose();
    _emailEmailController.dispose();
    _emailUsernameController.dispose();
    _emailPasswordController.dispose();
    _emailConfirmPasswordController.dispose();
    _mobileNameController.dispose();
    _mobileNumberController.dispose();
    _mobileUsernameController.dispose();
    _mobilePasswordController.dispose();
    _mobileConfirmPasswordController.dispose();
    super.dispose();
  }

  // Gmail Registration
  Future<void> _handleGmailRegistration() async {
    if (!_gmailDataLoaded) {
      // First step: Sign in with Google
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = ref.read(authServiceProvider);
        final credential = await authService.signInWithGoogle();
        
        if (credential.user != null) {
          // Auto-fill data from Google account
          setState(() {
            _gmailNameController.text = credential.user!.displayName ?? '';
            _gmailEmailController.text = credential.user!.email ?? '';
            _gmailUsernameController.text = credential.user!.email ?? ''; // Default username to email
            _gmailDataLoaded = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        _showErrorSnackbar(_errorMessage ?? 'Gmail registration failed');
      }
    } else {
      // Second step: Save profile with edited data
      if (_gmailNameController.text.trim().isEmpty) {
        _showErrorSnackbar('Please enter your name');
        return;
      }
      
      if (_gmailUsernameController.text.trim().isEmpty) {
        _showErrorSnackbar('Please enter a username');
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final firebaseService = ref.read(firebaseServiceProvider);
        final authService = ref.read(authServiceProvider);
        final user = authService.currentUser;
        
        if (user != null) {
          await firebaseService.initializeUserProfile(
            email: _gmailEmailController.text.trim(),
            displayName: _gmailNameController.text.trim(),
            photoUrl: user.photoURL,
            username: _gmailUsernameController.text.trim(),
            authMethod: 'gmail',
          );
          
          if (!mounted) return;
          
          // Initialize notification service after successful registration
          try {
            final notificationService = ref.read(notificationServiceProvider);
            await notificationService.initialize();
          } catch (e) {
            // Silently fail - notification initialization errors shouldn't block navigation
          }
          
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        _showErrorSnackbar(_errorMessage ?? 'Failed to create profile');
      }
    }
  }

  // Email/Username Registration
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  Future<void> _handleEmailRegistration() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final firebaseService = ref.read(firebaseServiceProvider);
      
      final credential = await authService.registerWithEmailAndPassword(
        email: _emailEmailController.text.trim(),
        password: _emailPasswordController.text,
        displayName: _emailNameController.text.trim(),
      );
      
      if (credential.user != null) {
        await firebaseService.initializeUserProfile(
          email: _emailEmailController.text.trim(),
          displayName: _emailNameController.text.trim(),
          username: _emailUsernameController.text.trim(),
          authMethod: 'email',
        );
        
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      _showErrorSnackbar(_errorMessage ?? 'Registration failed');
    }
  }

  // Mobile Registration
  String? _validateMobileNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }
    // Basic validation - should start with + and have digits
    final mobileRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!mobileRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Please enter a valid mobile number';
    }
    return null;
  }

  Future<void> _handleMobileRegistration() async {
    if (!_mobileFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // For mobile registration, we'll use email/password auth with a generated email
      // In production, you might want to use phone authentication
      final authService = ref.read(authServiceProvider);
      final firebaseService = ref.read(firebaseServiceProvider);
      
      // Generate a temporary email from mobile number for Firebase Auth
      final tempEmail = '${_mobileNumberController.text.replaceAll(RegExp(r'[^\d]'), '')}@mobile.smartbudget.app';
      
      final credential = await authService.registerWithEmailAndPassword(
        email: tempEmail,
        password: _mobilePasswordController.text,
        displayName: _mobileNameController.text.trim(),
      );
      
      if (credential.user != null) {
        await firebaseService.initializeUserProfile(
          email: tempEmail,
          displayName: _mobileNameController.text.trim(),
          username: _mobileUsernameController.text.trim(),
          mobileNumber: _mobileNumberController.text.trim(),
          authMethod: 'mobile',
        );
        
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      _showErrorSnackbar(_errorMessage ?? 'Registration failed');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Gmail'),
            Tab(text: 'Email'),
            Tab(text: 'Mobile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGmailRegistrationTab(),
          _buildEmailRegistrationTab(),
          _buildMobileRegistrationTab(),
        ],
      ),
    );
  }

  Widget _buildGmailRegistrationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          
          // App Logo
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 50,
                color: Color(0xFF4A90E2),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            'Sign up with Gmail',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            _gmailDataLoaded
                ? 'Review and edit your information'
                : 'Connect your Google account',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          if (_gmailDataLoaded) ...[
            // Name Field
            TextField(
              controller: _gmailNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outlined, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            const SizedBox(height: 20),

            // Email Field (read-only)
            TextField(
              controller: _gmailEmailController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 20),

            // Username Field
            TextField(
              controller: _gmailUsernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Choose a username',
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Error Message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE74C3C).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFE74C3C),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFE74C3C),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Submit Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleGmailRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _gmailDataLoaded ? 'Create Account' : 'Continue with Google',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Back to Login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 15,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Color(0xFF4A90E2),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailRegistrationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // App Logo
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 50,
                  color: Color(0xFF4A90E2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'Sign up with Email',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Name Field
            TextFormField(
              controller: _emailNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outlined, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Email Field
            TextFormField(
              controller: _emailEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 20),

            // Username Field
            TextFormField(
              controller: _emailUsernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: _validateUsername,
            ),
            const SizedBox(height: 20),

            // Password Field
            TextFormField(
              controller: _emailPasswordController,
              obscureText: _emailObscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined, size: 22),
                suffixIcon: IconButton(
                  icon: Icon(
                    _emailObscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _emailObscurePassword = !_emailObscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 20),

            // Confirm Password Field
            TextFormField(
              controller: _emailConfirmPasswordController,
              obscureText: _emailObscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outlined, size: 22),
                suffixIcon: IconButton(
                  icon: Icon(
                    _emailObscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _emailObscureConfirmPassword = !_emailObscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) => _validateConfirmPassword(
                value,
                _emailPasswordController.text,
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleEmailRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Back to Login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: Color(0xFF4A90E2),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileRegistrationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _mobileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // App Logo
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 50,
                  color: Color(0xFF4A90E2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'Sign up with Mobile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Name Field
            TextFormField(
              controller: _mobileNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outlined, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Mobile Number Field
            TextFormField(
              controller: _mobileNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Number',
                hintText: '+63 912 345 6789',
                prefixIcon: const Icon(Icons.phone_outlined, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: _validateMobileNumber,
            ),
            const SizedBox(height: 20),

            // Username Field
            TextFormField(
              controller: _mobileUsernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: _validateUsername,
            ),
            const SizedBox(height: 20),

            // Password Field
            TextFormField(
              controller: _mobilePasswordController,
              obscureText: _mobileObscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined, size: 22),
                suffixIcon: IconButton(
                  icon: Icon(
                    _mobileObscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _mobileObscurePassword = !_mobileObscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 20),

            // Confirm Password Field
            TextFormField(
              controller: _mobileConfirmPasswordController,
              obscureText: _mobileObscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outlined, size: 22),
                suffixIcon: IconButton(
                  icon: Icon(
                    _mobileObscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _mobileObscureConfirmPassword = !_mobileObscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) => _validateConfirmPassword(
                value,
                _mobilePasswordController.text,
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleMobileRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Back to Login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: Color(0xFF4A90E2),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


