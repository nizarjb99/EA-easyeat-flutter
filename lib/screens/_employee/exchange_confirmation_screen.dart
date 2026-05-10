import 'package:flutter/material.dart';

class ExchangeConfirmationScreen extends StatelessWidget {
  const ExchangeConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final customerName = (args?['customerName'] ?? 'Customer').toString();
    final rewardName = (args?['rewardName'] ?? 'Reward').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Exchange confirmed')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 72),
              const SizedBox(height: 16),
              Text(
                'Exchange completed',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text('Customer: $customerName'),
              const SizedBox(height: 8),
              Text('Reward: $rewardName'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
