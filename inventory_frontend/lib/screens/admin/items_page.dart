import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({Key? key}) : super(key: key);

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final items = await auth.getItems();
    final suppliers = await auth.getSuppliers();
    final categories = await auth.getCategories();
    setState(() {
      _items = items;
      _suppliers = suppliers;
      _categories = categories;
      _loading = false;
    });
  }

  Future<void> _showItemDialog({Map<String, dynamic>? item}) async {
    final _formKey = GlobalKey<FormState>();
    String nama = item?['nama_barang'] ?? '';
    String satuan = item?['satuan'] ?? '';
    String harga = item?['harga']?.toString() ?? '';
    String stok = item?['stok']?.toString() ?? '';
    String lokasi = item?['lokasi'] ?? '';
    int supplierId = item?['id_supplier'] is int
        ? item!['id_supplier']
        : (item?['id_supplier'] != null
              ? int.parse(item!['id_supplier'].toString())
              : (_suppliers.isNotEmpty ? (_suppliers[0]['id'] as int) : 0));
    int kategoriId = item?['id_kategori'] is int
        ? item!['id_kategori']
        : (item?['id_kategori'] != null
              ? int.parse(item!['id_kategori'].toString())
              : (_categories.isNotEmpty ? (_categories[0]['id'] as int) : 0));

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Tambah Barang' : 'Edit Barang'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: nama,
                  decoration: const InputDecoration(labelText: 'Nama Barang'),
                  onSaved: (v) => nama = v ?? '',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Nama required' : null,
                ),
                DropdownButtonFormField<int>(
                  value: supplierId == 0 && _suppliers.isNotEmpty
                      ? _suppliers[0]['id'] as int
                      : supplierId,
                  items: _suppliers
                      .map(
                        (s) => DropdownMenuItem(
                          value: s['id'] as int,
                          child: Text(s['nama_supplier'] ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => supplierId = v ?? supplierId,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                ),
                DropdownButtonFormField<int>(
                  value: kategoriId == 0 && _categories.isNotEmpty
                      ? _categories[0]['id'] as int
                      : kategoriId,
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['id'] as int,
                          child: Text(c['nama_kategori'] ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => kategoriId = v ?? kategoriId,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                ),
                TextFormField(
                  initialValue: stok,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => stok = v ?? '0',
                ),
                TextFormField(
                  initialValue: lokasi,
                  decoration: const InputDecoration(labelText: 'Lokasi (rak)'),
                  onSaved: (v) => lokasi = v ?? '',
                ),
                TextFormField(
                  initialValue: satuan,
                  decoration: const InputDecoration(labelText: 'Satuan'),
                  onSaved: (v) => satuan = v ?? '',
                ),
                TextFormField(
                  initialValue: harga,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => harga = v ?? '0',
                ),
              ],
            ),
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
              final payload = {
                'nama_barang': nama,
                'id_supplier': supplierId,
                'id_kategori': kategoriId,
                'stok': int.tryParse(stok) ?? 0,
                'lokasi': lokasi,
                'satuan': satuan,
                'harga': double.tryParse(harga) ?? 0,
              };
              bool ok = false;
              if (item == null) {
                ok = await auth.createItem(payload);
              } else {
                final id = item['id'] is int
                    ? item['id']
                    : int.parse(item['id'].toString());
                ok = await auth.updateItem(id, payload);
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
      await _loadAll();
    } else if (result == false) {
      final auth = Provider.of<AuthService>(context, listen: false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.lastError ?? 'Gagal')));
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus barang'),
        content: Text('Hapus ${item['nama_barang']} ?'),
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
    final id = item['id'] is int
        ? item['id']
        : int.parse(item['id'].toString());
    final ok = await auth.deleteItem(id);
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Terhapus')));
      await _loadAll();
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
      appBar: AppBar(title: const Text('Data Barang')),
      drawer: const RoleDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final it = _items[i];
                  return Card(
                    child: ListTile(
                      title: Text(it['nama_barang'] ?? ''),
                      subtitle: Text(
                        'Supplier: ${it['supplier_name'] ?? ''}\nStok: ${it['stok'] ?? ''} ${it['satuan'] ?? ''}\nHarga: ${it['harga'] ?? ''}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showItemDialog(item: it),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteItem(it),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Tambah barang',
      ),
    );
  }
}
