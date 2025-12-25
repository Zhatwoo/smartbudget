import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = ref.read(authServiceProvider);
        final firebaseService = ref.read(firebaseServiceProvider);
        
        if (_isLoginMode) {
          // Sign in
          await authService.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } else {
          // Register - create user and profile
          // Note: For full registration with username, user should use RegisterScreen
          // This is kept for backward compatibility
          final credential = await authService.registerWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          
          // Create Firestore user document if new (as per workflow)
          if (credential.user != null) {
            await firebaseService.initializeUserProfile(
              email: _emailController.text.trim(),
              displayName: credential.user!.displayName ?? _emailController.text.trim().split('@')[0],
              photoUrl: credential.user!.photoURL,
              username: _emailController.text.trim(), // Default username to email
              authMethod: 'email',
            );
          }
        }

        if (!mounted) return;

        // Initialize notification service after successful login
        try {
          final notificationService = ref.read(notificationServiceProvider);
          await notificationService.initialize();
        } catch (e) {
          // Silently fail - notification initialization errors shouldn't block navigation
        }

        // Success - navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'An error occurred'),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final firebaseService = ref.read(firebaseServiceProvider);
      
      if (provider == 'google') {
        // Sign in with Google
        final credential = await authService.signInWithGoogle();
        
        // Create Firestore user document if new (as per workflow)
        // Extract Gmail name and use email as default username
        if (credential.user != null) {
          final gmailName = credential.user!.displayName ?? '';
          final gmailEmail = credential.user!.email ?? '';
          
          await firebaseService.initializeUserProfile(
            email: gmailEmail,
            displayName: gmailName.isNotEmpty ? gmailName : gmailEmail.split('@')[0],
            photoUrl: credential.user!.photoURL,
            username: gmailEmail, // Email becomes default username
            authMethod: 'gmail',
          );
        }
        
        if (!mounted) return;
        
        // Initialize notification service after successful login
        try {
          final notificationService = ref.read(notificationServiceProvider);
          await notificationService.initialize();
        } catch (e) {
          // Silently fail - notification initialization errors shouldn't block navigation
        }
        
        // Success - navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Facebook login - coming soon
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$provider login coming soon!'),
            backgroundColor: const Color(0xFF4A90E2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      String errorMsg = e.toString().replaceAll('Exception: ', '');
      
      // Provide more helpful error message for Google Sign-In
      if (errorMsg.contains('ApiException') || 
          errorMsg.contains('sign_in_failed') ||
          errorMsg.contains('PlatformException')) {
        errorMsg = 'Google Sign-In not configured properly.\n\nPlease:\n1. Enable Google Sign-In in Firebase Console\n2. Add SHA-1 fingerprint\n3. Download updated google-services.json';
      }

      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }


  void _handleForgotPassword() {
    final identifierController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your username, mobile number, or email address and we\'ll send you a link to reset your password.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: identifierController,
                  keyboardType: TextInputType.text,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Username, Mobile, or Email',
                    hintText: 'Enter username, mobile number, or email',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username, mobile number, or email';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() {
                    _isLoading = true;
                  });

                  try {
                    final authService = ref.read(authServiceProvider);
                    final firebaseService = ref.read(firebaseServiceProvider);
                    final identifier = identifierController.text.trim();

                    // Determine if it's email, mobile, or username
                    String? username;
                    String? mobileNumber;
                    String? email;

                    // Check if it's an email
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (emailRegex.hasMatch(identifier)) {
                      email = identifier;
                    }
                    // Check if it's a mobile number (starts with + or has digits)
                    else if (RegExp(r'^\+?[0-9\s-]+$').hasMatch(identifier)) {
                      mobileNumber = identifier;
                    }
                    // Otherwise, treat as username
                    else {
                      username = identifier;
                    }

                    await authService.resetPasswordByIdentifier(
                      firebaseService: firebaseService,
                      username: username,
                      mobileNumber: mobileNumber,
                      email: email,
                    );

                    if (!mounted) return;

                    setDialogState(() {
                      _isLoading = false;
                    });

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset link sent to your email'),
                        backgroundColor: Color(0xFF4A90E2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;

                    setDialogState(() {
                      _isLoading = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: const Color(0xFFE74C3C),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Send Link',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: MediaQuery.of(context).size.height * 0.02,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

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
                  _isLoginMode ? 'Welcome Back' : 'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  _isLoginMode
                      ? 'Sign in to continue'
                      : 'Sign up to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined, size: 22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSubmit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outlined, size: 22),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 8),

                // Forgot Password Link (only in login mode)
                if (_isLoginMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: const Color(0xFF4A90E2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Error Message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
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
                ],

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
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
                            _isLoginMode ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Social Login Buttons
                // Google Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _handleSocialLogin('google'),
                    icon: const Icon(Icons.g_mobiledata, size: 22),
                    label: const Text(
                      'Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 1.5,
                      ),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Register Button (only in login mode)
                if (_isLoginMode) ...[
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () {
                        Navigator.of(context).pushNamed('/register');
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 22),
                      label: const Text(
                        'Create New Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4A90E2),
                        side: const BorderSide(
                          color: Color(0xFF4A90E2),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

