import 'package:flutter/material.dart';
import '../models/dish.dart';

/// Lightweight dish card for preview display in restaurant detail.
/// Shows image, name, price, and optional dietary badge.
class DishCard extends StatelessWidget {
  final Dish dish;
  final Color accentColor;
  final Color bgColor;
  final VoidCallback? onTap;

  const DishCard({
    super.key,
    required this.dish,
    required this.accentColor,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with fallback
            _DishImage(
              images: dish.images,
              accentColor: accentColor,
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      dish.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF1A1A1A),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Description (1 line max)
                    if (dish.description != null && dish.description!.isNotEmpty)
                      Text(
                        dish.description!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Bottom: Price + Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '€${dish.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: accentColor,
                          ),
                        ),
                        // Dietary badge
                        if (dish.dietaryFlags.isNotEmpty)
                          _DietaryBadge(
                            flag: dish.dietaryFlags.first,
                            accentColor: accentColor,
                            bgColor: bgColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays dish image with lazy loading and fallback.
class _DishImage extends StatelessWidget {
  final List<String> images;
  final Color accentColor;

  const _DishImage({
    required this.images,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = images.isNotEmpty && images.first.isNotEmpty;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                images.first,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _FallbackIcon(accentColor: accentColor),
              ),
            )
          : _FallbackIcon(accentColor: accentColor),
    );
  }
}

/// Fallback icon when image is unavailable.
class _FallbackIcon extends StatelessWidget {
  final Color accentColor;

  const _FallbackIcon({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.fastfood_rounded,
        color: accentColor.withValues(alpha: 0.4),
        size: 36,
      ),
    );
  }
}

/// Small dietary flag badge.
class _DietaryBadge extends StatelessWidget {
  final String flag;
  final Color accentColor;
  final Color bgColor;

  const _DietaryBadge({
    required this.flag,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _getDietaryIcon(flag);
    final shortLabel = _getDietaryShortLabel(flag);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: accentColor),
          const SizedBox(width: 2),
          Text(
            shortLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getDietaryShortLabel(String flag) {
    switch (flag.toLowerCase()) {
      case 'vegan':
        return 'V';
      case 'vegetarian':
        return 'Veg';
      case 'gluten-free':
        return 'GF';
      case 'halal':
        return 'H';
      case 'kosher':
        return 'K';
      case 'dairy-free':
        return 'DF';
      case 'nut-free':
        return 'NF';
      default:
        return flag.substring(0, 1).toUpperCase();
    }
  }

  IconData _getDietaryIcon(String flag) {
    switch (flag.toLowerCase()) {
      case 'vegan':
      case 'vegetarian':
        return Icons.eco_rounded;
      case 'gluten-free':
        return Icons.grain_rounded;
      case 'dairy-free':
        return Icons.local_cafe_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }
}

