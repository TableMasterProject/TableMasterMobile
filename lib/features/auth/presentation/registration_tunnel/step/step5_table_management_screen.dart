import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_master_mobile/features/table/data/models/table_changes.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';
import '../../../../table/data/models/table_entity_in.dart';

class Step5TableManagementScreen extends StatefulWidget {
  final Function(TableChanges changes) onNext;
  final List<TableEntityOut>? initialTables;

  const Step5TableManagementScreen({super.key, required this.onNext, this.initialTables});

  @override
  State<Step5TableManagementScreen> createState() => _Step5TableManagementScreenState();
}

class _Step5TableManagementScreenState extends State<Step5TableManagementScreen> {
  // Liste complète pour l'affichage (typée explicitement pour accepter In et Out)
  late List<TableEntityIn> _allTables;

  // Listes de suivi des changements au fil de l'eau
  final List<TableEntityIn> _toAdd = [];
  final List<TableEntityOut> _toUpdate = [];
  final List<TableEntityOut> _toDelete = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialTables != null && widget.initialTables!.isNotEmpty) {
      // On clone les tables initiales pour pouvoir comparer les modifications
      // List<TableEntityIn>.from garantit qu'on peut ajouter des nouveaux TableEntityIn plus tard
      _allTables = List<TableEntityIn>.from(widget.initialTables!.map((t) => TableEntityOut(
        id: t.id,
        createdAt: t.createdAt,
        restaurantId: t.restaurantId,
        tableNumber: t.tableNumber,
        numberOfSeats: t.numberOfSeats,
      )));
    } else {
      final firstTable = TableEntityIn(restaurantId: 0, tableNumber: 1, numberOfSeats: 2);
      _allTables = [firstTable];
      _toAdd.add(firstTable);
    }
  }

  /// Appelé à chaque modification de données pour classer la table dans toUpdate si besoin
  void _onTableDataChanged(TableEntityIn table) {
    if (table is TableEntityOut) {
      // C'est une table existante, on vérifie si elle diffère de l'originale
      final original = widget.initialTables?.firstWhere((t) => t.id == table.id);
      if (original != null) {
        final hasChanged = original.tableNumber != table.tableNumber ||
            original.numberOfSeats != table.numberOfSeats;

        setState(() {
          if (hasChanged) {
            if (!_toUpdate.any((t) => t.id == table.id)) {
              _toUpdate.add(table);
            }
          } else {
            _toUpdate.removeWhere((t) => t.id == table.id);
          }
        });
      }
    }
    // Si c'est une TableEntityIn (nouvelle), elle est déjà dans _toAdd 
    // et l'objet est mis à jour par référence.
  }

  void _addTable() {
    setState(() {
      int nextNum = _allTables.isEmpty
          ? 1
          : _allTables.map((t) => t.tableNumber).reduce((a, b) => a > b ? a : b) + 1;

      final newTable = TableEntityIn(
        restaurantId: widget.initialTables?.firstOrNull?.restaurantId ?? 0,
        tableNumber: nextNum,
        numberOfSeats: 2,
      );

      _allTables.add(newTable);
      _toAdd.add(newTable);
    });
  }

  void _removeTable(int index) {
    if (_allTables.length > 1) {
      setState(() {
        final removed = _allTables.removeAt(index);
        if (removed is TableEntityOut) {
          // Si on supprime une table existante : on l'enlève de toUpdate et on l'ajoute à toDelete
          _toUpdate.removeWhere((t) => t.id == removed.id);
          _toDelete.add(removed);
        } else {
          // Si on supprime une nouvelle table pas encore enregistrée : on l'enlève juste de toAdd
          _toAdd.remove(removed);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous devez configurer au moins une table.")),
      );
    }
  }

  bool _hasDuplicateTableNumbers() {
    final numbers = _allTables.map((t) => t.tableNumber).toList();
    return numbers.length != numbers.toSet().length;
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

          // En-tête
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
              itemCount: _allTables.length,
              itemBuilder: (context, index) {
                final table = _allTables[index];

                return Padding(
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
                            setState(() {
                              table.tableNumber = int.tryParse(val) ?? 0;
                              _onTableDataChanged(table);
                            });
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
                                  if (table.numberOfSeats > 1) {
                                    table.numberOfSeats--;
                                    _onTableDataChanged(table);
                                  }
                                }),
                              ),
                              Text("${table.numberOfSeats}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 20),
                                onPressed: () => setState(() {
                                  table.numberOfSeats++;
                                  _onTableDataChanged(table);
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // SUPPRIMER LA LIGNE
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

          SizedBox(
            width: double.infinity,
            height: 55,
            child: FilledButton(
              onPressed: () {
                if (_hasDuplicateTableNumbers()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Erreur : Plusieurs tables ont le même numéro."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  widget.onNext(TableChanges(
                    toAdd: _toAdd,
                    toUpdate: _toUpdate,
                    toDelete: _toDelete,
                  ));
                }
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Sauvegarder les modifications",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.initialTables == null)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  widget.onNext(TableChanges(toAdd: [], toUpdate: [], toDelete: []));
                },
                child: Text(
                  "Passer cette étape",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.secondary, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
