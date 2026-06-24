import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../services/api_service.dart';

class QRProvider extends ChangeNotifier {
  final ApiService _apiService;

  QRProvider(this._apiService);

  bool _isValidating = false;
  String? _scannedData;
  Map<String, dynamic>? _validatedExamData;
  String? _validationError;
  // Getters
  bool get isValidating => _isValidating;
  String? get scannedData => _scannedData;
  Map<String, dynamic>? get validatedExamData => _validatedExamData;
  String? get validationError => _validationError;
  /// Validates the scanned QR payload.
  /// Pre-configured to hook into ApiService endpoints in future production drops.
  Future<bool> validateQr(String qrContent) async {
     print("SCANNED QR = $qrContent");
     _isValidating = true;
     _scannedData = qrContent;
     _validationError = null;
     _validatedExamData = null;
     notifyListeners();
     try {
      final response = await _apiService.dio.post('/qr/validate',
      data: {
        'token_value': qrContent,
      },
    );

    print("QR VALIDATION RESPONSE = ${response.data}");

    _validatedExamData = response.data;
    return true;
  } on DioException catch (e) {
    print("QR VALIDATION ERROR = ${e.response?.data}");

    _validationError =
        e.response?.data['detail'] ?? 'QR validation failed.';
    return false;
  } finally {
    _isValidating = false;
    notifyListeners();
  }
}
Future<void> consumeQr(String qrContent) async {
  await _apiService.dio.post(
    '/qr/use',
    data: {
      'token_value': qrContent,
    },
  );

  print("QR CONSUMED = $qrContent");
}
  /// Reset the scanned state parameters.
  void resetState() {
    _isValidating = false;
    _scannedData = null;
    _validatedExamData = null;
    _validationError = null;
    notifyListeners();
  }
}
