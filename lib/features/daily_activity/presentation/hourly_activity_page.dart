import 'package:flutter/material.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/features/daily_activity/domain/repositories/daily_activity_repository.dart';
import 'package:table_master_mobile/features/daily_activity/data/models/daily_activity_in.dart';
import 'package:table_master_mobile/features/daily_activity/data/models/daily_activity_out.dart';

class HourlyActivityPage extends StatefulWidget {
  final int restaurantId;

  const HourlyActivityPage({super.key, required this.restaurantId});

  @override
  State<HourlyActivityPage> createState() => _HourlyActivityPageState();
}

class _HourlyActivityPageState extends State<HourlyActivityPage> {
  final _repo = getIt<IDailyActivityRepository>();

  bool _loading = false;
  String? _error;
  List<DailyActivityOut> _activities = [];

  final List<String> _days = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];
  
  int? _selectedDay; // 1 = Lundi, ..., 7 = Dimanche
  final _openingController = TextEditingController();
  final _closingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final activities = await _repo.getByRestaurant(widget.restaurantId);
      // Tri par jour de la semaine
      activities.sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
      setState(() => _activities = activities);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String formatTime(String input) {
    // Si c'est juste un chiffre (ex: "8" ou "08")
    if (RegExp(r'^\d{1,2}$').hasMatch(input)) {
      int hour = int.parse(input);
      if (hour >= 0 && hour <= 23) {
        return "${hour.toString().padLeft(2, '0')}:00";
      }
    }

    // Si c'est déjà au format H:mm ou HH:mm (ex: "8:30" -> "08:30")
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(input)) {
      List<String> parts = input.split(':');
      return "${parts[0].padLeft(2, '0')}:${parts[1]}";
    }
    return input; // Retourne tel quel si c'est n'importe quoi (le regex validera après)
  }

  Future<void> _addOrUpdateActivity() async {
    if (_selectedDay == null ||
        _openingController.text.isEmpty ||
        _closingController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Remplir tous les champs')));
      return;
    }
    String opening = _openingController.text.trim();
    String closing = _closingController.text.trim();

    String finalOpening = formatTime(opening);
    String finalClosing = formatTime(closing);

    // Validation basique du format HH:mm
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(finalOpening) || !timeRegex.hasMatch(finalClosing)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Format d\'heure invalide (HH:mm)')));
      return;
    }

    try {
      final activity = DailyActivityIn(
        restaurantId: widget.restaurantId,
        dayOfWeek: _selectedDay!,
        startTime: "$finalOpening:00", // Format HH:mm:ss pour l'API
        endTime: "$finalClosing:00",
      );

      await _repo.create(activity);

      _selectedDay = null;
      _openingController.clear();
      _closingController.clear();
      await _loadActivities();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Horaire enregistré avec succès')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _deleteActivity(int id) async {
    try {
      await _repo.delete(id);
      await _loadActivities();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Horaire supprimé')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Gérer les horaires')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text('Erreur: $_error'))
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajouter/modifier un horaire',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedDay,
                          items: List.generate(7, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text(_days[index]),
                            );
                          }),
                          onChanged: (val) => setState(() => _selectedDay = val),
                          decoration: const InputDecoration(
                            labelText: 'Jour de la semaine',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _openingController,
                                decoration: const InputDecoration(
                                  labelText: 'Ouverture',
                                  hintText: 'HH:MM',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.datetime,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _closingController,
                                decoration: const InputDecoration(
                                  labelText: 'Fermeture',
                                  hintText: 'HH:MM',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.datetime,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addOrUpdateActivity,
                            icon: const Icon(Icons.save),
                            label: const Text('Enregistrer'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      "Horaires actuels",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        _activities.isEmpty
                            ? Center(
                              child: Text(
                                'Aucun horaire configuré',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            )
                            : ListView.separated(
                              itemCount: _activities.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final a = _activities[index];
                                return ListTile(
                                  leading: const Icon(Icons.access_time),
                                  title: Text(
                                    _days[(a.dayOfWeek - 1) % 7],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${a.startTime.substring(0, 5)} - ${a.endTime.substring(0, 5)}',
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: colors.error,
                                    ),
                                    onPressed: () => _deleteActivity(a.id),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedDay = a.dayOfWeek;
                                      _openingController.text = a.startTime.substring(0, 5);
                                      _closingController.text = a.endTime.substring(0, 5);
                                    });
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  @override
  void dispose() {
    _openingController.dispose();
    _closingController.dispose();
    super.dispose();
  }
}
