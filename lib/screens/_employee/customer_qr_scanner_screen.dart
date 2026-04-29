import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';
import '../../utils/styles.dart';

// ─── Palette (matches home_employee_screen.dart) ──────────────────────────────
const Color _orange = Color(0xFFFF7A1A);
const Color _green = Color(0xFF16A34A);
const Color _blue = Color(0xFF2563EB);
const Color _dark = Color(0xFF0F172A);
const Color _grey = Color(0xFF64748B);
const Color _background = Color(0xFFF8FAFC);

// ═════════════════════════════════════════════════════════════════════════════
class CustomerQrScannerScreen extends StatefulWidget {
  const CustomerQrScannerScreen({super.key});

  @override
  State<CustomerQrScannerScreen> createState() => _CustomerQrScannerScreenState();
}

class _CustomerQrScannerScreenState extends State<CustomerQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final CustomerService _customerService = CustomerService();

  bool _isProcessing = false;
  String? _scannedCustomerId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQrDetection(BarcodeCapture barcodes) async {
    if (_isProcessing || _scannedCustomerId != null) return;

    final barcode = barcodes.barcodes.firstOrNull;
    if (barcode?.rawValue == null || barcode!.rawValue!.isEmpty) return;

    final customerId = barcode.rawValue!.trim();

    setState(() {
      _isProcessing = true;
      _scannedCustomerId = customerId;
    });

    if (!mounted) return;

    try {
      final auth = context.read<AuthProvider>();
      final token = auth.accessToken;

      if (token == null || token.isEmpty) {
        _showError('Authentication required');
        _reset();
        return;
      }

      // Verify customer exists by fetching their data
      final customer = await _customerService.getCustomerById(customerId, token);

      if (!mounted) return;

      // Success: navigate to visit form and pass customer data
      Navigator.pushReplacementNamed(
        context,
        '/add-visit',
        arguments: {
          'customerId': customer.id,
          'customerName': customer.name,
          'customerEmail': customer.email,
        },
      );
    } catch (e) {
      _showError('Customer not found or network error');
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _isProcessing = false;
      _scannedCustomerId = null;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFlash() {
    _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        backgroundColor: _dark,
        elevation: 0,
        title: const Text(
          'Scan Customer QR Code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on, color: _orange),
            tooltip: 'Toggle flash',
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(
            controller: _controller,
            onDetect: _handleQrDetection,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 48,
                      color: _orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Camera permission required',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
            placeholderBuilder: (context, child) {
              return const Center(
                child: CircularProgressIndicator(color: _orange),
              );
            },
          ),

          // Overlay with scanner frame and instructions
          _ScannerOverlay(isProcessing: _isProcessing),

          // Loading indicator (if processing)
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: _orange),
                    SizedBox(height: 16),
                    Text(
                      'Verifying customer...',
                      style: TextStyle(
                        color: Colors.white,
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
    final frameTop = (screenSize.height - frameSize) / 2 - 40;

    return Stack(
      children: [
        // Semi-transparent overlay outside scanner frame
        Positioned.fill(
          child: CustomPaint(
            painter: _ScannerFramePainter(
              frameRect: Rect.fromLTWH(frameLeft, frameTop, frameSize, frameSize),
            ),
          ),
        ),

        // Instructions below frame
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
                  border: Border.all(color: _orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: _orange, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Position the QR code in the frame',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (!isProcessing) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Make sure the code is clearly visible and well-lit',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _grey,
                          fontSize: 11,
                        ),
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
    // Semi-transparent dark background outside frame
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Draw the dark area around the frame
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(frameRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, bgPaint);

    // Draw frame border (green)
    final framePaint = Paint()
      ..color = _green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(frameRect, framePaint);

    // Draw corner brackets
    final cornerSize = 24.0;
    final cornerPaint = Paint()
      ..color = _orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(
      Offset(frameRect.left, frameRect.top + cornerSize),
      Offset(frameRect.left, frameRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.left, frameRect.top),
      Offset(frameRect.left + cornerSize, frameRect.top),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(frameRect.right - cornerSize, frameRect.top),
      Offset(frameRect.right, frameRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.right, frameRect.top),
      Offset(frameRect.right, frameRect.top + cornerSize),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(frameRect.left, frameRect.bottom - cornerSize),
      Offset(frameRect.left, frameRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.left, frameRect.bottom),
      Offset(frameRect.left + cornerSize, frameRect.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(frameRect.right, frameRect.bottom - cornerSize),
      Offset(frameRect.right, frameRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.right - cornerSize, frameRect.bottom),
      Offset(frameRect.right, frameRect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(_ScannerFramePainter oldDelegate) {
    return oldDelegate.frameRect != frameRect;
  }
}