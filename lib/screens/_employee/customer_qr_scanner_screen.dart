import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';
import '../../services/nfc_service.dart';
import '../../utils/styles.dart';

// ═════════════════════════════════════════════════════════════════════════════
class CustomerQrScannerScreen extends StatefulWidget {
  final String type;

  const CustomerQrScannerScreen({super.key, required this.type});

  @override
  State<CustomerQrScannerScreen> createState() =>
      _CustomerQrScannerScreenState();
}

class _CustomerQrScannerScreenState extends State<CustomerQrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _qrController = MobileScannerController();
  final CustomerService _customerService = CustomerService();

  late TabController _tabController;
  bool _isProcessing = false;
  String? _data;
  bool _nfcActive = false;
  String _nfcStatus = 'Acerca el móvil del cliente';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == 0) {
      // Tab QR
      _stopNfc();
      _qrController.start();
    } else {
      // Tab NFC
      _qrController.stop();
      _startNfc();
    }
  }

  @override
  void dispose() {
    _qrController.dispose();
    _tabController.dispose();
    _stopNfc();
    super.dispose();
  }

  // ── LOGIC: COMMON ──

  void _processData(String rawValue) {
    if (_isProcessing || _data != null) return;
    if (rawValue.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _data = rawValue;
    });

    if (!mounted) return;

    if (widget.type == 'visit') {
      Navigator.pushReplacementNamed(
        context,
        '/add-visit',
        arguments: {'customerId': rawValue},
      );
    } else if (widget.type == 'reward') {
      try {
        final Map<String, dynamic> json = jsonDecode(rawValue);
        Navigator.pushReplacementNamed(
          context,
          '/exchange-reward',
          arguments: {
            'customerId': json['customer_id'],
            'rewardId': json['reward_id'],
            'restaurantId': json['restaurant_id'],
          },
        );
      } catch (e) {
        _showError('Formato de QR inválido para recompensa');
        _reset();
      }
    }
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _data = null;
      _nfcStatus = 'Acerca el móvil del cliente';
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── LOGIC: QR ──

  Future<void> _handleQrDetection(BarcodeCapture barcodes) async {
    final barcode = barcodes.barcodes.isNotEmpty ? barcodes.barcodes.first : null;
    final rawValue = barcode?.rawValue?.trim();
    if (rawValue != null) {
      _processData(rawValue);
    }
  }

  void _toggleFlash() {
    _qrController.toggleTorch();
  }

  // ── LOGIC: NFC ──

  Future<void> _startNfc() async {
    final available = await NfcService.isNfcAvailable();
    if (!available) {
      setState(() => _nfcStatus = 'NFC no disponible en este dispositivo');
      return;
    }

    setState(() {
      _nfcActive = true;
      _nfcStatus = 'Escuchando NFC...\nAcerca el móvil del cliente';
    });

    await NfcService.startNfcReading(
      onCustomerIdReceived: (customerId) {
        _stopNfc();
        _processData(customerId);
      },
      onError: (error) {
        setState(() => _nfcStatus = error);
        _stopNfc();
      },
    );
  }

  void _stopNfc() {
    NfcService.stopNfcReading();
    if (mounted) {
      setState(() {
        _nfcActive = false;
      });
    }
  }

  // ── UI BUILD ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardHeader,
      appBar: AppBar(
        backgroundColor: AppColors.dashboardHeader,
        elevation: 0,
        title: const Text(
          'Identificar Cliente',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.flashlight_on, color: AppColors.customer),
              tooltip: 'Toggle flash',
              onPressed: _toggleFlash,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.employee,
          labelColor: AppColors.employee,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Escáner QR'),
            Tab(icon: Icon(Icons.nfc), text: 'Lector NFC'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(), // Evita cambiar deslizando para no romper la cámara accidentalmente
            children: [
              _buildQrTab(),
              _buildNfcTab(),
            ],
          ),

          // Loading indicator (if processing)
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.customer),
                    SizedBox(height: 16),
                    Text(
                      'Verificando cliente...',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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

  Widget _buildQrTab() {
    return Stack(
      children: [
        MobileScanner(
          controller: _qrController,
          onDetect: _handleQrDetection,
          errorBuilder: (context, error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 48,
                    color: AppColors.customer,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Camera permission required',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        _ScannerOverlay(isProcessing: _isProcessing),
      ],
    );
  }

  Widget _buildNfcTab() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Ripple effect background
              if (_nfcActive)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      width: 150 * value,
                      height: 150 * value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.employee.withAlpha((255 * (1.2 - value) * 0.3).round()),
                      ),
                    );
                  },
                  onEnd: () {
                    if (mounted && _nfcActive) setState(() {});
                  },
                ),
              // Main NFC Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.employee.withAlpha((255 * 0.1).round()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.nfc,
                  size: 64,
                  color: AppColors.employee,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            _nfcStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),
          if (!_nfcActive)
            ElevatedButton(
              onPressed: _startNfc,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.employee,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Reiniciar Escáner NFC'),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SCANNER OVERLAY WITH FRAME & INSTRUCTIONS
// ═════════════════════════════════════════════════════════════════════════════
class _ScannerOverlay extends StatelessWidget {
  final bool isProcessing;
  const _ScannerOverlay({required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final frameSize = 280.0;
    final frameLeft = (screenSize.width - frameSize) / 2;
    final frameTop = (screenSize.height - frameSize) / 2 - 80;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _ScannerFramePainter(
              frameRect: Rect.fromLTWH(frameLeft, frameTop, frameSize, frameSize),
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.customer.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.customer, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Apunta al código QR',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (!isProcessing) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Asegúrate de que el código esté bien iluminado',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER FOR SCANNER FRAME
// ═════════════════════════════════════════════════════════════════════════════
class _ScannerFramePainter extends CustomPainter {
  final Rect frameRect;

  _ScannerFramePainter({required this.frameRect});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(frameRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, bgPaint);

    final framePaint = Paint()
      ..color = AppColors.employee
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(frameRect, framePaint);

    final cornerSize = 24.0;
    final cornerPaint = Paint()
      ..color = AppColors.customer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(frameRect.left, frameRect.top + cornerSize), Offset(frameRect.left, frameRect.top), cornerPaint);
    canvas.drawLine(Offset(frameRect.left, frameRect.top), Offset(frameRect.left + cornerSize, frameRect.top), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(frameRect.right - cornerSize, frameRect.top), Offset(frameRect.right, frameRect.top), cornerPaint);
    canvas.drawLine(Offset(frameRect.right, frameRect.top), Offset(frameRect.right, frameRect.top + cornerSize), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(frameRect.left, frameRect.bottom - cornerSize), Offset(frameRect.left, frameRect.bottom), cornerPaint);
    canvas.drawLine(Offset(frameRect.left, frameRect.bottom), Offset(frameRect.left + cornerSize, frameRect.bottom), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(frameRect.right, frameRect.bottom - cornerSize), Offset(frameRect.right, frameRect.bottom), cornerPaint);
    canvas.drawLine(Offset(frameRect.right - cornerSize, frameRect.bottom), Offset(frameRect.right, frameRect.bottom), cornerPaint);
  }

  @override
  bool shouldRepaint(_ScannerFramePainter oldDelegate) => oldDelegate.frameRect != frameRect;
}