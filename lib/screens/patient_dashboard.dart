import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';
import '../l10n/app_localizations.dart';
import 'video_call_screen.dart';
import 'upload_records_screen.dart';
import 'chat_screen.dart';
import 'general_qr_scanner.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(l10n.myRecords, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.blue),
            tooltip: l10n.uploadFile,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadRecordsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: l10n.logout,
            onPressed: () => auth.signOut(),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('records')
            .where('patientEmail', isEqualTo: auth.user?.email)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state with permission handling
          if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            
            // Check if it's a permission error
            if (errorMsg.contains('permission-denied')) {
              return _buildPermissionError(context, l10n);
            }
            
            // Check if it's an index error
            if (errorMsg.contains('failed-precondition') || 
                errorMsg.contains('requires an index')) {
              return _buildIndexError(context, l10n, errorMsg);
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.error ?? 'Error loading records',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      errorMsg,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Force refresh
                      (context as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry ?? 'Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context, l10n);
          }

          // Success state
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final record = PatientRecord.fromFirestore(snapshot.data!.docs[index]);
              return _PatientRecordCard(record: record);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[800],
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GeneralQRScanner(title: "Scan Doctor QR"))
          );
        },
        label: Text(l10n.scanDoctorCode, style: const TextStyle(color: Colors.white)),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }

  Widget _buildPermissionError(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.orange[300]),
          const SizedBox(height: 16),
          const Text(
            'Permission Required',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'You don\'t have permission to view medical records. Please contact support or try logging out and back in.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out & Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexError(BuildContext context, AppLocalizations l10n, String errorMsg) {
    // Extract index URL if present
    final urlRegex = RegExp(r'https://[^\s]+');
    final match = urlRegex.firstMatch(errorMsg);
    final indexUrl = match?.group(0);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_outlined, size: 80, color: Colors.blue[300]),
          const SizedBox(height: 16),
          const Text(
            'Database Setup Required',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'The database needs to be configured. Please create the required index in Firebase Console.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          if (indexUrl != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Click the button below to create the index:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                // Note: In a real app, you'd use url_launcher here
                // For now, show the URL
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Create Index'),
                    content: SelectableText(indexUrl),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Create Index'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noRecords ?? 'No records yet',
            style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadRecordsScreen())
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add),
            label: Text(l10n.uploadFirstRecord ?? 'Upload First Record'),
          )
        ],
      ),
    );
  }
}

class _PatientRecordCard extends StatelessWidget {
  final PatientRecord record;
  const _PatientRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              backgroundImage: record.doctorPhotoUrl.isNotEmpty
                  ? NetworkImage(record.doctorPhotoUrl)
                  : null,
              child: record.doctorPhotoUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.blue)
                  : null,
            ),
            title: Text(
              record.doctorName,
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            subtitle: Text(record.date, style: TextStyle(color: Colors.grey[600])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_outlined, color: Colors.blue),
                  tooltip: l10n.chat,
                  onPressed: () => _openChat(context),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam_outlined, color: Colors.green),
                  tooltip: l10n.videoCall,
                  onPressed: () => _startVideoCall(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(l10n.diagnosis, record.diagnosis, Colors.red[700]!),
                const SizedBox(height: 12),
                _infoRow(l10n.prescriptionAndTreatment, record.prescription, Colors.green[700]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chatId = _generateChatId(auth.user!.uid, record.doctorId);
    
    // Ensure chat document exists
    await _ensureChatExists(chatId, auth.user!.uid, record.doctorId);
    
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            appointmentId: record.doctorId,
            receiverName: record.doctorName
          ),
        ),
      );
    }
  }

  void _startVideoCall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          channelName: record.doctorId,
          token: ""
        )
      ),
    );
  }

  String _generateChatId(String userId1, String userId2) {
    // Create a consistent chat ID from two user IDs
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> _ensureChatExists(String chatId, String patientId, String doctorId) async {
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final docSnapshot = await chatDoc.get();
    
    if (!docSnapshot.exists) {
      // Create the chat document
      await chatDoc.set({
        'participants': [patientId, doctorId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'patientId': patientId,
        'doctorId': doctorId,
      });
    }
  }

  Widget _infoRow(String label, String text, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 12),
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)
          ),
        ),
      ],
    );
  }
}
