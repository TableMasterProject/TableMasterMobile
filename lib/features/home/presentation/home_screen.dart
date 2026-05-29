import 'package:flutter/material.dart';
import 'package:table_master_mobile/features/auth/presentation/login/login_screen.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
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
      const NavDestination(
        icon: Icons.event_note_outlined,
        activeIcon: Icons.event_note,
        label: 'Réservations',
      ),
      const NavDestination(
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on,
        label: 'Restaurants',
      ),
      const NavDestination(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Mon Compte',
      ),
      if (isRestaurant)
        const NavDestination(
          icon: Icons.restaurant_outlined,
          activeIcon: Icons.restaurant,
          label: 'Mon Restaurant',
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
      2 => AccountPage(user: widget.user, onLogout: _logout),
      3 => RestaurantPage(user: widget.user),
      _ => const SizedBox.shrink(),
    };
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
      appBar: showAppBar
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
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
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
              Expanded(
                child: Text(
                  title,
                  style: textTheme.headlineMedium,
                ),
              ),
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
