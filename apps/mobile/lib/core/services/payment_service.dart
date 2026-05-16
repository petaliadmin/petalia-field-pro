import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/dio_provider.dart';

enum PaymentMethod { wave, orangeMoney, freeMoney }

extension PaymentMethodX on PaymentMethod {
  String get value => name.toUpperCase();
}

class PaymentRequest {
  final String id;
  final String description;
  final int amount;
  final int credits;
  final PaymentMethod method;

  const PaymentRequest({
    required this.id,
    required this.description,
    required this.amount,
    required this.credits,
    required this.method,
  });
}

class PaymentService {
  final Ref _ref;
  PaymentService(this._ref);

  Future<String?> initializePayment(PaymentRequest request) async {
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post('/payment/initialize', data: {
        'amount': request.amount,
        'credits': request.credits,
        'method': request.method.value,
      });

      if (response.statusCode == 201) {
        return response.data['paymentUrl'] as String;
      }
    } catch (e) {
      print('Error initializing payment: $e');
    }
    return null;
  }

  Future<bool> processPayment(PaymentRequest request) async {
    final paymentUrl = await initializePayment(request);
    
    if (paymentUrl != null) {
      final url = Uri.parse(paymentUrl);
      if (await canLaunchUrl(url)) {
        return await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    }
    return false;
  }

  Future<String> checkStatus(String paymentId) async {
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/payment/status/$paymentId');
      return response.data['status'] as String;
    } catch (e) {
      return 'ERROR';
    }
  }
}

final paymentServiceProvider = Provider((ref) => PaymentService(ref));
