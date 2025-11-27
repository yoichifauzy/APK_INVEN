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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request disetujui')));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'Gagal menyetujui')),
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
            decoration: const InputDecoration(hintText: 'Alasan'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, reason.text),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request ditolak')));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'Gagal menolak')),
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
      drawer: const RoleDrawer(),
      appBar: AppBar(title: const Text('Persetujuan Request')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _requests.length,
                itemBuilder: (c, i) {
                  final r = _requests[i];
                  return Card(
                    child: ListTile(
                      title: Text(_namaBarang(r)),
                      subtitle: Text(
                        'Peminta: ${_peminta(r)}\nQty: ${r['qty']}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _approve(r['id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _reject(r['id']),
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
