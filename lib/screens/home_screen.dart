import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'main_navigation_screen.dart'; // Import the new main navigation screen

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const Color orange = Color(0xFFFF7A1A);
  static const Color green = Color(0xFF16A34A);
  static const Color dark = Color(0xFF0F172A);
  static const Color grey = Color(0xFF64748B);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final clientesKey = GlobalKey();
  final restaurantesKey = GlobalKey();
  final comoFuncionaKey = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoggedIn) {
      return MainNavigationScreen(); // Removed const
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Header(
              onClientesTap: () => _scrollToSection(clientesKey),
              onRestaurantesTap: () => _scrollToSection(restaurantesKey),
              onComoFuncionaTap: () => _scrollToSection(comoFuncionaKey),
            ),
            _HeroSection(
              onClientesTap: () => _scrollToSection(clientesKey),
              onRestaurantesTap: () => _scrollToSection(restaurantesKey),
            ),
            _SplitSection(
              clientesKey: clientesKey,
              restaurantesKey: restaurantesKey,
            ),
            _HowItWorksSection(key: comoFuncionaKey),
            _Footer(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClientesTap;
  final VoidCallback onRestaurantesTap;
  final VoidCallback onComoFuncionaTap;

  const _Header({
    required this.onClientesTap,
    required this.onRestaurantesTap,
    required this.onComoFuncionaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Text(
                    'EasyEat',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: HomePage.dark,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 16 : 0),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _NavText(
                    text: 'Clientes',
                    onTap: onClientesTap,
                  ),
                  _NavText(
                    text: 'Restaurantes',
                    onTap: onRestaurantesTap,
                  ),
                  _NavText(
                    text: 'Cómo funciona',
                    onTap: onComoFuncionaTap,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomePage.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('Acceder'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavText extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _NavText({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: HomePage.dark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onClientesTap;
  final VoidCallback onRestaurantesTap;

  const _HeroSection({
    required this.onClientesTap,
    required this.onRestaurantesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFBF7),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                flex: isMobile ? 0 : 1,
                child: Column(
                  crossAxisAlignment:
                      isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu mesa ideal, a un click de distancia.',
                      textAlign: isMobile ? TextAlign.center : TextAlign.start,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: HomePage.dark,
                            fontWeight: FontWeight.w900,
                            fontSize: isMobile ? 42 : 58,
                            height: 1.1,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Descubre, reserva y disfruta de experiencias culinarias únicas. ¡Acumula puntos y canjéalos por recompensas exclusivas!',
                      textAlign: isMobile ? TextAlign.center : TextAlign.start,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: HomePage.grey,
                            fontSize: isMobile ? 18 : 22,
                          ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
                      children: [
                        ElevatedButton(
                          onPressed: onClientesTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HomePage.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Soy un cliente'),
                        ),
                        ElevatedButton(
                          onPressed: onRestaurantesTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HomePage.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Soy un restaurante'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String icon;
  final String title;
  final List<_InfoItem> items;

  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()), // Fixed withOpacity
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: HomePage.dark,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 24),
          ...items,
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HomePage.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: HomePage.grey,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitSection extends StatelessWidget {
  final GlobalKey clientesKey;
  final GlobalKey restaurantesKey;

  const _SplitSection({
    required this.clientesKey,
    required this.restaurantesKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Flexible(
                fit: isMobile ? FlexFit.loose : FlexFit.tight,
                child: Container(
                  key: clientesKey,
                  child: _InfoPanel(
                    icon: '⭐',
                    title: 'Para ti, foodie',
                    items: const [
                      _InfoItem(Icons.location_on,
                          'Descubre restaurantes cerca de ti'),
                      _InfoItem(Icons.emoji_events,
                          'Acumula puntos con cada visita'),
                      _InfoItem(Icons.card_giftcard,
                          'Canjea recompensas exclusivas gratis'),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 24 : 0),
              Flexible(
                fit: isMobile ? FlexFit.loose : FlexFit.tight,
                child: Container(
                  key: restaurantesKey,
                  child: _InfoPanel(
                    icon: '👨‍🍳',
                    title: 'Para tu restaurante',
                    items: const [
                      _InfoItem(Icons.restaurant_menu,
                          'Atrae nuevos clientes y fideliza los existentes'),
                      _InfoItem(Icons.qr_code,
                          'Gestiona reservas y pedidos de forma eficiente'),
                      _InfoItem(Icons.insights,
                          'Accede a estadísticas y mejora tu negocio'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFBF7),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return Column(
            children: [
              Text(
                '¿Cómo funciona EasyEat?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: HomePage.dark,
                      fontWeight: FontWeight.w900,
                      fontSize: isMobile ? 32 : 48,
                    ),
              ),
              const SizedBox(height: 32),
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Flexible(
                    flex: 1,
                    child: _HowItWorksStep(
                      step: '1',
                      title: 'Descubre',
                      description:
                          'Explora una amplia selección de restaurantes cerca de ti, filtra por tipo de cocina, ambiente o promociones.',
                      icon: Icons.search,
                    ),
                  ),
                  SizedBox(width: 24, height: 24),
                  Flexible(
                    flex: 1,
                    child: _HowItWorksStep(
                      step: '2',
                      title: 'Reserva',
                      description:
                          'Reserva tu mesa en segundos, elige la hora y el número de comensales. ¡Sin esperas ni complicaciones!',
                      icon: Icons.calendar_today,
                    ),
                  ),
                  SizedBox(width: 24, height: 24),
                  Flexible(
                    flex: 1,
                    child: _HowItWorksStep(
                      step: '3',
                      title: 'Disfruta',
                      description:
                          'Acude a tu reserva, disfruta de tu comida y acumula puntos para canjear por descuentos y experiencias exclusivas.',
                      icon: Icons.celebration,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final IconData icon;

  const _HowItWorksStep({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: HomePage.orange,
          radius: 24,
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: HomePage.dark,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            color: HomePage.grey,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Icon(icon, color: HomePage.orange, size: 48),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: HomePage.dark,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text(
                'EasyEat',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '© 2023 EasyEat. Todos los derechos reservados.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HomePage.grey,
                ),
          ),
        ],
      ),
    );
  }
}
