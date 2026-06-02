import 'package:flutter/material.dart';
import '../config/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่า / Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Info Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withValues(alpha: 0.08),
                  AppTheme.cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'slipD',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text(
                  'บันทึกรายรับ-รายจ่ายอัตโนมัติจากสลิป',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const Text(
                  'Auto Income-Expense Tracker from Slips',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Settings sections
          _sectionHeader('ทั่วไป / General'),
          const SizedBox(height: 8),
          _settingsTile(
            icon: Icons.category_outlined,
            title: 'จัดการหมวดหมู่',
            subtitle: 'Manage categories',
            onTap: () => _showComingSoon(context),
          ),
          _settingsTile(
            icon: Icons.palette_outlined,
            title: 'ธีม',
            subtitle: 'Theme',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cardBgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Dark',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
            onTap: () {},
          ),
          const SizedBox(height: 24),

          _sectionHeader('ข้อมูล / Data'),
          const SizedBox(height: 8),
          _settingsTile(
            icon: Icons.cloud_upload_outlined,
            title: 'สำรองข้อมูล',
            subtitle: 'Backup data',
            onTap: () => _showComingSoon(context),
          ),
          _settingsTile(
            icon: Icons.file_download_outlined,
            title: 'ส่งออกข้อมูล',
            subtitle: 'Export (PDF, Excel)',
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 24),

          _sectionHeader('เกี่ยวกับ / About'),
          const SizedBox(height: 8),
          _settingsTile(
            icon: Icons.info_outline,
            title: 'เกี่ยวกับแอป',
            subtitle: 'About slipD',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'slipD',
                applicationVersion: '1.0.0',
                applicationIcon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.white),
                ),
                children: const [
                  Text('แอปบันทึกรายรับ-รายจ่ายอัตโนมัติจากสลิปโอนเงิน'),
                  SizedBox(height: 8),
                  Text('Auto income-expense tracker from bank transfer slips'),
                ],
              );
            },
          ),
          _settingsTile(
            icon: Icons.star_outline,
            title: 'ให้คะแนน',
            subtitle: 'Rate this app',
            onTap: () => _showComingSoon(context),
          ),

          const SizedBox(height: 40),

          // Footer
          Center(
            child: Text(
              'Made with 💚 by slipD team',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.construction, color: AppTheme.primaryGreen),
            SizedBox(width: 10),
            Expanded(
              child: Text('เร็วๆ นี้ / Coming soon v2.0'),
            ),
          ],
        ),
        backgroundColor: AppTheme.cardBgLight,
      ),
    );
  }
}
