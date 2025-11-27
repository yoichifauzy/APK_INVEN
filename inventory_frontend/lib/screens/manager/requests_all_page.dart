import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/role_drawer.dart';

class ManagerRequestsPage extends StatefulWidget {
  const ManagerRequestsPage({Key? key}) : super(key: key);

  @override
  State<ManagerRequestsPage> createState() => _ManagerRequestsPageState();
}

class _ManagerRequestsPageState extends State<ManagerRequestsPage> {
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
      _requests = items;
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

  String _requester(Map r) {
    final rn = r['user_name'];
    if (rn is String && rn.isNotEmpty) return rn;
    final u = r['user'];
    if (u is Map) {
      final n = u['nama'] ?? u['name'];
      if (n is String) return n;
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const RoleDrawer(),
      appBar: AppBar(title: const Text('Semua Request')),
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
                      title: Text(_barangName(r)),
                      subtitle: Text(
                        'Peminta: ${_requester(r)}\nQty: ${r['qty']} — Status: ${r['status'] ?? ''}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
