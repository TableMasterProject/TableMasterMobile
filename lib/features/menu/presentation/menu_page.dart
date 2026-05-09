import 'package:flutter/material.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/features/menu/domain/repositories/menu_repository.dart';
import 'package:table_master_mobile/features/menu/data/models/menu_in.dart';
import 'package:table_master_mobile/features/menu/data/models/menu_out.dart';

class MenuPage extends StatefulWidget {
  final int restaurantId;

  const MenuPage({super.key, required this.restaurantId});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final _repo = getIt<IMenuRepository>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _loading = false;
  String? _error;
  List<MenuOut> _menus = [];

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final menus = await _repo.getByRestaurant(widget.restaurantId);
      setState(() => _menus = menus);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addMenu() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nom requis')));
      return;
    }
    try {
      final menu = MenuIn(
        restaurantId: widget.restaurantId,
        itemName: _nameController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        category:
            _categoryController.text.isEmpty
                ? 'Général'
                : _categoryController.text,
      );
      await _repo.create(menu);
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _categoryController.clear();
      await _loadMenus();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Menu ajouté')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _deleteMenu(int id) async {
    try {
      await _repo.delete(id);
      await _loadMenus();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Menu supprimé')));
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
      appBar: AppBar(title: const Text('Gérer le menu')),
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
                          'Ajouter un plat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Nom du plat',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            hintText: 'Catégorie (Entrée, Plat, Dessert...)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            hintText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            hintText: 'Prix (€)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addMenu,
                            child: const Text('Ajouter'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child:
                        _menus.isEmpty
                            ? Center(
                              child: Text(
                                'Aucun menu',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            )
                            : ListView.separated(
                              itemCount: _menus.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (_, i) {
                                final m = _menus[i];
                                return ListTile(
                                  title: Text(m.itemName),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Catégorie: ${m.category}'),
                                      if (m.description.isNotEmpty)
                                        Text(m.description),
                                      Text(
                                        'Prix: ${m.price.toStringAsFixed(2)}€',
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: colors.error,
                                    ),
                                    onPressed: () => _deleteMenu(m.id),
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
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
