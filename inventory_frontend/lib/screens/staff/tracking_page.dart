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
        c = Colors.green;
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
      appBar: AppBar(title: const Text('Tracking Request')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _myRequests.length,
                itemBuilder: (c, i) {
                  final r = _myRequests[i];
                  return Card(
                    child: ListTile(
                      title: Text(
                        r['nama_barang'] ?? r['barang']?['nama_barang'] ?? '-',
                      ),
                      subtitle: Text(
                        'Qty: ${r['qty']}\nTanggal: ${r['tanggal_request'] ?? ''}',
                      ),
                      trailing: _statusChip(r['status']?.toString()),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
