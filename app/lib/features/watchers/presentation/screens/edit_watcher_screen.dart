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
    setState(() => _formData = data);
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
              ...state.watcher.parameters,
              ...state.watcher.alertConditions,
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
        appBar: AppBar(
          title: const Text('Edit Watcher', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            if (!_isLoading)
              TextButton(
                onPressed: _save,
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.all(24),
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildDynamicForm(),
        const SizedBox(height: 32),
        _buildScheduleAndBudget(),
        const SizedBox(height: 60),
        _buildDangerZone(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_watcher!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Agent ID: ${_watcher!.watcherId.substring(0, 8)}...', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
          child: Text(_watcher!.type.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildDynamicForm() {
    switch (_watcher!.type.toLowerCase()) {
      case 'flight':
      case 'flights':
        return FlightWatcherForm(onChanged: _handleDataChange, initialData: _watcher!.parameters);
      case 'crypto':
        return CryptoWatcherForm(onChanged: _handleDataChange, initialData: _watcher!.parameters);
      case 'news':
        return NewsWatcherForm(onChanged: _handleDataChange, initialData: _watcher!.parameters);
      case 'product':
      case 'products':
        return ProductWatcherForm(onChanged: _handleDataChange, initialData: _watcher!.parameters);
      case 'job':
      case 'jobs':
        return JobWatcherForm(onChanged: _handleDataChange, initialData: _watcher!.parameters);
      default:
        return const Center(child: Text('Form type not supported for editing yet.'));
    }
  }

  Widget _buildScheduleAndBudget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Schedule & Economy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 24),
        
        // Interval Dropdown
        const Text('Check Frequency', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        _buildDropdown(
          'check_interval_minutes',
          {15: 'Every 15 minutes', 60: 'Every hour', 360: 'Every 6 hours', 1440: 'Once a day'},
        ),
        const SizedBox(height: 24),

        // Budget Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Weekly Budget Cap', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            Text('\$${(_formData['weekly_budget_usdc'] ?? 0.0).toStringAsFixed(2)} USDC', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ],
        ),
        Slider(
          value: _formData['weekly_budget_usdc'],
          min: 0.1,
          max: 2.0,
          onChanged: (val) => _handleDataChange({..._formData, 'weekly_budget_usdc': val}),
        ),
        const SizedBox(height: 24),

        // Priority
        const Text('Priority Level', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'low', label: Text('Low')),
            ButtonSegment(value: 'medium', label: Text('Med')),
            ButtonSegment(value: 'high', label: Text('High')),
          ],
          selected: {_formData['priority']},
          onSelectionChanged: (set) => _handleDataChange({..._formData, 'priority': set.first}),
        ),
      ],
    );
  }

  Widget _buildDropdown(String key, Map<int, String> options) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _formData[key],
          items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (val) => _handleDataChange({..._formData, key: val}),
          isExpanded: true,
          dropdownColor: AppTheme.surface,
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Danger Zone', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          _buildDangerAction(
            _watcher!.status == 'active' ? 'Pause Watcher' : 'Resume Watcher',
            'Temporarily stop this agent from running checks.',
            onTap: () => context.read<WatchersBloc>().add(ToggleWatcher(widget.watcherId)),
          ),
          const Divider(height: 32, color: Colors.white10),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isCritical ? Colors.redAccent : AppTheme.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Icon(isCritical ? Icons.delete_outline : Icons.pause_circle_outline, color: isCritical ? Colors.redAccent : AppTheme.textSecondary),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_watcher!.name}?'),
        content: Text('You\'ve spent \$${_watcher!.totalSpentUsdc.toStringAsFixed(3)} on ${_watcher!.totalChecks} checks so far. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Watcher')),
          TextButton(
            onPressed: () {
               context.read<WatchersBloc>().add(DeleteWatcher(widget.watcherId));
               Navigator.pop(context);
               context.pop();
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}
