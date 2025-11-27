import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class RiwayatPermintaanPage extends StatefulWidget {
  const RiwayatPermintaanPage({Key? key}) : super(key: key);

  @override
  State<RiwayatPermintaanPage> createState() => _RiwayatPermintaanPageState();
}

class _RiwayatPermintaanPageState extends State<RiwayatPermintaanPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const RoleDrawer(),
      appBar: AppBar(title: const Text('Riwayat Permintaan')),
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
                        'Tanggal: ${r['tanggal_request'] ?? ''}\nStatus: ${r['status'] ?? ''}\nAlasan: ${r['alasan_penolakan'] ?? '-'}',
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
