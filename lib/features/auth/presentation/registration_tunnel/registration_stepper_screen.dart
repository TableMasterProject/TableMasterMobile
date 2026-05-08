import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:table_master_mobile/features/auth/data/models/login_user_out.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step1_user_info_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step2_password_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step3_account_type_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step4_restaurant_info_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step5_table_management_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step6_error_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step6_success_screen.dart';
import 'package:table_master_mobile/features/table/data/models/table_changes.dart';
import 'package:table_master_mobile/features/table/domain/repositories/table_repository.dart';
import 'package:table_master_mobile/features/user/domain/repositories/user_repository.dart';

import '../../../../core/injection.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../restaurant/data/models/restaurant_in.dart';
import '../../../restaurant/data/models/restaurant_out.dart';
import '../../../restaurant/domain/repositories/restaurant_repository.dart';
import '../../../table/data/models/table_entity_in.dart';
import '../../../table/data/models/table_entity_out.dart';
import '../../../user/data/models/user_in.dart';

class RegistrationStepperScreen extends StatefulWidget {
  const RegistrationStepperScreen({super.key});

  @override
  State<RegistrationStepperScreen> createState() =>
      _RegistrationStepperScreenState();
}

class _RegistrationStepperScreenState extends State<RegistrationStepperScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  int totalSteps = 4;
  bool _isRestaurant = false;
  bool _hasError = false;
  bool _isLoading = false;
  String _errorMessage = "";

  // les repo
  final userRepo = getIt<IUserRepository>();
  final restaurantRepo = getIt<IRestaurantRepository>();
  final tableRepo = getIt<ITableRepository>();

  // dataOut
  LoginUserOut? loginUserOut;
  RestaurantOut? restaurantOut;
  List<TableEntityOut>? tablesOut;

  // --- NOS DONNÉES CENTRALISÉES ---
  late UserIn userData;
  late RestaurantIn restaurantData;
  TableChanges? tableChanges;

  @override
  void initState() {
    super.initState();
    // Initialisation par défaut
    userData = UserIn(
      email: '',
      password: '',
      firstName: '',
      lastName: '',
      accountType: 0,
    );
    restaurantData = RestaurantIn(
      userId: 0,
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

  void _nextStep({bool isError = false}) {
    if (!isError) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final lastPageIndex = totalSteps - 1;

      _pageController.animateToPage(
        lastPageIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _finish() {
    Navigator.pop(context);
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _saveUserStep(UserIn user) {
    userData = user;
    _nextStep();
  }

  void _savePasswordStep(String password) {
    userData.password = password;
    _nextStep();
  }

  void _setAccountType(int type) {
    setState(() {
      userData.accountType = type;
      _isRestaurant = (type == 1);
    });
    _submitUserRegistration();
  }

  void _saveRestaurantStep(RestaurantIn data) {
    restaurantData = data;
    _nextStep();
  }

  void _saveTablesStep(TableChanges changes) {
    tableChanges = changes;
    _submitRestaurantRegistration(); // Appel final
  }

  void _submitUserRegistration() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    try {
      if (loginUserOut == null) {
        AppLogger.debug("Envoi au serveur le user");
        loginUserOut = await userRepo.register(userData);

        // Sauvegarder l'utilisateur
        const storage = FlutterSecureStorage();
        await storage.write(
          key: 'user_id',
          value: loginUserOut!.user.id.toString(),
        );
      }
      setState(() => _isLoading = false);
      _nextStep();
    } catch (ex) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = ex.toString();
      });
      _nextStep(
        isError: true,
      ); // On avance quand même vers la dernière page (qui sera l'erreur)
    }
  }

  void _submitRestaurantRegistration() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    try {
      if (restaurantOut == null && loginUserOut != null) {
        restaurantData.userId = loginUserOut!.user.id;
        restaurantOut = await restaurantRepo.createRestaurant(restaurantData);
      }

      if (restaurantOut != null && tableChanges != null && tableChanges!.toAdd.isNotEmpty) {
        // En création, on a surtout des toAdd
        await tableRepo.replaceTables(restaurantOut!.id, tableChanges!.toAdd);
      }

      setState(() => _isLoading = false);
      _nextStep();
    } catch (ex) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = ex.toString();
      });
      _nextStep(isError: true);
    }
  }

  // Fonction pour permettre à l'utilisateur de retenter
  void _retry() {
    setState(() {
      _hasError = false;
      _currentStep = 0; // Ou revenir à une étape précise
    });
    _pageController.jumpToPage(0);
  }

  void _back() {
    if (!_hasError && _currentStep + 1 == totalSteps) {
      _finish();
    } else {
      _prevStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // 2. On construit la liste des pages dynamiquement
    final List<Widget> steps = [
      Step1UserInfoScreen(onNext: _saveUserStep, user: userData),
      Step2PasswordScreen(
        onNext: _savePasswordStep,
        password: userData.password,
      ),
      Step3AccountTypeScreen(onSelectType: _setAccountType),

      if (_isRestaurant) ...[
        Step4RestaurantInfoScreen(
          onNext: _saveRestaurantStep,
          restaurantIn: restaurantData,
        ),
        Step5TableManagementScreen(onNext: _saveTablesStep, initialTables: null,),
      ],

      // AFFICHAGE DYNAMIQUE DU RÉSULTAT FINAL
      _hasError
          ? Step6ErrorScreen(onRetry: _retry, errorMessage: _errorMessage)
          : Step6SuccessScreen(finish: _finish),
    ];

    // 3. Le nombre total de pages change selon le type de compte
    totalSteps = steps.length;
    double progress = (_currentStep + 1) / totalSteps;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _isLoading) return; // Bloquer le retour si on charge
        _back();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: colors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isLoading ? null : _back, // Désactiver si chargement
          ),
          title: Text(
            "Étape ${_currentStep + 1} sur $totalSteps",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6.0),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ),
        // 2. Utilisation d'un Stack pour superposer le loader
        body: SafeArea(
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: steps,
              ),

              // Overlay de chargement
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
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
                              "Traitement en cours...",
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
