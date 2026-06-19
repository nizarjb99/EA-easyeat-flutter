import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'qr_code_screen.dart';

import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';
import '../../models/customerStats.dart';
import '../../widgets/language_dropdown_widget.dart';
import '../../widgets/theme_toggle_widget.dart';
import '../../widgets/easy_eat_logo.dart';
import '../../utils/styles.dart';

import '../../services/fcm_service.dart';
import '../../services/notification_router.dart';
import '../../providers/notification_provider.dart';
import '../_common/accessibility/accessibility_controller.dart';

// ─── Color Palette ──────────────────────────────────────────────────────────
const Color _orange = Color(0xFFFF7A1A);
const Color _green = Color(0xFF16A34A);
const Color _dark = Color(0xFF0F172A);
const Color _grey = Color(0xFF64748B);

class HomeCustomerScreen extends StatefulWidget {
  const HomeCustomerScreen({super.key});

  @override
  State<HomeCustomerScreen> createState() => _HomeCustomerScreenState();
}

class _HomeCustomerScreenState extends State<HomeCustomerScreen> {
  final CustomerService _customerService = CustomerService();
  CustomerStatistics? _customerStats;
  bool _isStatsLoading = true;


  @override
  void initState() {
    super.initState();
    _loadCustomerStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    final auth = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    final fcmService = FcmService();

    await fcmService.initialize(
      customerId: auth.id,
      getAccessToken: () => auth.accessToken,
      onNotificationTap: (payload) async {
        if (!mounted) return;
        await NotificationRouter.routeFromPayload(context, payload);
      },
      onForegroundNotification: (notification) {
        notificationProvider.upsertForegroundNotification(notification);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification.message),
            action: SnackBarAction(
              label: 'Veure',
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadCustomerStats() async {
    final auth = context.read<AuthProvider>();
    final customerId = auth.currentCustomer?.id;
    final token = auth.accessToken;

    if (customerId == null || customerId.isEmpty || token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() => _isStatsLoading = false);
      return;
    }

    try {
      final stats = await _customerService
          .fetchCustomerStatistics(
            customerId,
            accessToken: token,
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() {
        _customerStats = stats;
        _isStatsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _customerStats = null;
        _isStatsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stats = _customerStats;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.dashboardBg : const Color(0xFFFFFBF7);
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.text : _dark;
    final mutedColor = isDark ? AppColors.textMuted : _grey;
    final a11y = context.watch<AccessibilityController>();
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: EasyEatLogo(height: 50),
        ),
        actions: [
          const ThemeToggleWidget(),
          const LanguageDropdownWidget(),
          if (MediaQuery.of(context).size.width >= 600)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  auth.displayName.split(' ').first,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          IconButton(
            tooltip: 'dashboard.logout'.tr(),
            onPressed: () {
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
            icon: Icon(Icons.logout, color: textColor),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeCard(name: auth.displayName),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;
                final cards = [
                  _StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    value: stats != null
                        ? stats.currentPointsBalance.toString()
                        : (_isStatsLoading ? '…' : '0'),
                    label: 'dashboard.points_available'.tr(),
                    color: _orange,
                  ),
                  _StatCard(
                    icon: Icons.local_fire_department_outlined,
                    value: stats != null
                        ? stats.totalVisits.toString()
                        : (_isStatsLoading ? '…' : '0'),
                    label: 'dashboard.visits'.tr(),
                    color: _green,
                  ),
                  _StatCard(
                    icon: Icons.star_outline,
                    value: stats != null
                        ? stats.averageReviewRating.toStringAsFixed(1)
                        : (_isStatsLoading ? '…' : '-'),
                    label: 'dashboard.avg_rating'.tr(),
                    color: _orange,
                  ),
                  _StatCard(
                    icon: Icons.favorite_outline,
                    value: stats != null
                        ? stats.favoriteRestaurants.toString()
                        : (_isStatsLoading ? '…' : '0'),
                    label: 'dashboard.favorite_restaurants'.tr(),
                    color: _green,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: cards
                        .map((card) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: card,
                              ),
                            ))
                        .toList(),
                  );
                }

                return Column(
                  children: [
                    Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
                    const SizedBox(height: 12),
                    Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            const _QuickActions(),
            const SizedBox(height: 28),
            TextField(
              decoration: InputDecoration(
                hintText: 'customer.search_hint'.tr(),
                prefixIcon: Icon(Icons.search, color: mutedColor),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'customer.recommended'.tr(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor),
            ),
            const SizedBox(height: 16),
            _EmptyCard(
              icon: Icons.restaurant,
              title: 'customer.no_restaurants'.tr(),
              subtitle: 'customer.connect_endpoint'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  const _WelcomeCard({required this.name});

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_orange, Color(0xFFFFB347)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('dashboard.welcome_back'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('$firstName 👋', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('dashboard.discover_flavors'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.text : _dark;
    final mutedColor = isDark ? AppColors.textMuted : _grey;

    return Container(
      constraints: const BoxConstraints(minHeight: 125),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Text(
            value,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor),
          ),
          Text(
            label,
            style: TextStyle(color: mutedColor, fontWeight: FontWeight.w600, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      icon: Icons.qr_code_2_rounded,
      label: 'customer.show_qr'.tr(),
      sublabel: 'customer.qr_sublabel'.tr(),
      color: _orange,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const QRCodeScreen(),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.text : _dark;
    final mutedColor = isDark ? AppColors.textMuted : _grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
           boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.04),
               blurRadius: 14,
               offset: const Offset(0, 6),
             ),
           ],
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                     label,
                     style: TextStyle(
                       fontSize: 15,
                       fontWeight: FontWeight.w900,
                       color: textColor,
                     ),
                   ),
                   const SizedBox(height: 2),
                   Text(
                     sublabel,
                     style: TextStyle(
                       fontSize: 12,
                       color: mutedColor,
                       fontWeight: FontWeight.w500,
                     ),
                   ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.text : _dark;
    final mutedColor = isDark ? AppColors.textMuted : _grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: mutedColor, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedColor,
                ),
          ),
        ],
      ),
    );
  }
}