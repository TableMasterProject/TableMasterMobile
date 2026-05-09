import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/features/closed_day_exception/domain/repositories/closed_day_exception_repository.dart';

import '../data/models/closed_day_exception_in.dart';
import '../data/models/closed_day_exception_out.dart';

class ExceptionsPage extends StatefulWidget {
  final int restaurantId;

  const ExceptionsPage({super.key, required this.restaurantId});

  @override
  State<ExceptionsPage> createState() => _ExceptionsPageState();
}

class _ExceptionsPageState extends State<ExceptionsPage> {
  final _repo = getIt<IClosedDayExceptionRepository>();

  bool _loading = false;
  String? _error;
  List<ClosedDayExceptionOut> _exceptions = [];

  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExceptions();
  }

  Future<void> _loadExceptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final exceptions = await _repo.getByRestaurant(widget.restaurantId);
      // Tri par date de début (plus proche en haut)
      exceptions.sort(
        (a, b) => a.exceptionDateBegin.compareTo(b.exceptionDateBegin),
      );
      setState(() => _exceptions = exceptions);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDateRange:
          (_startDate != null && _endDate != null)
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _addException() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionner une plage de dates')),
      );
      return;
    }
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Le motif est obligatoire')));
      return;
    }

    try {
      final exception = ClosedDayExceptionIn(
        restaurantId: widget.restaurantId,
        exceptionDateBegin: _startDate!,
        exceptionDateEnd: _endDate!,
        reason: _reasonController.text.trim(),
      );
      await _repo.create(exception);

      setState(() {
        _startDate = null;
        _endDate = null;
        _reasonController.clear();
      });

      await _loadExceptions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fermeture exceptionnelle ajoutée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _deleteException(int id) async {
    try {
      await _repo.delete(id);
      await _loadExceptions();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Exception supprimée')));
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
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Fermetures exceptionnelles')),
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
                          'Ajouter une période de fermeture',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            (_startDate == null || _endDate == null)
                                ? 'Sélectionner les dates'
                                : 'Du ${dateFormat.format(_startDate!)} au ${dateFormat.format(_endDate!)}',
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            labelText: 'Motif de la fermeture',
                            hintText: 'Ex: Travaux, Maladie, Congés...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _addException,
                            icon: const Icon(Icons.add),
                            label: const Text('Enregistrer la fermeture'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      "Fermetures prévues",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        _exceptions.isEmpty
                            ? Center(
                              child: Text(
                                'Aucune fermeture prévue',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            )
                            : ListView.separated(
                              itemCount: _exceptions.length,
                              padding: const EdgeInsets.only(bottom: 16),
                              separatorBuilder:
                                  (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final e = _exceptions[index];
                                final isExpired = e.exceptionDateEnd.isBefore(
                                  DateTime.now(),
                                );

                                return ListTile(
                                  leading: Icon(
                                    Icons.event_busy,
                                    color:
                                        isExpired ? Colors.grey : colors.error,
                                  ),
                                  title: Text(
                                    e.reason,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration:
                                          isExpired
                                              ? TextDecoration.lineThrough
                                              : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Du ${dateFormat.format(e.exceptionDateBegin)} au ${dateFormat.format(e.exceptionDateEnd)}',
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: colors.error,
                                    ),
                                    onPressed: () => _deleteException(e.id),
                                  ),
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
    _reasonController.dispose();
    super.dispose();
  }
}
