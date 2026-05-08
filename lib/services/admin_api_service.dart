import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';

import 'package:pawpoint_admin/admin_api_config.dart';

/// Service that talks to the Admin Backend (port 8001).
class AdminApiService {
  static const String _base = AdminApiConfig.baseUrl;

  /// Uploads a profile image to Firebase Storage and returns the download URL.
  static Future<String> uploadProfileImage(
    Uint8List fileBytes,
    String email,
  ) async {
    try {
      debugPrint('[AdminApiService] Starting image upload for $email...');
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${email}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Use putData with a timeout
      final uploadTask = await storageRef
          .putData(fileBytes, SettableMetadata(contentType: 'image/jpeg'))
          .timeout(const Duration(seconds: 30));

      final url = await uploadTask.ref.getDownloadURL();
      debugPrint('[AdminApiService] Image upload success: $url');
      return url;
    } catch (e) {
      debugPrint('[AdminApiService] Image upload ERROR: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // ─────────────────────────── Dashboard Stats ──────────────────────────────
  static Future<Map<String, dynamic>> fetchStats() async {
    final res = await http
        .get(Uri.parse('$_base/api/admin/stats'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load stats: ${res.body}');
  }

  // ─────────────────────────── Users ───────────────────────────────────────
  static Future<List<dynamic>> fetchAllUsers() async {
    final res = await http
        .get(Uri.parse('$_base/api/admin/users'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return jsonDecode(res.body)['users'];
    throw Exception('Failed to load users');
  }

  /// Fetch all pets for a specific user.
  static Future<List<dynamic>> fetchUserPets(String userId) async {
    final res = await http
        .get(Uri.parse('$_base/api/admin/users/$userId/pets'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return jsonDecode(res.body)['pets'];
    throw Exception('Failed to load user pets');
  }

  // ─────────────────────────── Pending Appointments ────────────────────────
  static Future<List<dynamic>> fetchPendingAppointments() async {
    final res = await http
        .get(Uri.parse('$_base/api/admin/appointments/pending'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['appointments'];
    }
    throw Exception('Failed to load pending appointments');
  }

  // ─────────────────────────── Approved/All Appointments ───────────────────
  static Future<List<dynamic>> fetchApprovedAppointments() async {
    final res = await http
        .get(Uri.parse('$_base/api/admin/appointments/approved'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['appointments'];
    }
    throw Exception('Failed to load approved appointments');
  }

  // ─────────────────────────── Completed Appointments ──────────────────────
  static Future<List<dynamic>> fetchCompletedAppointments() async {
    final res = await http
        .get(Uri.parse('$_base/api/admin/appointments/completed'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['appointments'];
    }
    throw Exception('Failed to load completed appointments');
  }

  // ─────────────────────────── Rejected Appointments ───────────────────────
  static Future<List<dynamic>> fetchRejectedAppointments() async {
    final res = await http
        .get(Uri.parse('$_base/api/admin/appointments/rejected'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['appointments'];
    }
    throw Exception('Failed to load rejected appointments');
  }

  // ─────────────────────────── Approve ─────────────────────────────────────
  static Future<void> approveAppointment(
    String userId,
    String appointmentId, {
    String doctorNote = '',
    String assignedDoctor = '',
  }) async {
    final res = await http
        .put(
          Uri.parse(
            '$_base/api/admin/appointments/$userId/$appointmentId/approve',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'status': 'approved',
            'doctor_note': doctorNote,
            'assigned_doctor': assignedDoctor,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception('Failed to approve');
  }

  // ─────────────────────────── Reject ──────────────────────────────────────
  static Future<void> rejectAppointment(
    String userId,
    String appointmentId, {
    String doctorNote = '',
  }) async {
    final res = await http
        .put(
          Uri.parse(
            '$_base/api/admin/appointments/$userId/$appointmentId/reject',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': 'rejected', 'doctor_note': doctorNote}),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception('Failed to reject');
  }

  // ─────────────────────────── Cancel by Admin ──────────────────────────────
  static Future<void> cancelAppointmentByAdmin(
    String userId,
    String appointmentId, {
    String reason = '',
  }) async {
    final res = await http
        .put(
          Uri.parse(
            '$_base/api/admin/appointments/$userId/$appointmentId/cancel',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': 'cancelled', 'doctor_note': reason}),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      final detail = jsonDecode(res.body)['detail'] ?? 'Failed to cancel';
      throw Exception(detail);
    }
  }

  // ─────────────────────────── Propose Reschedule ───────────────────────────
  static Future<void> proposeReschedule(
    String userId,
    String appointmentId, {
    required String proposedDatetime,
    String assignedDoctor = '',
  }) async {
    final res = await http
        .put(
          Uri.parse(
            '$_base/api/admin/appointments/$userId/$appointmentId/propose-reschedule',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'proposed_datetime': proposedDatetime,
            'assigned_doctor': assignedDoctor,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      final detail =
          jsonDecode(res.body)['detail'] ?? 'Failed to propose reschedule';
      throw Exception(detail);
    }
  }

  // ─────────────────────────── Complete ────────────────────────────────────
  static Future<void> completeAppointment(
    String userId,
    String appointmentId,
  ) async {
    final res = await http
        .put(
          Uri.parse(
            '$_base/api/admin/appointments/$userId/$appointmentId/complete',
          ),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception('Failed to complete');
  }

  // ─────────────────────────── Staff/Admins ────────────────────────────────

  /// List all admin accounts (from the 'admins' Firestore collection).
  static Future<List<dynamic>> fetchStaff() async {
    final res = await http
        .get(Uri.parse('$_base/api/admin/staff'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return jsonDecode(res.body)['staff'];
    throw Exception('Failed to load staff');
  }

  /// Provision a new doctor account via the backend.
  static Future<void> createStaffAccount({
    required String name,
    required String email,
    required String password,
    String specialty = 'Veterinarian',
    String phone = '',
    String bio = '',
    String photoUrl = '',
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/api/admin/staff'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'specialty': specialty,
            'role': 'staff_admin',
            'phone': phone,
            'bio': bio,
            'photoUrl': photoUrl,
            'isActive': false,
          }),
        )
        .timeout(const Duration(seconds: 60)); // Long timeout for creation

    if (res.statusCode != 200 && res.statusCode != 201) {
      final detail =
          jsonDecode(res.body)['detail'] ?? 'Failed to create staff account';
      throw Exception(detail);
    }
  }

  /// Mark a staff member as active (usually on first login).
  static Future<void> markStaffActive(String uid) async {
    final res = await http
        .put(
          Uri.parse('$_base/api/admin/staff/$uid/activate'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('Failed to activate staff account');
    }
  }

  /// Mark a staff member as deactivated (fired/resigned).
  static Future<void> deactivateStaff(String uid) async {
    final res = await http
        .put(
          Uri.parse('$_base/api/admin/staff/$uid/deactivate'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('Failed to deactivate staff account');
    }
  }

  // ─────────────────────────── Services & Pricing ──────────────────────────

  /// Fetch all clinic services.
  static Future<List<dynamic>> fetchServices() async {
    final res = await http
        .get(Uri.parse('$_base/api/admin/services'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return jsonDecode(res.body)['services'];
    throw Exception('Failed to load services');
  }

  /// Create a new service.
  static Future<void> createService({
    required String name,
    required double price,
    String description = '',
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/api/admin/services'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'price': price,
            'description': description,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to create service');
    }
  }

  /// Update an existing service.
  static Future<void> updateService({
    required String id,
    required String name,
    required double price,
    String description = '',
  }) async {
    final res = await http
        .put(
          Uri.parse('$_base/api/admin/services/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'price': price,
            'description': description,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception('Failed to update service');
  }

  /// Delete a service.
  static Future<void> deleteService(String id) async {
    final res = await http
        .delete(Uri.parse('$_base/api/admin/services/$id'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception('Failed to delete service');
  }

  // ─────────────────────────── Messages ────────────────────────────────────
  static Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String senderName = '',
    String receiverName = '',
    String senderRole = 'staff_admin',
  }) async {
    await http
        .post(
          Uri.parse('$_base/api/admin/messages'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sender_id': senderId,
            'receiver_id': receiverId,
            'content': content,
            'sender_name': senderName,
            'receiver_name': receiverName,
            'sender_role': senderRole,
          }),
        )
        .timeout(const Duration(seconds: 15));
  }

  static Future<List<dynamic>> fetchConversations(String uid) async {
    final res = await http
        .get(Uri.parse('$_base/api/admin/messages/$uid'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['conversations'];
    }
    throw Exception('Failed to load messages');
  }

  static Future<List<dynamic>> fetchAllConversations() async {
    final res = await http
        .get(Uri.parse('$_base/api/admin/messages'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['conversations'];
    }
    throw Exception('Failed to load conversations');
  }

  // ─────────────────────────── Phase 3: Financials ─────────────────────────

  /// Fetch gross revenue, cash collected, pending receivables & per-service breakdown.
  static Future<Map<String, dynamic>> fetchFinancials() async {
    final res = await http
        .get(Uri.parse('$_base/api/admin/financials'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load financials');
  }

  /// Fetch the full transaction ledger.
  static Future<List<dynamic>> fetchTransactions() async {
    final res = await http
        .get(Uri.parse('$_base/api/admin/transactions'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return jsonDecode(res.body)['transactions'];
    throw Exception('Failed to load transactions');
  }

  /// Staff action: mark the OTC balance as paid for an appointment.
  static Future<void> markBalancePaid({
    required String userId,
    required String appointmentId,
  }) async {
    final res = await http
        .put(
          Uri.parse('$_base/api/payments/mark-paid'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'appointment_id': appointmentId,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      final detail =
          jsonDecode(res.body)['detail'] ?? 'Failed to mark balance paid';
      throw Exception(detail);
    }
  }
}
