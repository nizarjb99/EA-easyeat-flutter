import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pointsWallet.dart';
import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';
import '../../services/restaurant_service.dart';
import '../_common/restaurant_detail_screen.dart';

class PointsWalletScreen extends StatefulWidget {
  const PointsWalletScreen({super.key});

  @override
  State<PointsWalletScreen> createState() => _PointsWalletScreenState();
}

class _PointsWalletScreenState extends State<PointsWalletScreen> {
  final CustomerService _customerService = CustomerService();
  final RestaurantService _restaurantService = RestaurantService();

  bool _isLoading = true;
  String? _errorMessage;
  List<PointsWallet> _wallets = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWallet();
    });
  }

  int get _totalPoints => _wallets.fold<int>(0, (sum, wallet) => sum + wallet.points);

  DateTime? get _lastUpdate {
    final dates = _wallets
        .map((wallet) => wallet.updatedAt ?? wallet.createdAt)
        .whereType<DateTime>()
        .toList();

    if (dates.isEmpty) return null;
    dates.sort((a, b) => b.compareTo(a));
    return dates.first;
  }

  Future<void> _openRestaurantFromWallet(PointsWallet wallet) async {
    final restaurantId = wallet.restaurant.id;
    if (restaurantId.isEmpty) return;

    try {
      final restaurant = await _restaurantService.fetchRestaurantById(
        restaurantId,
        accessToken: context.read<AuthProvider>().accessToken,
      );

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open restaurant: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  Future<void> _loadWallet() async {
    final auth = context.read<AuthProvider>();

    if (auth.id == null || auth.accessToken == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'You need to be logged in as a customer to view your points wallet.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _customerService.getCustomerPointsWallet(
        auth.id!,
        auth.accessToken!,
        page: 1,
        limit: 100,
      );

      final items = _extractWalletItems(response)
          .whereType<Map<String, dynamic>>()
          .map(PointsWallet.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _wallets = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  List<dynamic> _extractWalletItems(dynamic response) {
    if (response is List) return response;

    if (response is Map<String, dynamic>) {
      for (final key in const ['data', 'pointsWallet', 'wallets', 'items', 'docs', 'results']) {
        final candidate = response[key];
        if (candidate is List) return candidate;
      }

      if (response.containsKey('_id') || response.containsKey('id')) {
        return [response];
      }
    }

    return const [];
  }

  String _shortId(String value) {
    if (value.isEmpty) return 'Unknown';
    if (value.length <= 8) return value;
    return '${value.substring(0, 8)}…';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'No date';
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Points Wallet',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadWallet,
            icon: const Icon(Icons.refresh, color: Color(0xFF0F172A)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWallet,
        color: const Color(0xFFFF7A1A),
        child: _buildBody(auth),
      ),
    );
  }

  Widget _buildBody(AuthProvider auth) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 48),
          _StateCard(
            icon: Icons.error_outline_rounded,
            title: 'Couldn’t load points wallet',
            subtitle: _errorMessage!,
            buttonLabel: 'Try again',
            onPressed: _loadWallet,
            color: const Color(0xFFDC2626),
          ),
        ],
      );
    }

    if (_wallets.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 48),
          _StateCard(
            icon: Icons.wallet_giftcard_rounded,
            title: 'No points yet',
            subtitle: 'Your wallet will appear here once you start earning points from visits.',
            buttonLabel: 'Refresh',
            onPressed: _loadWallet,
            color: const Color(0xFFFF7A1A),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        _SummaryCard(
          customerName: auth.displayName,
          totalPoints: _totalPoints,
          walletCount: _wallets.length,
          lastUpdate: _lastUpdate,
        ),
        const SizedBox(height: 20),
        const Text(
          'Wallet entries',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        ..._wallets.map(
          (wallet) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _WalletTile(
              wallet: wallet,
              restaurantLabel: wallet.restaurant.name ??
                  'Restaurant ${_shortId(wallet.restaurant.id)}',
              cityLabel: wallet.restaurant.city,
              dateLabel: _formatDate(wallet.updatedAt ?? wallet.createdAt),
              onTap: () => _openRestaurantFromWallet(wallet),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _InfoBanner(),
      ],
    );
  }
}




class _SummaryCard extends StatelessWidget {
  final String customerName;
  final int totalPoints;
  final int walletCount;
  final DateTime? lastUpdate;

  const _SummaryCard({
    required this.customerName,
    required this.totalPoints,
    required this.walletCount,
    required this.lastUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A1A), Color(0xFFFFB347)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7A1A).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $customerName',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your points balance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$totalPoints',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(
                icon: Icons.account_balance_wallet_outlined,
                value: '$walletCount',
                label: 'Wallet records',
              ),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.update_outlined,
                value: lastUpdate == null ? '—' : _formatDateShort(lastUpdate!),
                label: 'Last update',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDateShort(DateTime value) {
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  final PointsWallet wallet;
  final String restaurantLabel;
  final String? cityLabel;
  final String dateLabel;
  final VoidCallback onTap;

  const _WalletTile({
    required this.wallet,
    required this.restaurantLabel,
    required this.cityLabel,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A1A).withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Color(0xFFFF7A1A),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurantLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (cityLabel != null && cityLabel!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      cityLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'Updated: $dateLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Wallet ID: ${_shortId(wallet.id)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${wallet.points}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const Text(
                  'points',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shortId(String value) {
    if (value.isEmpty) return 'Unknown';
    if (value.length <= 8) return value;
    return '${value.substring(0, 8)}…';
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;
  final Color color;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 54, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD8B0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFFF7A1A)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Points are updated when a visit is added or a reward is redeemed. Pull down to refresh the latest balance.',
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}