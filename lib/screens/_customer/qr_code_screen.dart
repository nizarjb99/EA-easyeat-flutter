import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';

class QRCodeScreen extends StatelessWidget {
  final String? restaurantId;
  final String? rewardId;

  const QRCodeScreen({
    super.key,
    this.restaurantId,
    this.rewardId,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Use the general getters from AuthProvider
    final String? customerId = authProvider.id;
    final String customerName = authProvider.displayName;
    final String? customerEmail = authProvider.email;
    final bool isRewardQr =
        restaurantId != null && restaurantId!.isNotEmpty && rewardId != null && rewardId!.isNotEmpty;

    final String qrData = isRewardQr
        ? jsonEncode({
            'customer_id': customerId,
            'restaurant_id': restaurantId,
            'reward_id': rewardId,
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
          ],
        ),
      ),
    );
  }
}
