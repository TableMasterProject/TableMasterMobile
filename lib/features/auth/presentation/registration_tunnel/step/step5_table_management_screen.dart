import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/models/table_entity_in.dart';

class Step5TableManagementScreen extends StatefulWidget {
  final Function(List<TableEntityIn> tables) onNext;

  const Step5TableManagementScreen({super.key, required this.onNext});

  @override
  State<Step5TableManagementScreen> createState() => _Step5TableManagementScreenState();
}

class _Step5TableManagementScreenState extends State<Step5TableManagementScreen> {
  // Liste initiale utilisant ton modèle TableEntityIn
  final List<TableEntityIn> _tables = [
    TableEntityIn(restaurantId: 0, tableNumber: 1, numberOfSeats: 2),
  ];

  /// Vérifie si des doublons existent dans la liste entière
  bool _hasDuplicateTableNumbers() {
    final numbers = _tables.map((t) => t.tableNumber).toList();
    return numbers.length != numbers.toSet().length;
  }

  /// Vérifie les doublons spécifiquement pour une ligne lors de la saisie
  void _checkDuplicateAndWarn(int index, String value) {
    int? newNumber = int.tryParse(value);
    if (newNumber == null) return;

    bool isDuplicate = _tables.asMap().entries.any((entry) =>
    entry.key != index && entry.value.tableNumber == newNumber);

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Le numéro $newNumber est déjà utilisé par une autre table."),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addTable() {
    setState(() {
      // On calcule le prochain numéro suggéré (max actuel + 1) pour éviter les doublons par défaut
      int nextNum = _tables.isEmpty
          ? 1
          : _tables.map((t) => t.tableNumber).reduce((a, b) => a > b ? a : b) + 1;

      _tables.add(
        TableEntityIn(
          restaurantId: 0,
          tableNumber: nextNum,
          numberOfSeats: 2,
        ),
      );
    });
  }

  void _removeTable(int index) {
    if (_tables.length > 1) {
      setState(() {
        _tables.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous devez configurer au moins une table.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Plan de salle",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Définissez vos tables et leur capacité d'accueil.",
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // En-tête du tableau
          Row(
            children: [
              Expanded(flex: 2, child: Text("N° Table", style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary))),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: Center(child: Text("Sièges", style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)))),
              const Expanded(flex: 1, child: SizedBox()),
            ],
          ),
          const Divider(),

          Expanded(
            child: ListView.builder(
              itemCount: _tables.length,
              itemBuilder: (context, index) {
                final table = _tables[index];

                return Padding(
                  // ObjectKey est CRUCIAL pour que Flutter sache quel widget supprimer physiquement
                  key: ObjectKey(table),
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      // NUMÉRO DE TABLE
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: table.tableNumber.toString(),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (val) {
                            table.tableNumber = int.tryParse(val) ?? 0;
                          },
                          onFieldSubmitted: (val) => _checkDuplicateAndWarn(index, val),
                          onTapOutside: (event) {
                            FocusScope.of(context).unfocus();
                            _checkDuplicateAndWarn(index, table.tableNumber.toString());
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // CAPACITÉ (SIÈGES)
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 20),
                                onPressed: () => setState(() {
                                  if (table.numberOfSeats > 1) table.numberOfSeats--;
                                }),
                              ),
                              Text("${table.numberOfSeats}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 20),
                                onPressed: () => setState(() => table.numberOfSeats++),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // SUPPRIMER LA LIGNE SPÉCIFIQUE
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: Icon(Icons.delete_outline, color: colors.error),
                          onPressed: () => _removeTable(index),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // BOUTON AJOUTER
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addTable,
              icon: const Icon(Icons.add),
              label: const Text("Ajouter une table"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // BOUTON FINALISER AVEC VALIDATION FINALE
          SizedBox(
            width: double.infinity,
            height: 55,
            child: FilledButton(
              onPressed: () {
                if (_hasDuplicateTableNumbers()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Erreur : Plusieurs tables ont le même numéro."),
                      backgroundColor: colors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  widget.onNext(_tables);
                }
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Finaliser l'inscription",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}