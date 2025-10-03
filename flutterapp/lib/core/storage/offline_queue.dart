import 'dart:convert';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineQueueService {
  OfflineQueueService(this._prefs);

  final SharedPreferences _prefs;

  static const _queueKey = 'offline_inspections';

  static Future<OfflineQueueService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return OfflineQueueService(prefs);
  }

  Future<List<Map<String, dynamic>>> pendingInspections() async {
    final raw = _prefs.getStringList(_queueKey) ?? <String>[];
    return raw.map((entry) => jsonDecode(entry) as Map<String, dynamic>).toList();
  }

  Future<void> enqueueInspection(Map<String, dynamic> payload) async {
    final queue = _prefs.getStringList(_queueKey) ?? <String>[];
    queue.add(jsonEncode(payload));
    await _prefs.setStringList(_queueKey, queue);
  }

  Future<void> clearInspection(Map<String, dynamic> payload) async {
    final queue = _prefs.getStringList(_queueKey) ?? <String>[];
    final encoded = jsonEncode(payload);
    queue.remove(encoded);
    await _prefs.setStringList(_queueKey, queue);
  }

  Future<void> clearAll() => _prefs.remove(_queueKey);
}
