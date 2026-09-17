import 'package:flutter/services.dart';

class SmsInboxMessage {
  final String id;
  final String address;
  final String body;
  final DateTime date;

  const SmsInboxMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
  });

  factory SmsInboxMessage.fromMap(Map<dynamic, dynamic> map) {
    return SmsInboxMessage(
      id: '${map['id'] ?? ''}',
      address: '${map['address'] ?? ''}',
      body: '${map['body'] ?? ''}',
      date: DateTime.fromMillisecondsSinceEpoch(
        (map['date'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}

class SmsInboxService {
  static const _channel = MethodChannel('personal_tracker/sms');

  Future<bool> requestPermission() async {
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  Future<bool> hasPermission() async {
    return await _channel.invokeMethod<bool>('hasPermission') ?? false;
  }

  Future<List<SmsInboxMessage>> readMessages() async {
    final result = await _channel.invokeMethod<List<dynamic>>('readMessages');
    return (result ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .map(SmsInboxMessage.fromMap)
        .toList();
  }
}
