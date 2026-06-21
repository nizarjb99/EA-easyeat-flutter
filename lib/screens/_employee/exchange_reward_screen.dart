import 'package:ea_easyeat_flutter/models/customer.dart';
import 'package:ea_easyeat_flutter/services/customer_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/reward.dart';
import '../../providers/auth_provider.dart';
import '../../services/reward_service.dart';

const Color _green = Color(0xFF16A34A);
const Color _red = Color(0xFFFF0000);
const Color _dark = Color(0xFF0F172A);
const Color _grey = Color(0xFF64748B);

class ExchangeRewardScreen extends StatefulWidget {
  const ExchangeRewardScreen({super.key});

  @override
  State<ExchangeRewardScreen> createState() => _ExchangeRewardScreenState();
}

class _ExchangeRewardScreenState extends State<ExchangeRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  final RewardService _rewardService = RewardService();
  final CustomerService _customerService = CustomerService();

  bool _isSaving = false;
  bool _isLoading = false;
  String _rewardName = '';
  bool _hasFetchedReward = false;
  String _customerName = '';
  bool _hasFetchedCustomer = false;
  String idempotencyKey = Uuid().v4();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (!_hasFetchedReward) {
      final rewardId = args?['rewardId']?.toString();

      if (rewardId != null && rewardId.isNotEmpty) {
        _fetchReward(rewardId).then((r) {
          if (r != null && mounted) {
            setState(() {
              _rewardName = r.name;
            });
          }
        });
      }
      _hasFetchedReward = true;
    }

    if (!_hasFetchedCustomer) {
      final customerId = args?['customerId']?.toString();

      if (customerId != null && customerId.isNotEmpty) {
        _fetchCustomer(customerId).then((r) {
          if (r != null && mounted) {
            setState(() {
              _customerName = r.name;
            });
          }
        });
      }
      _hasFetchedCustomer = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _submitExchange({
    required String customer_id,
    required String reward_id,
    required String restaurant_id,
  }) async {
    final auth = context.read<AuthProvider>();
    final employeeId = auth.id;

    if (employeeId == null || employeeId.isEmpty) {
      _showError('Employee not authenticated');
      return;
    }

    if (auth.currentEmployee?.restaurantId != restaurant_id) {
      _showError('Reward not from the same restaurant.');
      return;
    }

    final token = auth.accessToken;

    if (token == null || token.isEmpty) {
      _showError('Authentication required');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final createdVisit = await _rewardService.redeemReward(
        customer_id,
        reward_id,
        employeeId,
        token,
        idempotencyKey,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/exchange-confirmation',
        arguments: {'customerName': _customerName, 'rewardName': _rewardName},
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
      idempotencyKey = Uuid().v4();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<Customer?> _fetchCustomer(String customerId) async {
    final auth = context.read<AuthProvider>();
    final token = auth.accessToken;

    if (token == null) return null;

    setState(() => _isLoading = true);

    try {
      final customer = await _customerService.getCustomerById(
        customerId,
        token,
      );

      if (!mounted) return null;
      return customer;
    } catch (e) {
      if (!mounted) return null;
      _showError(e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Reward?> _fetchReward(String rewardId) async {
    setState(() => _isLoading = true);

    try {
      final reward = await _rewardService.fetchRewardById(rewardId);

      if (!mounted) return null;
      if (!reward.isValid) return null;
      return reward;
    } catch (e) {
      if (!mounted) return null;
      _showError(e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final customerId = (args?['customerId'] ?? '').toString();
    final rewardId = (args?['rewardId'] ?? '').toString();
    final restaurantId = (args?['restaurantId'] ?? '').toString();
    final customerName = _customerName.isEmpty
        ? 'Loading customer name...'
        : _customerName;
    final rewardName = _rewardName.isEmpty
        ? 'Loading reward name...'
        : _rewardName;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Confirm the reward exchange',
          style: TextStyle(color: _dark, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _dark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reward',
                      style: TextStyle(
                        color: _grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rewardName,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rewardId,
                      style: const TextStyle(color: _grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer',
                      style: TextStyle(
                        color: _grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      customerName,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customerId,
                      style: const TextStyle(color: _grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Do you want to exchenge this reward to this customer?',
                style: TextStyle(
                  color: _dark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 32),

              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () => _submitExchange(
                              customer_id: customerId,
                              reward_id: rewardId,
                              restaurant_id: restaurantId,
                            ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Yes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: (() => Navigator.pop(context)),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
