import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/reward.dart';
import '../../providers/auth_provider.dart';
import '../../services/reward_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROULETTE MINIGAME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class RouletteMinigameScreen extends StatefulWidget {
  final Reward rouletteReward;
  final String restaurantId;
  final List<Reward> availableRewards; // non-roulette rewards for display

  const RouletteMinigameScreen({
    super.key,
    required this.rouletteReward,
    required this.restaurantId,
    required this.availableRewards,
  });

  @override
  State<RouletteMinigameScreen> createState() => _RouletteMinigameScreenState();
}

class _RouletteMinigameScreenState extends State<RouletteMinigameScreen>
    with TickerProviderStateMixin {
  final RewardService _rewardService = RewardService();

  // State
  bool _isLoading = false;
  bool _hasPlayed = false;
  bool _won = false;
  String? _wonRewardName;
  String? _errorMessage;
  int? _pointsAfter;

  // Animation
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  late AnimationController _resultController;
  late Animation<double> _resultFadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Wheel segments: available rewards + "Sin premio"
  late List<_WheelSegment> _segments;
  int _targetIndex = 0;

  // Colors for the wheel segments
  static const List<Color> _segmentColors = [
    Color(0xFFFF6B35),
    Color(0xFF2EC4B6),
    Color(0xFFE71D36),
    Color(0xFF011627),
    Color(0xFFFF9F1C),
    Color(0xFF7B2D8E),
    Color(0xFF3A86FF),
    Color(0xFF06D6A0),
    Color(0xFFEF476F),
    Color(0xFF118AB2),
  ];

  @override
  void initState() {
    super.initState();

    // Build wheel segments
    _buildSegments();

    // Spin animation
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 4500),
      vsync: this,
    );

    // Result fade in
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultFadeAnimation = CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOut,
    );

    // Pulse for the play button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _buildSegments() {
    _segments = [];
    for (int i = 0; i < widget.availableRewards.length; i++) {
      _segments.add(_WheelSegment(
        label: widget.availableRewards[i].name,
        color: _segmentColors[i % _segmentColors.length],
        isNoPrize: false,
      ));
    }
    // Add "Sin premio" segment
    _segments.add(_WheelSegment(
      label: 'Sin premio',
      color: const Color(0xFF374151),
      isNoPrize: true,
    ));
  }

  @override
  void dispose() {
    _spinController.dispose();
    _resultController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _playRoulette() async {
    final auth = context.read<AuthProvider>();
    if (auth.id == null || auth.accessToken == null) {
      setState(() => _errorMessage = 'Debes iniciar sesión');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasPlayed = false;
    });

    try {
      final result = await _rewardService.playRoulette(
        widget.rouletteReward.id,
        auth.id!,
        auth.accessToken!,
      );

      _won = result['won'] == true;
      _pointsAfter = (result['pointsAfter'] as num?)?.toInt();

      if (_won && result['reward'] != null) {
        final rewardData = result['reward'] as Map<String, dynamic>;
        _wonRewardName = rewardData['name']?.toString() ?? 'Premio';

        // Find the segment index for the won reward
        final wonId = (rewardData['_id'] ?? rewardData['id'] ?? '').toString();
        _targetIndex = widget.availableRewards.indexWhere((r) => r.id == wonId);
        if (_targetIndex < 0) _targetIndex = 0;
      } else {
        _wonRewardName = null;
        // Target the "Sin premio" segment (last one)
        _targetIndex = _segments.length - 1;
      }

      // Calculate spin animation to land on target segment
      _setupSpinAnimation();

      // Start spinning
      _spinController.forward(from: 0.0).then((_) {
        setState(() {
          _hasPlayed = true;
          _isLoading = false;
        });
        _resultController.forward(from: 0.0);
        _pulseController.stop();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _setupSpinAnimation() {
    final segmentAngle = (2 * pi) / _segments.length;
    // Target angle: center of the target segment, aligned to top (subtract pi/2)
    final targetAngle = segmentAngle * _targetIndex + segmentAngle / 2;

    // Full spins (5-7 full rotations) plus the target position
    final fullSpins = (5 + Random().nextInt(3)) * 2 * pi;
    // We want the wheel to stop so that the target is at the top (pointer position)
    // The pointer is at the top, wheel rotates clockwise
    final totalAngle = fullSpins + (2 * pi - targetAngle);

    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: totalAngle,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          '🎰 Ruleta de Premios',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Cost info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade700.withOpacity(0.2),
                    Colors.orange.shade800.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Cuesta ${widget.rouletteReward.pointsRequired} puntos',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // WHEEL
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = min(constraints.maxWidth, constraints.maxHeight) * 0.9;
                  final wheelSize = size.clamp(200.0, 300.0);
                  return Center(
                    child: _buildWheel(wheelSize),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // RESULT or PLAY BUTTON
            if (_errorMessage != null)
              _buildErrorCard()
            else if (_hasPlayed)
              _buildResultCard()
            else
              _buildPlayButton(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                  blurRadius: size * 0.1,
                  spreadRadius: size * 0.016,
                ),
              ],
            ),
          ),

          // The spinning wheel
          AnimatedBuilder(
            animation: _spinController,
            builder: (context, child) {
              final angle = _spinController.isAnimating || _hasPlayed
                  ? _spinAnimation.value
                  : 0.0;
              return Transform.rotate(
                angle: angle,
                child: child,
              );
            },
            child: CustomPaint(
              size: Size(size * 0.93, size * 0.93),
              painter: _WheelPainter(segments: _segments),
            ),
          ),

          // Center circle
          Container(
            width: size * 0.18,
            height: size * 0.18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: size * 0.04,
                  spreadRadius: size * 0.006,
                ),
              ],
            ),
            child: Icon(
              Icons.casino_rounded,
              color: Colors.white,
              size: size * 0.09,
            ),
          ),

          // Pointer (top arrow)
          Positioned(
            top: -2,
            child: CustomPaint(
              size: Size(size * 0.1, size * 0.08),
              painter: _PointerPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _playRoulette,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.5),
              elevation: 8,
              shadowColor: const Color(0xFFFF6B35).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Jugar por ${widget.rouletteReward.pointsRequired} pts',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return FadeTransition(
      opacity: _resultFadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _won
                ? [const Color(0xFF16A34A).withOpacity(0.15), const Color(0xFF059669).withOpacity(0.15)]
                : [const Color(0xFF64748B).withOpacity(0.15), const Color(0xFF475569).withOpacity(0.15)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _won
                ? const Color(0xFF16A34A).withOpacity(0.4)
                : const Color(0xFF64748B).withOpacity(0.4),
          ),
        ),
        child: Column(
          children: [
            Icon(
              _won ? Icons.celebration_rounded : Icons.sentiment_neutral_rounded,
              color: _won ? Colors.amber : Colors.grey,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              _won ? '🎉 ¡Has ganado!' : '😔 Sin premio',
              style: TextStyle(
                color: _won ? Colors.greenAccent : Colors.grey.shade400,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (_won && _wonRewardName != null) ...[
              const SizedBox(height: 6),
              Text(
                _wonRewardName!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Tu recompensa está desbloqueada. ¡Muestra el QR al empleado para usarla gratis!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
              const Text(
                '¡Vuelve a intentarlo la próxima vez!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
            if (_pointsAfter != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Puntos restantes: $_pointsAfter',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: _won ? Colors.greenAccent.withOpacity(0.5) : Colors.grey.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Volver',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _errorMessage = null),
            child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WHEEL SEGMENT DATA
// ─────────────────────────────────────────────────────────────────────────────

class _WheelSegment {
  final String label;
  final Color color;
  final bool isNoPrize;

  const _WheelSegment({
    required this.label,
    required this.color,
    required this.isNoPrize,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// WHEEL PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _WheelPainter extends CustomPainter {
  final List<_WheelSegment> segments;

  _WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * pi) / segments.length;

    // Draw outer ring
    final outerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFFD700),
          Color(0xFFFF8C00),
          Color(0xFFFFD700),
          Color(0xFFFF6B35),
          Color(0xFFFFD700),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 3, outerRingPaint);

    for (int i = 0; i < segments.length; i++) {
      final startAngle = segmentAngle * i - pi / 2;

      // Draw segment
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = segments[i].color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 7),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw segment border
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withOpacity(0.3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 7),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      // Draw label
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + segmentAngle / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: _truncateLabel(segments[i].label, 14),
          style: TextStyle(
            color: Colors.white,
            fontSize: segments.length > 6 ? 10 : 12,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 2),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: radius * 0.55);
      textPainter.paint(
        canvas,
        Offset(radius * 0.3, -textPainter.height / 2),
      );

      // Draw icon for "Sin premio"
      if (segments[i].isNoPrize) {
        final iconPainter = TextPainter(
          text: const TextSpan(
            text: '✕',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        iconPainter.layout();
        iconPainter.paint(
          canvas,
          Offset(radius * 0.18, -iconPainter.height / 2),
        );
      }

      canvas.restore();
    }
  }

  String _truncateLabel(String label, int maxLen) {
    if (label.length <= maxLen) return label;
    return '${label.substring(0, maxLen - 1)}…';
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// POINTER PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.8);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
