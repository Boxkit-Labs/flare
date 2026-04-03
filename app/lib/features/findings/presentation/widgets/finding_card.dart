import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_app/core/models/models.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:ghost_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:ghost_app/features/findings/presentation/bloc/findings_event.dart';
import 'package:intl/intl.dart';

class FindingCard extends StatefulWidget {
  final FindingModel finding;

  const FindingCard({super.key, required this.finding});

  @override
  State<FindingCard> createState() => _FindingCardState();
}

class _FindingCardState extends State<FindingCard> {
  late bool _localIsRead;

  @override
  void initState() {
    super.initState();
    _localIsRead = widget.finding.isRead;
  }

  @override
  void didUpdateWidget(FindingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.finding.isRead != widget.finding.isRead) {
      _localIsRead = widget.finding.isRead;
    }
  }

  String _getEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'flights': return '✈️';
      case 'crypto': return '💰';
      case 'news': return '📰';
      case 'products': return '🛍️';
      case 'jobs': return '💼';
      default: return '✨';
    }
  }

  Color _getBorderColor(String type) {
    switch (type.toLowerCase()) {
      case 'flights': return Colors.blue;
      case 'crypto': return Colors.green;
      case 'news': return Colors.purple;
      case 'products': return Colors.orange;
      case 'jobs': return Colors.teal;
      default: return AppTheme.primary;
    }
  }

  String _getTimeAgo(String foundAt) {
    try {
      final date = DateTime.parse(foundAt);
      final diff = DateTime.now().difference(date);
      if (diff.inSeconds < 60) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return '';
    }
  }

  void _onTap() {
    if (!_localIsRead) {
      setState(() => _localIsRead = true);
      context.read<FindingsBloc>().add(MarkFindingAsRead(widget.finding.findingId));
    }
    context.push('/findings/${widget.finding.findingId}');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.surface,
      child: InkWell(
        onTap: _onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _getBorderColor(widget.finding.type),
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                       children: [
                         Text(_getEmoji(widget.finding.type), style: const TextStyle(fontSize: 14)),
                         const SizedBox(width: 6),
                         Text(
                           widget.finding.watcherName?.toUpperCase() ?? widget.finding.type.toUpperCase(),
                           style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
                         ),
                       ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.finding.headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.finding.detail ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getTimeAgo(widget.finding.foundAt),
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$${widget.finding.costUsdc.toStringAsFixed(3)}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_localIsRead)
                 Padding(
                   padding: const EdgeInsets.only(left: 12, top: 4),
                   child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  ),
                 ),
            ],
          ),
        ),
      ),
    );
  }
}

