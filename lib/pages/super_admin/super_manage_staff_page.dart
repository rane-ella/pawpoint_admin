import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_api_service.dart';

class SuperManageStaffPage extends StatefulWidget {
  const SuperManageStaffPage({super.key});

  @override
  State<SuperManageStaffPage> createState() => _SuperManageStaffPageState();
}

class _SuperManageStaffPageState extends State<SuperManageStaffPage> {
  List<dynamic> _staff = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  List<dynamic> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminApiService.fetchStaff();
      if (mounted) {
        setState(() {
          _staff = data;
          _filtered = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _staff
          : _staff.where((s) {
              final name = (s['name'] ?? '').toString().toLowerCase();
              final email = (s['email'] ?? '').toString().toLowerCase();
              final spec = (s['specialty'] ?? '').toString().toLowerCase();
              return name.contains(q) || email.contains(q) || spec.contains(q);
            }).toList();
    });
  }

  // ── Provision new doctor dialog ────────────────────────────────────────
  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final specialtyCtrl = TextEditingController(text: 'Veterinarian');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Add New Doctor',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, 'Full Name', Icons.person_rounded),
                const SizedBox(height: 10),
                _dialogField(
                  emailCtrl,
                  'Email Address',
                  Icons.email_rounded,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                _dialogField(
                  passCtrl,
                  'Password',
                  Icons.lock_rounded,
                  obscure: true,
                ),
                const SizedBox(height: 10),
                _dialogField(
                  specialtyCtrl,
                  'Specialty',
                  Icons.medical_services_rounded,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          emailCtrl.text.trim().isEmpty ||
                          passCtrl.text.trim().isEmpty) {
                        return;
                      }
                      setLocal(() => isSaving = true);
                      try {
                        await AdminApiService.createStaffAccount(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text.trim(),
                          specialty: specialtyCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showSnack(
                          'Doctor account created ✓',
                          const Color(0xFF10B981),
                        );
                        _load();
                      } catch (e) {
                        setLocal(() => isSaving = false);
                        _showSnack('Error: $e', const Color(0xFFEF4444));
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Create Account',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Color(0xFF1E293B)),
      obscureText: obscure,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
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

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  )
                : _filtered.isEmpty
                ? _buildEmpty()
                : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1E293B),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search staff by name or specialty…',
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: _load,
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: _showAddStaffDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Add Doctor',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medical_services_outlined,
            color: Color(0xFFE2E8F0),
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            'No staff members found',
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _showAddStaffDialog,
            icon: const Icon(Icons.add_rounded, color: Color(0xFF10B981)),
            label: Text(
              'Add the first doctor',
              style: GoogleFonts.poppins(color: Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _buildStaffCard(_filtered[i]),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> s) {
    final initials = _getInitials(s['name'] ?? 'Dr');
    final specialty = s['specialty'] ?? 'Veterinarian';
    final isNurse = (s['role'] ?? '') == 'super_admin';
    final roleLabel = isNurse ? 'Super Admin / Nurse' : 'Staff Admin / Doctor';
    final roleColor = isNurse
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: roleColor.withValues(alpha: 0.1),
            backgroundImage:
                s['photoUrl'] != null && (s['photoUrl'] as String).isNotEmpty
                ? NetworkImage(s['photoUrl'])
                : null,
            child: s['photoUrl'] == null || (s['photoUrl'] as String).isEmpty
                ? Text(
                    initials,
                    style: GoogleFonts.poppins(
                      color: roleColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['name'] ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  specialty,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF94A3B8),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        s['email'] ?? '-',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              roleLabel,
              style: GoogleFonts.poppins(
                color: roleColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'D';
  }
}
