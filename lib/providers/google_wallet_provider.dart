import 'package:flutter/foundation.dart';
import '../services/google_wallet_service.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleWalletProvider extends ChangeNotifier {
  GoogleWalletProvider() : _googleWalletService = GoogleWalletService();

  final GoogleWalletService _googleWalletService;

  bool _isLoading = false;
  String _errorMessage = '';
  bool _success = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get success => _success;

  // ── Methods ────────────────────────────────────────────────────────────────

  /// Obtiene el enlace de Google Wallet y lo abre en el navegador
  /// 
  /// Parámetros:
  /// - [userId]: ID del cliente
  /// 
  /// Retorna true si fue exitoso, false en caso contrario
  Future<bool> openGoogleWalletSaveLink(String userId) async {
    _isLoading = true;
    _errorMessage = '';
    _success = false;
    notifyListeners();

    try {
      // Obtener el enlace de Google Wallet desde el backend
      final walletUrl = await _googleWalletService.getGoogleWalletSaveLink(userId);

      // Intentar abrir la URL
      final Uri uri = Uri.parse(walletUrl);
      
      if (!await canLaunchUrl(uri)) {
        _errorMessage = 'No se pudo abrir Google Wallet. Por favor, intenta más tarde.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      _success = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpia el estado del provider
  void clearState() {
    _isLoading = false;
    _errorMessage = '';
    _success = false;
    notifyListeners();
  }
}
