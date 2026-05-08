import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'staff_dashboard_page.dart';
import 'staff_appointments_page.dart';
import 'staff_schedule_page.dart';
import 'staff_messages_page.dart';
import 'staff_profile_page.dart';

class StaffAdminShell extends StatefulWidget {
  const StaffAdminShell({super.key});

  @override
  State<StaffAdminShell> createState() => _StaffAdminShellState();
}

class _StaffAdminShellState extends State<StaffAdminShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
  }

  final List<_NavEntry> _nav = [
    _NavEntry(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavEntry(
      Icons.pending_actions_rounded,
      Icons.pending_actions_outlined,
      'Patients',
    ),
    _NavEntry(
      Icons.calendar_month_rounded,
      Icons.calendar_month_outlined,
      'Schedule',
    ),
    _NavEntry(
      Icons.chat_bubble_rounded,
      Icons.chat_bubble_outline_rounded,
      'Messages',
    ),
    _NavEntry(Icons.person_rounded, Icons.person_outlined, 'Profile'),
  ];

  late final List<Widget> _pages = [
    const StaffDashboardPage(),
    const StaffAppointmentsPage(),
    const StaffSchedulePage(),
    const StaffMessagesPage(),
    const StaffProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _pages[_index],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_nav.length, (i) {
              final item = _nav[i];
              final selected = _index == i;
              return GestureDetector(
                onTap: () => setState(() => _index = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.black.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected ? item.filled : item.outline,
                        color: selected ? Colors.black : Colors.black38,
                        size: 24,
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavEntry {
  final IconData filled, outline;
  final String label;
  const _NavEntry(this.filled, this.outline, this.label);
}
