import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_master_mobile/features/room/data/models/restaurant_room_in.dart';
import 'package:table_master_mobile/features/room/data/models/restaurant_room_layout.dart';
import 'package:table_master_mobile/features/room/data/models/restaurant_room_out.dart';
import 'package:table_master_mobile/features/room/data/models/room_point.dart';
import 'package:table_master_mobile/features/room/presentation/widgets/room_plan_canvas.dart';
import 'package:table_master_mobile/features/table/data/models/table_changes.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_in.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';

class Step5TableManagementScreen extends StatefulWidget {
  final Function(TableChanges changes) onNext;
  final List<TableEntityOut>? initialTables;
  final List<RestaurantRoomOut>? initialRooms;

  const Step5TableManagementScreen({
    super.key,
    required this.onNext,
    this.initialTables,
    this.initialRooms,
  });

  @override
  State<Step5TableManagementScreen> createState() =>
      _Step5TableManagementScreenState();
}

class _Step5TableManagementScreenState
    extends State<Step5TableManagementScreen> {
  late List<_RoomDraft> _rooms;
  int _selectedRoomIndex = 0;
  TableEntityIn? _selectedTable;
  int _layoutRevision = 0;
  final ScrollController _scrollController = ScrollController();
  final Set<int> _deletedRoomIds = {};

  _RoomDraft get _currentRoom => _rooms[_selectedRoomIndex];

  @override
  void initState() {
    super.initState();
    _rooms = _createInitialDrafts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<_RoomDraft> _createInitialDrafts() {
    final initialRooms = widget.initialRooms;
    final initialTables = widget.initialTables ?? [];

    if (initialRooms != null && initialRooms.isNotEmpty) {
      return initialRooms.map((room) {
        final tables = List<TableEntityIn>.from(
          initialTables
              .where(
                (table) =>
                    table.roomId == room.id ||
                    (table.roomId == null && room == initialRooms.first),
              )
              .map(_cloneTable),
        );
        return _RoomDraft(
          id: room.id,
          room: RestaurantRoomIn(
            restaurantId: room.restaurantId,
            name: room.name,
            sortOrder: room.sortOrder,
            boundaryPoints:
                room.boundaryPoints
                    .map((p) => RoomPoint(x: p.x, y: p.y))
                    .toList(),
          ),
          tables: tables,
        );
      }).toList();
    }

    if (initialTables.isNotEmpty) {
      return [
        _RoomDraft(
          room: RestaurantRoomIn.defaultRoom(),
          tables: List<TableEntityIn>.from(initialTables.map(_cloneTable)),
        ),
      ];
    }

    final firstTable = TableEntityIn(
      restaurantId: 0,
      tableNumber: 1,
      numberOfSeats: 2,
      shape: TableShape.square,
      positionX: 0.18,
      positionY: 0.18,
      width: 0.14,
      height: 0.14,
    );
    return [
      _RoomDraft(room: RestaurantRoomIn.defaultRoom(), tables: [firstTable]),
    ];
  }

  TableEntityOut _cloneTable(TableEntityOut table) {
    return TableEntityOut(
      id: table.id,
      createdAt: table.createdAt,
      restaurantId: table.restaurantId,
      roomId: table.roomId,
      tableNumber: table.tableNumber,
      numberOfSeats: table.numberOfSeats,
      shape: table.shape,
      positionX: table.positionX,
      positionY: table.positionY,
      width: table.width,
      height: table.height,
      rotationDegrees: table.rotationDegrees,
    );
  }

  void _addRoom() {
    setState(() {
      _rooms.add(
        _RoomDraft(
          room: RestaurantRoomIn.defaultRoom().copyWith(
            name: 'Salle ${_rooms.length + 1}',
            sortOrder: _rooms.length,
          ),
        ),
      );
      _selectedRoomIndex = _rooms.length - 1;
      _selectedTable = null;
    });
  }

  void _deleteRoom() {
    if (_rooms.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez garder au moins une salle.')),
      );
      return;
    }
    if (_currentRoom.tables.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Supprimez les tables de cette salle avant de la retirer.',
          ),
        ),
      );
      return;
    }
    setState(() {
      if (_currentRoom.id != null) _deletedRoomIds.add(_currentRoom.id!);
      _rooms.removeAt(_selectedRoomIndex);
      _selectedRoomIndex =
          (_selectedRoomIndex - 1).clamp(0, _rooms.length - 1).toInt();
      _selectedTable = null;
    });
  }

  void _addTable() {
    late int addedTableNumber;
    setState(() {
      final numbers = _rooms
          .expand((room) => room.tables)
          .map((table) => table.tableNumber);
      final nextNumber =
          numbers.isEmpty ? 1 : numbers.reduce((a, b) => a > b ? a : b) + 1;
      addedTableNumber = nextNumber;
      final position = _nextTablePosition();
      final table = TableEntityIn(
        restaurantId: 0,
        roomId: _currentRoom.id,
        tableNumber: nextNumber,
        numberOfSeats: 2,
        shape: TableShape.square,
        positionX: position.x,
        positionY: position.y,
        width: 0.14,
        height: 0.14,
      );
      _currentRoom.tables.add(table);
      _selectedTable = table;
      _layoutRevision++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Table $addedTableNumber ajoutée.')),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  RoomPoint _nextTablePosition() {
    final positions = [
      RoomPoint(x: 0.12, y: 0.14),
      RoomPoint(x: 0.34, y: 0.14),
      RoomPoint(x: 0.56, y: 0.14),
      RoomPoint(x: 0.78, y: 0.14),
      RoomPoint(x: 0.12, y: 0.36),
      RoomPoint(x: 0.34, y: 0.36),
      RoomPoint(x: 0.56, y: 0.36),
      RoomPoint(x: 0.78, y: 0.36),
      RoomPoint(x: 0.12, y: 0.58),
      RoomPoint(x: 0.34, y: 0.58),
      RoomPoint(x: 0.56, y: 0.58),
      RoomPoint(x: 0.78, y: 0.58),
      RoomPoint(x: 0.12, y: 0.78),
      RoomPoint(x: 0.34, y: 0.78),
      RoomPoint(x: 0.56, y: 0.78),
      RoomPoint(x: 0.78, y: 0.78),
    ];

    for (final position in positions) {
      final occupied = _currentRoom.tables.any(
        (table) =>
            (table.positionX - position.x).abs() < 0.08 &&
            (table.positionY - position.y).abs() < 0.08,
      );
      if (!occupied) return position;
    }

    final offset = (_currentRoom.tables.length % 6) * 0.04;
    return RoomPoint(x: 0.12 + offset, y: 0.12 + offset);
  }

  void _deleteSelectedTable() {
    final table = _selectedTable;
    if (table == null) return;

    setState(() {
      _currentRoom.tables.remove(table);
      if (table is TableEntityOut) {
        _currentRoom.deletedTableIds.add(table.id);
      }
      _selectedTable = null;
    });
  }

  bool _hasDuplicateTableNumbers() {
    final numbers =
        _rooms
            .expand((room) => room.tables)
            .map((table) => table.tableNumber)
            .toList();
    return numbers.length != numbers.toSet().length;
  }

  TableChanges _buildChanges() {
    final layouts =
        _rooms.map((draft) {
          final tablesToAdd =
              draft.tables
                  .whereType<TableEntityIn>()
                  .where((t) => t is! TableEntityOut)
                  .toList();
          final tablesToUpdate =
              draft.tables.whereType<TableEntityOut>().toList();
          final layout = RestaurantRoomLayoutIn(
            room: draft.room,
            tablesToAdd: tablesToAdd,
            tablesToUpdate: tablesToUpdate,
            tableIdsToDelete: draft.deletedTableIds.toList(),
          );
          return RoomLayoutDraft(
            roomId: draft.id,
            room: draft.room,
            layout: layout,
          );
        }).toList();

    return TableChanges(
      toAdd: layouts.expand((layout) => layout.layout.tablesToAdd).toList(),
      toUpdate:
          layouts.expand((layout) => layout.layout.tablesToUpdate).toList(),
      toDelete: const [],
      layouts: layouts,
      roomIdsToDelete: _deletedRoomIds.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedTable = _selectedTable;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Plan de salle',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton.filledTonal(
                onPressed: _addRoom,
                icon: const Icon(Icons.add_business_outlined),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _deleteRoom,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _rooms.asMap().entries.map((entry) {
                    final selected = entry.key == _selectedRoomIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: selected,
                        label: Text(entry.value.room.name),
                        onSelected:
                            (_) => setState(() {
                              _selectedRoomIndex = entry.key;
                              _selectedTable = null;
                            }),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _currentRoom.room.name,
            key: ValueKey('room-name-${_currentRoom.id}-$_selectedRoomIndex'),
            decoration: const InputDecoration(
              labelText: 'Nom de la salle',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => _currentRoom.room.name = value,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _addTable,
                  icon: const Icon(Icons.table_bar_outlined),
                  label: const Text('Ajouter une table'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed:
                    () => setState(() {
                      _currentRoom.room.boundaryPoints.add(
                        RoomPoint(x: 0.5, y: 0.5),
                      );
                    }),
                icon: const Icon(Icons.control_point),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: [
                RoomPlanCanvas(
                  key: ValueKey(
                    'room-${_currentRoom.id ?? _selectedRoomIndex}-${_currentRoom.tables.length}-$_layoutRevision',
                  ),
                  boundaryPoints: _currentRoom.room.boundaryPoints,
                  tables: _currentRoom.tables,
                  isEditing: true,
                  selectedDraftTable: selectedTable,
                  onTableSelected:
                      (table) => setState(() => _selectedTable = table),
                  onTableMoved:
                      (table, x, y) => setState(() {
                        table.positionX = x;
                        table.positionY = y;
                      }),
                  onBoundaryPointMoved:
                      (index, x, y) => setState(() {
                        _currentRoom.room.boundaryPoints[index] = RoomPoint(
                          x: x,
                          y: y,
                        );
                      }),
                ),
                if (selectedTable != null) ...[
                  const SizedBox(height: 16),
                  _TableEditor(
                    key: ValueKey(_tableEditorKey(selectedTable)),
                    table: selectedTable,
                    onChanged: () => setState(() {}),
                    onDelete: _deleteSelectedTable,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                if (_hasDuplicateTableNumbers()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Plusieurs tables ont le même numéro.'),
                    ),
                  );
                  return;
                }
                widget.onNext(_buildChanges());
              },
              child: const Text('Sauvegarder le plan'),
            ),
          ),
          if (widget.initialTables == null)
            TextButton(
              onPressed:
                  () => widget.onNext(
                    TableChanges(toAdd: [], toUpdate: [], toDelete: []),
                  ),
              child: Text(
                'Passer cette étape',
                style: TextStyle(color: colors.secondary),
              ),
            ),
        ],
      ),
    );
  }

  String _tableEditorKey(TableEntityIn table) {
    if (table is TableEntityOut) return 'table-${table.id}';
    return 'draft-${identityHashCode(table)}';
  }
}

class _TableEditor extends StatelessWidget {
  final TableEntityIn table;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _TableEditor({
    super.key,
    required this.table,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: table.tableNumber.toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'N table'),
                    onChanged: (value) {
                      table.tableNumber =
                          int.tryParse(value) ?? table.tableNumber;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<TableShape>(
              segments: const [
                ButtonSegment(
                  value: TableShape.square,
                  icon: Icon(Icons.crop_square),
                  label: Text('Carree'),
                ),
                ButtonSegment(
                  value: TableShape.rectangle,
                  icon: Icon(Icons.table_bar),
                  label: Text('Rect.'),
                ),
                ButtonSegment(
                  value: TableShape.circle,
                  icon: Icon(Icons.circle_outlined),
                  label: Text('Ronde'),
                ),
              ],
              selected: {table.shape},
              onSelectionChanged: (selection) {
                table.shape = selection.first;
                if (table.shape == TableShape.circle ||
                    table.shape == TableShape.square) {
                  table.height = table.width;
                }
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed:
                      table.numberOfSeats > 1
                          ? () {
                            table.numberOfSeats--;
                            onChanged();
                          }
                          : null,
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    '${table.numberOfSeats} places',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {
                    table.numberOfSeats++;
                    onChanged();
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            _SliderRow(
              label: 'Largeur',
              value: table.width,
              min: 0.08,
              max: 0.35,
              onChanged: (value) {
                table.width = value;
                if (table.shape != TableShape.rectangle) table.height = value;
                onChanged();
              },
            ),
            _SliderRow(
              label: 'Hauteur',
              value: table.height,
              min: 0.08,
              max: 0.35,
              onChanged:
                  table.shape == TableShape.rectangle
                      ? (value) {
                        table.height = value;
                        onChanged();
                      }
                      : null,
            ),
            _SliderRow(
              label: 'Rotation',
              value: table.rotationDegrees,
              min: 0,
              max: 360,
              onChanged: (value) {
                table.rotationDegrees = value;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _RoomDraft {
  final int? id;
  final RestaurantRoomIn room;
  final List<TableEntityIn> tables;
  final Set<int> deletedTableIds = {};

  _RoomDraft({this.id, required this.room, List<TableEntityIn>? tables})
    : tables = tables ?? [];
}
