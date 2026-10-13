import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/prescription_model.dart';
import '../../services/prescription_service.dart';

class PrescriptionChatScreen extends StatefulWidget {
  const PrescriptionChatScreen({super.key});

  @override
  State<PrescriptionChatScreen> createState() => _PrescriptionChatScreenState();
}

class _PrescriptionChatScreenState extends State<PrescriptionChatScreen> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _requestId = '';
  String _pharmacyName = 'Pharmacy';
  String _pharmacyPhone = '';
  String _prescriptionImageUrl = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _requestId = args['requestId'] as String? ?? 'sample_rx_1';
      _pharmacyName = args['pharmacyName'] as String? ?? 'CarePlus Chemist';
      _pharmacyPhone = args['pharmacyPhone'] as String? ?? '+1 (555) 234-5678';
      _prescriptionImageUrl = args['prescriptionImageUrl'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? quickText}) async {
    final text = quickText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    final msg = PrescriptionChatMessage(
      id: '',
      senderId: 'patient_sample_uid',
      senderName: 'John Doe',
      senderRole: 'customer',
      text: text,
      timestamp: DateTime.now(),
    );

    if (quickText == null) {
      _messageController.clear();
    }

    await _prescriptionService.sendChatMessage(
      requestId: _requestId,
      message: msg,
    );

    // Auto scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_pharmacyName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const Text('Verified Pharmacist • Active Now', style: TextStyle(fontSize: 11, color: AppColors.successDark)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
            tooltip: 'Call Store',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling $_pharmacyName at $_pharmacyPhone...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Prescription Thumbnail Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _prescriptionImageUrl.isNotEmpty
                      ? Image.network(
                          _prescriptionImageUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.receipt_rounded, color: AppColors.primary),
                          ),
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.receipt_rounded, color: AppColors.primary),
                        ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prescription attached to this chat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      Text('Pharmacist verified the doctor stamp', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Prescription In Review', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.successDark)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Real-time Chat Messages Stream
          Expanded(
            child: StreamBuilder<List<PrescriptionChatMessage>>(
              stream: _prescriptionService.streamChatMessages(_requestId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [
                  PrescriptionChatMessage(
                    id: '1',
                    senderId: 'pharmacy_store',
                    senderName: 'Pharmacist Sarah',
                    senderRole: 'pharmacy',
                    text: 'Hello John! We received your prescription. Amoxicillin 500mg and Paracetamol 650mg are both available. Do you require the brand name or generic version?',
                    timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
                  ),
                ];

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderRole == 'customer';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          border: isMe ? null : Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                msg.senderName,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: isMe ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 9,
                                color: isMe ? Colors.white70 : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Quick Replies
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _quickReplyChip('Yes, generic is fine'),
                _quickReplyChip('Can I pick up at 5 PM?'),
                _quickReplyChip('Please pack it, on my way!'),
                _quickReplyChip('What is the total price?'),
              ],
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Message $_pharmacyName...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(),
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

  Widget _quickReplyChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryLight,
        side: BorderSide.none,
        onPressed: () => _sendMessage(quickText: text),
      ),
    );
  }
}
