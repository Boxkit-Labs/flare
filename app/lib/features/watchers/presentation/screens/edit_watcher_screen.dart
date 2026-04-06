import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_event.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_state.dart';
import 'package:flare_app/features/watchers/presentation/widgets/forms/flight_watcher_form.dart';
import 'package:flare_app/features/watchers/presentation/widgets/forms/crypto_watcher_form.dart';
import 'package:flare_app/features/watchers/presentation/widgets/forms/news_watcher_form.dart';
import 'package:flare_app/features/watchers/presentation/widgets/forms/product_watcher_form.dart';
import 'package:flare_app/features/watchers/presentation/widgets/forms/job_watcher_form.dart';
import 'package:flare_app/core/widgets/top_snackbar.dart';

class EditWatcherScreen extends StatefulWidget {
  final String watcherId;

  const EditWatcherScreen({super.key, required this.watcherId});

  @override
  State<EditWatcherScreen> createState() => _EditWatcherScreenState();
}

class _EditWatcherScreenState extends State<EditWatcherScreen> {
  late Map<String, dynamic> _formData;
  late Map<String, dynamic> _initialData;
  bool _isLoading = true;
  WatcherModel? _watcher;

  @override
  void initState() {
    super.initState();
    _loadWatcher();
  }

  void _loadWatcher() {
    context.read<WatchersBloc>().add(LoadWatcherDetail(widget.watcherId));
  }

  void _handleDataChange(Map<String, dynamic> data) {
    setState(() {
      _formData.addAll(data);
    });
  }

  Map<String, dynamic> _getDiff() {
    final diff = <String, dynamic>{};
    _formData.forEach((key, value) {
      if (value != _initialData[key]) {
        diff[key] = value;
      }
    });
    return diff;
  }

  Future<void> _save() async {
    final diff = _getDiff();
    if (diff.isEmpty) {
      context.pop();
      return;
    }

    context.read<WatchersBloc>().add(UpdateWatcher(widget.watcherId, diff));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WatchersBloc, WatchersState>(
      listener: (context, state) {
        if (state is WatcherDetailLoaded && state.watcher.watcherId == widget.watcherId) {
          setState(() {
            _watcher = state.watcher;
            _initialData = {
              'name': state.watcher.name,
              'check_interval_minutes': state.watcher.checkIntervalMinutes,
              'weekly_budget_usdc': state.watcher.weeklyBudgetUsdc,
              'priority': state.watcher.priority,
              'parameters': state.watcher.parameters,
              'alert_conditions': state.watcher.alertConditions,
            };
            _formData = Map.from(_initialData);
            _isLoading = false;
          });
        }
        if (state is WatcherActionSuccess) {
           TopSnackbar.showSuccess(context, 'Watcher updated');
           context.pop();
        }
        if (state is WatchersError) {
          TopSnackbar.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text('Edit Agent', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.8)),
          actions: [
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Container(
                   decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: _save,
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildInfoCard(),
        const SizedBox(height: 24),
        _buildSectionHeader('Configuration'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: _buildDynamicForm(),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('Schedule & Budget'),
        const SizedBox(height: 12),
        _buildScheduleAndBudgetCard(),
        const SizedBox(height: 48),
        _buildDangerZoneCard(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.psychology_outlined, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_watcher!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('ID: ${_watcher!.watcherId.substring(0, 12)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Text(_watcher!.type.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicForm() {
    final combinedInitialData = {
      ..._watcher!.parameters,
      ..._watcher!.alertConditions,
    };

    switch (_watcher!.type.toLowerCase()) {
      case 'flight':
      case 'flights':
        return FlightWatcherForm(onChanged: _handleDataChange, initialData: combinedInitialData);
      case 'crypto':
        return CryptoWatcherForm(onChanged: _handleDataChange, initialData: combinedInitialData);
      case 'news':
        return NewsWatcherForm(onChanged: _handleDataChange, initialData: combinedInitialData);
      case 'product':
      case 'products':
        return ProductWatcherForm(onChanged: _handleDataChange, initialData: combinedInitialData);
      case 'job':
      case 'jobs':
        return JobWatcherForm(onChanged: _handleDataChange, initialData: combinedInitialData);
      default:
        return const Center(child: Text('Form type not supported for editing yet.'));
    }
  }

  Widget _buildScheduleAndBudgetCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Check Frequency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          _buildDropdown(
            'check_interval_minutes',
            {
              2: 'Every 2 minutes',
              5: 'Every 5 minutes',
              15: 'Every 15 minutes', 
              60: 'Every hour', 
              360: 'Every 6 hours', 
              1440: 'Once a day'
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Weekly Budget Cap', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              Text('\$${(_formData['weekly_budget_usdc'] ?? 0.0).toStringAsFixed(2)} USDC', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _formData['weekly_budget_usdc'],
            min: 0.1,
            max: 2.0,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.primary.withValues(alpha: 0.1),
            onChanged: (val) => _handleDataChange({..._formData, 'weekly_budget_usdc': val}),
          ),
          const SizedBox(height: 16),
          const Text('Priority Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'low', label: Text('Low')),
                ButtonSegment(value: 'medium', label: Text('Med')),
                ButtonSegment(value: 'high', label: Text('High')),
              ],
              selected: {_formData['priority']},
              onSelectionChanged: (set) => _handleDataChange({..._formData, 'priority': set.first}),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppTheme.primary,
                selectedForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String key, Map<int, String> options) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _formData[key],
          items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)))).toList(),
          onChanged: (val) => _handleDataChange({..._formData, key: val}),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
          dropdownColor: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.red.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Danger Zone', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 20),
          _buildDangerAction(
            _watcher!.status == 'active' ? 'Pause Watcher' : 'Resume Watcher',
            'Temporarily stop this agent from running checks.',
            onTap: () => context.read<WatchersBloc>().add(ToggleWatcher(widget.watcherId)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.red, thickness: 0.1),
          ),
          _buildDangerAction(
            'Delete Watcher',
            'Irreversibly stop and remove this agent.',
            isCritical: true,
            onTap: _showDeleteDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerAction(String title, String subtitle, {required VoidCallback onTap, bool isCritical = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isCritical ? Colors.red : AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: (isCritical ? Colors.red : AppTheme.textSecondary).withValues(alpha: 0.1),
               shape: BoxShape.circle,
             ),
             child: Icon(
              isCritical ? Icons.delete_outline_rounded : Icons.pause_circle_outline_rounded, 
              color: isCritical ? Colors.red : AppTheme.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.surface,
        title: Text('Delete ${_watcher!.name}?', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text('You\'ve spent \$${_watcher!.totalSpentUsdc.toStringAsFixed(3)} on ${_watcher!.totalChecks} checks so far. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Keep Agent', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold))
          ),
          TextButton(
            onPressed: () {
               context.read<WatchersBloc>().add(DeleteWatcher(widget.watcherId));
               Navigator.pop(context);
               context.pop();
            }, 
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}

