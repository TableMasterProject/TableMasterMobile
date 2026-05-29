import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Description d'une entrée de navigation, indépendante du widget de navigation utilisé.
class NavDestination {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final GlobalKey? tutorialKey;

  const NavDestination({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.tutorialKey,
  });
}

/// Scaffold qui adapte sa navigation principale selon la taille d'écran :
/// - mobile : BottomNavigationBar
/// - tablet : NavigationRail compact
/// - desktop / wide : NavigationRail étendu (labels visibles)
///
/// L'AppBar et le contenu sont fournis par l'appelant.
class ResponsiveScaffold extends StatelessWidget {
  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? railLeading;
  final Widget? railTrailing;

  const ResponsiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.railLeading,
    this.railTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final size = context.screenSize;

    if (size == ScreenSize.mobile) {
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onDestinationSelected,
          type: BottomNavigationBarType.fixed,
          items:
              destinations.asMap().entries.map((entry) {
                final index = entry.key;
                final destination = entry.value;
                final icon =
                    index == selectedIndex
                        ? destination.activeIcon ?? destination.icon
                        : destination.icon;

                return BottomNavigationBarItem(
                  icon: _TutorialTarget(
                    targetKey: destination.tutorialKey,
                    child: Icon(icon),
                  ),
                  label: destination.label,
                );
              }).toList(),
        ),
      );
    }

    final extended = size == ScreenSize.desktop || size == ScreenSize.wide;

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          _Rail(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: extended,
            leading: railLeading,
            trailing: railTrailing,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool extended;
  final Widget? leading;
  final Widget? trailing;

  const _Rail({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.extended,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended,
      labelType:
          extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      minWidth: 72,
      minExtendedWidth: 220,
      leading: leading,
      trailing: trailing,
      destinations:
          destinations.asMap().entries.map((entry) {
            final index = entry.key;
            final destination = entry.value;
            final icon =
                index == selectedIndex
                    ? destination.activeIcon ?? destination.icon
                    : destination.icon;

            return NavigationRailDestination(
              icon: _TutorialTarget(
                targetKey: destination.tutorialKey,
                child: Icon(icon),
              ),
              label: Text(destination.label),
            );
          }).toList(),
    );
  }
}

class _TutorialTarget extends StatelessWidget {
  final GlobalKey? targetKey;
  final Widget child;

  const _TutorialTarget({required this.targetKey, required this.child});

  @override
  Widget build(BuildContext context) {
    if (targetKey == null) {
      return child;
    }

    return KeyedSubtree(key: targetKey, child: child);
  }
}
