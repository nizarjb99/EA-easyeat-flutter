import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/visit.dart';
import '../services/restaurant_service.dart';
import '../utils/styles.dart';
import '../models/employee.dart'; // Import Employee model

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RestaurantService _service = RestaurantService();
  List<Visit> _visits = [];
  bool _isLoading = true;
  // String _errorMessage = ''; // Removed as it's unused

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final auth = context.read<AuthProvider>();
      final employee = auth.currentEmployee; // Use currentEmployee instead of currentUser
      final restaurant = auth.restaurant; // Get restaurant from AuthProvider
      final token = auth.accessToken;

      if (restaurant == null || restaurant['_id'] == null) { // Check restaurant and its ID
        setState(() => _isLoading = false);
        return;
      }

      final visits = await _service.fetchVisitsByRestaurant(
        restaurant['_id'], // Use restaurant ID from the map
        accessToken: token,
      );

      if (!mounted) return;

      setState(() {
        _visits = visits;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // _errorMessage = e.toString(); // Removed as it's unused
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final employee = auth.currentEmployee; // Use currentEmployee
    final restaurantName = auth.restaurant?['name'] ?? 'Tu restaurante'; // Get restaurant name from AuthProvider

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C), // Matching Landing Page bg
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(employee), // Pass employee
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHero(restaurantName),
                          const SizedBox(height: 24),
                          _buildStats(),
                          const SizedBox(height: 32),
                          _buildSectionTitle('Acciones rápidas'),
                          const SizedBox(height: 16),
                          _buildQuickActions(),
                          const SizedBox(height: 32),
                          _buildSectionTitle('Visitas recientes'),
                          const SizedBox(height: 16),
                          _buildVisitsList(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(Employee? employee) { // Added type annotation
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 80,
      backgroundColor: const Color(0xFF0C0C0C).withAlpha((255 * 0.9).round()), // Fixed withOpacity
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF1F2937), width: 1)),
        ),
      ),
      title: Row(
        children: [
          const Text('🍽️ ', style: TextStyle(fontSize: 22)),
          const Text(
            'EasyEat',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((255 * 0.1).round()), // Fixed withOpacity
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.primary.withAlpha((255 * 0.3).round())), // Fixed withOpacity
            ),
            child: Text(
              (employee?.role ?? 'STAFF').toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937).withAlpha((255 * 0.5).round()), // Fixed withOpacity
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      employee?.name[0].toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    employee?.name.split(' ')[0] ?? 'Usuario',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(Icons.logout, size: 22, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }

  Widget _buildHero(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF1F2937)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha((255 * 0.05).round()), // Fixed withOpacity
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PANEL DE GESTIÓN',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHeroTag(Icons.location_on, 'Barcelona'),
              const SizedBox(width: 12),
              _buildHeroTag(Icons.star, '4.8', color: Colors.amber),
              const SizedBox(width: 12),
              _buildHeroTag(Icons.verified, 'Verificado', color: AppColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTag(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color ?? const Color(0xFF94A3B8), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final uniqueCustomers = _visits.map((v) => v.customerId).toSet().length;

    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.trending_up, _visits.length.toString(), 'Visitas', AppColors.accent)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(Icons.people, uniqueCustomers.toString(), 'Clientes', AppColors.primary)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(Icons.star, '4.8', 'Rating', Colors.amber)),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.1).round()), // Fixed withOpacity
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _buildActionCard(Icons.qr_code, 'Generar QR', 'Escaneo visita', Colors.orange)),
        const SizedBox(width: 16),
        Expanded(child: _buildActionCard(Icons.list_alt, 'Ver visitas', 'Historial', AppColors.primary)),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.1).round()), // Fixed withOpacity
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsList() {
    if (_visits.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        child: const Column(
          children: [
            Icon(Icons.history, size: 56, color: Color(0xFF374151)),
            SizedBox(height: 20),
            Text('No hay visitas registradas', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: _visits.take(5).map((visit) => _buildVisitItem(visit)).toList(),
      ),
    );
  }

  Widget _buildVisitItem(Visit visit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withAlpha((255 * 0.3).round()), AppColors.accent.withAlpha((255 * 0.2).round())], // Fixed withOpacity
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              (visit.customerName ?? 'C')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.customerName ?? 'Cliente',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(
                      '${visit.date.day}/${visit.date.month}/${visit.date.year}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // pointsEarned is now non-nullable with a default value, so no need for null check
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha((255 * 0.1).round()), // Fixed withOpacity
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${visit.pointsEarned.toInt()} pts', // Removed ! operator
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right, color: Color(0xFF4B5563)),
        ],
      ),
    );
  }
}
