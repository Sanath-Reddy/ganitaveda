import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganitaveda/app/providers.dart';
import 'package:ganitaveda/features/debug/debug_screen.dart';
import 'package:ganitaveda/features/explore/concept_screen.dart';
import 'package:ganitaveda/features/explore/explore_screen.dart';
import 'package:ganitaveda/features/explore/people_screens.dart';
import 'package:ganitaveda/features/explore/texts_screens.dart';
import 'package:ganitaveda/features/explore/timeline_screen.dart';
import 'package:ganitaveda/features/lesson/lesson_player.dart';
import 'package:ganitaveda/features/onboarding/onboarding_screen.dart';
import 'package:ganitaveda/features/progress/progress_screen.dart';
import 'package:ganitaveda/features/progress/review_screen.dart';
import 'package:ganitaveda/features/school/school_screens.dart';
import 'package:ganitaveda/features/search/search_screen.dart';
import 'package:ganitaveda/features/settings/settings_screens.dart';
import 'package:ganitaveda/features/verse/verse_screen.dart';
import 'package:ganitaveda/shared/widgets/app_shell.dart';
import 'package:go_router/go_router.dart';

GoRouter buildRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/school',
    redirect: (context, state) {
      final onboarded = ref.read(settingsProvider).onboarded;
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!onboarded && !atOnboarding) return '/onboarding';
      if (onboarded && atOnboarding) return '/school';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/school',
                builder: (_, _) => const SchoolScreen(),
                routes: [
                  GoRoute(
                    path: 'chapter/:id',
                    builder: (_, s) => ChapterScreen(id: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (_, _) => const ExploreScreen(),
                routes: [
                  GoRoute(
                    path: 'search',
                    builder: (_, s) => SearchScreen(initial: s.uri.queryParameters['q'] ?? ''),
                  ),
                  GoRoute(
                    path: 'area/:id',
                    builder: (_, s) => AreaScreen(id: s.pathParameters['id']!),
                  ),
                  GoRoute(path: 'texts', builder: (_, _) => const TextsScreen()),
                  GoRoute(path: 'people', builder: (_, _) => const PeopleScreen()),
                  GoRoute(path: 'lineage', builder: (_, _) => const LineageScreen()),
                  GoRoute(path: 'timeline', builder: (_, _) => const TimelineScreen()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (_, _) => const ProgressScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (_, _) => const SettingsScreen(),
                    routes: [
                      GoRoute(path: 'translations', builder: (_, _) => const TranslationOrderScreen()),
                      GoRoute(path: 'sources', builder: (_, _) => const SourcesScreen()),
                      GoRoute(path: 'privacy', builder: (_, _) => const PrivacyScreen()),
                      if (kDebugMode) GoRoute(path: 'debug', builder: (_, _) => const DebugScreen()),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Detail pages open from any tab (search, bookmarks, links), so they sit
      // outside the tab branches; pushing a branch route from another tab breaks.
      GoRoute(
        path: '/concept/:id',
        builder: (_, s) => ConceptScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/person/:id',
        builder: (_, s) => PersonScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/text/:id',
        builder: (_, s) => WorkScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/section/:id',
        builder: (_, s) => ReadingRoomScreen(sectionId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/lesson/:id',
        builder: (_, s) => LessonPlayer(lessonId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/verse/:id',
        builder: (_, s) => VerseScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/review', builder: (_, _) => const ReviewScreen()),
    ],
    errorBuilder: (context, state) => const Scaffold(body: Center(child: Icon(Icons.error_outline))),
  );
}

/// Opens an entity found in search, a bookmark or a timeline link.
void openEntity(BuildContext context, String id) {
  final kind = id.split('.').first;
  switch (kind) {
    case 'lesson':
      unawaited(context.push('/lesson/$id'));
    case 'concept':
      unawaited(context.push('/concept/$id'));
    case 'person':
      unawaited(context.push('/person/$id'));
    case 'verse':
      unawaited(context.push('/verse/$id'));
    case 'work':
      unawaited(context.push('/text/$id'));
    case 'term':
    case 'glossary':
    case 'seg':
      break;
  }
}
