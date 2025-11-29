import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/role_drawer.dart';

class ManagerApprovePage extends StatefulWidget {
  const ManagerApprovePage({Key? key}) : super(key: key);

  @override
  State<ManagerApprovePage> createState() => _ManagerApprovePageState();
}

class _ManagerApprovePageState extends State<ManagerApprovePage> {
  bool _loading = false;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final items = await auth.getRequestBarang();
    setState(() {
      // show only pending requests for approval
      _requests = items.where((r) => (r['status'] ?? '') == 'pending').toList();
      _loading = false;
    });
  }

  Future<void> _approve(int id) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    setState(() => _loading = true);
    final ok = await auth.updateRequestStatus(id, 'approved');
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request disetujui'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.lastError ?? 'Gagal menyetujui'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _reject(int id) async {
    final TextEditingController reason = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Alasan penolakan'),
          content: TextField(
            controller: reason,
            decoration: const InputDecoration(
              hintText: 'Masukkan alasan penolakan...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, reason.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
              ),
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );
    if (res == null) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    setState(() => _loading = true);
    final ok = await auth.updateRequestStatus(id, 'rejected', reason: res);
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request ditolak'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.lastError ?? 'Gagal menolak'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _namaBarang(Map r) {
    final nb = r['nama_barang'];
    if (nb is String && nb.isNotEmpty) return nb;
    final b = r['barang'];
    if (b is Map) return (b['nama_barang'] ?? b['name']) ?? '-';
    return '-';
  }

  String _peminta(Map r) {
    final rn = r['user_name'];
    if (rn is String && rn.isNotEmpty) return rn;
    final u = r['user'];
    if (u is Map) return (u['nama'] ?? u['name']) ?? '-';
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const RoleDrawer(),
      appBar: AppBar(
        title: const Text('Persetujuan Request'),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () {
    print('🔙 Back button pressed');
    Navigator.maybePop(context); // Gunakan maybePop instead of pop
  },
),
        // Hapus actions (refresh button)
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.teal.shade700),
              ),
            )
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada request pending',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Semua request telah diproses',
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
                    itemCount: _requests.length,
                    itemBuilder: (c, i) {
                      final r = _requests[i];
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.pending_actions,
                              color: Colors.orange.shade700,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            _namaBarang(r),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Peminta: ${_peminta(r)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Qty: ${r['qty']}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
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
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.check,
                                    color: Colors.green.shade700,
                                  ),
                                  onPressed: () => _approve(r['id']),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.red.shade700,
                                  ),
                                  onPressed: () => _reject(r['id']),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}