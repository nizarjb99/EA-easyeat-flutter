import 'package:flutter/material.dart';

class EasyEatLogo extends StatelessWidget {
  final double height;
  
  const EasyEatLogo({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const FittedBox(
        fit: BoxFit.contain,
        child: _EasyEatLogoContent(),
      ),
    );
  }
}

class _EasyEatLogoContent extends StatelessWidget {
  const _EasyEatLogoContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const ForkSpoonIcon(size: 40),
            const SizedBox(width: 10),
            const Text(
              'EASY',
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Color(0xFF18B97A),
                letterSpacing: -1,
                height: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFCCCCCC),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Text(
              'EAT',
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE8450A),
                letterSpacing: -1,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 50),
            Container(
              width: 82,
              height: 2.5,
              decoration: BoxDecoration(
                color: const Color(0xFF18B97A).withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 18),
            Container(
              width: 60,
              height: 2.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE8450A).withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'SIMPLE. FAST. DELICIOUS.',
          style: TextStyle(
            fontFamily: 'Arial',
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: Color(0xFF999999),
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }
}

class ForkSpoonIcon extends StatelessWidget {
  final double size;
  const ForkSpoonIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.6,
      height: size,
      child: CustomPaint(painter: _ForkSpoonPainter()),
    );
  }
}

class _ForkSpoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green = Paint()
      ..color = const Color(0xFF18B97A)
      ..style = PaintingStyle.fill;
    final orange = Paint()
      ..color = const Color(0xFFE8450A)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.50, w * 0.20, h * 0.46), const Radius.circular(4)),
      green,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.02, h * 0.37, w * 0.34, h * 0.09), const Radius.circular(3)),
      green,
    );
    for (int i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.02 + i * (w * 0.12), h * 0.04, w * 0.09, h * 0.35), const Radius.circular(3)),
        green,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.70, h * 0.34, w * 0.20, h * 0.62), const Radius.circular(4)),
      orange,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.80, h * 0.18), width: w * 0.36, height: h * 0.28),
      orange,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
