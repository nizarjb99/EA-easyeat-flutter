import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/employee.dart';
import '../../models/visit.dart';
import '../../providers/auth_provider.dart';
import '../../services/restaurant_service.dart';
import '../../utils/styles.dart';

const Color _orange = Color(0xFFFF7A1A);
const Color _green = Color(0xFF16A34A);
const Color _dark = Color(0xFF0F172A);
const Color _grey = Color(0xFF64748B);
const Color _background = Color(0xFFF8FAFC);
const Color _cardBorder = Color(0xFFE2E8F0);

class HomeEmployeeScreen extends StatefulWidget {
  const HomeEmployeeScreen({super.key});

  @override
  State<HomeEmployeeScreen> createState() => _HomeEmployeeScreenState();
}

class _HomeEmployeeScreenState extends State<HomeEmployeeScreen> {
  final RestaurantService _service = RestaurantService();
  List<Visit> _visits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final auth = context.read<AuthProvider>();
      final restaurant = auth.restaurant ?? <String, dynamic>{};
      final profile = _mapOrEmpty(restaurant['profile']);
      final restaurantId = _restaurantId(restaurant, profile);

      if (restaurantId == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final visits = await _service.fetchVisitsByRestaurant(
        restaurantId,
        accessToken: auth.accessToken,
      );

      if (!mounted) return;

      setState(() {
        _visits = visits;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final employee = auth.currentEmployee;
    final restaurant = auth.restaurant ?? <String, dynamic>{};

    final profile = _mapOrEmpty(restaurant['profile']);
    final location = _mapOrEmpty(profile['location']);

    final restaurantName = _textOrFallback(
      profile['name'] ?? restaurant['name'],
      'Tu restaurante',
    );
    final restCity = _textOrNull(location['city']);
    final restAddress = _textOrNull(location['address']);
    final rating = profile['globalRating'] ?? restaurant['globalRating'];

    final role = employee?.role ?? auth.role ?? 'staff';
    final isOwner = role == 'owner';
    final displayName = _firstName(auth.displayName);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text(
              'EasyEat',
              style: TextStyle(
                color: _dark,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            _RoleBadge(role: role),
          ],
        ),
        actions: [
          Center(
            child: Text(
              displayName,
              style: const TextStyle(
                color: _dark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
            icon: const Icon(Icons.logout, color: _dark),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RestaurantHero(
                      restaurantName: restaurantName,
                      city: restCity,
                      address: restAddress,
                      rating: rating,
                    ),
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cards = [
                          _StatCard(
                            icon: Icons.trending_up,
                            value: _visits.length.toString(),
                            label: 'Visitas recientes',
                            color: _orange,
                          ),
                          _StatCard(
                            icon: Icons.people_outline,
                            value: _uniqueCustomers.toString(),
                            label: 'Clientes únicos',
                            color: _green,
                          ),
                          _StatCard(
                            icon: Icons.star_outline,
                            value: _formatRating(rating),
                            label: 'Valoración media',
                            color: _orange,
                          ),
                        ];

                        if (constraints.maxWidth >= 760) {
                          return Row(
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 12),
                              Expanded(child: cards[1]),
                              const SizedBox(width: 12),
                              Expanded(child: cards[2]),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 12),
                            cards[1],
                            const SizedBox(height: 12),
                            cards[2],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Acciones rápidas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final actions = [
                          const _ActionCard(
                            icon: Icons.qr_code_2,
                            title: 'Generar QR',
                            subtitle: 'Escaneo de visita',
                            color: _orange,
                          ),
                          const _ActionCard(
                            icon: Icons.list_alt,
                            title: 'Ver visitas',
                            subtitle: 'Historial completo',
                            color: _green,
                          ),
                          if (isOwner)
                            const _ActionCard(
                              icon: Icons.settings_outlined,
                              title: 'Configuración',
                              subtitle: 'Ajustes del local',
                              color: _orange,
                            ),
                        ];

                        if (constraints.maxWidth >= 760) {
                          return Row(
                            children: [
                              Expanded(child: actions[0]),
                              const SizedBox(width: 12),
                              Expanded(child: actions[1]),
                              if (isOwner) ...[
                                const SizedBox(width: 12),
                                Expanded(child: actions[2]),
                              ],
                            ],
                          );
                        }

                        return Column(
                          children: [
                            actions[0],
                            const SizedBox(height: 12),
                            actions[1],
                            if (isOwner) ...[
                              const SizedBox(height: 12),
                              actions[2],
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Visitas recientes',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildVisitsList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  int get _uniqueCustomers {
    return _visits.map((v) => v.customerId).toSet().length;
  }

  Widget _buildVisitsList() {
    if (_visits.isEmpty) {
      return const _EmptyVisitsCard();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: _visits.take(5).map((visit) => _buildVisitItem(visit)).toList(),
      ),
    );
  }

  Widget _buildVisitItem(Visit visit) {
    final initial = _initial(visit.customerName, fallback: 'C');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _cardBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _orange.withOpacity(0.18),
                  _green.withOpacity(0.14),
                ],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: _dark,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _textOrFallback(visit.customerName, 'Cliente'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: _grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${visit.date.day}/${visit.date.month}/${visit.date.year}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${visit.pointsEarned.toInt()} pts',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right, color: _grey),
        ],
      ),
    );
  }

  static String _formatRating(dynamic value) {
    if (value == null) return '-';
    final number = num.tryParse(value.toString());
    if (number == null) return '-';
    return number.toStringAsFixed(1);
  }

  Map<String, dynamic> _mapOrEmpty(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }

  String _textOrFallback(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String? _textOrNull(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String _firstName(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Usuario';
    return text.split(RegExp(r'\s+')).first;
  }

  String _initial(dynamic value, {String fallback = 'U'}) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return fallback;
    return text[0].toUpperCase();
  }

  String? _restaurantId(
    Map<String, dynamic> restaurant,
    Map<String, dynamic> profile,
  ) {
    final dynamic rawId =
        restaurant['_id'] ?? profile['_id'] ?? restaurant['id'] ?? profile['id'];

    final id = rawId?.toString().trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isOwner = role == 'owner';
    final badgeColor = isOwner ? _orange : _green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RestaurantHero extends StatelessWidget {
  final String restaurantName;
  final String? city;
  final String? address;
  final dynamic rating;

  const _RestaurantHero({
    required this.restaurantName,
    this.city,
    this.address,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF243B55)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestionando',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            restaurantName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (city != null && city!.isNotEmpty)
                _HeroTag(
                  icon: Icons.location_on_outlined,
                  text: city!,
                ),
              if (rating != null)
                _HeroTag(
                  icon: Icons.star,
                  text: _HomeEmployeeScreenState._formatRating(rating),
                ),
            ],
          ),
          if (address != null && address!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '📍 $address',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroTag({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _dark,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: _grey,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _grey),
        ],
      ),
    );
  }
}

class _EmptyVisitsCard extends StatelessWidget {
  const _EmptyVisitsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.access_time, size: 40, color: _orange),
          SizedBox(height: 12),
          Text(
            'No hay visitas registradas todavía',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'El login de employee ya detecta owner/staff. El siguiente paso es conectar /restaurants/:id/visits.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _grey),
          ),
        ],
      ),
    );
  }
}