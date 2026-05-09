import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
// import 'login_screen.dart'; // Removed unused import

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    // Fetch full user data (including populated organization) when profile opens.
    Future.microtask(() {
      if (!mounted) return;
      context.read<AuthProvider>().loadProfileFromApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;
    final errorMessage = authProvider.errorMessage;

    // Use displayName, email, and restaurant from AuthProvider directly
    final String displayName = authProvider.displayName;
    final String? email = authProvider.email;
    final restaurantData = authProvider.restaurant;
    final String? restaurantName = restaurantData?['profile']?['name'] ?? restaurantData?['name'];

    // Check if there's any logged-in user (customer or employee)
    if (!authProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Error: User session not found or not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isLoading) const LinearProgressIndicator(),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Name'),
                      subtitle: Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      subtitle: Text(
                        email ?? 'N/A', // Display N/A if email is null
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (authProvider.isEmployee) ...[ // Only show restaurant for employees
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.business),
                        title: const Text('Restaurante'),
                        subtitle: Text(
                          restaurantName ?? 'No asignado',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Log out', style: TextStyle(fontSize: 16)),
                onPressed: () {
                  context.read<AuthProvider>().logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
