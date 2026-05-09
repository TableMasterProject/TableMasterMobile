import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:table_master_mobile/features/review/data/models/search_reviews.dart';
import '../../data/models/review_in.dart';
import '../../data/models/review_out.dart';
import '../../domain/repositories/review_repository.dart';
import '../../../../core/injection.dart';

class RestaurantReviewsPage extends StatefulWidget {
  final int restaurantId;

  const RestaurantReviewsPage({super.key, required this.restaurantId});

  @override
  State<RestaurantReviewsPage> createState() => _RestaurantReviewsPageState();
}

class _RestaurantReviewsPageState extends State<RestaurantReviewsPage> {
  late IReviewRepository _reviewRepository;
  final storage = const FlutterSecureStorage();
  List<ReviewOut> _reviews = [];
  bool _isLoading = false;
  String? _error;
  int? _currentUserId;
  final SearchReviews _search = SearchReviews(offset: 0, pageSize: 50);

  @override
  void initState() {
    super.initState();
    _reviewRepository = getIt<IReviewRepository>();
    _loadUserAndReviews();
  }

  Future<void> _loadUserAndReviews() async {
    setState(() => _isLoading = true);
    try {
      // Récupérer le user_id du storage
      String? userIdStr = await storage.read(key: 'user_id');
      if (userIdStr != null) {
        final userId = int.parse(userIdStr);
        _currentUserId = userId;
      }

      final reviews = await _reviewRepository.getByRestaurant(
        widget.restaurantId,
        _search,
      );
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
    if (review.userId != _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez modifier que vos propres avis'),
        ),
      );
      return;
    }
    _showReviewDialog(review);
  }

  void _deleteReview(ReviewOut review) {
    if (review.userId != _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez supprimer que vos propres avis'),
        ),
      );
      return;
    }

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
                    await _reviewRepository.deleteReview(review.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Avis supprimé')),
                      );
                      _loadUserAndReviews();
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

                    if (_currentUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Utilisateur non identifié'),
                        ),
                      );
                      return;
                    }

                    final reviewIn = ReviewIn(
                      userId: _currentUserId!,
                      restaurantId: widget.restaurantId,
                      rating: rating,
                      comment:
                          commentController.text.isEmpty
                              ? null
                              : commentController.text,
                    );

                    if (review == null) {
                      await _reviewRepository.addReview(reviewIn);
                    } else {
                      await _reviewRepository.updateReview(review.id, reviewIn);
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            review == null ? 'Avis ajouté' : 'Avis modifié',
                          ),
                        ),
                      );
                      _loadUserAndReviews();
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
      appBar: AppBar(title: const Text('Avis du restaurant')),
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
                      onPressed: _loadUserAndReviews,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
              : _reviews.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [const Text('Aucun avis pour ce restaurant')],
                ),
              )
              : ListView.builder(
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  final isOwnReview = review.userId == _currentUserId;
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
                              if (isOwnReview)
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
