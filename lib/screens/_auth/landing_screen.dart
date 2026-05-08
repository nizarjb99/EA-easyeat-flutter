import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../_common/navigation_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const Color orange = Color(0xFFFF7A1A);
  static const Color green = Color(0xFF16A34A);
  static const Color dark = Color(0xFF0F172A);
  static const Color grey = Color(0xFF64748B);
  static const Color bgLight = Color(0xFFF8FAFC);

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
      return MainNavigationScreen();
    }

    return Scaffold(
      backgroundColor: HomePage.bgLight,
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
            _FeaturesSection(
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Text(
                    'EasyEat',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: HomePage.dark,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              ),
              if (!isMobile)
                Row(
                  children: [
                    _NavText(text: 'Clientes', onTap: onClientesTap),
                    const SizedBox(width: 30),
                    _NavText(text: 'Restaurantes', onTap: onRestaurantesTap),
                    const SizedBox(width: 30),
                    _NavText(text: 'Cómo funciona', onTap: onComoFuncionaTap),
                    const SizedBox(width: 40),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: HomePage.dark,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                      child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HomePage.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Registrarse', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              else
                IconButton(
                  icon: const Icon(Icons.menu, color: HomePage.dark),
                  onPressed: () {
                    // Simple logic for mobile menu could go here if needed
                  },
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: HomePage.dark,
            fontWeight: FontWeight.w500,
            fontSize: 16,
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 60 : 120,
        horizontal: size.width * 0.08,
      ),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Column(
              crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: HomePage.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NUEVA EXPERIENCIA GOURMET',
                    style: TextStyle(
                      color: HomePage.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Tu mesa ideal, a un click de distancia',
                  textAlign: isMobile ? TextAlign.center : TextAlign.start,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: HomePage.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: isMobile ? 42 : 64,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Optimiza la gestión de tu restaurante o disfruta de la mejor gastronomía con EasyEat. La plataforma SaaS que conecta el sabor con la tecnología.',
                  textAlign: isMobile ? TextAlign.center : TextAlign.start,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: HomePage.grey,
                        fontSize: 20,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HomePage.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                        elevation: 4,
                        shadowColor: HomePage.orange.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Empezar Gratis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HomePage.dark,
                        side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ya tengo cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onClientesTap,
                      child: Text('Ver para clientes', style: TextStyle(color: HomePage.grey, decoration: TextDecoration.underline)),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: onRestaurantesTap,
                      child: Text('Ver para restaurantes', style: TextStyle(color: HomePage.grey, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMobile) const SizedBox(width: 60),
          if (isMobile) const SizedBox(height: 60),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Container(
              height: isMobile ? 300 : 500,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: isMobile ? 250 : 400,
                  height: isMobile ? 200 : 350,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            _dot(Colors.red[300]!),
                            const SizedBox(width: 6),
                            _dot(Colors.amber[300]!),
                            const SizedBox(width: 6),
                            _dot(Colors.green[300]!),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 12, width: 100, color: const Color(0xFFE2E8F0)),
                              const SizedBox(height: 12),
                              Container(height: 8, width: double.infinity, color: const Color(0xFFF1F5F9)),
                              const SizedBox(height: 8),
                              Container(height: 8, width: 180, color: const Color(0xFFF1F5F9)),
                              const Spacer(),
                              Row(
                                children: [
                                  Container(height: 40, width: 40, decoration: const BoxDecoration(color: Color(0xFFE2E8F0), shape: BoxShape.circle)),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(height: 8, width: 60, color: const Color(0xFFE2E8F0)),
                                      const SizedBox(height: 4),
                                      Container(height: 6, width: 40, color: const Color(0xFFF1F5F9)),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _FeaturesSection extends StatelessWidget {
  final GlobalKey clientesKey;
  final GlobalKey restaurantesKey;

  const _FeaturesSection({
    required this.clientesKey,
    required this.restaurantesKey,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 100, horizontal: size.width * 0.08),
      child: Column(
        children: [
          const Text(
            'Soluciones para todos',
            style: TextStyle(
              color: HomePage.orange,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Una plataforma, dos experiencias',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: HomePage.dark,
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 32 : 48,
                ),
          ),
          const SizedBox(height: 60),
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            children: [
              Expanded(
                flex: isMobile ? 0 : 1,
                child: _SaaSCard(
                  key: clientesKey,
                  icon: Icons.star_rounded,
                  title: 'Para ti, foodie',
                  description: 'Descubre, reserva y disfruta de beneficios exclusivos en tus locales favoritos.',
                  items: const [
                    'Busca restaurantes por zona y tipo',
                    'Reserva en tiempo real sin esperas',
                    'Gana puntos por cada consumición',
                    'Canjea premios y descuentos gratis'
                  ],
                  color: HomePage.orange,
                ),
              ),
              if (!isMobile) const SizedBox(width: 32),
              if (isMobile) const SizedBox(height: 32),
              Expanded(
                flex: isMobile ? 0 : 1,
                child: _SaaSCard(
                  key: restaurantesKey,
                  icon: Icons.restaurant_menu_rounded,
                  title: 'Para tu negocio',
                  description: 'La herramienta definitiva para digitalizar y escalar tu restaurante.',
                  items: const [
                    'Panel de control intuitivo',
                    'Gestión de reservas automatizada',
                    'Programa de fidelización nativo',
                    'Analíticas de clientes y ventas'
                  ],
                  color: HomePage.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaaSCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> items;
  final Color color;

  const _SaaSCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: HomePage.dark,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: HomePage.grey,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 32),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: HomePage.dark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    final steps = const [
      _HowItWorksStep(
        step: '01',
        title: 'Explora',
        description: 'Navega entre cientos de opciones gastronómicas seleccionadas.',
        icon: Icons.search_rounded,
      ),
      _HowItWorksStep(
        step: '02',
        title: 'Disfruta',
        description: 'Realiza tu reserva y vive una experiencia sin complicaciones.',
        icon: Icons.confirmation_number_outlined,
      ),
      _HowItWorksStep(
        step: '03',
        title: 'Gana',
        description: 'Acumula puntos y desbloquea recompensas exclusivas.',
        icon: Icons.card_giftcard_rounded,
      ),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 100, horizontal: size.width * 0.08),
      child: Column(
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
          const SizedBox(height: 80),
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(flex: isMobile ? 0 : 1, child: steps[0]),
              if (!isMobile) _arrow(),
              if (isMobile) const SizedBox(height: 40),
              Expanded(flex: isMobile ? 0 : 1, child: steps[1]),
              if (!isMobile) _arrow(),
              if (isMobile) const SizedBox(height: 40),
              Expanded(flex: isMobile ? 0 : 1, child: steps[2]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _arrow() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.east_rounded, color: Color(0xFFE2E8F0), size: 32),
      );
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
      children: [
        Text(
          step,
          style: TextStyle(
            color: HomePage.orange.withOpacity(0.2),
            fontSize: 48,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Icon(icon, color: HomePage.orange, size: 40),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            color: HomePage.dark,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: HomePage.grey,
            fontSize: 16,
            height: 1.5,
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
      color: HomePage.dark,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Text(
                'EasyEat',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Wrap(
            spacing: 30,
            runSpacing: 20,
            children: [
              Text('Privacidad', style: TextStyle(color: Color(0xFF94A3B8))),
              Text('Términos', style: TextStyle(color: Color(0xFF94A3B8))),
              Text('Contacto', style: TextStyle(color: Color(0xFF94A3B8))),
              Text('Soporte', style: TextStyle(color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 60),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 40),
          const Text(
            '© 2024 EasyEat. Todos los derechos reservados. Diseñado para el éxito gastronómico.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

