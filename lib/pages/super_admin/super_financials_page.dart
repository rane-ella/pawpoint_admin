import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_api_service.dart';

class SuperFinancialsPage extends StatefulWidget {
  const SuperFinancialsPage({super.key});

  @override
  State<SuperFinancialsPage> createState() => _SuperFinancialsPageState();
}

class _SuperFinancialsPageState extends State<SuperFinancialsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  Map<String, dynamic>? _financials;
  List<dynamic> _transactions = [];
  bool _loadingFinancials = true;
  bool _loadingTx = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadFinancials();
    _loadTransactions();
  }

  Future<void> _loadFinancials() async {
    setState(() => _loadingFinancials = true);
    try {
      final data = await AdminApiService.fetchFinancials();
      if (mounted) {
        setState(() {
          _financials = data;
          _loadingFinancials = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFinancials = false);
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _loadingTx = true);
    try {
      final data = await AdminApiService.fetchTransactions();
      if (mounted) {
        setState(() {
          _transactions = data;
          _loadingTx = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTx = false);
    }
  }

  List<dynamic> get _filteredTx {
    if (_searchQuery.isEmpty) return _transactions;
    final q = _searchQuery.toLowerCase();
    return _transactions.where((t) {
      return (t['user_name'] ?? '').toString().toLowerCase().contains(q) ||
          (t['service'] ?? '').toString().toLowerCase().contains(q) ||
          (t['transactionId'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [_buildOverviewTab(), _buildLedgerTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Text(
            'Financial Overview',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF10B981)),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(10),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Transaction Ledger'),
        ],
      ),
    );
  }

  // ── Overview Tab ───────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    if (_loadingFinancials) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      );
    }
    final f = _financials ?? {};
    final gross = (f['gross_revenue'] as num?)?.toDouble() ?? 0.0;
    final collected = (f['cash_collected'] as num?)?.toDouble() ?? 0.0;
    final pending = (f['pending_receivables'] as num?)?.toDouble() ?? 0.0;
    final serviceRev = Map<String, dynamic>.from(f['service_revenue'] ?? {});

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top KPI Cards ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'Gross Revenue',
                  gross,
                  Icons.monetization_on_rounded,
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiCard(
                  'Cash Collected',
                  collected,
                  Icons.account_balance_wallet_rounded,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _kpiCard(
            'Pending Receivables',
            pending,
            Icons.hourglass_top_rounded,
            const Color(0xFFF59E0B),
            fullWidth: true,
          ),
          const SizedBox(height: 24),

          // ── Revenue by Service ──────────────────────────────────────
          if (serviceRev.isNotEmpty) ...[
            Text(
              'Revenue by Service',
              style: GoogleFonts.poppins(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            _buildServiceChart(serviceRev, gross),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _kpiCard(
    String label,
    double value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₱${value.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChart(Map<String, dynamic> data, double total) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    int ci = 0;
    final entries = data.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: entries.map((e) {
          final rev = (e.value as num).toDouble();
          final pct = total > 0 ? rev / total : 0.0;
          final color = colors[ci++ % colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E293B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '₱${rev.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Ledger Tab ─────────────────────────────────────────────────────────────
  Widget _buildLedgerTab() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _loadingTx
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                )
              : _filteredTx.isEmpty
              ? _buildEmptyLedger()
              : _buildLedgerList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        style: GoogleFonts.poppins(
          color: const Color(0xFF1E293B),
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: 'Search by user, service, or transaction ID…',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF64748B),
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildEmptyLedger() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 52,
            color: Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 14),
          Text(
            'No transactions yet',
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Transactions appear once appointments include\npayment data (Phase 3 checkout flow).',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _filteredTx.length,
      itemBuilder: (_, i) => _buildTxRow(_filteredTx[i]),
    );
  }

  Widget _buildTxRow(Map<String, dynamic> tx) {
    final status = tx['paymentStatus'] ?? 'pending';
    final Color statusColor;
    switch (status) {
      case 'fully_paid':
        statusColor = const Color(0xFF10B981);
        break;
      case 'partially_paid':
        statusColor = const Color(0xFFF59E0B);
        break;
      default:
        statusColor = const Color(0xFF64748B);
    }

    DateTime? dt;
    try {
      dt = DateTime.parse(tx['dateTime'] as String);
    } catch (_) {}

    final total = (tx['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final balance = (tx['balanceRemaining'] as num?)?.toDouble() ?? 0.0;
    final txId = (tx['transactionId'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showTransactionDetails(tx),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tx['user_name'] ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '₱${total.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    tx['service'] ?? '',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                  if (dt != null) ...[
                    const Text(
                      ' · ',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      _fmtDate(dt),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
              if (txId.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'ID: $txId',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _badge(status.replaceAll('_', ' '), statusColor),
                  const Spacer(),
                  if (balance > 0)
                    Text(
                      'Balance: ₱${balance.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFF59E0B),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> tx) {
    final status = tx['paymentStatus'] ?? 'pending';
    final apptStatus = tx['status'] ?? 'approved';
    final balance = (tx['balanceRemaining'] as num?)?.toDouble() ?? 0.0;
    final total = (tx['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final paid = (tx['amountPaidOnline'] as num?)?.toDouble() ?? 0.0;
    bool isUpdating = false;

    // We can't collect balance for services that were never performed
    final bool isCanceled =
        (apptStatus == 'cancelled' ||
        apptStatus == 'auto_cancelled' ||
        apptStatus == 'rejected');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Transaction Detail',
              style: GoogleFonts.poppins(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailItem('Customer', tx['user_name'] ?? 'Unknown'),
                  _detailItem('Pet Name', tx['pet'] ?? 'N/A'),
                  _detailItem('Service', tx['service'] ?? 'N/A'),
                  _detailItem('Doctor', tx['doctor'] ?? 'N/A'),
                  _detailItem('Schedule', () {
                    try {
                      final dt = DateTime.parse(tx['dateTime'] as String);
                      return '${_fmtDate(dt)} · ${_timeStr(dt)}';
                    } catch (_) {
                      return tx['dateTime'] ?? 'N/A';
                    }
                  }()),
                  const Divider(color: Color(0xFFE2E8F0), height: 32),
                  _detailItem(
                    'Total Price',
                    '₱${total.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                  _detailItem(
                    'Paid Online',
                    '₱${paid.toStringAsFixed(2)}',
                    color: const Color(0xFF10B981),
                  ),
                  _detailItem(
                    'Remaining Balance',
                    '₱${balance.toStringAsFixed(2)}',
                    color: balance > 0
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF64748B),
                  ),
                  _detailItem(
                    'Payment Status',
                    status.replaceAll('_', ' ').toUpperCase(),
                    color: status == 'fully_paid'
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                  _detailItem(
                    'Appt Status',
                    apptStatus.toUpperCase(),
                    color: isCanceled
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1E293B),
                  ),
                  if (isCanceled && balance > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Note: Balance collection is disabled because the appointment was canceled/rejected.',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFEF4444),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (tx['transactionId'] != null)
                    _detailItem('Ref ID', tx['transactionId']),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'CLOSE',
                  style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                ),
              ),
              if (status == 'partially_paid' && balance > 0 && !isCanceled)
                ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setModalState(() => isUpdating = true);
                          try {
                            await AdminApiService.markBalancePaid(
                              userId: tx['user_id'],
                              appointmentId: tx['id'],
                            );
                            if (!ctx.mounted) return;
                            _loadAll(); // Refresh the list and stats
                            Navigator.pop(ctx);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Payment updated successfully!'),
                              ),
                            );
                          } catch (e) {
                            if (!ctx.mounted) return;
                            setModalState(() => isUpdating = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'COLLECT BALANCE',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailItem(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: color ?? const Color(0xFF1E293B),
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final m = [
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
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _timeStr(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:${d.minute.toString().padLeft(2, '0')} $ampm';
  }
}
