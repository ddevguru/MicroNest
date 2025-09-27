import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  static const String apiBaseUrl = 'https://micronest.devloperwala.in/api';
  static late Razorpay _razorpay;

  static void initialize() {
    _razorpay = Razorpay();
  }

  static void dispose() {
    _razorpay.clear();
  }

  static Future<Map<String, dynamic>> createOrder({
    required int amount,
    required String currency,
    required String receipt,
    required Map<String, dynamic> notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/payment/create-order.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'receipt': receipt,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to create payment order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/payment/verify.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'payment_id': paymentId,
          'signature': signature,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Payment verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<void> makePayment({
    required int amount,
    required String currency,
    required String receipt,
    required Map<String, dynamic> notes,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Create order
      final orderResult = await createOrder(
        amount: amount,
        currency: currency,
        receipt: receipt,
        notes: notes,
      );

      if (!orderResult['success']) {
        onError(orderResult['message']);
        return;
      }

      final orderData = orderResult['data'];
      
      // Configure Razorpay options
      var options = {
        'key': 'YOUR_RAZORPAY_KEY_ID', // Replace with your Razorpay key
        'amount': amount,
        'name': 'MicroNest',
        'description': notes['description'] ?? 'Payment',
        'order_id': orderData['id'],
        'prefill': {
          'contact': notes['contact'] ?? '',
          'email': notes['email'] ?? '',
        },
        'theme': {
          'color': '#1B4332',
        }
      };

      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
        // Verify payment
        final verifyResult = await verifyPayment(
          orderId: orderData['id'],
          paymentId: response.paymentId!,
          signature: response.signature!,
        );

        if (verifyResult['success']) {
          onSuccess(verifyResult['data']);
        } else {
          onError('Payment verification failed');
        }
      });

      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        onError('Payment failed: ${response.message}');
      });

      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
        onError('External wallet selected: ${response.walletName}');
      });

      _razorpay.open(options);
    } catch (e) {
      onError('Payment error: ${e.toString()}');
    }
  }
} 