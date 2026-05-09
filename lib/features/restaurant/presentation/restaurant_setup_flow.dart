import 'package:flutter/material.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step4_restaurant_info_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step5_table_management_screen.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_in.dart';
import 'package:table_master_mobile/features/restaurant/domain/repositories/restaurant_repository.dart';
import 'package:table_master_mobile/features/room/domain/repositories/room_repository.dart';
import 'package:table_master_mobile/features/table/data/models/table_changes.dart';
import 'package:table_master_mobile/features/table/domain/repositories/table_repository.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';

class RestaurantSetupFlow extends StatefulWidget {
  final UserOut user;
  final IRestaurantRepository restaurantRepository;
  final ITableRepository tableRepository;
  final IRoomRepository roomRepository;

  const RestaurantSetupFlow({
    super.key,
    required this.user,
    required this.restaurantRepository,
    required this.tableRepository,
    required this.roomRepository,
  });

  @override
  State<RestaurantSetupFlow> createState() => _RestaurantSetupFlowState();
}

class _RestaurantSetupFlowState extends State<RestaurantSetupFlow> {
  final PageController _pageController = PageController();
  late RestaurantIn _restaurantData;
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _restaurantData = RestaurantIn(
      userId: widget.user.id,
      restaurantName: '',
      streetNumber: '',
      streetName: '',
      postalCode: '',
      city: '',
      phone: '',
      cuisineType: '',
      paymentMethods: '',
      description: '',
      isAutoValidateReservation: false,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _saveRestaurantStep(RestaurantIn restaurant) {
    _restaurantData = restaurant.copyWith(userId: widget.user.id);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveTablesStep(TableChanges changes) async {
    setState(() => _isLoading = true);

    try {
      final createdRestaurant = await widget.restaurantRepository.createRestaurant(
        _restaurantData.copyWith(userId: widget.user.id),
      );

      if (changes.layouts.isNotEmpty) {
        for (var i = 0; i < changes.layouts.length; i++) {
          final draft = changes.layouts[i];
          final defaultRoom = createdRestaurant.rooms?.isNotEmpty == true
              ? createdRestaurant.rooms!.first
              : null;
          final roomId = draft.roomId ??
              (i == 0
                  ? defaultRoom?.id
                  : (await widget.roomRepository.addRoom(
                      createdRestaurant.id,
                      draft.room.copyWith(restaurantId: createdRestaurant.id),
                    ))
                      .id);

          if (roomId == null) continue;

          await widget.roomRepository.saveLayout(
            roomId,
            draft.layout
              ..room.restaurantId = createdRestaurant.id
              ..room.sortOrder = i,
          );
        }
      } else if (changes.toAdd.isNotEmpty) {
        final tables = changes.toAdd.map((table) => table.copyWith(restaurantId: createdRestaurant.id)).toList();
        await widget.tableRepository.replaceTables(createdRestaurant.id, tables);
      }

      final restaurant = await widget.restaurantRepository.getRestaurantDetails(
        createdRestaurant.id,
      );

      if (!mounted) return;
      Navigator.pop(context, restaurant);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _back() {
    if (_isLoading) return;

    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = (_currentStep + 1) / 2;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _back();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: colors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isLoading ? null : _back,
          ),
          title: Text(
            "Restaurant - étape ${_currentStep + 1} sur 2",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6.0),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  Step4RestaurantInfoScreen(
                    onNext: _saveRestaurantStep,
                    restaurantIn: _restaurantData,
                  ),
                  Step5TableManagementScreen(
                    onNext: _saveTablesStep,
                    initialTables: null,
                    initialRooms: null,
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              "Création en cours...",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
