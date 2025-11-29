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

  Widget _statusChip(String? status) {
    status = status ?? '';
    Color c;
    switch (status) {
      case 'pending':
        c = Colors.orange;
        break;
      case 'approved':
        c = Colors.blue;
        break;
      case 'done':
        c = const Color.fromARGB(255, 21, 222, 28);
        break;
      case 'rejected':
        c = Colors.red;
        break;
      default:
        c = Colors.grey;
    }
    return Chip(label: Text(status), backgroundColor: c.withOpacity(0.15));
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    drawer: const RoleDrawer(),
    backgroundColor: Colors.grey.shade100,
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
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _myRequests.isEmpty
                  ? Center(
                      child: Text(
                        "Belum ada request yang dibuat",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _myRequests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (c, i) {
                        final r = _myRequests[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              r['nama_barang'] ??
                                  r['barang']?['nama_barang'] ??
                                  '-',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                "Qty: ${r['qty']}\nTanggal: ${r['tanggal_request'] ?? '-'}",
                                style: TextStyle(
                                  height: 1.4,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            trailing: _statusChip(r['status']?.toString()),
                          ),
                        );
                      },
                    ),
            ),
          ),
  );
}

}
