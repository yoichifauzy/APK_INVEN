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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final TextEditingController nameCtrl = TextEditingController(
      text: supplier?['nama_supplier'] ?? '',
    );
    final TextEditingController contactCtrl = TextEditingController(
      text: supplier?['kontak'] ?? '',
    );
    final TextEditingController addressCtrl = TextEditingController(
      text: supplier?['alamat'] ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              supplier == null
                                  ? 'Tambah Supplier'
                                  : 'Edit Supplier',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Form(
                          key: _formKey,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth > 520;
                              return Column(
                                children: [
                                  if (wide)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: TextFormField(
                                              controller: nameCtrl,
                                              decoration: const InputDecoration(
                                                labelText: 'Nama Supplier',
                                                filled: true,
                                              ),
                                              validator: (v) =>
                                                  (v == null || v.isEmpty)
                                                  ? 'Nama required'
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                            ),
                                            child: TextFormField(
                                              controller: contactCtrl,
                                              decoration: const InputDecoration(
                                                labelText: 'Kontak',
                                                filled: true,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        TextFormField(
                                          controller: nameCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Nama Supplier',
                                            filled: true,
                                          ),
                                          validator: (v) =>
                                              (v == null || v.isEmpty)
                                              ? 'Nama required'
                                              : null,
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: contactCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Kontak',
                                            filled: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: addressCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Alamat',
                                      filled: true,
                                    ),
                                    maxLines: 3,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Simpan'),
                              onPressed: () async {
                                if (!_formKey.currentState!.validate()) return;
                                final auth = Provider.of<AuthService>(
                                  context,
                                  listen: false,
                                );
                                bool ok = false;
                                final nama = nameCtrl.text.trim();
                                final kontak = contactCtrl.text.trim();
                                final alamat = addressCtrl.text.trim();
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    contactCtrl.dispose();
    addressCtrl.dispose();

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
                padding: const EdgeInsets.all(12),
                itemCount:
                    _suppliers.where((s) {
                      final q = _searchController.text.trim().toLowerCase();
                      if (q.isEmpty) return true;
                      final name = (s['nama_supplier'] ?? '')
                          .toString()
                          .toLowerCase();
                      final contact = (s['kontak'] ?? '')
                          .toString()
                          .toLowerCase();
                      final addr = (s['alamat'] ?? '').toString().toLowerCase();
                      return name.contains(q) ||
                          contact.contains(q) ||
                          addr.contains(q);
                    }).length +
                    1,
                itemBuilder: (context, index) {
                  final filtered = _suppliers.where((s) {
                    final q = _searchController.text.trim().toLowerCase();
                    if (q.isEmpty) return true;
                    final name = (s['nama_supplier'] ?? '')
                        .toString()
                        .toLowerCase();
                    final contact = (s['kontak'] ?? '')
                        .toString()
                        .toLowerCase();
                    final addr = (s['alamat'] ?? '').toString().toLowerCase();
                    return name.contains(q) ||
                        contact.contains(q) ||
                        addr.contains(q);
                  }).toList();

                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari nama, kontak, atau alamat',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Data Supplier',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${filtered.length} suppliers',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  }

                  final s = filtered[index - 1];
                  final name = s['nama_supplier'] ?? '';
                  final contact = s['kontak'] ?? '';
                  final addr = s['alamat'] ?? '';

                  String initials(String s) {
                    final parts = s.toString().split(' ');
                    if (parts.isEmpty) return '';
                    if (parts.length == 1)
                      return parts.first.substring(0, 1).toUpperCase();
                    return (parts[0][0] + parts[1][0]).toUpperCase();
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 1,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Text(
                          initials(name),
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact),
                          const SizedBox(height: 6),
                          Text(
                            addr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showSupplierDialog(supplier: s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSupplier(s),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSupplierDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
        tooltip: 'Tambah supplier',
      ),
    );
  }
}
