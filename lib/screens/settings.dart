import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/humbergersidebar.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Profile picture will be loaded from Firestore via provider

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
    } catch (e) {
      // Silently fail - notifications will be handled when toggled
    }
  }

  final List<String> _currencies = [
    'PHP (₱)',
    'USD (\$)',
    'EUR (€)',
    'GBP (£)',
    'JPY (¥)',
  ];

  Future<void> _pickProfilePicture() async {
    // TODO: Implement actual image picker
    // For now, simulate image selection
    // In production, use: image_picker package
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile picture selection coming soon'),
        backgroundColor: Color(0xFF27AE60),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateProfile() {
    // Get current profile data from providers
    final profile = ref.read(userProfileProvider).value;
    final displayName = profile?['displayName'] as String? ?? '';
    final email = profile?['email'] as String? ?? '';
    final mobileNumber = profile?['mobileNumber'] as String? ?? '';
    final username = profile?['username'] as String? ?? '';
    
    final nameController = TextEditingController(text: displayName);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: mobileNumber);
    final usernameController = TextEditingController(text: username);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            onPressed: () async {
                              // TODO: Implement image picker
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile picture selection coming soon'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Mobile Number (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final firebaseService = ref.read(firebaseServiceProvider);
                  await firebaseService.updateUserProfile(
                    displayName: nameController.text.trim(),
                    username: usernameController.text.trim(),
                    mobileNumber: phoneController.text.trim().isEmpty 
                        ? null 
                        : phoneController.text.trim(),
                  );
                  
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Profile updated successfully'),
                      backgroundColor: const Color(0xFF27AE60),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating profile: ${e.toString()}'),
                      backgroundColor: const Color(0xFFE74C3C),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Get profile data from providers
    final profileAsync = ref.watch(userProfileProvider);
    final displayName = ref.watch(userDisplayNameProvider);
    final email = ref.watch(userEmailProvider);
    final mobileNumber = ref.watch(userMobileNumberProvider);
    final username = ref.watch(userUsernameProvider);
    final photoUrl = ref.watch(userPhotoUrlProvider);
    
    // Handle loading state
    if (profileAsync.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header (matching dashboard style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF4A90E2),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // User Profile Section
                  _buildSectionHeader('Profile'),
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar with Profile Picture
                        Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: photoUrl != null && photoUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person_rounded,
                                            size: 50,
                                            color: Theme.of(context).colorScheme.primary,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.person_rounded,
                                      size: 50,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _updateProfile,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          displayName ?? 'No name',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (email != null) ...[
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (username != null) ...[
                          Text(
                            '@$username',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (mobileNumber != null && mobileNumber!.isNotEmpty) ...[
                          Text(
                            mobileNumber!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _updateProfile,
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                              foregroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preferences Section
                  _buildSectionHeader('Preferences'),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Currency
                        _buildSettingsTile(
                          icon: Icons.attach_money_rounded,
                          title: 'Currency',
                          subtitle: ref.watch(currencyProvider),
                          onTap: () {
                            final currentCurrency = ref.read(currencyProvider);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                title: const Text(
                                  'Select Currency',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _currencies.map((currency) {
                                    return RadioListTile<String>(
                                      title: Text(currency),
                                      value: currency,
                                      groupValue: currentCurrency,
                                      onChanged: (value) async {
                                        if (value != null) {
                                          await ref.read(currencyProvider.notifier).setCurrency(value);
                                          if (mounted) {
                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Currency set to $value'),
                                                backgroundColor: const Color(0xFF27AE60),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                        // Dark Mode
                        _buildSwitchTile(
                          icon: Icons.dark_mode_rounded,
                          title: 'Dark Mode',
                          subtitle: 'Enable dark theme',
                          value: ref.watch(darkModeProvider),
                          onChanged: (value) async {
                            await ref.read(darkModeProvider.notifier).setDarkMode(value);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value ? 'Dark mode enabled' : 'Dark mode disabled'),
                                  backgroundColor: const Color(0xFF27AE60),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notifications Section
                  _buildSectionHeader('Notifications'),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.notifications_rounded,
                          title: 'Enable Notifications',
                          subtitle: 'Receive app notifications',
                          value: ref.watch(notificationsEnabledProvider),
                          onChanged: (value) async {
                            await ref.read(notificationsEnabledProvider.notifier).setNotificationsEnabled(value);
                            
                            if (value) {
                              // Request notification permissions
                              try {
                                final notificationService = ref.read(notificationServiceProvider);
                                await notificationService.initialize();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error enabling notifications: ${e.toString()}'),
                                      backgroundColor: const Color(0xFFE74C3C),
                                    ),
                                  );
                                }
                                return;
                              }
                            }
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
                                  backgroundColor: const Color(0xFF27AE60),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        Divider(height: 1, color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                        _buildSwitchTile(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'Budget Alerts',
                          subtitle: 'Alert when approaching budget limit',
                          value: ref.watch(budgetAlertsProvider),
                          onChanged: ref.watch(notificationsEnabledProvider)
                              ? (value) async {
                                  await ref.read(budgetAlertsProvider.notifier).setBudgetAlertsEnabled(value);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(value ? 'Budget alerts enabled' : 'Budget alerts disabled'),
                                        backgroundColor: const Color(0xFF27AE60),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              : null,
                        ),
                        Divider(height: 1, color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                        _buildSwitchTile(
                          icon: Icons.trending_up_rounded,
                          title: 'Inflation Alerts',
                          subtitle: 'Alert about price changes',
                          value: ref.watch(inflationAlertsProvider),
                          onChanged: ref.watch(notificationsEnabledProvider)
                              ? (value) async {
                                  await ref.read(inflationAlertsProvider.notifier).setInflationAlertsEnabled(value);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(value ? 'Inflation alerts enabled' : 'Inflation alerts disabled'),
                                        backgroundColor: const Color(0xFF27AE60),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              : null,
                        ),
                        Divider(height: 1, color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                        _buildSwitchTile(
                          icon: Icons.warning_rounded,
                          title: 'Spending Alerts',
                          subtitle: 'Alert about unusual spending',
                          value: ref.watch(spendingAlertsProvider),
                          onChanged: ref.watch(notificationsEnabledProvider)
                              ? (value) async {
                                  await ref.read(spendingAlertsProvider.notifier).setSpendingAlertsEnabled(value);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(value ? 'Spending alerts enabled' : 'Spending alerts disabled'),
                                        backgroundColor: const Color(0xFF27AE60),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout Section
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE74C3C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF4A90E2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

