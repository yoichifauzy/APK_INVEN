import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({Key? key}) : super(key: key);

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final list = await auth.getSuppliers();
    setState(() {
      _suppliers = list;
      _loading = false;
    });
  }

  Future<void> _showSupplierDialog({Map<String, dynamic>? supplier}) async {
    final _formKey = GlobalKey<FormState>();
    String nama = supplier?['nama_supplier'] ?? '';
    String kontak = supplier?['kontak'] ?? '';
    String alamat = supplier?['alamat'] ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supplier == null ? 'Tambah Supplier' : 'Edit Supplier'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: nama,
                decoration: const InputDecoration(labelText: 'Nama Supplier'),
                onSaved: (v) => nama = v ?? '',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nama required' : null,
              ),
              TextFormField(
                initialValue: kontak,
                decoration: const InputDecoration(labelText: 'Kontak'),
                onSaved: (v) => kontak = v ?? '',
              ),
              TextFormField(
                initialValue: alamat,
                decoration: const InputDecoration(labelText: 'Alamat'),
                onSaved: (v) => alamat = v ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              _formKey.currentState!.save();
              final auth = Provider.of<AuthService>(context, listen: false);
              bool ok = false;
              if (supplier == null) {
                ok = await auth.createSupplier({
                  'nama_supplier': nama,
                  'kontak': kontak,
                  'alamat': alamat,
                });
              } else {
                final id = supplier['id'] is int
                    ? supplier['id']
                    : int.parse(supplier['id'].toString());
                ok = await auth.updateSupplier(id, {
                  'nama_supplier': nama,
                  'kontak': kontak,
                  'alamat': alamat,
                });
              }
              Navigator.pop(context, ok);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Berhasil')));
      await _loadSuppliers();
    } else if (result == false) {
      final auth = Provider.of<AuthService>(context, listen: false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.lastError ?? 'Gagal')));
    }
  }

  Future<void> _deleteSupplier(Map<String, dynamic> supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus supplier'),
        content: Text('Hapus ${supplier['nama_supplier']} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    final id = supplier['id'] is int
        ? supplier['id']
        : int.parse(supplier['id'].toString());
    final ok = await auth.deleteSupplier(id);
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Terhapus')));
      await _loadSuppliers();
    } else {
      final auth = Provider.of<AuthService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'Gagal menghapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Supplier')),
      drawer: const RoleDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSuppliers,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _suppliers.length,
                itemBuilder: (context, i) {
                  final s = _suppliers[i];
                  return Card(
                    child: ListTile(
                      title: Text(s['nama_supplier'] ?? ''),
                      subtitle: Text(
                        '${s['kontak'] ?? ''}\n${s['alamat'] ?? ''}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showSupplierDialog(supplier: s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteSupplier(s),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Tambah supplier',
      ),
    );
  }
}
