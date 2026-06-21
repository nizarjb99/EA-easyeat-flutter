import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

/// NfcService — unified NFC logic for EasyEat
///
/// CUSTOMER SIDE: startHceEmission / stopHceEmission
///   Uses a MethodChannel to call native Android HCE (Host Card Emulation).
///   The customer's phone acts as an NFC card emitting their customerId.
///
/// EMPLOYEE SIDE: startNfcReading / stopNfcReading
///   Uses nfc_manager package to detect ISO-DEP NFC tags (the customer's HCE).
///   Sends APDU commands to read the customerId, then calls the callback.
class NfcService {
  static const _channel = MethodChannel('com.easyeat/nfc_hce');

  // Our proprietary AID: F0394148148100
  static const _aid = [0xF0, 0x39, 0x41, 0x48, 0x14, 0x81, 0x00];

  // APDU: SELECT AID command
  static Uint8List get _selectApdu => Uint8List.fromList([
        0x00, 0xA4, 0x04, 0x00, // CLA, INS, P1, P2
        0x07, // Lc = AID length
        ..._aid, // AID bytes
        0x00, // Le
      ]);

  // APDU: GET DATA command (reads the customerId)
  static Uint8List get _getDataApdu =>
      Uint8List.fromList([0x00, 0xCA, 0x01, 0x00, 0x00]);

  // Status word OK (9000)
  static const _swOk = [0x90, 0x00];

  // ───────────────────────────────────────────────────
  // CUSTOMER SIDE — HCE Emission
  // ───────────────────────────────────────────────────

  /// Activates the HCE service so the customer's phone emits NFC
  static Future<bool> startHceEmission(String customerId) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'startHce',
        {'customerId': customerId},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('NfcService: startHce error: ${e.message}');
      return false;
    }
  }

  /// Deactivates the HCE service
  static Future<void> stopHceEmission() async {
    try {
      await _channel.invokeMethod('stopHce');
    } on PlatformException catch (e) {
      print('NfcService: stopHce error: ${e.message}');
    }
  }

  /// Returns true if NFC is available on this device
  static Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  // ───────────────────────────────────────────────────
  // EMPLOYEE SIDE — NFC Reading
  // ───────────────────────────────────────────────────

  /// Starts listening for NFC tags. When a customer's phone is detected,
  /// [onCustomerIdReceived] is called with their customerId.
  /// [onError] is called on failure.
  static Future<void> startNfcReading({
    required void Function(String customerId) onCustomerIdReceived,
    required void Function(String error) onError,
  }) async {
    final available = await isNfcAvailable();
    if (!available) {
      onError('NFC no disponible en este dispositivo');
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          // Get ISO-DEP interface (required for HCE communication)
          final isoDep = IsoDep.from(tag);
          if (isoDep == null) {
            onError('Tag NFC no compatible (se requiere ISO-DEP)');
            return;
          }

          // 1. Send SELECT AID command
          final selectResponse =
              await isoDep.transceive(data: _selectApdu);

          if (!_isResponseOk(selectResponse)) {
            onError('No se reconoció la tarjeta EasyEat');
            return;
          }

          // 2. Send GET DATA command to retrieve customerId
          final dataResponse =
              await isoDep.transceive(data: _getDataApdu);

          if (dataResponse.length < 3 || !_isResponseOk(dataResponse)) {
            onError('No se pudo leer el ID del cliente');
            return;
          }

          // Remove last 2 bytes (SW 9000) to get the customerId string
          final idBytes = dataResponse.sublist(0, dataResponse.length - 2);
          final customerId = String.fromCharCodes(idBytes);

          if (customerId.isNotEmpty) {
            onCustomerIdReceived(customerId);
          } else {
            onError('ID de cliente vacío');
          }
        } catch (e) {
          onError('Error al leer NFC: $e');
        }
      },
      onError: (e) async {
        onError('Error de sesión NFC: ${e.message}');
      },
    );
  }

  /// Stops the NFC reading session
  static Future<void> stopNfcReading() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  // ───────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────

  static bool _isResponseOk(Uint8List response) {
    if (response.length < 2) return false;
    final sw1 = response[response.length - 2];
    final sw2 = response[response.length - 1];
    return sw1 == _swOk[0] && sw2 == _swOk[1];
  }
}
