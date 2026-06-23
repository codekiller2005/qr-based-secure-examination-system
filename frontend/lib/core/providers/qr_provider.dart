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
    // Simulate network latency / cryptographic validation overhead
    await Future.delayed(const Duration(milliseconds: 1500));
    try {
      // Decode the scanned payload
      final Map<String, dynamic> decoded = jsonDecode(qrContent);
      // Verify that it contains our required mock structure: examId, subject, and startTime
      if (decoded.containsKey('examId') &&
          decoded.containsKey('subject') &&
          decoded.containsKey('startTime')) {
        _validatedExamData = decoded;
        _isValidating = false;
        notifyListeners();
        return true;
      } else {
        _validationError = "Malformed payload: Missing required exam identifier keys.";
      }
    } catch (e) {
      _validationError = "Failed to parse QR token: Data is not valid JSON.";
    }
    _isValidating = false;
    notifyListeners();
    return false;
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
