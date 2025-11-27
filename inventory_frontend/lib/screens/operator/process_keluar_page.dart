import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class ProcessKeluarPage extends StatefulWidget {
  const ProcessKeluarPage({Key? key}) : super(key: key);

  @override
  State<ProcessKeluarPage> createState() => _ProcessKeluarPageState();
}

class _ProcessKeluarPageState extends State<ProcessKeluarPage> {
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
      _requests = items
          .where((r) => (r['status'] ?? '') == 'approved')
          .toList();
      _loading = false;
    });
  }

  Future<void> _process(Map<String, dynamic> req) async {
    final qtyController = TextEditingController(
      text: req['qty']?.toString() ?? '',
    );
    final lokasiController = TextEditingController();
    final keteranganController = TextEditingController();

    String barangNameFromReq() {
      final nb = req['nama_barang'];
      if (nb is String && nb.isNotEmpty) return nb;
      final b = req['barang'];
      if (b is Map) {
        final n = b['nama_barang'] ?? b['name'];
        if (n is String) return n;
      }
      return '-';
    }

    final res = await showDialog<bool?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Proses Request #${req['id']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Barang: ${barangNameFromReq()}'),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah dikeluarkan',
                ),
              ),
              TextField(
                controller: lokasiController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi pengambilan',
                ),
              ),
              TextField(
                controller: keteranganController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (opsional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Proses'),
            ),
          ],
        );
      },
    );
    if (res != true) return;
    final qty = int.tryParse(qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Qty must be > 0')));
      return;
    }
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final ok = await auth.processRequestToKeluar(req['id'], {
      'qty': qty,
      'lokasi': lokasiController.text,
      'keterangan': keteranganController.text,
    });
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request processed')));
      _load();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.lastError ?? 'Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const RoleDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Operator — Proses Barang Keluar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _requests.length,
                itemBuilder: (ctx, i) {
                  final r = _requests[i];
                  String barangName() {
                    final nb = r['nama_barang'];
                    if (nb is String && nb.isNotEmpty) return nb;
                    final b = r['barang'];
                    if (b is Map) {
                      final n = b['nama_barang'] ?? b['name'];
                      if (n is String) return n;
                    }
                    return 'Barang';
                  }

                  String requesterName() {
                    final rn = r['user_name'];
                    if (rn is String && rn.isNotEmpty) return rn;
                    final u = r['user'];
                    if (u is Map) {
                      final n = u['nama'] ?? u['name'];
                      if (n is String) return n;
                    }
                    return '-';
                  }

                  return Card(
                    child: ListTile(
                      title: Text(barangName()),
                      subtitle: Text(
                        'Peminta: ${requesterName()} — Jumlah: ${r['qty']}',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _process(r),
                        child: const Text('Proses'),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
