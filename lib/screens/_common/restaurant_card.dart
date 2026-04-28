import 'package:flutter/material.dart';
import 'package:ea_easyeat_flutter/models/restaurant.dart'; // Corrected package name case

class RestaurantCard extends StatefulWidget {
  final Restaurant restaurant;
  final String distance;
  final int pointsMultiplier;
  final bool hasSpecialOffer;
  final VoidCallback onClick;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.distance,
    required this.pointsMultiplier,
    this.hasSpecialOffer = false,
    required this.onClick,
  });

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onClick();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  SizedBox(
                    height: 192,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.restaurant.profile.image != null &&
                                  widget.restaurant.profile.image!.isNotEmpty
                              ? widget.restaurant.profile.image![0]
                              : 'https://via.placeholder.com/150',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[200]),
                        ),
                        // Gradient overlay
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name, Category & Rating
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.restaurant.profile.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.restaurant.profile.category.join(', '),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Rating badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.restaurant.profile.globalRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Divider
                        Divider(color: Colors.grey[200], height: 1),

                        const SizedBox(height: 12),

                        // Distance & Points Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Distance
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  widget.distance,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            // Points multiplier badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF97316),
                                    Color(0xFFEF4444),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.card_giftcard,
                                      size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.pointsMultiplier}x PUNTS',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Special Offer Badge (top right)
              if (widget.hasSpecialOffer)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department,
                            size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'OFERTA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}