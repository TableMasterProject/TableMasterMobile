import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:table_master_mobile/features/auth/presentation/login/login_screen.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';
import '../../reservation/presentation/my_reservations_page.dart';
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
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  void _initializePages() {
    _pages = [
      MyReservationsPage(userId: widget.user.id,),
      const MapsPage(),
      AccountPage(user: widget.user, onLogout: _logout),
      if (widget.user.accountType == 1) RestaurantPage(user: widget.user),
    ];
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    // On vide les tokens en local
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');

    if (mounted) {
      // Redirection vers le login et nettoyage de la pile de navigation
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Déterminer si c'est un restaurant
    final isRestaurant = widget.user.accountType == 1;

    // Titres des pages selon l'index
    final pageTitles = [
      "Mes Réservations",
      "Trouver des Restaurants",
      "Mon Compte",
      if (isRestaurant) "Mon Restaurant",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${widget.user.firstName} ${widget.user.lastName}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    widget.user.accountType == 0 ? "Client" : "Restaurant",
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.event_note_outlined),
            activeIcon: const Icon(Icons.event_note),
            label: 'Réservations',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.location_on_outlined),
            activeIcon: const Icon(Icons.location_on),
            label: 'Restaurants',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'Mon Compte',
          ),
          if (isRestaurant)
            BottomNavigationBarItem(
              icon: const Icon(Icons.restaurant_outlined),
              activeIcon: const Icon(Icons.restaurant),
              label: 'Mon Restaurant',
            ),
        ],
      ),
    );
  }
}
