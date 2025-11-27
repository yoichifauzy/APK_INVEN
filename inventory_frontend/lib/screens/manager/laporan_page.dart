import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/role_drawer.dart';

class ManagerLaporanPage extends StatefulWidget {
  const ManagerLaporanPage({Key? key}) : super(key: key);

  @override
  State<ManagerLaporanPage> createState() => _ManagerLaporanPageState();
}

class _ManagerLaporanPageState extends State<ManagerLaporanPage> {
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

  Map<String, int> _aggregateByItem() {
    final Map<String, int> acc = {};
    for (var r in _requests) {
      final name = (r['nama_barang'] is String && r['nama_barang'] != '')
          ? r['nama_barang']
          : (r['barang'] is Map
                ? (r['barang']['nama_barang'] ?? r['barang']['name'])
                : 'Unknown');
      final parsed = int.tryParse(r['qty']?.toString() ?? '0') ?? 0;
      final int qty = parsed;
      acc[name] = (acc[name] ?? 0) + qty;
    }
    return acc;
  }

  @override
  Widget build(BuildContext context) {
    final report = _aggregateByItem();
    return Scaffold(
      drawer: const RoleDrawer(),
      appBar: AppBar(title: const Text('Laporan — Rekap Permintaan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(8),
              children: report.entries
                  .map(
                    (e) => Card(
                      child: ListTile(
                        title: Text(e.key),
                        trailing: Text(e.value.toString()),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
