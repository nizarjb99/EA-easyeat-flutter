import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/visit.dart';
import '../../providers/auth_provider.dart';
import '../../services/visit_service.dart';

const Color _orange = Color(0xFFFF7A1A);
const Color _green = Color(0xFF16A34A);
const Color _dark = Color(0xFF0F172A);
const Color _grey = Color(0xFF64748B);

class AddVisitScreen extends StatefulWidget {
  const AddVisitScreen({super.key});

  @override
  State<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billAmountController = TextEditingController();
  final VisitService _visitService = VisitService();

  bool _isSaving = false;

  @override
  void dispose() {
    _billAmountController.dispose();
    super.dispose();
  }

  String? _restaurantId(dynamic restaurant) {
    if (restaurant == null) return null;

    // If the provider stored a plain string id
    if (restaurant is String) {
      final id = restaurant.trim();
      return id.isEmpty ? null : id;
    }

    // If it's a Map, check multiple possible keys
    if (restaurant is Map<String, dynamic>) {
      final rawId =
          restaurant['_id'] ??
          restaurant['id'] ??
          restaurant['restaurant_id'] ??
          restaurant['restaurantId'];
      final id = rawId?.toString().trim();
      if (id == null || id.isEmpty) return null;
      return id;
    }

    // Unsupported shape
    return null;
  }

  Future<void> _submitVisit({
    required String customerId,
    required String customerName,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final employeeId = auth.id;

    // Try provider restaurant first, then fallback to currentEmployee.restaurantId
    final restaurantFromProvider = _restaurantId(auth.restaurant);
    final restaurantFromEmployee = auth.currentEmployee?.restaurantId
        ?.toString()
        .trim();
    final restaurantId =
        restaurantFromProvider ??
        (restaurantFromEmployee != null && restaurantFromEmployee.isNotEmpty
            ? restaurantFromEmployee
            : null);

    final token = auth.accessToken;

    if (employeeId == null || employeeId.isEmpty) {
      _showError('Employee not authenticated');
      return;
    }

    if (restaurantId == null || restaurantId.isEmpty) {
      _showError('No restaurant linked to this employee account');
      return;
    }

    if (token == null || token.isEmpty) {
      _showError('Authentication required');
      return;
    }

    final billAmount = double.tryParse(_billAmountController.text.trim());
    if (billAmount == null || billAmount <= 0) {
      _showError('Enter a valid bill amount');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final createdVisit = await _visitService.createVisit(
        token: token,
        customerId: customerId,
        restaurantId: restaurantId,
        employeeId: employeeId,
        billAmount: billAmount,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/visit-confirmation',
        arguments: {'visit': createdVisit, 'customerName': customerName},
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
    final customerName = (args?['customerName'] ?? 'Customer').toString();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Add Visit & Assign Points',
          style: TextStyle(color: _dark, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _dark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
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
                'Bill Amount',
                style: TextStyle(
                  color: _dark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _billAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter bill amount',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _grey.withOpacity(0.3)),
                  ),
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid bill amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Spacer(),

              SizedBox(
                width: double.infinity,
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
                      : () => _submitVisit(
                          customerId: customerId,
                          customerName: customerName,
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
                          'Save Visit & Assign Points',
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
        ),
      ),
    );
  }
}
