import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class EmployeeDashboardScreen extends StatelessWidget {
  const EmployeeDashboardScreen({super.key});

  static const Color orange = Color(0xFFFF7A1A);
  static const Color green = Color(0xFF16A34A);
  static const Color dark = Color(0xFF0F172A);
  static const Color grey = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final employee = auth.currentEmployee;
    final restaurant = auth.restaurant;

    final restaurantProfile = restaurant?['profile'] is Map<String, dynamic>
        ? restaurant!['profile'] as Map<String, dynamic>
        : <String, dynamic>{};

    final location = restaurantProfile['location'] is Map<String, dynamic>
        ? restaurantProfile['location'] as Map<String, dynamic>
        : <String, dynamic>{};

    final restName = restaurantProfile['name']?.toString() ?? 'Tu restaurante';
    final restCity = location['city']?.toString();
    final restAddress = location['address']?.toString();
    final rating = restaurantProfile['globalRating'];
    final role = employee?.role ?? auth.role ?? 'staff';
    final isOwner = role == 'owner';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('EasyEat', style: TextStyle(color: dark, fontWeight: FontWeight.w900)),
            const SizedBox(width: 10),
            _RoleBadge(role: role),
          ],
        ),
        actions: [
          Center(child: Text(auth.displayName.split(' ').first, style: const TextStyle(color: dark, fontWeight: FontWeight.w700))),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
            icon: const Icon(Icons.logout, color: dark),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RestaurantHero(
              restaurantName: restName,
              city: restCity,
              address: restAddress,
              rating: rating,
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  const _StatCard(icon: Icons.trending_up, value: '0', label: 'Visitas recientes', color: orange),
                  const _StatCard(icon: Icons.people_outline, value: '0', label: 'Clientes únicos', color: green),
                  _StatCard(icon: Icons.star_outline, value: _formatRating(rating), label: 'Valoración media', color: orange),
                ];

                if (constraints.maxWidth >= 760) {
                  return Row(
                    children: cards
                        .map((card) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: card)))
                        .toList(),
                  );
                }

                return Column(
                  children: cards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 12), child: card)).toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            const Text('Acciones rápidas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dark)),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final actions = [
                  const _ActionCard(icon: Icons.qr_code_2, title: 'Generar QR', subtitle: 'Escaneo de visita', color: orange),
                  const _ActionCard(icon: Icons.list_alt, title: 'Ver visitas', subtitle: 'Historial completo', color: green),
                  if (isOwner) const _ActionCard(icon: Icons.settings_outlined, title: 'Configuración', subtitle: 'Ajustes del local', color: orange),
                ];

                if (constraints.maxWidth >= 760) {
                  return Row(
                    children: actions
                        .map((action) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: action)))
                        .toList(),
                  );
                }

                return Column(
                  children: actions.map((action) => Padding(padding: const EdgeInsets.only(bottom: 12), child: action)).toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            const Text('Visitas recientes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dark)),
            const SizedBox(height: 14),
            const _EmptyVisitsCard(),
          ],
        ),
      ),
    );
  }

  static String _formatRating(dynamic value) {
    if (value == null) return '-';
    final number = num.tryParse(value.toString());
    if (number == null) return '-';
    return number.toStringAsFixed(1);
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isOwner = role == 'owner';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isOwner ? EmployeeDashboardScreen.orange : EmployeeDashboardScreen.green).withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: isOwner ? EmployeeDashboardScreen.orange : EmployeeDashboardScreen.green,
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

  const _RestaurantHero({required this.restaurantName, this.city, this.address, this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF243B55)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gestionando', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(restaurantName, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (city != null && city!.isNotEmpty) _HeroTag(icon: Icons.location_on_outlined, text: city!),
              if (rating != null) _HeroTag(icon: Icons.star, text: EmployeeDashboardScreen._formatRating(rating)),
            ],
          ),
          if (address != null && address!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('📍 $address', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 8))]),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: EmployeeDashboardScreen.dark)),
              Text(label, style: const TextStyle(color: EmployeeDashboardScreen.grey, fontWeight: FontWeight.w700)),
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

  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: EmployeeDashboardScreen.dark)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: EmployeeDashboardScreen.grey, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: EmployeeDashboardScreen.grey),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: const Column(
        children: [
          Icon(Icons.access_time, size: 40, color: EmployeeDashboardScreen.orange),
          SizedBox(height: 12),
          Text('No hay visitas registradas todavía', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: EmployeeDashboardScreen.dark)),
          SizedBox(height: 8),
          Text('El login de employee ya detecta owner/staff. El siguiente paso es conectar /restaurants/:id/visits.', textAlign: TextAlign.center, style: TextStyle(color: EmployeeDashboardScreen.grey)),
        ],
      ),
    );
  }
}
