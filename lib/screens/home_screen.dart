import 'package:flutter/material.dart';

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
  final GlobalKey _clientesKey = GlobalKey();
  final GlobalKey _restaurantesKey = GlobalKey();
  final GlobalKey _comoFuncionaKey = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    final sectionContext = key.currentContext;

    if (sectionContext != null) {
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Navbar(
              onClientesTap: () => _scrollToSection(_clientesKey),
              onRestaurantesTap: () => _scrollToSection(_restaurantesKey),
              onComoFuncionaTap: () => _scrollToSection(_comoFuncionaKey),
            ),
            _HeroSection(
              onClientesTap: () => _scrollToSection(_clientesKey),
              onRestaurantesTap: () => _scrollToSection(_restaurantesKey),
            ),
            _SplitSection(
              clientesKey: _clientesKey,
              restaurantesKey: _restaurantesKey,
            ),
            _StepsSection(sectionKey: _comoFuncionaKey),
            _StatsSection(),
            _FinalCta(),
            _Footer(),
          ],
        ),
      ),
    );
  }
}

class _Navbar extends StatelessWidget {
  final VoidCallback onClientesTap;
  final VoidCallback onRestaurantesTap;
  final VoidCallback onComoFuncionaTap;

  const _Navbar({
    required this.onClientesTap,
    required this.onRestaurantesTap,
    required this.onComoFuncionaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          return Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🍽️', style: TextStyle(fontSize: 26)),
                  SizedBox(width: 8),
                  Text(
                    'EasyEat',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: HomePage.dark,
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

  const _NavText({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: HomePage.grey,
            fontWeight: FontWeight.w600,
          ),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 90),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFF7ED),
            Color(0xFFF0FDF4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 56,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: HomePage.dark,
              ),
              children: [
                TextSpan(
                  text: 'Gana puntos.\n',
                  style: TextStyle(color: HomePage.orange),
                ),
                TextSpan(
                  text: 'Come más.\n',
                  style: TextStyle(color: HomePage.green),
                ),
                TextSpan(text: 'Vive mejor.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700),
            child: Text(
              'La plataforma de fidelización que recompensa cada bocado. '
              'Conecta con tus restaurantes favoritos y consigue premios exclusivos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                height: 1.5,
                color: HomePage.grey,
              ),
            ),
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 16,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              _BigButton(
                text: 'Soy cliente',
                color: HomePage.orange,
                onPressed: onClientesTap,
              ),
              _BigButton(
                text: 'Soy restaurante',
                color: HomePage.green,
                onPressed: onRestaurantesTap,
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            icon: const Icon(Icons.login, size: 18),
            label: const Text('¿Eres administrador? Accede aquí'),
            style: TextButton.styleFrom(
              foregroundColor: HomePage.dark,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const _BigButton({
    required this.text,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.chevron_right),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
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
            children: [
              Expanded(
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
              Expanded(
                child: Container(
                  key: restaurantesKey,
                  child: _InfoPanel(
                    icon: '📊',
                    title: 'Para tu negocio',
                    items: const [
                      _InfoItem(Icons.bar_chart,
                          'Analiza visitas y estadísticas reales'),
                      _InfoItem(Icons.people,
                          'Fideliza a tus clientes con puntos'),
                      _InfoItem(Icons.bolt,
                          'Gestiona carta y premios fácilmente'),
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 42)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: HomePage.dark,
            ),
          ),
          const SizedBox(height: 24),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(item.icon, color: HomePage.orange, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: HomePage.dark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String text;

  const _InfoItem(this.icon, this.text);
}

class _StepsSection extends StatelessWidget {
  final GlobalKey sectionKey;

  const _StepsSection({
    required this.sectionKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 70),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            'Tan fácil como comer',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: HomePage.dark,
            ),
          ),
          const SizedBox(height: 36),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;

              final cards = [
                _StepCard(
                  number: '01',
                  icon: Icons.search,
                  title: 'Encuentra',
                  description:
                      'Busca por categoría, ubicación o valoración y descubre tu próximo sitio favorito.',
                ),
                _StepCard(
                  number: '02',
                  icon: Icons.location_on,
                  title: 'Visita',
                  description:
                      'Haz check-in al llegar y acumula puntos automáticamente por cada comida.',
                ),
                _StepCard(
                  number: '03',
                  icon: Icons.card_giftcard,
                  title: 'Disfruta',
                  description:
                      'Canjea tus puntos acumulados por platos gratis, descuentos o experiencias únicas.',
                ),
              ];

              if (isMobile) {
                return Column(
                  children: cards
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: card,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: cards
                    .map(
                      (card) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: card,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE4CC)),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: HomePage.orange.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 10),
          Icon(icon, size: 38, color: HomePage.orange),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: HomePage.dark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              height: 1.45,
              color: HomePage.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 70),
      child: Column(
        children: [
          Wrap(
            spacing: 60,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: const [
              _StatItem(
                value: '+200',
                label: 'Restaurantes',
                color: HomePage.orange,
              ),
              _StatItem(
                value: '+3.4k',
                label: 'Usuarios',
                color: HomePage.green,
              ),
              _StatItem(
                value: '+12k',
                label: 'Visitas',
                color: HomePage.orange,
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'CRECIENDO CADA SEMANA EN BARCELONA',
            style: TextStyle(
              color: HomePage.grey,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 44,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: HomePage.dark,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FinalCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 54),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              '¿Listo para empezar a ganar?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: HomePage.dark,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 650),
              child: Text(
                'Únete a los miles de usuarios que ya están disfrutando de las mejores ventajas en los mejores restaurantes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: HomePage.grey,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Acceder a mi cuenta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HomePage.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Wrap(
              spacing: 24,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _CheckText('Sin tarjetas físicas'),
                _CheckText('100% Gratuito'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckText extends StatelessWidget {
  final String text;

  const _CheckText(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: HomePage.green, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: HomePage.grey,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: HomePage.dark,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      child: const Column(
        children: [
          Text(
            'EasyEat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Revolucionando la fidelización en el sector de la restauración.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFCBD5E1)),
          ),
          SizedBox(height: 22),
          Text(
            '© 2026 EasyEat · Proyecto Académico · UPC · Barcelona',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
