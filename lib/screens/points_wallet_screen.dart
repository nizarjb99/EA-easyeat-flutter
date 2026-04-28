import 'package:flutter/material.dart';

class PointsWalletScreen extends StatelessWidget {
  const PointsWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Points Wallet'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('View your earned points and rewards (Coming Soon!)'),
      ),
    );
  }
}
