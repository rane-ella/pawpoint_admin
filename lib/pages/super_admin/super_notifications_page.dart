import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuperNotificationsPage extends StatefulWidget {
  const SuperNotificationsPage({super.key});

  @override
  State<SuperNotificationsPage> createState() => _SuperNotificationsPageState();
}

class _SuperNotificationsPageState extends State<SuperNotificationsPage> {
  final List<_Notif> _notifs = [
    _Notif(
      'New Appointment Booked',
      'Fluffy · Grooming — Mon, Apr 7, 10:00 AM',
      Icons.calendar_today_rounded,
      const Color(0xFF6366F1),
      false,
    ),
    _Notif(
      'Appointment Approved',
      'Buddy · Check-up by Dr. Santos',
      Icons.check_circle_rounded,
      const Color(0xFF10B981),
      false,
    ),
    _Notif(
      'New User Registered',
      'Maria Santos created an account',
      Icons.person_add_rounded,
      const Color(0xFF3B82F6),
      true,
    ),
    _Notif(
      'Appointment Rejected',
      'Max · Vaccination — rescheduled',
      Icons.cancel_rounded,
      const Color(0xFFEF4444),
      true,
    ),
    _Notif(
      'Doctor Sent a Message',
      'Dr. Reyes: Please check the schedule',
      Icons.chat_bubble_rounded,
      const Color(0xFF8B5CF6),
      false,
    ),
    _Notif(
      'Appointment Completed',
      'Mochi · Dental — completed successfully',
      Icons.task_alt_rounded,
      const Color(0xFFF59E0B),
      true,
    ),
  ];

  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final visible = _filter == 'unread'
        ? _notifs.where((n) => !n.read).toList()
        : _filter == 'read'
        ? _notifs.where((n) => n.read).toList()
        : _notifs;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Text(
                  '${_notifs.where((n) => !n.read).length} unread',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF10B981),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    for (var n in _notifs) {
                      n.read = true;
                    }
                  }),
                  child: Text(
                    'Mark all read',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Filter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['all', 'unread', 'read'].map((f) {
                final sel = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        f[0].toUpperCase() + f.substring(1),
                        style: GoogleFonts.poppins(
                          color: sel ? Colors.white : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      'No notifications',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: visible.length,
                    itemBuilder: (_, i) => _buildNotifTile(visible[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifTile(_Notif n) {
    return GestureDetector(
      onTap: () => setState(() => n.read = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.read ? const Color(0xFFF8FAFF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.read
                ? const Color(0xFFE2E8F0)
                : n.color.withValues(alpha: 0.3),
          ),
          boxShadow: n.read
              ? []
              : [
                  BoxShadow(
                    color: n.color.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: n.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(n.icon, color: n.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E293B),
                      fontWeight: n.read ? FontWeight.w400 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.body,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!n.read)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: n.color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Notif {
  final String title, body;
  final IconData icon;
  final Color color;
  bool read;
  _Notif(this.title, this.body, this.icon, this.color, this.read);
}
