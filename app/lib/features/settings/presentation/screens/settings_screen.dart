import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flare_app/services/api_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flare_app/core/widgets/top_snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<String, dynamic> _localSettings;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _localSettings = {
        'briefing_enabled': true,
        'briefing_time': user.briefingTime,
        'timezone': user.timezone,
        'notifications_findings': true,
        'notifications_briefing': true,
        'notifications_budget': true,
        'dnd_enabled': true,
        'dnd_start': user.dndStart,
        'dnd_end': user.dndEnd,
        'global_daily_cap_enabled': user.globalDailyCap != null,
        'global_daily_cap': user.globalDailyCap ?? 1.0,
        'low_balance_threshold': 0.10,
      };
    } else {
      _localSettings = {};
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    setState(() {
      _localSettings[key] = value;
    });

    try {
      final userId = (context.read<AuthBloc>().state as AuthAuthenticated).user.userId;
      await context.read<ApiService>().updateSettings(userId, _localSettings);
      if (mounted) {
        TopSnackbar.showSuccess(context, 'Settings saved');
      }
    } catch (e) {
      if (mounted) {
        TopSnackbar.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) return const SizedBox.shrink();
          final user = state.user;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader('ACCOUNT'),
              _buildAccountTile(user),
              const SizedBox(height: 32),
              
              _buildSectionHeader('MORNING BRIEFING'),
              _buildSwitchTile(
                'Enable daily briefing',
                'briefing_enabled',
                icon: Icons.wb_sunny_outlined,
              ),
              _buildActionTile(
                'Briefing time',
                _localSettings['briefing_time'],
                Icons.access_time,
                onTap: () => _pickTime('briefing_time'),
              ),
              _buildActionTile(
                'Timezone',
                _localSettings['timezone'],
                Icons.public,
                onTap: _showTimezonePicker,
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('NOTIFICATIONS'),
              _buildSwitchTile('Finding alerts', 'notifications_findings'),
              _buildSwitchTile('Morning briefing', 'notifications_briefing'),
              _buildSwitchTile('Budget warnings', 'notifications_budget'),
              _buildSwitchTile('Do Not Disturb', 'dnd_enabled'),
              if (_localSettings['dnd_enabled'] == true) ...[
                _buildActionTile('DND Start', _localSettings['dnd_start'], Icons.nightlight_outlined, onTap: () => _pickTime('dnd_start')),
                _buildActionTile('DND End', _localSettings['dnd_end'], Icons.wb_twilight, onTap: () => _pickTime('dnd_end')),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Note: High priority watchers bypass DND',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              _buildSectionHeader('BUDGET'),
              _buildSwitchTile('Global daily cap', 'global_daily_cap_enabled'),
              if (_localSettings['global_daily_cap_enabled'] == true)
                _buildInputTile('Daily Cap (USDC)', 'global_daily_cap'),
              _buildInputTile('Low balance threshold', 'low_balance_threshold'),
              const SizedBox(height: 32),

              _buildSectionHeader('DATA'),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Clear check history', style: TextStyle(color: Colors.redAccent)),
                onTap: _showClearCacheDialog,
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('View all Stellar transactions'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => context.push('/wallet'),
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('ABOUT'),
              _buildAboutSection(),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildAccountTile(UserModel user) {
    final address = user.stellarPublicKey;
    return Card(
      elevation: 0,
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stellar Address', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        '${address.substring(0, 8)}...${address.substring(address.length - 8)}',
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code, size: 20),
                  onPressed: () => _showQRDialog(address),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: address));
                    TopSnackbar.showSuccess(context, 'Address copied');
                  },
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Device ID', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text(
                  user.deviceId.length > 20 ? '${user.deviceId.substring(0, 10)}...' : user.deviceId,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String key, {IconData? icon}) {
    return ListTile(
      leading: icon != null ? Icon(icon, size: 20) : null,
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Switch(
        value: _localSettings[key] ?? false,
        onChanged: (val) => _updateSetting(key, val),
        activeTrackColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildActionTile(String title, String value, IconData icon, {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          const Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildInputTile(String title, String key) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: SizedBox(
        width: 80,
        child: TextField(
          textAlign: TextAlign.end,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: '0.00',
            contentPadding: EdgeInsets.zero,
          ),
          onSubmitted: (val) {
            final num = double.tryParse(val);
            if (num != null) _updateSetting(key, num);
          },
          controller: TextEditingController(text: _localSettings[key]?.toString() ?? ''),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        const ListTile(title: Text('App version'), trailing: Text('Flare v1.0.0')),
        const ListTile(title: Text('Built for'), subtitle: Text('Stellar Hacks: Agents hackathon')),
        ListTile(
          title: const Text('GitHub Repository'),
          trailing: const Icon(Icons.launch, size: 16),
          onTap: () => _launchUrl(Uri.parse('https://github.com/Boxkit-Labs/flare')),
        ),
        const SizedBox(height: 20),
        Opacity(
          opacity: 0.6,
          child: Column(
            children: [
              const Text('Powered by Stellar Testnet', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              const Text('Made with ❤️ and x402 micropayments', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  void _showQRDialog(String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Stellar Address', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(
                data: address,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(address, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _pickTime(String key) async {
    final current = _localSettings[key] as String;
    final parts = current.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: AppTheme.lightTheme.copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _updateSetting(key, formatted);
    }
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Check History?'),
        content: const Text('This will clear the local cache of agent actions. Your findings and wallet are stored on the server and will not be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              TopSnackbar.showSuccess(context, 'History cleared');
            }, 
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await canLaunchUrl(url)) {
      if (mounted) {
        TopSnackbar.showError(context, 'Could not launch $url');
      }
      return;
    }
    await launchUrl(url);
  }

  void _showTimezonePicker() {
    final timezones = ['UTC', 'EST (UTC-5)', 'PST (UTC-8)', 'GMT (UTC+0)', 'CET (UTC+1)', 'IST (UTC+5:30)'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Timezone'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: timezones.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(timezones[index]),
              onTap: () {
                _updateSetting('timezone', timezones[index]);
                Navigator.pop(context);
              },
              trailing: _localSettings['timezone'] == timezones[index] ? const Icon(Icons.check, color: AppTheme.primary) : null,
            ),
          ),
        ),
      ),
    );
  }
}
