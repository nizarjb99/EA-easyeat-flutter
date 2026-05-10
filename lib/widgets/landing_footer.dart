import 'package:flutter/material.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  static const Color dark = Color(0xFF0F172A);
  static const Color grey = Color(0xFF64748B);
  static const Color orange = Color(0xFFFF7A1A);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Container(
      color: dark,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 60 : 80,
        horizontal: size.width * 0.08,
      ),
      child: Column(
        children: [
          _buildTopRow(context, isMobile),
          const SizedBox(height: 60),
          _buildLinks(context, isMobile),
          const SizedBox(height: 60),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 40),
          _buildBottomText(isMobile),
        ],
      ),
    );
  }

  Widget _buildTopRow(BuildContext context, bool isMobile) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
        const SizedBox(height: 16),
        Text(
          'Conectando el sabor con la tecnología.',
          style: TextStyle(color: grey, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildLinks(BuildContext context, bool isMobile) {
    return Wrap(
      spacing: 40,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: [
        _FooterLink(
          text: 'Aviso Legal',
          onTap: () => Navigator.pushNamed(context, '/aviso-legal'),
        ),
        _FooterLink(
          text: 'Privacidad',
          onTap: () {
            // Future implementation for Privacy Policy
          },
        ),
        _FooterLink(
          text: 'Cookies',
          onTap: () {
            // Future implementation for Cookies Policy
          },
        ),
        _FooterLink(
          text: 'Contacto',
          onTap: () {
            // Handle contact
          },
        ),
      ],
    );
  }

  Widget _buildBottomText(bool isMobile) {
    return Text(
      '© ${DateTime.now().year} EasyEat. Todos los derechos reservados. Diseñado para el éxito gastronómico.',
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterLink({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
