import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/features/review/data/models/review_out.dart';
import 'package:table_master_mobile/features/review/data/models/search_reviews.dart';
import 'package:table_master_mobile/features/review/domain/repositories/review_repository.dart';

class ReviewsPage extends StatefulWidget {
  final int? restaurantId; // Si null, affiche "Mes avis" (client)
  final String title;

  const ReviewsPage({super.key, this.restaurantId, required this.title});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final _repo = getIt<IReviewRepository>();
  bool _loading = false;
  String? _error;
  List<ReviewOut> _reviews = [];
  final SearchReviews _search = SearchReviews(offset: 0, pageSize: 50);

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reviews =
          widget.restaurantId != null
              ? await _repo.getByRestaurant(widget.restaurantId!, _search)
              : await _repo.getMyReviews(_search);

      // Tri par date (plus récent en haut)
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() => _reviews = reviews);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteReview(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Supprimer l'avis"),
            content: const Text(
              "Êtes-vous sûr de vouloir supprimer cet avis ?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Annuler"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Supprimer",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await _repo.deleteReview(id);
      await _loadReviews();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Avis supprimé")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text("Erreur: $_error"))
                : _reviews.isEmpty
                ? const Center(child: Text("Aucun avis pour le moment"))
                : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final r = _reviews[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      i < r.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 20,
                                    );
                                  }),
                                ),
                                Text(
                                  dateFormat.format(r.createdAt.toLocal()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              r.comment ?? "Pas de commentaire",
                              style: const TextStyle(fontSize: 15),
                            ),
                            if (widget.restaurantId == null) ...[
                              // Mode "Mes avis" (Client)
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteReview(r.id),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
