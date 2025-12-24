import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Moneyroll'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Header
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      "assets/images/logo.png",
                      width: Get.width * .5,
                      height: Get.width * .5,
                    ),
                    const Text(
                      'Moneyroll',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Expense Management Made Simple',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // App Description
              const Text(
                'About the App',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Moneyroll is a comprehensive expense management solution designed for individuals, employees, and HR professionals. '
                'Manage your expenses efficiently without any login requirements, using only local storage for complete privacy.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 30),

              // Key Features
              const Text(
                'Key Features',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildFeatureTile(
                icon: Icons.person,
                title: 'For Everyone',
                subtitle:
                    'No login required. Use it as individual, employee, or HR professional.',
              ),
              _buildFeatureTile(
                icon: Icons.history,
                title: 'Expense History',
                subtitle:
                    'View and edit your complete expense history with powerful filtering.',
              ),
              _buildFeatureTile(
                icon: Icons.import_export,
                title: 'Import & Export',
                subtitle:
                    'Export your data before deleting the app. Import it back anytime.',
              ),
              _buildFeatureTile(
                icon: Icons.storage,
                title: 'Local Storage',
                subtitle:
                    'All data stored locally on your device. No cloud, no API, complete privacy.',
              ),
              _buildFeatureTile(
                icon: Icons.edit,
                title: 'Full Edit Control',
                subtitle: 'Edit any expense entry anytime. No restrictions.',
              ),
              const SizedBox(height: 30),

              // Data Safety Section
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ Important Data Safety Note',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Moneyroll uses only local mobile database (no cloud backup). '
                      'Always export your data before:',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.delete, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Uninstalling the app',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.phone_android,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Resetting your device',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.cleaning_services,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Clearing app data/cache',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: () => _showExportInstructions(context),
                      icon: const Icon(Icons.download),
                      label: const Text('How to Export Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // App Info Section
              const Text(
                'Technical Information',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildInfoCard(
                'Storage Method',
                'Local mobile database',
                Icons.storage,
              ),
              _buildInfoCard(
                'Data Privacy',
                '100% local - no data leaves your device',
                Icons.security,
              ),
              _buildInfoCard(
                'Backup Method',
                'Manual export/import via file system',
                Icons.backup,
              ),
              const SizedBox(height: 30),

              // Contact/Support
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'For questions or feedback about Moneyroll:',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _launchEmail(context),
                          icon: const Icon(Icons.email, color: Colors.black),
                        ),
                        const SizedBox(width: 10),
                        const Text('nithinlal@astsolution.org'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              _copyToClipboard(context, 'Moneyroll App v1.0.0'),
                          icon: const Icon(Icons.copy, color: Colors.black),
                        ),
                        const SizedBox(width: 10),
                        const Text('Tap to copy app info'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Footer
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Made with ❤️ for expense management',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '© ${DateTime.now().year} Moneyroll',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Get.width * .3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExportInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Export Your Data'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To safely export your expense data:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 15),
              _buildInstructionStep('1. Go to History screen'),
              _buildInstructionStep('2. Tap "Export" button'),
              _buildInstructionStep('3. Choose export location'),
              _buildInstructionStep('4. Save the .json file'),
              _buildInstructionStep('5. Keep the file safe'),
              const SizedBox(height: 15),
              const Text(
                'Import the same file anytime to restore all your data.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.black),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // FIXED: Email launch function with proper error handling
  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'nithinlal@astsolution.org',
      queryParameters: {'subject': 'Moneyroll App Feedback'},
    );

    final String emailString = emailLaunchUri.toString();

    try {
      if (await canLaunchUrl(Uri.parse(emailString))) {
        await launchUrl(Uri.parse(emailString));
      } else {
        // If mailto: doesn't work, try showing a snackbar
        _showNoEmailAppDialog(context);
      }
    } catch (e) {
      // Alternative: Show email in a dialog
      _showEmailFallback(context);
    }
  }

  void _showNoEmailAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email App Not Found'),
        content: const Text(
          'No email app detected on your device. '
          'Please send your feedback to: support@moneyroll.example.com',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyToClipboard(context, 'support@moneyroll.example.com');
            },
            child: const Text('Copy Email'),
          ),
        ],
      ),
    );
  }

  void _showEmailFallback(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send your feedback to:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SelectableText(
                'support@moneyroll.example.com',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Subject: Moneyroll App Feedback'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _copyToClipboard(context, 'support@moneyroll.example.com');
              Navigator.pop(context);
            },
            child: const Text('Copy Email'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    // Show a snackbar confirmation
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
