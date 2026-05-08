import 'package:flutter/material.dart';
import '../../models/restaurant.dart';
import '../../models/reward.dart';
import '../../services/restaurant_service.dart';
import '../../widgets/reward_card.dart';
import '../_customer/qr_code_screen.dart';


// ---------------------------------------------------------------------------
// PANTALLA PRINCIPAL
// ---------------------------------------------------------------------------

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  late Restaurant _restaurant;
  final RestaurantService _restaurantService = RestaurantService();
  late Future<List<Reward>> _rewardsFuture;

  // ...existing code...
  static const _orange = Color(0xFFFF6B35);
  static const _orangeLight = Color(0xFFFFF0EA);
  static const _bg = Color(0xFFF7F7F7);
  static const _textDark = Color(0xFF1A1A1A);
  static const _textMuted = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _restaurant = widget.restaurant;
    _rewardsFuture = _loadRewardsForCurrentRestaurant();
  }

  @override
  void didUpdateWidget(covariant RestaurantDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurant.id != widget.restaurant.id) {
      _restaurant = widget.restaurant;
      _rewardsFuture = _loadRewardsForCurrentRestaurant();
    }
  }

  Future<List<Reward>> _loadRewardsForCurrentRestaurant() {
    return _restaurantService.getRestaurantRewards(_restaurant.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // AppBar amb imatge de fons (hero)
          _RestaurantSliverAppBar(
            restaurant: _restaurant,
            accentColor: _orange,
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Capçalera: nom, categoria, rating, descripció
                _RestaurantHeaderSection(
                  restaurant: _restaurant,
                  accentColor: _orange,
                  orangeLight: _orangeLight,
                  textDark: _textDark,
                  textMuted: _textMuted,
                ),

                const _SectionDivider(),


                // Horaris + contacte + ubicació
                _RestaurantInfoSection(
                  restaurant: _restaurant,
                  accentColor: _orange,
                  orangeLight: _orangeLight,
                  textDark: _textDark,
                  textMuted: _textMuted,
                ),

                const _SectionDivider(),

                // Rewards disponibles (ganxo de fidelització)
                _RewardsSection(
                  restaurantId: _restaurant.id,
                  rewardsFuture: _rewardsFuture,
                  accentColor: _orange,
                  orangeLight: _orangeLight,
                  textDark: _textDark,
                ),

                const _SectionDivider(),

                // Preview de plats destacats
                _DishesPreviewSection(
                  dishIds: _restaurant.dishes ?? [],
                  accentColor: _orange,
                  textDark: _textDark,
                  textMuted: _textMuted,
                  onSeeAllPressed: () {
                    // TODO: Navegar a DishesScreen
                  },
                ),

                const _SectionDivider(),

                // Reviews (preview de 2)
                _ReviewsPreviewSection(
                  reviewIds: _restaurant.reviews ?? [],
                  globalRating: _restaurant.profile.globalRating,
                  accentColor: _orange,
                  orangeLight: _orangeLight,
                  textDark: _textDark,
                  textMuted: _textMuted,
                  onSeeAllPressed: () {
                    // TODO: Navegar a ReviewsScreen
                  },
                ),

                const _SectionDivider(),

                // NEW: QR Code Section
                _CustomerQRCodeSection(
                  accentColor: _orange,
                  orangeLight: _orangeLight,
                  textDark: _textDark,
                  onQRPressed: () {
                    // Navigate to QR code screen or show dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QRCodeScreen()),
                    );
                  },
                ),

                const _SectionDivider(),

                // Badges (credencials del restaurant)
                _BadgesSection(
                  badgeIds: _restaurant.badges ?? [],
                  accentColor: _orange,
                  orangeLight: _orangeLight,
                  textDark: _textDark,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SLIVER APP BAR AMB HERO IMAGE
// ---------------------------------------------------------------------------

class _RestaurantSliverAppBar extends StatelessWidget {
  final Restaurant restaurant;
  final Color accentColor;

  const _RestaurantSliverAppBar({
    required this.restaurant,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final images = restaurant.profile.image ?? [];
    final hasImage = images.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: hasImage
            ? Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              images.first,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _FallbackHero(color: accentColor),
            ),
            // Gradient per llegibilitat
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ],
        )
            : _FallbackHero(color: accentColor),
      ),
    );
  }
}

class _FallbackHero extends StatelessWidget {
  final Color color;
  const _FallbackHero({required this.color});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: const Center(
        child: Icon(Icons.restaurant, size: 80, color: Colors.white54),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CAPÇALERA: NOM, CATEGORIA, RATING, DESCRIPCIÓ
// ---------------------------------------------------------------------------

class _RestaurantHeaderSection extends StatelessWidget {
  final Restaurant restaurant;
  final Color accentColor;
  final Color orangeLight;
  final Color textDark;
  final Color textMuted;

  const _RestaurantHeaderSection({
    required this.restaurant,
    required this.accentColor,
    required this.orangeLight,
    required this.textDark,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final profile = restaurant.profile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom + rating en la mateixa fila
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  profile.name,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _RatingBadge(rating: profile.globalRating, accentColor: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          // Categories com a chips
          Wrap(
            spacing: 6,
            children: profile.category
                .map((cat) => _CategoryChip(
              label: cat,
              accentColor: accentColor,
              bgColor: orangeLight,
            ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Text(
            profile.description,
            style: TextStyle(color: textMuted, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  final Color accentColor;

  const _RatingBadge({required this.rating, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color accentColor;
  final Color bgColor;

  const _CategoryChip({
    required this.label,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accentColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// INFORMACIÓ: HORARIS, ADREÇA, TELÈFON
// ---------------------------------------------------------------------------

class _RestaurantInfoSection extends StatelessWidget {
  final Restaurant restaurant;
  final Color accentColor;
  final Color orangeLight;
  final Color textDark;
  final Color textMuted;

  const _RestaurantInfoSection({
    required this.restaurant,
    required this.accentColor,
    required this.orangeLight,
    required this.textDark,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final profile = restaurant.profile;
    final location = profile.location;
    final contact = profile.contact;

    // Determinem si el restaurant està obert ara (lògica bàsica)
    final isOpenNow = _isOpenNow(profile.timetable);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Information', textDark: textDark),
          const SizedBox(height: 12),
          // Estat obert/tancat + horari d'avui
          _InfoRow(
            icon: Icons.access_time_rounded,
            accentColor: accentColor,
            orangeLight: orangeLight,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOpenNow ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isOpenNow ? 'Obert ara' : 'Tancat',
                    style: TextStyle(
                      color: isOpenNow ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getTodaySchedule(profile.timetable),
                    style: TextStyle(color: textMuted, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (location.address != null || location.city.isNotEmpty)
            _InfoRow(
              icon: Icons.location_on_rounded,
              accentColor: accentColor,
              orangeLight: orangeLight,
              child: Text(
                location.address ?? location.city,
                style: TextStyle(color: textDark, fontSize: 14),
              ),
            ),
          if (contact?.phone != null)
            _InfoRow(
              icon: Icons.phone_rounded,
              accentColor: accentColor,
              orangeLight: orangeLight,
              child: Text(
                contact!.phone!,
                style: TextStyle(color: textDark, fontSize: 14),
              ),
            ),
          if (contact?.email != null)
            _InfoRow(
              icon: Icons.email_rounded,
              accentColor: accentColor,
              orangeLight: orangeLight,
              child: Text(
                contact!.email!,
                style: TextStyle(color: textMuted, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  /// Retorna true si hi ha algun slot obert en el dia actual.
  bool _isOpenNow(Timetable? timetable) {
    if (timetable == null) return false;
    final slots = _getSlotsForToday(timetable);
    if (slots == null || slots.isEmpty) return false;

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    for (final slot in slots) {
      final openParts = slot.open.split(':');
      final closeParts = slot.close.split(':');
      if (openParts.length < 2 || closeParts.length < 2) continue;

      final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      var closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
      // Gestió de cierre a mitjanit (00:00 → 1440)
      if (closeMinutes == 0) closeMinutes = 1440;

      if (nowMinutes >= openMinutes && nowMinutes < closeMinutes) return true;
    }
    return false;
  }

  List<TimetableSlot>? _getSlotsForToday(Timetable timetable) {
    final weekday = DateTime.now().weekday; // 1=dl, 7=dg
    switch (weekday) {
      case 1: return timetable.monday;
      case 2: return timetable.tuesday;
      case 3: return timetable.wednesday;
      case 4: return timetable.thursday;
      case 5: return timetable.friday;
      case 6: return timetable.saturday;
      case 7: return timetable.sunday;
      default: return null;
    }
  }

  String _getTodaySchedule(Timetable? timetable) {
    if (timetable == null) return 'Horari no disponible';
    final slots = _getSlotsForToday(timetable);
    if (slots == null || slots.isEmpty) return 'Tancat avui';
    return slots.map((s) => '${s.open}–${s.close}').join('  ·  ');
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final Color orangeLight;
  final Widget child;

  const _InfoRow({
    required this.icon,
    required this.accentColor,
    required this.orangeLight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: orangeLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REWARDS
// ---------------------------------------------------------------------------

class _RewardsSection extends StatelessWidget {
  final String restaurantId;
  final Future<List<Reward>> rewardsFuture;
  final Color accentColor;
  final Color orangeLight;
  final Color textDark;

  const _RewardsSection({
    required this.restaurantId,
    required this.rewardsFuture,
    required this.accentColor,
    required this.orangeLight,
    required this.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Rewards', textDark: textDark),
          const SizedBox(height: 12),
          FutureBuilder<List<Reward>>(
            future: rewardsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, __) => RewardCardSkeleton(
                      accentColor: accentColor,
                      bgColor: orangeLight,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _EmptyPlaceholder(
                  icon: Icons.error_outline_rounded,
                  message: 'Error loading rewards',
                  accentColor: accentColor,
                );
              }

              final rewards = snapshot.data ?? [];
              if (rewards.isEmpty) {
                return _EmptyPlaceholder(
                  icon: Icons.card_giftcard_rounded,
                  message: 'Aviat hi haurà recompenses disponibles',
                  accentColor: accentColor,
                );
              }

              final displayedRewards = rewards.take(5).toList();
              return SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayedRewards.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) => RewardCard(
                    reward: displayedRewards[index],
                    accentColor: accentColor,
                    bgColor: orangeLight,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Redeem: ${displayedRewards[index].name}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PLATS DESTACATS (preview)
// ---------------------------------------------------------------------------

class _DishesPreviewSection extends StatelessWidget {
  final List<String> dishIds;
  final Color accentColor;
  final Color textDark;
  final Color textMuted;
  final VoidCallback onSeeAllPressed;

  const _DishesPreviewSection({
    required this.dishIds,
    required this.accentColor,
    required this.textDark,
    required this.textMuted,
    required this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasDishes = dishIds.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle(title: 'Menu', textDark: textDark),
              if (hasDishes)
                TextButton(
                  onPressed: onSeeAllPressed,
                  style: TextButton.styleFrom(foregroundColor: accentColor),
                  child: const Text('Veure tot'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          hasDishes
              ? SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dishIds.length.clamp(0, 6),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) => _DishCard(
                // TODO: substituir per objecte IDish complet
                name: 'Plat ${index + 1}',
                accentColor: accentColor,
                textDark: textDark,
                textMuted: textMuted,
              ),
            ),
          )
              : _EmptyPlaceholder(
            icon: Icons.restaurant_menu_rounded,
            message: 'La carta encara no està disponible',
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  final String name;
  final Color accentColor;
  final Color textDark;
  final Color textMuted;

  const _DishCard({
    required this.name,
    required this.accentColor,
    required this.textDark,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder imatge plat
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(Icons.fastfood_rounded, color: Colors.grey.shade300, size: 32),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REVIEWS (preview)
// ---------------------------------------------------------------------------

class _ReviewsPreviewSection extends StatelessWidget {
  final List<String> reviewIds;
  final double globalRating;
  final Color accentColor;
  final Color orangeLight;
  final Color textDark;
  final Color textMuted;
  final VoidCallback onSeeAllPressed;

  const _ReviewsPreviewSection({
    required this.reviewIds,
    required this.globalRating,
    required this.accentColor,
    required this.orangeLight,
    required this.textDark,
    required this.textMuted,
    required this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    final count = reviewIds.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle(title: 'Reviews', textDark: textDark),
              if (count > 0)
                TextButton(
                  onPressed: onSeeAllPressed,
                  style: TextButton.styleFrom(foregroundColor: accentColor),
                  child: Text('Veure les $count'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Resum de rating
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: orangeLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  globalRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (i) {
                          final filled = i < (globalRating / 2).round();
                          return Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: accentColor,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count opinions',
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Placeholder de reviews (substituir per dades reals)
          if (count > 0) ...[
            const SizedBox(height: 12),
            _ReviewPlaceholderCard(accentColor: accentColor, textDark: textDark, textMuted: textMuted),
          ],
        ],
      ),
    );
  }
}

class _ReviewPlaceholderCard extends StatelessWidget {
  final Color accentColor;
  final Color textDark;
  final Color textMuted;

  const _ReviewPlaceholderCard({
    required this.accentColor,
    required this.textDark,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: substituir per widget que rep un objecte IReview real
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: Colors.grey.shade200, child: Icon(Icons.person, color: Colors.grey.shade400, size: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Usuari anònim', style: TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 13)),
              ),
              Row(
                children: [
                  Icon(Icons.star_rounded, color: accentColor, size: 14),
                  const SizedBox(width: 2),
                  Text('8.5', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"Molt bona experiència, el peix fresc i el servei excel·lent."',
            style: TextStyle(color: textMuted, fontSize: 13, fontStyle: FontStyle.italic),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// QR CODE
// ---------------------------------------------------------------------------


class _CustomerQRCodeSection extends StatelessWidget {
  final Color accentColor;
  final Color orangeLight;
  final Color textDark;
  final VoidCallback onQRPressed;

  const _CustomerQRCodeSection({
    required this.accentColor,
    required this.orangeLight,
    required this.textDark,
    required this.onQRPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'El meu codi QR', textDark: textDark),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: orangeLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(Icons.qr_code_2_rounded, color: accentColor, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Mostra el teu codi QR al restaurant',
                  style: TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onQRPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Veure QR',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// BADGES
// ---------------------------------------------------------------------------

class _BadgesSection extends StatelessWidget {
  final List<String> badgeIds;
  final Color accentColor;
  final Color orangeLight;
  final Color textDark;

  const _BadgesSection({
    required this.badgeIds,
    required this.accentColor,
    required this.orangeLight,
    required this.textDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasBadges = badgeIds.isNotEmpty;
    if (!hasBadges) return const SizedBox.shrink(); // Si no n'hi ha, no mostrem la secció

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Distintius', textDark: textDark),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: badgeIds.asMap().entries.map((entry) {
              return _BadgeChip(
                // TODO: substituir per objecte IBadge complet
                label: 'Badge ${entry.key + 1}',
                accentColor: accentColor,
                bgColor: orangeLight,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color accentColor;
  final Color bgColor;

  const _BadgeChip({
    required this.label,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: accentColor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGETS COMPARTITS / UTILS
// ---------------------------------------------------------------------------

/// Títol de secció estandarditzat
class _SectionTitle extends StatelessWidget {
  final String title;
  final Color textDark;

  const _SectionTitle({required this.title, required this.textDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: textDark,
      ),
    );
  }
}

/// Divisor visual entre seccions
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 20,
      endIndent: 20,
    );
  }
}

/// Placeholder quan una secció no té dades
class _EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color accentColor;

  const _EmptyPlaceholder({
    required this.icon,
    required this.message,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}