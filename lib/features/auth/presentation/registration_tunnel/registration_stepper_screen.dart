import 'package:flutter/material.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step1_user_info_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step2_password_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step3_account_type_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step4_restaurant_info_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step5_table_management_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step6_success_screen.dart';

class RegistrationStepperScreen extends StatefulWidget {
  const RegistrationStepperScreen({super.key});

  @override
  State<RegistrationStepperScreen> createState() => _RegistrationStepperScreenState();
}

class _RegistrationStepperScreenState extends State<RegistrationStepperScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // 1. On suit si l'utilisateur est un restaurant ou non
  bool _isRestaurant = false;

  // Fonction pour définir le type et avancer
  void _setAccountType(bool isRestaurant) {
    setState(() {
      _isRestaurant = isRestaurant;
    });
    _nextStep();
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // 2. On construit la liste des pages dynamiquement
    final List<Widget> steps = [
      Step1UserInfoScreen(onNext: _nextStep),
      Step2PasswordScreen(onNext: _nextStep),
      Step3AccountTypeScreen(onSelectType: _setAccountType), // On passe la nouvelle fonction

      // On ajoute ces étapes UNIQUEMENT si c'est un restaurant
      if (_isRestaurant) ...[
        Step4RestaurantInfoScreen(onNext: _nextStep),
        Step5TableManagementScreen(onNext: _nextStep),
      ],

      Step6SuccessScreen(finish: _finish),
    ];

    // 3. Le nombre total de pages change selon le type de compte
    int totalSteps = steps.length;
    double progress = (_currentStep + 1) / totalSteps;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
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
    );
  }
}