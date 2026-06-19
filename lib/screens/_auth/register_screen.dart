import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/styles.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Validation rules
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _passwordsMatch => _passwordController.text.isNotEmpty && 
                              _passwordController.text == _confirmPasswordController.text;

  bool get _isValid => _hasMinLength && _hasUppercase && _passwordsMatch && 
                       _nameController.text.isNotEmpty && _emailController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
  }

  Future<void> _register() async {
    if (!_isValid) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signup(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      // Success! main.dart will switch home automatically
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final errorMessage = authProvider.errorMessage;
    const primaryColor = AppColors.customer;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // Background Effect Orbs (Mimicking image 2/3 style)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.5, -0.5),
                  radius: 1.5,
                  colors: [
                    primaryColor.withOpacity(0.08),
                    const Color(0xFFF1F5F9),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 24),
                      
                      // Logo and Brand
                      Center(
                        child: Column(
                          children: [
                            const Text('🍽️', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 8),
                            const Text(
                              'EasyEat',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        'Crear nueva cuenta',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        'Rellena tus datos y empieza a disfrutar',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 40),
                      
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
                            _buildTextField(
                              controller: _nameController,
                              label: 'Nombre completo',
                              placeholder: 'Ej. Juan Pérez',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Correo electrónico',
                              placeholder: 'tu@email.com',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              placeholder: '••••••••',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              isVisible: _isPasswordVisible,
                              onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                            const SizedBox(height: 12),
                            
                            // Password Rules Tracker (Mimicking image 3)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                children: [
                                  _buildRuleItem(_hasMinLength, 'Mínimo 8 caracteres de longitud'),
                                  const SizedBox(height: 8),
                                  _buildRuleItem(_hasUppercase, 'Incluye al menos una letra mayúscula'),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirmar contraseña',
                              placeholder: '••••••••',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              isVisible: false, // Don't show for confirm
                            ),
                            
                            if (_confirmPasswordController.text.isNotEmpty) ...[
                               const SizedBox(height: 12),
                               _buildRuleItem(_passwordsMatch, 'Las contraseñas coinciden perfectamente'),
                            ],
                            
                            if (errorMessage.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  disabledBackgroundColor: primaryColor.withOpacity(0.5),
                                ),
                                onPressed: (authProvider.isLoading || !_isValid) ? null : _register,
                                child: authProvider.isLoading
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Finalizar Registro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            const Row(
                              children: [
                                Expanded(child: Divider(color: Color(0xFFCBD5E1))),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('O', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                ),
                                Expanded(child: Divider(color: Color(0xFFCBD5E1))),
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
                                onPressed: authProvider.isLoading ? null : () {
                                  context.read<AuthProvider>().registerWithGoogle().then((success) {
                                    if (success && mounted) {
                                      // If registered successfully, it also logs them in, 
                                      // and main.dart might handle routing if auth state changes, 
                                      // or we explicitly push to dashboard.
                                      // We don't push here because main.dart Consumer might take care of it,
                                      // but to be safe:
                                      // Wait, regular register relies on Consumer in main.dart:
                                      // "Success! main.dart will switch home automatically"
                                    }
                                  });
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blue)),
                                    SizedBox(width: 12),
                                    Text(
                                      'Registrarse con Google',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('¿Ya tienes cuenta?', style: TextStyle(color: Color(0xFF64748B))),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Inicia sesión en su lugar', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(bool isValid, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isValid ? const Color(0xFF16A34A).withOpacity(0.1) : const Color(0xFF94A3B8).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isValid ? Icons.check : Icons.close,
            size: 12,
            color: isValid ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isValid ? const Color(0xFF16A34A) : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !isVisible,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: placeholder,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            suffixIcon: isPassword && onToggleVisibility != null
                ? IconButton(icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF64748B), size: 20), onPressed: onToggleVisibility)
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.customer, width: 2)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
