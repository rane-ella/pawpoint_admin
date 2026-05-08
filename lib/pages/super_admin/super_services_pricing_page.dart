import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_api_service.dart';

class SuperServicesPricingPage extends StatefulWidget {
  const SuperServicesPricingPage({super.key});

  @override
  State<SuperServicesPricingPage> createState() =>
      _SuperServicesPricingPageState();
}

class _SuperServicesPricingPageState extends State<SuperServicesPricingPage> {
  List<dynamic> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminApiService.fetchServices();
      if (mounted) {
        setState(() {
          _services = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final existingData = existing ?? {};
    final nameCtrl = TextEditingController(text: existingData['name'] ?? '');
    final priceCtrl = TextEditingController(
      text: existingData['price'] != null
          ? existingData['price'].toString()
          : '',
    );
    final descCtrl = TextEditingController(
      text: existingData['description'] ?? '',
    );
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
            isEdit ? 'Edit Service' : 'Add New Service',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameCtrl, 'Service Name', Icons.pets_rounded),
              const SizedBox(height: 10),
              _field(
                priceCtrl,
                'Base Price (₱)',
                Icons.attach_money_rounded,
                type: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _field(
                descCtrl,
                'Description (optional)',
                Icons.description_rounded,
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            if (isEdit)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _deleteService(existingData['id'] as String);
                },
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: const Color(0xFFEF4444)),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          priceCtrl.text.trim().isEmpty) {
                        return;
                      }
                      setLocal(() => isSaving = true);
                      try {
                        final price =
                            double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                        if (isEdit) {
                          await AdminApiService.updateService(
                            id: existingData['id'] as String,
                            name: nameCtrl.text.trim(),
                            price: price,
                            description: descCtrl.text.trim(),
                          );
                        } else {
                          await AdminApiService.createService(
                            name: nameCtrl.text.trim(),
                            price: price,
                            description: descCtrl.text.trim(),
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showSnack(
                          isEdit ? 'Service updated ✓' : 'Service added ✓',
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
                      isEdit ? 'Save Changes' : 'Add Service',
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

  Future<void> _deleteService(String id) async {
    try {
      await AdminApiService.deleteService(id);
      _showSnack('Service removed', const Color(0xFF94A3B8));
      _load();
    } catch (e) {
      _showSnack('Error: $e', const Color(0xFFEF4444));
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Color(0xFF1E293B)),
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: const Color(0xFF94A3B8), size: 18)
            : null,
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  )
                : _services.isEmpty
                ? _buildEmpty()
                : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Text(
            '${_services.length} service${_services.length == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
            onPressed: _load,
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: Text(
              'Add Service',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
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
            Icons.local_offer_outlined,
            color: Color(0xFFE2E8F0),
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            'No services defined yet',
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add_rounded, color: Color(0xFF10B981)),
            label: Text(
              'Add first service',
              style: GoogleFonts.poppins(color: const Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _services.length,
      itemBuilder: (_, i) => _buildCard(_services[i]),
    );
  }

  Widget _buildCard(Map<String, dynamic> s) {
    final price = (s['price'] as num?)?.toDouble() ?? 0.0;
    final serviceColors = const [
      Color(0xFF6366F1),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
    ];
    final color = serviceColors[_services.indexOf(s) % serviceColors.length];

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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.medical_services_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['name'] ?? 'Unnamed Service',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if ((s['description'] ?? '').toString().isNotEmpty)
                  Text(
                    s['description'],
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${price.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showAddEditDialog(existing: s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
