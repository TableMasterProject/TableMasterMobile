import 'package:flutter/material.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step1_user_info_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step2_password_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step3_account_type_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step4_restaurant_info_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step5_table_management_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step6_error_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step6_success_screen.dart';

import '../../../../core/models/restaurant_in.dart';
import '../../../../core/models/table_entity_in.dart';
import '../../../../core/models/user_in.dart';

class RegistrationStepperScreen extends StatefulWidget {
  const RegistrationStepperScreen({super.key});

  @override
  State<RegistrationStepperScreen> createState() => _RegistrationStepperScreenState();
}

class _RegistrationStepperScreenState extends State<RegistrationStepperScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  int totalSteps = 4;
  bool _isRestaurant = false;
  bool _hasError = false;
  String _errorMessage = "";

  // --- NOS DONNÉES CENTRALISÉES ---
  late UserIn userData;
  late RestaurantIn restaurantData;
  List<TableEntityIn> tablesData = [];

  @override
  void initState() {
    super.initState();
    // Initialisation par défaut
    userData = UserIn(email: '', password: '', firstName: '', lastName: '', accountType: 0);
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

  void _nextStep() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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

  void _saveTablesStep(List<TableEntityIn> tables) {
    tablesData = tables;
    _submitRestaurantRegistration(); // Appel final
  }

  void _submitUserRegistration() {
    setState(() => _hasError = false); // Reset avant l'appel
    try {
      print("Envoi au serveur le user ...");
      // Simulation appel API réussi
      _nextStep();
    } catch (ex) {
      setState(() {
        _hasError = true;
        _errorMessage = "Impossible de créer votre compte utilisateur.";
      });
      _nextStep(); // On avance quand même vers la dernière page (qui sera l'erreur)
    }
  }

  void _submitRestaurantRegistration() {
    setState(() => _hasError = false);
    try {
      print("Envoi au serveur le restaurant...");
      _nextStep();
    } catch (ex) {
      setState(() {
        _hasError = true;
        _errorMessage = "Une erreur est survenue lors de la configuration du restaurant.";
      });
      _nextStep();
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

  void _back(){
    if(!_hasError && _currentStep +1 == totalSteps){
      _finish();
    }
    else{
      _prevStep();
    }
  }


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // 2. On construit la liste des pages dynamiquement
    final List<Widget> steps = [
      Step1UserInfoScreen(onNext: _saveUserStep,user: userData,),
      Step2PasswordScreen(onNext: _savePasswordStep, password: userData.password,),
      Step3AccountTypeScreen(onSelectType: _setAccountType),

      if (_isRestaurant) ...[
        Step4RestaurantInfoScreen(onNext: _saveRestaurantStep, restaurantIn: restaurantData,),
        Step5TableManagementScreen(onNext: _saveTablesStep),
      ],

      // AFFICHAGE DYNAMIQUE DU RÉSULTAT FINAL
      _hasError ? Step6ErrorScreen(onRetry: _retry, errorMessage: _errorMessage,
      ) : Step6SuccessScreen(finish: _finish),
    ];

    // 3. Le nombre total de pages change selon le type de compte
    totalSteps = steps.length;
    double progress = (_currentStep + 1) / totalSteps;

    return PopScope(
      canPop: false, // On bloque le retour automatique du système
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _back();
      },
      child:Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: colors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _back,
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
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentStep = index),
            children: steps, // On utilise notre liste dynamique
          ),
        ),
      ),
    );
  }
}