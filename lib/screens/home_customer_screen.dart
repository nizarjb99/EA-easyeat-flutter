import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class HomeCustomerScreen extends StatelessWidget {
  const HomeCustomerScreen({super.key});

  static const Color orange = Color(0xFFFF7A1A);
  static const Color green = Color(0xFF16A34A);
  static const Color dark = Color(0xFF0F172A);
  static const Color grey = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final customer = auth.currentCustomer;

    final totalPoints = customer?.pointsWallet.length ?? 0;
    final visits = customer?.visitHistory.length ?? 0;
    final badges = customer?.badges.length ?? 0;
    final favorites = customer?.favoriteRestaurants.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Text('🍽️', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              'EasyEat',
              style: TextStyle(color: dark, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                auth.displayName.split(' ').first,
                style: const TextStyle(color: dark, fontWeight: FontWeight.w700),
              ),
            ),
          ),
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
            _WelcomeCard(name: auth.displayName),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;
                final cards = [
                  _StatCard(icon: Icons.monetization_on_outlined, value: '$totalPoints', label: 'Wallets de puntos', color: orange),
                  _StatCard(icon: Icons.local_fire_department_outlined, value: '$visits', label: 'Visitas', color: green),
                  _StatCard(icon: Icons.emoji_events_outlined, value: '$badges', label: 'Badges', color: orange),
                  _StatCard(icon: Icons.favorite_outline, value: '$favorites', label: 'Favoritos', color: green),
                ];

                if (isWide) {
                  return Row(
                    children: cards
                        .map((card) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: card,
                              ),
                            ))
                        .toList(),
                  );
                }

                return Column(
                  children: [
                    Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
                    const SizedBox(height: 12),
                    Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar restaurantes o ciudades…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Restaurantes recomendados',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dark),
            ),
            const SizedBox(height: 16),
            const _EmptyCard(
              icon: Icons.restaurant,
              title: 'Todavía no hay restaurantes cargados',
              subtitle: 'El login de customer ya está separado. El siguiente paso es conectar esta lista al endpoint /restaurants.',
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  const _WelcomeCard({required this.name});

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [HomeCustomerScreen.orange, Color(0xFFFFB347)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bienvenido de vuelta,', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('$firstName 👋', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Descubre sabores que te esperan hoy', style: TextStyle(color: Colors.white, fontSize: 16)),
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
      height: 125,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: HomeCustomerScreen.dark)),
          Text(label, style: const TextStyle(color: HomeCustomerScreen.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: HomeCustomerScreen.grey, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: HomeCustomerScreen.dark,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HomeCustomerScreen.grey,
                ),
          ),
        ],
      ),
    );
  }
}