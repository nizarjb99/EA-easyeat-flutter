import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/google_wallet_provider.dart';
import '../../services/nfc_service.dart';

class QRCodeScreen extends StatefulWidget {
  final String? restaurantId;
  final String? rewardId;

  const QRCodeScreen({
    super.key,
    this.restaurantId,
    this.rewardId,
  });

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen>
    with SingleTickerProviderStateMixin {
  bool _nfcActive = false;
  bool _nfcAvailable = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.85, end: 1.0).animate(_pulseController);

    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    final available = await NfcService.isNfcAvailable();
    if (mounted) setState(() => _nfcAvailable = available);
  }

  Future<void> _toggleNfc(String customerId) async {
    if (_nfcActive) {
      await NfcService.stopHceEmission();
      if (mounted) setState(() => _nfcActive = false);
    } else {
      final success = await NfcService.startHceEmission(customerId);
      if (mounted) {
        setState(() => _nfcActive = success);
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo activar NFC'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    if (_nfcActive) NfcService.stopHceEmission();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String? customerId = authProvider.id;
    final String customerName = authProvider.displayName;
    final String? customerEmail = authProvider.email;
    final bool isRewardQr = widget.restaurantId != null &&
        widget.restaurantId!.isNotEmpty &&
        widget.rewardId != null &&
        widget.rewardId!.isNotEmpty;

    final String qrData = isRewardQr
        ? jsonEncode({
            'customer_id': customerId,
            'restaurant_id': widget.restaurantId,
            'reward_id': widget.rewardId,
          })
        : customerId ?? '';

    if (customerId == null || customerId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My QR Code'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Inicia sesión para ver tu código QR'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isRewardQr ? 'Reward QR Code' : 'My QR Code'),
        centerTitle: true,
      ),
      body: Consumer<GoogleWalletProvider>(
        builder: (context, walletProvider, _) {
          return SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (customerEmail != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      customerEmail,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha((255 * 0.2).round()),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 250.0,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    isRewardQr
                        ? 'Show this QR code to redeem this reward'
                        : 'Show this QR code at the restaurant\nto identify yourself',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // ── NFC Button (only for identification QR, not reward) ──
                  if (!isRewardQr && _nfcAvailable) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _NfcButton(
                        isActive: _nfcActive,
                        pulseAnimation: _pulseAnimation,
                        onTap: () => _toggleNfc(customerId),
                      ),
                    ),
                  ],

                  // Google Wallet Button
                  if (!isRewardQr) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: walletProvider.isLoading
                                  ? null
                                  : () => _onAddToGoogleWalletPressed(
                                        context,
                                        customerId,
                                        walletProvider,
                                      ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                disabledBackgroundColor:
                                    Colors.blue.withAlpha((255 * 0.5).round()),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: walletProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_to_photos_outlined),
                                        SizedBox(width: 8),
                                        Text(
                                          'Add to Google Wallet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          if (walletProvider.errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    Colors.red.withAlpha((255 * 0.1).round()),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red
                                      .withAlpha((255 * 0.3).round()),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      walletProvider.errorMessage,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (walletProvider.success) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green
                                    .withAlpha((255 * 0.1).round()),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green
                                      .withAlpha((255 * 0.3).round()),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.green, size: 20),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Tarjeta añadida a Google Wallet',
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onAddToGoogleWalletPressed(
    BuildContext context,
    String customerId,
    GoogleWalletProvider walletProvider,
  ) async {
    walletProvider.clearState();
    final success = await walletProvider.openGoogleWalletSaveLink(customerId);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(walletProvider.errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// NFC BUTTON WIDGET
// ═══════════════════════════════════════════════════════════════
class _NfcButton extends StatelessWidget {
  final bool isActive;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  const _NfcButton({
    required this.isActive,
    required this.pulseAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.green.withAlpha((255 * 0.12).round())
              : Colors.grey.withAlpha((255 * 0.08).round()),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? Colors.green.withAlpha((255 * 0.6).round())
                : Colors.grey.withAlpha((255 * 0.3).round()),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive)
              ScaleTransition(
                scale: pulseAnimation,
                child: const Icon(Icons.nfc, color: Colors.green, size: 28),
              )
            else
              const Icon(Icons.nfc, color: Colors.grey, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'NFC Activo' : 'Activar NFC',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.green : Colors.grey[700],
                  ),
                ),
                Text(
                  isActive
                      ? 'Acerca el móvil del empleado'
                      : 'Identificación por proximidad',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.green[700] : Colors.grey[500],
                  ),
                ),
              ],
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                key: ValueKey(isActive),
                color: isActive ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// EOF
