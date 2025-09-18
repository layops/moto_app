import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/theme_provider.dart';
import 'notifications_page.dart'; // Add this import
import '../auth/change_password_page.dart'; // Add this import

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add your logout logic here
              },
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // General Section
          Text(
            'General',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            context,
            title: 'Language',
            value: 'English',
            onTap: () {
              // Navigate to language settings
            },
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context,
            title: 'Units of Measurement',
            value: 'Miles',
            onTap: () {
              // Navigate to units settings
            },
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context,
            title: 'Data Sync',
            onTap: () {
              // Navigate to data sync settings
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Theme',
                  style: theme.textTheme.bodyLarge,
                ),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Account Management Section
          Text(
            'Account Management',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            context,
            title: 'Change Password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context,
            title: 'Delete Account',
            onTap: () {
              // Navigate to delete account
            },
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context,
            title: 'Linked Accounts',
            onTap: () {
              // Navigate to linked accounts
            },
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context,
            title: 'Notification Settings',
            onTap: () {
              // Navigate to notification settings
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationsPage()),
              );
            },
          ),
          const SizedBox(height: 32),

          // Support Section
          Text(
            'Support',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            context,
            title: 'Help & Support',
            onTap: () {
              // Navigate to help & support
            },
          ),
          const Divider(height: 1),
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Logout',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context,
      {required String title, String? value, VoidCallback? onTap}) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyLarge,
            ),
            Row(
              children: [
                if (value != null)
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                if (onTap != null) const SizedBox(width: 8),
                if (onTap != null) const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
