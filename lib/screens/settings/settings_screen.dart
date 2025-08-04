import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to edit profile
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangePasswordDialog(),
                ),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.userModel;
                    return ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Private Account'),
                      subtitle: const Text('Only followers can see your posts'),
                      trailing: Switch(
                        value: user?.isPrivate ?? false,
                        onChanged: (value) {
                          authProvider.updateUserProfile(isPrivate: value);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                );
              },
            ),
          ),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Push Notifications'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // Handle notification settings
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: const Text('Likes'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // Handle like notifications
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Comments'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // Handle comment notifications
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_outlined),
                  title: const Text('New Followers'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // Handle follower notifications
                    },
                  ),
                ),
              ],
            ),
          ),

          // Privacy & Safety Section
          _buildSectionHeader('Privacy & Safety'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.block_outlined),
                  title: const Text('Blocked Users'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to blocked users
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report_outlined),
                  title: const Text('Report a Problem'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to report
                  },
                ),
              ],
            ),
          ),

          // About Section
          _buildSectionHeader('About'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Clipus'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Show about dialog
                    _showAboutDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Show terms
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Show privacy policy
                  },
                ),
              ],
            ),
          ),

          // Danger Zone
          _buildSectionHeader('Danger Zone'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.orange),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.orange),
                  ),
                  onTap: () => _showSignOutDialog(),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _showDeleteAccountDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _currentPasswordController,
              hintText: 'Current Password',
              obscureText: true,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _newPasswordController,
              hintText: 'New Password',
              obscureText: true,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirm New Password',
              obscureText: true,
              prefixIcon: Icons.lock_outline,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return LoadingButton(
                onPressed: () => _changePassword(authProvider),
                isLoading: authProvider.isLoading,
                text: 'Change',
                width: 100,
                height: 36,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(AuthProvider authProvider) async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final success = await authProvider.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (success && mounted) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
              Navigator.pop(context);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmationDialog();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your password to confirm account deletion:'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: passwordController,
              hintText: 'Password',
              obscureText: true,
              prefixIcon: Icons.lock_outline,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return LoadingButton(
                onPressed: () async {
                  final success = await authProvider.deleteAccount(
                    passwordController.text,
                  );
                  if (success && mounted) {
                    Navigator.pop(context);
                  }
                },
                isLoading: authProvider.isLoading,
                text: 'Delete',
                width: 100,
                height: 36,
                backgroundColor: Colors.red,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Clipus',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          Icons.video_camera_back,
          color: Theme.of(context).scaffoldBackgroundColor,
          size: 30,
        ),
      ),
      children: [
        const Text('A social media app for sharing photos and videos.'),
        const SizedBox(height: 16),
        const Text('Built with Flutter and Firebase.'),
      ],
    );
  }
}