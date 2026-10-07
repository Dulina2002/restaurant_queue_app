import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reservation_model.dart';

class ReservationStorageService {
  static final ReservationStorageService _instance = ReservationStorageService._internal();
  factory ReservationStorageService() => _instance;
  ReservationStorageService._internal();

  static const String _storageKey = 'local_reservations_cache';

  Future<List<ReservationModel>> getStoredReservations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => ReservationModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReservations(List<ReservationModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((r) => r.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  Future<void> upsertReservation(ReservationModel reservation) async {
    final current = await getStoredReservations();
    final idx = current.indexWhere((r) => r.id == reservation.id);
    if (idx != -1) {
      current[idx] = reservation;
    } else {
      current.insert(0, reservation);
    }
    await saveReservations(current);
  }

  Future<void> updateStatus(String reservationId, String newStatus) async {
    final current = await getStoredReservations();
    final idx = current.indexWhere((r) => r.id == reservationId);
    if (idx != -1) {
      current[idx] = current[idx].copyWith(status: newStatus);
      await saveReservations(current);
    }
  }
}
