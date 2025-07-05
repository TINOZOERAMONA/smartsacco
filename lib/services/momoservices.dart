import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MomoService {
  // Configuration
  static const _configFile = 'assets/config.json';
  late final String _subscriptionKey;
  late final String _apiUser;
  late final String _apiKey;
  late final bool _isSandbox;
  late final String _callbackUrl;

  MomoService() {
    _loadConfig();
  }
