import 'package:flutter/material.dart';
import 'package:flare_app/features/events/domain/entities/ticket_tier_entity.dart';
import 'package:flare_app/core/utils/currency_formatter.dart';

class TicketTierCard extends StatelessWidget {
  final TicketTierEntity tier;
  final VoidCallback? onPlatformLinkTap;

  const TicketTierCard({
    super.key,
    required this.tier,
    this.onPlatformLinkTap,
  });

  Color _getAvailabilityColor() {
    if (!tier.available) return const Color(0xFFEF4444); // Red
    if (tier.quantityRemaining != null && tier.quantityRemaining! <= 10) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF10B981); // Emerald
  }

  @override
  Widget build(BuildContext context) {
    final availabilityColor = _getAvailabilityColor();
    final isSoldOut = !tier.available;

    return Opacity(
      opacity: isSoldOut ? 0.6 : 1.0,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Surface
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // 4px left accent
                Container(
                  width: 4,
                  color: availabilityColor,
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Name and Status Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                tier.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  decoration: isSoldOut ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: availabilityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: availabilityColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                tier.availabilityText.toUpperCase(),
                                style: TextStyle(
                                  color: availabilityColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Middle: Large Price
                        Text(
                          tier.isFree ? 'FREE' : tier.displayPrice,
                          style: TextStyle(
                            color: tier.isFree ? const Color(0xFF10B981) : Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Bottom Row: Remaining and Platform Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tier.quantityRemaining != null 
                                ? '${tier.quantityRemaining} remaining' 
                                : 'Available',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (onPlatformLinkTap != null)
                              GestureDetector(
                                onTap: onPlatformLinkTap,
                                child: Row(
                                  children: [
                                    Text(
                                      'View Details',
                                      style: TextStyle(
                                        color: const Color(0xFF6366F1),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.open_in_new, size: 14, color: const Color(0xFF6366F1)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
