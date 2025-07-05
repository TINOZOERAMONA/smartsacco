import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smartloan_sacco/services/momo_services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';


class MomoPaymentPage extends StatefulWidget {
  final double amount;
  final Function(bool success) onPaymentComplete;

  const MomoPaymentPage({
    super.key,
    required this.amount,
    required this.onPaymentComplete,
  });

  @override
  State<MomoPaymentPage> createState() => _MomoPaymentPageState();
}

