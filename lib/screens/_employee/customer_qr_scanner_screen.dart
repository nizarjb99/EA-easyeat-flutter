import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';
import '../../utils/styles.dart';

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

    // Avoid using firstOrNull if you want simpler/safer behavior
    final barcode = barcodes.barcodes.isNotEmpty ? barcodes.barcodes.first : null;
    final rawValue = barcode?.rawValue?.trim();

    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _scannedCustomerId = rawValue;
    });

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/add-visit',
        arguments: {
          'customerId': rawValue,
        },
      );
  }

  void _reset() {
    if (!mounted) return;
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
        backgroundColor: Colors.red.shade600,
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
      backgroundColor: AppColors.dashboardHeader,
      appBar: AppBar(
        backgroundColor: AppColors.dashboardHeader,
        elevation: 0,
        title: const Text(
          'Scan Customer QR Code',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on, color: AppColors.customer),
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
            placeholderBuilder: (context, child) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.customer),
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
                    CircularProgressIndicator(color: AppColors.customer),
                    SizedBox(height: 16),
                    Text(
                      'Verifying customer...',
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
                          'Position the QR code in the frame',
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
                        'Make sure the code is clearly visible and well-lit',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
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

    // Draw frame border (employee green)
    final framePaint = Paint()
      ..color = AppColors.employee
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(frameRect, framePaint);

    // Draw corner brackets (customer orange)
    final cornerSize = 24.0;
    final cornerPaint = Paint()
      ..color = AppColors.customer
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