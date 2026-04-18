import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';
import 'package:flare_app/features/events/presentation/bloc/event_search_bloc.dart';
import 'package:flare_app/features/events/presentation/bloc/event_search_event.dart';
import 'package:flare_app/features/events/presentation/bloc/event_search_state.dart';
import 'package:flare_app/features/events/presentation/widgets/event_mini_card.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/utils/locale_detector.dart';
import 'package:go_router/go_router.dart';

class HomeEventsIntegration extends StatelessWidget {
  const HomeEventsIntegration({super.key});

  @override
  Widget build(BuildContext context) {
    final localeInfo = LocaleDetector.detect();
    final title = localeInfo.isNigerian ? 'Events in ${localeInfo.defaultCity}' : 'Trending Events';

    return BlocProvider(
      create: (context) => context.read<EventSearchBloc>()..add(LoadInitialEvents()),
      child: BlocBuilder<EventSearchBloc, EventSearchState>(
        builder: (context, state) {
          if (state is EventSearchLoaded && state.events.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, title),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: state.events.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: EventMiniCard(
                          event: state.events[index],
                          onTap: () => context.push(
                            '/events/detail/${state.events[index].platform}/${state.events[index].externalId}',
                            extra: state.events[index],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 12, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          TextButton(
            onPressed: () => context.push('/events/discovery'),
            child: const Text(
              'EXPLORE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
