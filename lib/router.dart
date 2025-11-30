
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/screens/advisory/advisory_chat_screen.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/screens/onboarding/language_select_screen.dart';
import 'package:myapp/screens/onboarding/login_screen.dart';
import 'package:myapp/screens/onboarding/signup_screen.dart';
import 'package:myapp/screens/profile_setup/profile_setup_screen.dart';
import 'package:myapp/screens/smart_farming/community_hub_screen.dart';
import 'package:myapp/screens/smart_farming/finance_ledger_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LanguageSelectScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/ledger',
      builder: (context, state) => const FinanceLedgerScreen(),
    ),
    GoRoute(
      path: '/community',
      builder: (context, state) => const CommunityHubScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const AdvisoryChatScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.error}'),
    ),
  ),
);
