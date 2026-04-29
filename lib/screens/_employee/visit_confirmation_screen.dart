import 'package:flutter/material.dart';

import '../../models/visit.dart';

class VisitConfirmationScreen extends StatelessWidget {
  const VisitConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final visit = args?['visit'] as Visit?;
    final customerName = (args?['customerName'] ?? 'Customer').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redemption confirmed'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 72),
              const SizedBox(height: 16),
              Text(
                'Redemption completed',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text('Customer: $customerName'),
              const SizedBox(height: 8),
              Text('Bill amount: ${visit?.billAmount.toStringAsFixed(2) ?? '-'}'),
              const SizedBox(height: 8),
              Text('Points earned: ${visit?.pointsEarned.toStringAsFixed(0) ?? '-'}'),
              const SizedBox(height: 8),
              Text('Date: ${visit?.date.toLocal().toString() ?? '-'}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}