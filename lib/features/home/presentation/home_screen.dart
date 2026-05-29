import 'dart:async';

import 'package:flutter/material.dart';
import 'package:table_master_mobile/core/tutorial/tutorial_service.dart';
import 'package:table_master_mobile/features/auth/presentation/login/login_screen.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../../reservation/presentation/my_reservations_page.dart';
import '../../../core/injection.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/responsive/responsive_scaffold.dart';
import 'pages/maps_page.dart';
import 'pages/account_page.dart';
import 'pages/restaurant_page.dart';

class HomeScreen extends StatefulWidget {
  final UserOut user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget?> _pages;
  late List<NavDestination> _destinations;
  late List<String> _titles;
  final _authRepo = getIt<IAuthRepository>();
  final _tutorialService = const TutorialService();
  final _reservationsTutorialKey = GlobalKey(
    debugLabel: 'reservationsTutorial',
  );
  final _restaurantsTutorialKey = GlobalKey(debugLabel: 'restaurantsTutorial');
  final _accountTutorialKey = GlobalKey(debugLabel: 'accountTutorial');
  final _restaurantTutorialKey = GlobalKey(debugLabel: 'restaurantTutorial');
  bool _tutorialVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showInitialTutorialIfNeeded());
    });
  }

  void _initializeNavigation() {
    final isRestaurant = widget.user.accountType == 1;

    _titles = [
      'Mes Réservations',
      'Trouver des Restaurants',
      'Mon Compte',
      if (isRestaurant) 'Mon Restaurant',
    ];

    _destinations = [
      NavDestination(
        icon: Icons.event_note_outlined,
        activeIcon: Icons.event_note,
        label: 'Réservations',
        tutorialKey: _reservationsTutorialKey,
      ),
      NavDestination(
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on,
        label: 'Restaurants',
        tutorialKey: _restaurantsTutorialKey,
      ),
      NavDestination(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Mon Compte',
        tutorialKey: _accountTutorialKey,
      ),
      if (isRestaurant)
        NavDestination(
          icon: Icons.restaurant_outlined,
          activeIcon: Icons.restaurant,
          label: 'Mon Restaurant',
          tutorialKey: _restaurantTutorialKey,
        ),
    ];

    _pages = List<Widget?>.filled(_destinations.length, null);
    _ensurePageLoaded(_selectedIndex);
  }

  void _ensurePageLoaded(int index) {
    if (_pages[index] != null) return;

    _pages[index] = switch (index) {
      0 => MyReservationsPage(userId: widget.user.id),
      1 => const MapsPage(),
      2 => AccountPage(
        user: widget.user,
        onLogout: _logout,
        onReplayTutorial: () => unawaited(_showTutorial(force: true)),
      ),
      3 => RestaurantPage(user: widget.user),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _showInitialTutorialIfNeeded() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final shouldShow = await _tutorialService.shouldShowHomeTutorial(
      widget.user,
    );
    if (!mounted || !shouldShow) return;

    await _showTutorial();
  }

  Future<void> _showTutorial({bool force = false}) async {
    if (_tutorialVisible || !mounted) return;
    if (!force) {
      final shouldShow = await _tutorialService.shouldShowHomeTutorial(
        widget.user,
      );
      if (!mounted || !shouldShow) return;
    }

    final targets = _buildTutorialTargets();
    if (targets.isEmpty) return;

    _tutorialVisible = true;

    void completeTutorial() {
      if (!_tutorialVisible) return;
      _tutorialVisible = false;
      unawaited(_tutorialService.markHomeTutorialSeen(widget.user));
    }

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.78,
      paddingFocus: 8,
      textSkip: 'Passer',
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      alignSkip: Alignment.topRight,
      pulseEnable: true,
      useSafeArea: true,
      onFinish: completeTutorial,
      onSkip: () {
        completeTutorial();
        return true;
      },
    ).show(context: context);
  }

  List<TargetFocus> _buildTutorialTargets() {
    final contentAlign =
        context.isMobile ? ContentAlign.top : ContentAlign.right;
    final targets = <TargetFocus>[
      _buildTarget(
        key: _reservationsTutorialKey,
        identify: 'reservations',
        title: 'Vos réservations',
        message:
            'Suivez vos réservations validées, en attente et votre historique.',
        align: contentAlign,
      ),
      _buildTarget(
        key: _restaurantsTutorialKey,
        identify: 'restaurants',
        title: 'Trouver un restaurant',
        message:
            'Explorez les restaurants sur la carte, filtrez et ouvrez les fiches détail.',
        align: contentAlign,
      ),
      _buildTarget(
        key: _accountTutorialKey,
        identify: 'account',
        title: 'Votre compte',
        message:
            'Gérez votre profil, vos avis, votre sécurité et relancez ce tutoriel.',
        align: contentAlign,
      ),
      if (widget.user.accountType == 1)
        _buildTarget(
          key: _restaurantTutorialKey,
          identify: 'restaurant',
          title: 'Espace restaurateur',
          message:
              'Administrez votre établissement, vos tables, menus et réservations restaurant.',
          align: contentAlign,
        ),
    ];

    return targets
        .where((target) => target.keyTarget?.currentContext != null)
        .toList();
  }

  TargetFocus _buildTarget({
    required GlobalKey key,
    required String identify,
    required String title,
    required String message,
    required ContentAlign align,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: key,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      enableOverlayTab: true,
      contents: [
        TargetContent(
          align: align,
          child: _TutorialContent(title: title, message: message),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    await _authRepo.logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _ensurePageLoaded(index);
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final showAppBar = context.isMobile;

    return ResponsiveScaffold(
      destinations: _destinations,
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      appBar:
          showAppBar
              ? AppBar(
                title: Text(_titles[_selectedIndex]),
                elevation: 0,
                actions: [_UserBadge(user: widget.user)],
              )
              : null,
      railLeading: _RailLeading(user: widget.user),
      railTrailing: const Spacer(),
      body: _DesktopHeader(
        title: _titles[_selectedIndex],
        user: widget.user,
        showHeader: !showAppBar,
        accentColor: colors.primary,
        child: IndexedStack(
          index: _selectedIndex,
          children: List.generate(
            _pages.length,
            (index) => _pages[index] ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _UserBadge extends StatelessWidget {
  final UserOut user;
  const _UserBadge({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${user.firstName} ${user.lastName}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              user.accountType == 0 ? 'Client' : 'Restaurant',
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialContent extends StatelessWidget {
  final String title;
  final String message;

  const _TutorialContent({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailLeading extends StatelessWidget {
  final UserOut user;
  const _RailLeading({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials = _initials(user);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            child: Text(
              initials,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _initials(UserOut u) {
    final f = u.firstName.isNotEmpty ? u.firstName[0] : '';
    final l = u.lastName.isNotEmpty ? u.lastName[0] : '';
    return (f + l).toUpperCase();
  }
}

/// En-tête visible uniquement quand l'AppBar mobile n'est pas affichée
/// (tablet/desktop) : titre + badge utilisateur dans le contenu principal.
class _DesktopHeader extends StatelessWidget {
  final String title;
  final UserOut user;
  final bool showHeader;
  final Color accentColor;
  final Widget child;

  const _DesktopHeader({
    required this.title,
    required this.user,
    required this.showHeader,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!showHeader) return child;

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 24, 16),
          child: Row(
            children: [
              Expanded(child: Text(title, style: textTheme.headlineMedium)),
              _UserBadge(user: user),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    );
  }
}
