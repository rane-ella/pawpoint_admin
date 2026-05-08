import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_api_service.dart';

class SuperDashboardPage extends StatefulWidget {
  const SuperDashboardPage({super.key});

  @override
  State<SuperDashboardPage> createState() => _SuperDashboardPageState();
}

class _SuperDashboardPageState extends State<SuperDashboardPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await AdminApiService.fetchStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Color(0xFF64748B),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Cannot reach admin backend.\nMake sure it is running on port 8001.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final s = _stats!;
    final monthly = Map<String, int>.from(s['monthly_appointments'] ?? {});
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
    final chartData = months.map((m) => monthly[m] ?? 0).toList();
    final maxVal = chartData.reduce((a, b) => a > b ? a : b).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, Super Admin 👋',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Here\'s what\'s happening at PawAdmin today.',
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),

          // ── Stat Cards ──────────────────────────────────────────
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _statCard(
                'Total Users',
                '${s['total_users'] ?? 0}',
                Icons.people_alt_rounded,
                const Color(0xFF6366F1),
              ),
              _statCard(
                'Doctors',
                '${s['total_doctors'] ?? 0}',
                Icons.medical_services_rounded,
                const Color(0xFF10B981),
              ),
              _statCard(
                'Pending',
                '${s['total_pending'] ?? 0}',
                Icons.pending_actions_rounded,
                const Color(0xFFF59E0B),
              ),
              _statCard(
                'Approved',
                '${s['total_approved'] ?? 0}',
                Icons.check_circle_rounded,
                const Color(0xFF3B82F6),
              ),
              _statCard(
                'Completed',
                '${s['total_completed'] ?? 0}',
                Icons.task_alt_rounded,
                const Color(0xFF8B5CF6),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Bar Chart ───────────────────────────────────────────
          _chartCard('Monthly Appointments', chartData, months, maxVal),
          const SizedBox(height: 24),

          // ── Pie-like Overview ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _pieCard(
                  'Pending',
                  s['total_pending'] ?? 0,
                  s['total_approved'] ?? 1,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _pieCard(
                  'Completed',
                  s['total_completed'] ?? 0,
                  s['total_approved'] ?? 1,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Recent Activity ─────────────────────────────────────
          _recentActivityCard(),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(
    String title,
    List<int> data,
    List<String> labels,
    double maxVal,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (i) {
                final val = data[i].toDouble();
                final barH = maxVal > 0 ? (val / maxVal) * 120 : 4.0;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (val > 0)
                        Text(
                          '${data[i]}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                            fontSize: 9,
                          ),
                        ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300 + i * 50),
                        height: barH.clamp(4.0, 120.0),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        labels[i].substring(0, 1),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF64748B),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pieCard(String label, int value, int total, Color color) {
    final pct = total > 0 ? (value / total * 100).toStringAsFixed(0) : '0';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: total > 0 ? value / total : 0,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 10,
                ),
                Text(
                  '$pct%',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          Text(
            '$value of $total',
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentActivityCard() {
    final activities = [
      _Activity(
        'New appointment booked',
        'Fluffy - Grooming',
        '2 min ago',
        Icons.calendar_today_rounded,
        const Color(0xFF6366F1),
      ),
      _Activity(
        'Appointment approved',
        'Buddy - Check-up',
        '15 min ago',
        Icons.check_circle_rounded,
        const Color(0xFF10B981),
      ),
      _Activity(
        'User registered',
        'Maria Santos joined',
        '1 hr ago',
        Icons.person_add_rounded,
        const Color(0xFF3B82F6),
      ),
      _Activity(
        'Appointment completed',
        'Max - Vaccination',
        '3 hrs ago',
        Icons.task_alt_rounded,
        const Color(0xFF8B5CF6),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ...activities.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(a.icon, color: a.color, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1E293B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          a.subtitle,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    a.time,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Activity {
  final String title, subtitle, time;
  final IconData icon;
  final Color color;
  const _Activity(this.title, this.subtitle, this.time, this.icon, this.color);
}
