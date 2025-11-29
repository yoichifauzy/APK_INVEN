import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class StaffTrackingPage extends StatefulWidget {
  const StaffTrackingPage({Key? key}) : super(key: key);

  @override
  State<StaffTrackingPage> createState() => _StaffTrackingPageState();
}

class _StaffTrackingPageState extends State<StaffTrackingPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _myRequests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final all = await auth.getRequestBarang();
    final meId = auth.user?.id;
    setState(() {
      _myRequests = all.where((r) => r['id_user'] == meId).toList();
      _loading = false;
    });
  }

  String _barangName(Map r) {
    final nb = r['nama_barang'];
    if (nb is String && nb.isNotEmpty) return nb;
    final b = r['barang'];
    if (b is Map) {
      final n = b['nama_barang'] ?? b['name'];
      if (n is String) return n;
    }
    return '-';
  }

  Widget _statusChip(String? status) {
    status = status ?? '';
    Color color;
    Color textColor;
    String statusText;
    
    switch (status) {
      case 'pending':
        color = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        statusText = 'Pending';
        break;
      case 'approved':
        color = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        statusText = 'Disetujui';
        break;
      case 'done':
        color = Colors.green.shade50;
        textColor = Colors.green.shade800;
        statusText = 'Selesai';
        break;
      case 'rejected':
        color = Colors.red.shade50;
        textColor = Colors.red.shade800;
        statusText = 'Ditolak';
        break;
      default:
        color = Colors.grey.shade50;
        textColor = Colors.grey.shade800;
        statusText = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'approved':
        return Icons.check_circle_outline;
      case 'done':
        return Icons.done_all;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _statusIconColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'approved':
        return Colors.blue.shade700;
      case 'done':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '-';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const RoleDrawer(),
      appBar: AppBar(
        title: const Text('Tracking Request'),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.teal.shade700),
              ),
            )
          : _myRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.track_changes_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada request',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Request yang Anda buat akan muncul di sini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: Colors.teal.shade700,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myRequests.length,
                    itemBuilder: (c, i) {
                      final r = _myRequests[i];
                      final status = r['status']?.toString();
                      final tanggal = _formatDate(r['tanggal_request']);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _statusIconColor(status).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _statusIcon(status),
                              color: _statusIconColor(status),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            _barangName(r),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Qty: ${r['qty']}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tanggal: $tanggal',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (r['keterangan'] != null && 
                                  r['keterangan'].toString().isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      'Keterangan: ${r['keterangan']}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              if (r['alasan_penolakan'] != null && 
                                  r['alasan_penolakan'].toString().isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      'Alasan: ${r['alasan_penolakan']}',
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          trailing: _statusChip(status),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}