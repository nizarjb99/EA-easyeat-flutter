import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import '../../utils/styles.dart';
import '../../widgets/language_selector.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String _loginType = 'customer'; // 'customer' | 'employee'

  Future<void> _login() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
      role: _loginType == 'customer' ? 'customer' : 'employee',
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;
    final errorMessage = authProvider.errorMessage;
    
    final primaryColor = _loginType == 'customer' ? AppColors.customer : AppColors.employee;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light grayish background
      body: Stack(
        children: [
          // Radial Gradient Background Effect (mimicking image)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.5),
                  radius: 1.5,
                  colors: [
                    primaryColor.withOpacity(0.08),
                    const Color(0xFFF1F5F9),
                  ],
                ),
              ),
            ),
          ),
          
          const SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: LanguageSelector(),
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and Brand
                    const _EasyEatLogo(),
                    const SizedBox(height: 40),

                    // Login Card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'auth.welcome_back'.tr(),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'auth.login_subtitle'.tr(),
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 32),
                          
                          // Tab Selector (mimicking image 2)
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _buildTabBtn('customer', 'auth.customer'.tr(), Icons.person_outline),
                                _buildTabBtn('employee', 'auth.employee'.tr(), Icons.business_center_outlined),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          _buildTextField(
                            controller: _emailController,
                            label: 'auth.email_label'.tr(),
                            placeholder: 'auth.email_placeholder'.tr(),
                            icon: Icons.mail_outline,
                          ),
                          const SizedBox(height: 20),
                          
                          _buildTextField(
                            controller: _passwordController,
                            label: 'auth.password_label'.tr(),
                            placeholder: 'auth.password_placeholder'.tr(),
                            icon: Icons.lock_outline,
                            isPassword: true,
                            isVisible: _isPasswordVisible,
                            onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                          
                          if (errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600))),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: isLoading ? null : _login,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      'auth.login_button'.tr(),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFCBD5E1))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('auth.or'.tr(), style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFCBD5E1))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: isLoading ? null : () {
                                context.read<AuthProvider>().loginWithGoogle(
                                  role: _loginType == 'customer' ? 'customer' : 'employee',
                                ).then((success) {
                                  if (success && mounted) {
                                    Navigator.pushReplacementNamed(context, '/dashboard');
                                  }
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blue)),
                                  const SizedBox(width: 12),
                                  Text(
                                    'auth.google_continue'.tr(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'auth.no_account'.tr(),
                          style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: Text(
                            'auth.register_free'.tr(),
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String type, String label, IconData icon) {
    final isActive = _loginType == type;
    final primaryColor = type == 'customer' ? AppColors.customer : AppColors.employee;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _loginType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive 
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] 
              : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? primaryColor : const Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? primaryColor : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !isVisible,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: placeholder,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF64748B),
                      size: 18,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _loginType == 'customer' ? AppColors.customer : AppColors.employee, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// ── Logo reutilitzable ────────────────────────────────────────────────────────
class _EasyEatLogo extends StatelessWidget {
  const _EasyEatLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _ForkSpoonIcon(size: 40),
            const SizedBox(width: 10),
            const Text(
              'EASY',
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Color(0xFF18B97A),
                letterSpacing: -1,
                height: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFCCCCCC),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Text(
              'EAT',
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE8450A),
                letterSpacing: -1,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 50),
            Container(
              width: 82,
              height: 2.5,
              decoration: BoxDecoration(
                color: const Color(0xFF18B97A).withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 18),
            Container(
              width: 60,
              height: 2.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE8450A).withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'SIMPLE. FAST. DELICIOUS.',
          style: TextStyle(
            fontFamily: 'Arial',
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: Color(0xFF999999),
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }
}

class _ForkSpoonIcon extends StatelessWidget {
  final double size;
  const _ForkSpoonIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.6,
      height: size,
      child: CustomPaint(painter: _ForkSpoonPainter()),
    );
  }
}

class _ForkSpoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green = Paint()
      ..color = const Color(0xFF18B97A)
      ..style = PaintingStyle.fill;
    final orange = Paint()
      ..color = const Color(0xFFE8450A)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.50, w * 0.20, h * 0.46), const Radius.circular(4)),
      green,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.02, h * 0.37, w * 0.34, h * 0.09), const Radius.circular(3)),
      green,
    );
    for (int i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.02 + i * (w * 0.12), h * 0.04, w * 0.09, h * 0.35), const Radius.circular(3)),
        green,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.70, h * 0.34, w * 0.20, h * 0.62), const Radius.circular(4)),
      orange,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.80, h * 0.18), width: w * 0.36, height: h * 0.28),
      orange,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}