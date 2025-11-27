import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class ManagerItemsPage extends StatefulWidget {
  const ManagerItemsPage({Key? key}) : super(key: key);

  @override
  State<ManagerItemsPage> createState() => _ManagerItemsPageState();
}

class _ManagerItemsPageState extends State<ManagerItemsPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final items = await auth.getItems();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const RoleDrawer(),
      appBar: AppBar(title: const Text('Data Barang (Lihat)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final it = _items[i];
                  return Card(
                    child: ListTile(
                      title: Text(it['nama_barang'] ?? ''),
                      subtitle: Text(
                        'Stok: ${it['stok'] ?? ''} ${it['satuan'] ?? ''}\nSupplier: ${it['supplier_name'] ?? ''}',
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
