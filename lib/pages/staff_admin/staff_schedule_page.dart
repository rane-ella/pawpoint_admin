import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_api_service.dart';

class StaffSchedulePage extends StatefulWidget {
  const StaffSchedulePage({super.key});

  @override
  State<StaffSchedulePage> createState() => _StaffSchedulePageState();
}

class _StaffSchedulePageState extends State<StaffSchedulePage> {
  List<dynamic> _allAppointments = [];
  bool _loading = true;
  bool _showAll = false;
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  String _doctorName = '';

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
    _selectedDay = DateTime.now();
  }

  Future<void> _loadDoctorName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _doctorName = (doc.data() as Map<String, dynamic>)['name'] ?? '';
        });
      }
    } catch (_) {}
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminApiService.fetchApprovedAppointments();
      if (mounted) {
        setState(() {
          _allAppointments = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Filter appointments for the selected doctor
  List<dynamic> get _myAppointments {
    if (_showAll || _doctorName.isEmpty) return _allAppointments;
    return _allAppointments.where((a) {
      final doctor = (a['doctor'] ?? '').toString().toLowerCase();
      return doctor.contains(_doctorName.toLowerCase()) ||
          _doctorName.toLowerCase().contains(doctor);
    }).toList();
  }

  // Appointments for a specific day
  List<dynamic> _appointmentsForDay(DateTime day) {
    return _myAppointments.where((a) {
      try {
        final dt = DateTime.parse(a['dateTime'] as String);
        return dt.year == day.year &&
            dt.month == day.month &&
            dt.day == day.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // All days in current month that have appointments
  Set<String> get _daysWithEvents {
    return _myAppointments
        .map((a) {
          try {
            final dt = DateTime.parse(a['dateTime'] as String);
            return '${dt.year}-${dt.month}-${dt.day}';
          } catch (_) {
            return '';
          }
        })
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAppts = _selectedDay != null
        ? _appointmentsForDay(_selectedDay!)
        : [];

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildCalendar(),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildDayLabel(selectedAppts.length),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  )
                : selectedAppts.isEmpty
                ? _buildNone()
                : _buildApptList(selectedAppts),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      color: const Color(0xFFF8FAFF),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Schedule',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    if (_doctorName.isNotEmpty)
                      Text(
                        'Assigned to: $_doctorName',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF10B981),
                ),
                onPressed: _load,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showAll
                    ? 'Showing ALL Clinic Appointments'
                    : 'Showing ONLY My Appointments',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch.adaptive(
                value: _showAll,
                activeThumbColor: const Color(0xFF10B981),
                activeTrackColor: const Color(
                  0xFF10B981,
                ).withValues(alpha: 0.5),
                onChanged: (val) => setState(() => _showAll = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sun=0..Sat=6
    final totalCells = startWeekday + lastDay.day;
    final rows = (totalCells / 7).ceil();

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          // Month navigation
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF10B981),
                ),
                onPressed: () => setState(
                  () => _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF10B981),
                ),
                onPressed: () => setState(
                  () => _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                  ),
                ),
              ),
            ],
          ),
          // Day labels
          Row(
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map(
                  (d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          // Calendar grid
          ...List.generate(rows, (row) {
            return Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNum = cellIndex - startWeekday + 1;
                if (dayNum < 1 || dayNum > lastDay.day) {
                  return const Expanded(child: SizedBox(height: 36));
                }
                final day = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  dayNum,
                );
                final key = '${day.year}-${day.month}-${day.day}';
                final hasEvent = _daysWithEvents.contains(key);
                final isSelected =
                    _selectedDay?.year == day.year &&
                    _selectedDay?.month == day.month &&
                    _selectedDay?.day == day.day;
                final isToday =
                    day.year == DateTime.now().year &&
                    day.month == DateTime.now().month &&
                    day.day == DateTime.now().day;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: Container(
                      height: 36,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : isToday
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: GoogleFonts.poppins(
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF1E293B),
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                          if (hasEvent && !isSelected)
                            Positioned(
                              bottom: 3,
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayLabel(int count) {
    if (_selectedDay == null) return const SizedBox.shrink();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = _selectedDay!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      color: const Color(0xFFF8FAFF),
      child: Row(
        children: [
          Text(
            '${months[d.month - 1]} ${d.day}, ${d.year}',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count appt${count == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(
                color: const Color(0xFF10B981),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNone() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_available_rounded,
            color: Color(0xFFCBD5E1),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No appointments on this day',
            style: GoogleFonts.poppins(
              color: const Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApptList(List<dynamic> appts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appts.length,
      itemBuilder: (_, i) => _buildApptCard(appts[i]),
    );
  }

  Widget _buildApptCard(Map<String, dynamic> a) {
    final status = a['status'] ?? 'approved';
    final Color color;
    switch (status) {
      case 'completed':
        color = const Color(0xFF10B981);
        break;
      case 'approved':
        color = const Color(0xFF3B82F6);
        break;
      default:
        color = const Color(0xFFF59E0B);
    }

    DateTime? dt;
    try {
      dt = DateTime.parse(a['dateTime'] as String);
    } catch (_) {}

    // ── Phase 3 payment fields ──────────────────────────────────────
    final paymentMethod = (a['paymentMethod'] ?? '').toString();
    final payStatus = (a['paymentStatus'] ?? '').toString();
    final balance = (a['balanceRemaining'] as num?)?.toDouble() ?? 0.0;
    final totalPrice = (a['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final hasPaymentData = paymentMethod.isNotEmpty || totalPrice > 0;
    final isFullyPaid = payStatus == 'fully_paid' || balance <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Appointment info ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['service'] ?? 'Service',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${a['user_name'] ?? 'Owner'}  ·  Pet: ${a['pet'] ?? '-'}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      if (dt != null)
                        Text(
                          _timeStr(dt),
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // ── Phase 3 Billing Section ───────────────────────────────
            if (hasPaymentData) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Billing',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (totalPrice > 0)
                      _billingRow(
                        'Total',
                        '₱${totalPrice.toStringAsFixed(2)}',
                        const Color(0xFF1E293B),
                      ),
                    if (balance > 0) ...[
                      _billingRow(
                        'Balance Remaining',
                        '₱${balance.toStringAsFixed(2)}',
                        const Color(0xFFF59E0B),
                      ),
                    ],
                    _billingRow(
                      'Payment Status',
                      payStatus.replaceAll('_', ' '),
                      isFullyPaid
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Mark OTC Paid button (only when balance is due and unpaid)
              if (!isFullyPaid && balance > 0 && status != 'completed')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _markOtcPaid(a),
                    icon: const Icon(
                      Icons.payments_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Mark Balance Paid (OTC)  ₱${balance.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ),
            ],

            // ── Mark as Completed button ──────────────────────────────
            if (status == 'approved') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (hasPaymentData && !isFullyPaid)
                      ? null // blocked — balance unpaid
                      : () => _markComplete(a),
                  icon: Icon(
                    Icons.task_alt_rounded,
                    size: 16,
                    color: (hasPaymentData && !isFullyPaid)
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF10B981),
                  ),
                  label: Text(
                    (hasPaymentData && !isFullyPaid)
                        ? 'Complete (pay balance first)'
                        : 'Mark as Completed',
                    style: GoogleFonts.poppins(
                      color: (hasPaymentData && !isFullyPaid)
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: (hasPaymentData && !isFullyPaid)
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF10B981),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _billingRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markOtcPaid(Map<String, dynamic> a) async {
    final userId = a['user_id']?.toString() ?? '';
    final apptId = a['id']?.toString() ?? '';
    if (userId.isEmpty || apptId.isEmpty) {
      _showSnack('Missing appointment IDs', const Color(0xFFEF4444));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm OTC Payment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Mark the remaining balance of ₱${((a['balanceRemaining'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)} as collected in-clinic?',
          style: GoogleFonts.poppins(
            color: const Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Confirm',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await AdminApiService.markBalancePaid(
          userId: userId,
          appointmentId: apptId,
        );
        _showSnack('Balance marked as paid ✓', const Color(0xFF10B981));
        _load();
      } catch (e) {
        _showSnack('Error: $e', const Color(0xFFEF4444));
      }
    }
  }

  Future<void> _markComplete(Map<String, dynamic> a) async {
    final userId = a['user_id']?.toString() ?? '';
    final apptId = a['id']?.toString() ?? '';
    if (userId.isEmpty || apptId.isEmpty) {
      _showSnack('Missing appointment IDs', const Color(0xFFEF4444));
      return;
    }
    try {
      await AdminApiService.completeAppointment(userId, apptId);
      _showSnack('Appointment marked completed ✓', const Color(0xFF10B981));
      _load();
    } catch (e) {
      _showSnack('Error: $e', const Color(0xFFEF4444));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _timeStr(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:${d.minute.toString().padLeft(2, '0')} $ampm';
  }
}
