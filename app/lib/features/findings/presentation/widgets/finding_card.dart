import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_event.dart';
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
      case 'flights':
      case 'flight':
        return '✈️';
      case 'crypto':
        return '💰';
      case 'news':
        return '📰';
      case 'products':
      case 'product':
        return '🛍️';
      case 'jobs':
      case 'job':
        return '💼';
      default:
        return '✨';
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'flights':
      case 'flight':
        return Colors.blue;
      case 'crypto':
        return Colors.green;
      case 'news':
        return Colors.purple;
      case 'products':
      case 'product':
        return Colors.orange;
      case 'jobs':
      case 'job':
        return Colors.teal;
      default:
        return AppTheme.primary;
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
    final typeColor = _getTypeColor(widget.finding.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: InkWell(
        onTap: _onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getEmoji(widget.finding.type), style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(
                          widget.finding.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9, 
                            fontWeight: FontWeight.w900, 
                            color: typeColor, 
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _getTimeAgo(widget.finding.foundAt),
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      if (!_localIsRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppTheme.primary, blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.finding.headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900, 
                  fontSize: 17, 
                  height: 1.2,
                  letterSpacing: -0.4,
                ),
              ),
              if (widget.finding.detail != null && widget.finding.detail!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.finding.detail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.finding.watcherName ?? 'Unknown Agent',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\$${widget.finding.costUsdc.toStringAsFixed(3)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


