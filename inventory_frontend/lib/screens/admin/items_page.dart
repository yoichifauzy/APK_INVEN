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
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (v) => nama = v ?? '',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Nama required' : null,
                ),
                const SizedBox(height: 12),
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
                  decoration: const InputDecoration(
                    labelText: 'Supplier',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
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
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: stok,
                  decoration: const InputDecoration(
                    labelText: 'Stok',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => stok = v ?? '0',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: lokasi,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi (rak)',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (v) => lokasi = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: satuan,
                  decoration: const InputDecoration(
                    labelText: 'Satuan',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (v) => satuan = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: harga,
                  decoration: const InputDecoration(
                    labelText: 'Harga',
                    border: OutlineInputBorder(),
                  ),
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
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data barang berhasil disimpan'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadAll();
    } else if (result == false) {
      final auth = Provider.of<AuthService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.lastError ?? 'Gagal menyimpan'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text('Hapus ${item['nama_barang']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Barang berhasil dihapus'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadAll();
    } else {
      final auth = Provider.of<AuthService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.lastError ?? 'Gagal menghapus'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _stockChip(int stok) {
    Color color;
    if (stok <= 0) {
      color = Colors.red.shade600;
    } else if (stok < 10) {
      color = Colors.orange.shade600;
    } else {
      color = Colors.green.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$stok',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const RoleDrawer(),
      appBar: AppBar(
        title: const Text('Data Barang'),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.teal.shade700),
              ),
            )
          : _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data barang',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Data barang akan muncul di sini',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: Colors.teal.shade700,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final it = _items[i];
                  final stok = int.tryParse(it['stok']?.toString() ?? '0') ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        it['nama_barang'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Supplier: ${it['supplier_name'] ?? '-'}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kategori: ${it['category_name'] ?? '-'}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lokasi: ${it['lokasi'] ?? '-'}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Harga: ${it['harga'] ?? '0'}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _stockChip(stok),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: Colors.blue.shade600,
                            ),
                            onPressed: () => _showItemDialog(item: it),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outlined,
                              color: Colors.red.shade600,
                            ),
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
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
