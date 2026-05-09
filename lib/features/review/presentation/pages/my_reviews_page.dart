import 'package:flutter/material.dart';
import '../../data/models/review_in.dart';
import '../../data/models/review_out.dart';
import '../../data/models/search_reviews.dart';
import '../../domain/repositories/review_repository.dart';
import '../../../../core/injection.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  late IReviewRepository _repository;
  List<ReviewOut> _reviews = [];
  bool _isLoading = false;
  String? _error;
  final SearchReviews _search = SearchReviews(offset: 0, pageSize: 50);

  @override
  void initState() {
    super.initState();
    _repository = getIt<IReviewRepository>();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final reviews = await _repository.getMyReviews(_search);
      setState(() {
        _reviews = reviews;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editReview(ReviewOut review) {
    _showReviewDialog(review);
  }

  void _deleteReview(ReviewOut review) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Supprimer l\'avis'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cet avis ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  try {
                    await _repository.deleteReview(review.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Avis supprimé')),
                      );
                      _loadReviews();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                    }
                  }
                },
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showReviewDialog(ReviewOut? review) {
    final ratingController = TextEditingController(
      text: review?.rating.toString() ?? '',
    );
    final commentController = TextEditingController(
      text: review?.comment ?? '',
    );

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              review == null ? 'Ajouter un avis' : 'Modifier l\'avis',
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ratingController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Note (0-5)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Commentaire',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  try {
                    final rating = int.tryParse(ratingController.text) ?? 0;
                    if (rating < 0 || rating > 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('La note doit être entre 0 et 5'),
                        ),
                      );
                      return;
                    }

                    if (review == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ID restaurant manquant')),
                      );
                      return;
                    }

                    final reviewIn = ReviewIn(
                      userId: review.userId,
                      restaurantId: review.restaurantId,
                      rating: rating,
                      comment:
                          commentController.text.isEmpty
                              ? null
                              : commentController.text,
                    );

                    await _repository.updateReview(review.id, reviewIn);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Avis modifié')),
                      );
                      _loadReviews();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes avis')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Erreur: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadReviews,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
              : _reviews.isEmpty
              ? const Center(child: Text('Vous n\'avez pas d\'avis'))
              : ListView.builder(
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    Icons.star,
                                    color:
                                        i < review.rating
                                            ? Colors.amber
                                            : Colors.grey[300],
                                    size: 18,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editReview(review),
                                    iconSize: 18,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteReview(review),
                                    iconSize: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (review.comment != null &&
                              review.comment!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(review.comment!),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              review.createdAt.toString().split('.')[0],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
