import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/visit.dart';
import '../../providers/auth_provider.dart';
import '../../services/restaurant_service.dart';
import '../../services/employee_service.dart';
import '../../utils/styles.dart';
import '../_employee/customer_qr_scanner_screen.dart';
import '../../models/employeeStats.dart';
import '../../widgets/language_dropdown_widget.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const Color _orange = Color(0xFFFF7A1A);
const Color _green = Color(0xFF16A34A);
const Color _blue = Color(0xFF2563EB);
const Color _amber = Color(0xFFD97706);
const Color _red = Color(0xFFDC2626);
const Color _dark = Color(0xFF0F172A);
const Color _grey = Color(0xFF64748B);
const Color _background = Color(0xFFF8FAFC);
const Color _cardBorder = Color(0xFFE2E8F0);

// ─── Fake activity-feed entry (replace with real model when API is ready) ─────
enum _FeedType { visit, redemption, review }

class _FeedEntry {
  final _FeedType type;
  final String text;
  final DateTime time;
  const _FeedEntry({
    required this.type,
    required this.text,
    required this.time,
  });
}

// ─── Fake alert entry ─────────────────────────────────────────────────────────
enum _AlertSeverity { warning, info }

class _AlertEntry {
  final _AlertSeverity severity;
  final String message;
  const _AlertEntry({required this.severity, required this.message});
}

// ═════════════════════════════════════════════════════════════════════════════
class HomeEmployeeScreen extends StatefulWidget {
  const HomeEmployeeScreen({super.key});

  @override
  State<HomeEmployeeScreen> createState() => _HomeEmployeeScreenState();
}

class _HomeEmployeeScreenState extends State<HomeEmployeeScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  final EmployeeService _employeeService = EmployeeService();

  // ── raw data from backend ──────────────────────────────────────────────────
  List<Visit> _visits = [];
  bool _isLoading = true;
  bool _isStatsLoading = true;
  Map<String, dynamic>? _restaurantData;

  // This value is loaded and kept for future use in the UI.
  // ignore: unused_field
  EmployeeStatistics? _employeeStats;

  // ── today's window ─────────────────────────────────────────────────────────
  DateTime get _todayStart {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ── KPI helpers (derived from Visit / Review / RewardRedemption models) ────

  /// pointsEarned (Visit.pointsEarned) summed for today
  int get _pointsGivenToday {
    return _visits
        .where((v) => !v.date.isBefore(_todayStart) && v.deletedAt == null)
        .fold(0, (sum, v) => sum + v.pointsEarned.toInt());
  }

  /// count of non-deleted visits today (Visit.deletedAt == null)
  int get _visitsToday {
    return _visits
        .where((v) => !v.date.isBefore(_todayStart) && v.deletedAt == null)
        .length;
  }

  /// placeholder — replace with RewardRedemption API call
  /// (RewardRedemption.status == 'redeemed', filtered by date)
  int get _redeemedToday => 0;

  /// placeholder — replace with Review API call
  /// (Review.globalRating, Review.deleted == false)
  double? get _avgRatingToday => null;

  // ── Activity feed (stub — replace with real API / websocket) ───────────────
  List<_FeedEntry> get _feedEntries {
    final entries = <_FeedEntry>[];
    for (final v in _visits.take(5)) {
      // Visit model: customerName, pointsEarned, date
      entries.add(
        _FeedEntry(
          type: _FeedType.visit,
          text: 'home.earned_points'.tr(
            args: [
              _textOrFallback(v.customerName, 'dashboard.roles.customer'.tr()),
              v.pointsEarned.toInt().toString(),
            ],
          ),
          time: v.date,
        ),
      );
    }
    return entries;
  }

  // ── Alerts (derived from real data; extend with review/stats API) ──────────
  List<_AlertEntry> get _alerts {
    final list = <_AlertEntry>[];
    if (_visitsToday == 0 && !_isLoading) {
      list.add(
        _AlertEntry(
          severity: _AlertSeverity.info,
          message: 'home.fewer_visits'.tr(),
        ),
      );
    }
    // Extend: pull Review.ratings.staffService average; if < 6 add warning
    // Extend: pull Statistics.loyalCustomers trend
    return list;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final auth = context.read<AuthProvider>();
      final restaurantFromProvider = _mapOrEmpty(auth.restaurant);
      final profileFromProvider = _mapOrEmpty(
        restaurantFromProvider['profile'],
      );
      final employeeRestaurantId = auth.currentEmployee?.restaurantId
          .toString()
          .trim();
      final restaurantId =
          _restaurantId(restaurantFromProvider, profileFromProvider) ??
          ((employeeRestaurantId != null && employeeRestaurantId.isNotEmpty)
              ? employeeRestaurantId
              : null);
      final employeeId = auth.currentEmployee?.id ?? auth.id;

      if (restaurantId == null) {
        if (!mounted) return;
        setState(() {
          _restaurantData = restaurantFromProvider.isNotEmpty
              ? restaurantFromProvider
              : null;
          _isLoading = false;
          _isStatsLoading = false;
        });
        return;
      }

      final needsRestaurantFetch = !_hasRestaurantProfile(
        restaurantFromProvider,
      );

      final results = await Future.wait<dynamic>([
        _restaurantService
            .fetchVisitsByRestaurant(
              restaurantId,
              accessToken: auth.accessToken,
            )
            .catchError((_) => <Visit>[]),
        needsRestaurantFetch
            ? _restaurantService
                  .fetchRestaurantById(
                    restaurantId,
                    accessToken: auth.accessToken,
                  )
                  .then<Map<String, dynamic>?>(
                    (restaurant) => restaurant.toJson(),
                  )
                  .catchError((_) => null)
            : Future<Map<String, dynamic>?>.value(
                restaurantFromProvider.isNotEmpty
                    ? restaurantFromProvider
                    : null,
              ),
      ]);

      final visits = results[0] as List<Visit>;
      final restaurantData = results[1] as Map<String, dynamic>?;

      if (!mounted) return;
      setState(() {
        _visits = visits;
        _restaurantData = restaurantData ?? restaurantFromProvider;
        _isLoading = false;
      });

      if (employeeId == null || employeeId.isEmpty) {
        if (!mounted) return;
        setState(() => _isStatsLoading = false);
        return;
      }

      _loadEmployeeStatistics(employeeId, auth.accessToken);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isStatsLoading = false;
      });
    }
  }

  Future<void> _loadEmployeeStatistics(
    String employeeId,
    String? accessToken,
  ) async {
    try {
      final stats = await _employeeService
          .fetchEmployeeStatistics(employeeId, accessToken: accessToken)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() {
        _employeeStats = stats;
        _isStatsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _employeeStats = null;
        _isStatsLoading = false;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final employee = auth.currentEmployee;
    final restaurant = _restaurantData ?? _mapOrEmpty(auth.restaurant);
    final profile = _mapOrEmpty(restaurant['profile']);
    final location = _mapOrEmpty(profile['location']);

    final restaurantName = _textOrFallback(
      profile['name'] ?? restaurant['name'],
      'home.tu_restaurante'.tr(),
    );
    final restCity = _textOrNull(location['city']);
    final restAddress = _textOrNull(location['address']);
    final rating = profile['globalRating'] ?? restaurant['globalRating'];

    final role = employee?.role ?? auth.role ?? 'staff';
    final isOwner = role == 'owner';
    final displayName = _firstName(auth.displayName);
    final stats = _employeeStats;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'EasyEat',
                style: TextStyle(color: _dark, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 8),
              _RoleBadge(role: role),
            ],
          ),
        ),
        actions: [
          LanguageDropdownWidget(),
          if (MediaQuery.of(context).size.width >= 600)
            Center(
              child: Text(
                displayName,
                style: const TextStyle(
                  color: _dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          IconButton(
            tooltip: 'dashboard.logout'.tr(),
            onPressed: () {
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
            icon: const Icon(Icons.logout, color: _dark),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Restaurant Hero ──────────────────────────────────────
                    _RestaurantHero(
                      restaurantName: restaurantName,
                      city: restCity,
                      address: restAddress,
                      rating: rating,
                    ),

                    const SizedBox(height: 28),

                    // ════════════════════════════════════════════════════════
                    // 1. KPI CARDS
                    // ════════════════════════════════════════════════════════
                    _SectionTitle(
                      title: 'dashboard.overview'.tr(),
                      icon: Icons.bar_chart_rounded,
                    ),
                    const SizedBox(height: 14),
                    _KpiGrid(
                      cards: [
                        _KpiCard(
                          icon: Icons.people_alt_outlined,
                          label: 'dashboard.customers_served'.tr(),
                          value: stats != null
                              ? stats.totalCustomersServed.toString()
                              : (_isStatsLoading ? '…' : '0'),
                          color: _green,
                        ),
                        _KpiCard(
                          icon: Icons.payments_outlined,
                          label: 'dashboard.revenue_generated'.tr(),
                          value: stats != null
                              ? '\$${stats.totalRevenueGenerated.toStringAsFixed(2)}'
                              : (_isStatsLoading ? '…' : '\$0.00'),
                          color: _blue,
                        ),
                        _KpiCard(
                          icon: Icons.verified_rounded,
                          label: 'dashboard.reward_approvals'.tr(),
                          value: stats != null
                              ? stats.totalRewardApprovalsApproved.toString()
                              : (_isStatsLoading ? '…' : '0'),
                          color: _orange,
                        ),
                        _KpiCard(
                          icon: Icons.receipt_long_rounded,
                          label: 'dashboard.visits_handled'.tr(),
                          value: stats != null
                              ? stats.totalVisitsHandled.toString()
                              : (_isStatsLoading ? '…' : '0'),
                          color: _amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ════════════════════════════════════════════════════════
                    // 2. QUICK ACTIONS
                    // ════════════════════════════════════════════════════════
                    _SectionTitle(
                      title: 'home.quick_actions'.tr(),
                      icon: Icons.bolt_rounded,
                    ),
                    const SizedBox(height: 14),
                    _QuickActions(isOwner: isOwner),

                    const SizedBox(height: 28),

                    // ════════════════════════════════════════════════════════
                    // 3. LIVE ACTIVITY FEED
                    // ════════════════════════════════════════════════════════
                    _SectionTitle(
                      title: 'home.activity_feed'.tr(),
                      icon: Icons.stream,
                    ),
                    const SizedBox(height: 14),
                    _ActivityFeed(entries: _feedEntries, visits: _visits),

                    const SizedBox(height: 28),

                    // ════════════════════════════════════════════════════════
                    // 4. ALERTS & INSIGHTS
                    // ════════════════════════════════════════════════════════
                    if (_alerts.isNotEmpty) ...[
                      _SectionTitle(
                        title: 'home.alerts'.tr(),
                        icon: Icons.notifications_active_outlined,
                      ),
                      const SizedBox(height: 14),
                      _AlertsPanel(alerts: _alerts),
                      const SizedBox(height: 28),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  static String _formatRating(dynamic value) {
    if (value == null) return '-';
    final number = num.tryParse(value.toString());
    if (number == null) return '-';
    return number.toStringAsFixed(1);
  }

  Map<String, dynamic> _mapOrEmpty(dynamic value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  bool _hasRestaurantProfile(Map<String, dynamic> restaurant) {
    final profile = _mapOrEmpty(restaurant['profile']);
    return profile.isNotEmpty;
  }

  String _textOrFallback(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String? _textOrNull(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String _firstName(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'dashboard.roles.user_fallback'.tr();
    return text.split(RegExp(r'\s+')).first;
  }

  String? _restaurantId(
    Map<String, dynamic> restaurant,
    Map<String, dynamic> profile,
  ) {
    final dynamic rawId =
        restaurant['_id'] ??
        profile['_id'] ??
        restaurant['id'] ??
        profile['id'];
    final id = rawId?.toString().trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SECTION TITLE
// ═════════════════════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _orange, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _dark,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. KPI CARDS
// ═════════════════════════════════════════════════════════════════════════════
class _KpiCard {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _KpiGrid extends StatelessWidget {
  final List<_KpiCard> cards;
  const _KpiGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossCount = 2;
        if (constraints.maxWidth >= 800)
          crossCount = 4;
        else if (constraints.maxWidth < 300)
          crossCount = 1;

        final width =
            (constraints.maxWidth - (crossCount - 1) * 12) / crossCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (c) => SizedBox(
                  width: width,
                  child: _KpiTile(card: c),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  final _KpiCard card;
  const _KpiTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: card.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(card.icon, color: card.color, size: 20),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  card.value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _dark,
                  ),
                ),
              ),
              Text(
                card.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: _grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. QUICK ACTIONS
// ═════════════════════════════════════════════════════════════════════════════
class _QuickActions extends StatelessWidget {
  final bool isOwner;
  const _QuickActions({required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        final actions = <Widget>[
          // Redeem Reward — triggers RewardRedemption creation
          // (status: 'pending' → employee marks as 'redeemed')
          _ActionButton(
            icon: Icons.card_giftcard_rounded,
            label: 'home.redeem_reward'.tr(),
            sublabel: 'home.scan_approve'.tr(),
            color: _blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerQrScannerScreen(),
                ),
              );
            },
          ),
          // Add Visit & Points — creates Visit + updates PointsWallet
          _ActionButton(
            icon: Icons.add_circle_outline,
            label: 'home.add_visit'.tr(),
            sublabel: 'home.scan_assign'.tr(),
            color: _green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerQrScannerScreen(),
                ),
              );
            },
          ),
          if (isOwner)
            _ActionButton(
              icon: Icons.settings_outlined,
              label: 'home.settings'.tr(),
              sublabel: 'home.restaurant_config'.tr(),
              color: _orange,
              onTap: () {
                // TODO: navigate to settings
              },
            ),
        ];

        if (wide) {
          return Row(
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: actions[i]),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              actions[i],
            ],
          ],
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
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _grey,
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

// ═════════════════════════════════════════════════════════════════════════════
// 3. LIVE ACTIVITY FEED
// ═════════════════════════════════════════════════════════════════════════════
class _ActivityFeed extends StatelessWidget {
  final List<_FeedEntry> entries;
  final List<Visit> visits;

  const _ActivityFeed({required this.entries, required this.visits});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          children: [
            const Icon(Icons.stream, size: 36, color: _orange),
            const SizedBox(height: 12),
            Text(
              'home.no_activity'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: _dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Activity will appear here as visits and rewards are registered.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: entries
            .asMap()
            .entries
            .map(
              (e) => _FeedTile(
                entry: e.value,
                isLast: e.key == entries.length - 1,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  final _FeedEntry entry;
  final bool isLast;
  const _FeedTile({required this.entry, required this.isLast});

  IconData get _icon {
    switch (entry.type) {
      case _FeedType.visit:
        return Icons.stars_rounded;
      case _FeedType.redemption:
        return Icons.card_giftcard_rounded;
      case _FeedType.review:
        return Icons.star_rounded;
    }
  }

  Color get _color {
    switch (entry.type) {
      case _FeedType.visit:
        return _green;
      case _FeedType.redemption:
        return _blue;
      case _FeedType.review:
        return _amber;
    }
  }

  String _timeLabel() {
    final now = DateTime.now();
    final diff = now.difference(entry.time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${entry.time.day}/${entry.time.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              entry.text,
              style: const TextStyle(
                fontSize: 14,
                color: _dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _timeLabel(),
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 4. ALERTS & INSIGHTS
// ═════════════════════════════════════════════════════════════════════════════
class _AlertsPanel extends StatelessWidget {
  final List<_AlertEntry> alerts;
  const _AlertsPanel({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: alerts
          .asMap()
          .entries
          .map(
            (e) => Padding(
              padding: EdgeInsets.only(
                bottom: e.key < alerts.length - 1 ? 10 : 0,
              ),
              child: _AlertTile(alert: e.value),
            ),
          )
          .toList(),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final _AlertEntry alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isWarning = alert.severity == _AlertSeverity.warning;
    final color = isWarning ? _red : _blue;
    final bg = color.withOpacity(0.06);
    final emoji = isWarning ? '⚠️' : '📉';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RESTAURANT HERO
// ═════════════════════════════════════════════════════════════════════════════
class _RestaurantHero extends StatelessWidget {
  final String restaurantName;
  final String? city;
  final String? address;
  final dynamic rating;

  const _RestaurantHero({
    required this.restaurantName,
    this.city,
    this.address,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF243B55)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'home.managing'.tr(),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            restaurantName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (city != null && city!.isNotEmpty)
                _HeroTag(icon: Icons.location_on_outlined, text: city!),
              if (rating != null)
                _HeroTag(
                  icon: Icons.star,
                  text: _HomeEmployeeScreenState._formatRating(rating),
                ),
            ],
          ),
          if (address != null && address!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '📍 $address',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ROLE BADGE (AppBar)
// ═════════════════════════════════════════════════════════════════════════════
class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isOwner = role == 'owner';
    final badgeColor = isOwner ? _orange : _green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'dashboard.roles.$role'.tr().toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
