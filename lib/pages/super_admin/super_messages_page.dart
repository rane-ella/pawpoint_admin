import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/admin_api_service.dart';

class SuperMessagesPage extends StatefulWidget {
  const SuperMessagesPage({super.key});

  @override
  State<SuperMessagesPage> createState() => _SuperMessagesPageState();
}

class _SuperMessagesPageState extends State<SuperMessagesPage> {
  // ── State ──────────────────────────────────────────────────────────────────
  String? _activeConvId;
  String? _activePeerName;
  String? _activePeerUid;

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _staff = [];

  bool _loadingConvs = true;
  bool _loadingMsgs = false;

  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  Timer? _convTimer;
  Timer? _msgTimer;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _myName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'Super Admin';

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadConversations();
    _loadStaff();
    // Poll conversations every 5 seconds
    _convTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadConversations(),
    );
  }

  @override
  void dispose() {
    _convTimer?.cancel();
    _msgTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────
  Future<void> _loadStaff() async {
    try {
      final staff = await AdminApiService.fetchStaff();
      if (mounted) {
        setState(() => _staff = List<Map<String, dynamic>>.from(staff));
      }
    } catch (_) {}
  }

  Future<void> _loadConversations() async {
    if (_myUid.isEmpty) return;
    try {
      // Only fetch conversations that involve the current super admin
      final convs = await AdminApiService.fetchConversations(_myUid);
      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(convs);
          _loadingConvs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingConvs = false);
    }
  }

  Future<void> _loadMessages(String convId) async {
    if (mounted) setState(() => _loadingMsgs = true);
    try {
      // Fetch only conversations that include the current super admin
      final convs = await AdminApiService.fetchConversations(_myUid);
      final match = convs
          .cast<Map<String, dynamic>>()
          .where((c) => c['conversation_id'] == convId)
          .toList();
      final msgs = match.isNotEmpty
          ? List<Map<String, dynamic>>.from(match.first['messages'] ?? [])
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _messages = msgs;
          _loadingMsgs = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMsgs = false);
    }
  }

  void _openConversation(String convId, String peerName, String peerUid) {
    _msgTimer?.cancel();
    setState(() {
      _activeConvId = convId;
      _activePeerName = peerName;
      _activePeerUid = peerUid;
      _messages = [];
    });
    _loadMessages(convId);
    // Poll messages every 3 seconds
    _msgTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_activeConvId == convId) _loadMessages(convId);
    });
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ── Send ───────────────────────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (_activePeerUid == null || text.isEmpty) return;
    _msgCtrl.clear();
    try {
      await AdminApiService.sendMessage(
        senderId: _myUid,
        receiverId: _activePeerUid!,
        content: text,
        senderName: _myName,
        receiverName: _activePeerName ?? '',
        senderRole: 'super_admin',
      );
      if (_activeConvId != null) await _loadMessages(_activeConvId!);
      await _loadConversations();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
      }
    }
  }

  // ── Start New Chat ─────────────────────────────────────────────────────────
  void _startNewChat() {
    if (_staff.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loading contacts...')));
      _loadStaff();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'New Message',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: _staff.where((m) => m['uid'] != _myUid).isEmpty
              ? Center(
                  child: Text(
                    'No staff available',
                    style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                  ),
                )
              : ListView(
                  children: _staff.where((m) => m['uid'] != _myUid).map((
                    member,
                  ) {
                    final uid = member['uid'] as String? ?? '';
                    final name = member['name'] as String? ?? 'Staff';
                    final role = member['role'] as String? ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(
                          0xFF10B981,
                        ).withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E293B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        role,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                      onTap: () {
                        final convId = ([_myUid, uid]..sort()).join('__');
                        Navigator.pop(ctx);
                        _openConversation(convId, name, uid);
                      },
                    );
                  }).toList(),
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
        ],
      ),
    );
  }

  // ── Helper: resolve peer name ──────────────────────────────────────────────
  String _peerName(Map<String, dynamic> conv) {
    final participants = (conv['participants'] as List?)?.cast<String>() ?? [];
    final peerUid = participants.firstWhere(
      (p) => p != _myUid,
      orElse: () => '',
    );
    if (peerUid.isEmpty) return 'Unknown';
    // 1. Try the loaded staff list first (most reliable)
    final match = _staff.where((s) => s['uid'] == peerUid).toList();
    if (match.isNotEmpty) return match.first['name'] as String? ?? peerUid;
    // 2. Fall back to participant_names stored in the conversation doc
    final names = conv['participant_names'] as Map<String, dynamic>?;
    if (names != null &&
        names[peerUid] != null &&
        (names[peerUid] as String).isNotEmpty) {
      return names[peerUid] as String;
    }
    return peerUid;
  }

  String _peerUid(Map<String, dynamic> conv) {
    final participants = (conv['participants'] as List?)?.cast<String>() ?? [];
    return participants.firstWhere((p) => p != _myUid, orElse: () => '');
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isWide = constraints.maxWidth >= 600;
        if (isWide) {
          // Tablet / web — side-by-side layout
          return Container(
            color: Colors.white,
            child: Row(
              children: [
                SizedBox(width: 280, child: _buildSidebar()),
                Expanded(
                  child: _activeConvId == null
                      ? _buildEmptyState()
                      : _buildChatPanel(showBack: false),
                ),
              ],
            ),
          );
        }
        // Phone — single-panel layout
        return Container(
          color: Colors.white,
          child: _activeConvId == null
              ? _buildSidebar()
              : _buildChatPanel(showBack: true),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Conversations',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_comment_rounded,
                    color: Color(0xFF10B981),
                  ),
                  tooltip: 'New Chat',
                  onPressed: _startNewChat,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingConvs
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  )
                : _conversations.isEmpty
                ? Center(
                    child: Text(
                      'No conversations yet',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (_, i) {
                      final conv = _conversations[i];
                      final convId = conv['conversation_id'] as String? ?? '';
                      final isActive = _activeConvId == convId;
                      final name = _peerName(conv);
                      final pUid = _peerUid(conv);
                      return ListTile(
                        selected: isActive,
                        selectedTileColor: const Color(
                          0xFF10B981,
                        ).withValues(alpha: 0.1),
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1E293B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          conv['last_message'] ?? '',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _openConversation(convId, name, pUid),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Color(0xFFE2E8F0),
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a conversation',
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel({bool showBack = false}) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 18,
                    color: Colors.black87,
                  ),
                  onPressed: () => setState(() => _activeConvId = null),
                ),
              const Icon(
                Icons.medical_services_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _activePeerName ?? 'Chat',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_loadingMsgs)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF10B981),
                  ),
                ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: _messages.isEmpty && !_loadingMsgs
              ? Center(
                  child: Text(
                    'No messages yet. Say hello! 👋',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _buildBubble(_messages[i]),
                ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMe = msg['sender_id'] == _myUid;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF10B981) : const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  msg['sender_name'] ?? 'Staff',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              msg['content'] ?? '',
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white : const Color(0xFF1E293B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              onSubmitted: (_) => _send(),
              style: GoogleFonts.poppins(
                color: const Color(0xFF1E293B),
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Color(0xFF10B981)),
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
