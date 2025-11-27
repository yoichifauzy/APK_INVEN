import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class BarangMasukPage extends StatefulWidget {
  const BarangMasukPage({Key? key}) : super(key: key);

  @override
  State<BarangMasukPage> createState() => _BarangMasukPageState();
}

class _BarangMasukPageState extends State<BarangMasukPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final entries = await auth.getBarangMasuk();
    final items = await auth.getItems();
    final suppliers = await auth.getSuppliers();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _items = items;
      _suppliers = suppliers;
      _loading = false;
    });
  }

  Future<void> _showMasukDialog() async {
    final _formKey = GlobalKey<FormState>();
    int selectedItemId = _items.isNotEmpty ? (_items[0]['id'] as int) : 0;
    int? selectedSupplierId = _suppliers.isNotEmpty
        ? (_suppliers[0]['id'] as int)
        : null;
    String qty = '1';
    DateTime tanggal = DateTime.now();
    String keterangan = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Input Barang Masuk'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_items.isEmpty)
                  const Text('Tidak ada data barang tersedia.'),
                if (_items.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: selectedItemId,
                    items: _items
                        .map(
                          (it) => DropdownMenuItem(
                            value: it['id'] as int,
                            child: Text(it['nama_barang'] ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedItemId = v ?? selectedItemId,
                    decoration: const InputDecoration(labelText: 'Barang'),
                  ),
                if (_suppliers.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: selectedSupplierId,
                    items: _suppliers
                        .map(
                          (s) => DropdownMenuItem(
                            value: s['id'] as int,
                            child: Text(s['nama_supplier'] ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedSupplierId = v,
                    decoration: const InputDecoration(
                      labelText: 'Supplier (opsional)',
                    ),
                  ),
                TextFormField(
                  initialValue: qty,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Qty required' : null,
                  onSaved: (v) => qty = v ?? '1',
                ),
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: tanggal.toIso8601String().split('T').first,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Tanggal (YYYY-MM-DD)',
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: tanggal,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) {
                      tanggal = d;
                      setState(() {});
                    }
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Keterangan'),
                  onSaved: (v) => keterangan = v ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              _formKey.currentState!.save();
              final auth = Provider.of<AuthService>(context, listen: false);
              final payload = {
                'id_barang': selectedItemId,
                if (selectedSupplierId != null)
                  'id_supplier': selectedSupplierId,
                'qty': int.tryParse(qty) ?? 1,
                'tanggal_masuk': tanggal.toIso8601String(),
                'keterangan': keterangan,
              };
              final ok = await auth.createBarangMasuk(payload);
              if (!mounted) return;
              try {
                Navigator.pop(c, ok);
              } catch (_) {}
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Barang masuk disimpan')));
      await _loadAll();
    } else if (result == false) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.lastError ?? 'Gagal')));
    }
  }

  Future<void> _showDetail(Map<String, dynamic> e) async {
    final tanggalRaw = e['tanggal_masuk'];
    String tanggal = '';
    if (tanggalRaw != null) {
      try {
        tanggal = tanggalRaw.toString().split('T').first;
      } catch (_) {
        tanggal = tanggalRaw.toString();
      }
    }

    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Detail #${e['id'] ?? ''}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Barang: ${e['nama_barang'] ?? ''}'),
              Text('Supplier: ${e['nama_supplier'] ?? '-'}'),
              Text('Qty: ${e['qty'] ?? ''}'),
              Text('Tanggal: $tanggal'),
              Text('Operator: ${e['user_name'] ?? '-'}'),
              Text('Status: ${e['status'] ?? 'pending'}'),
              if ((e['reject_reason'] ?? '').toString().isNotEmpty)
                Text('Reject reason: ${e['reject_reason']}'),
              const SizedBox(height: 12),
              Text('Keterangan:'),
              Text(e['keterangan'] ?? '-'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cetak belum diimplementasikan')),
              );
            },
            child: const Text('Cetak'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final _formKey = GlobalKey<FormState>();
    int selectedItemId = item['id_barang'] is int
        ? item['id_barang']
        : int.parse(item['id_barang'].toString());
    int? selectedSupplierId = item['id_supplier'] is int
        ? item['id_supplier']
        : (item['id_supplier'] != null
              ? int.parse(item['id_supplier'].toString())
              : (_suppliers.isNotEmpty ? (_suppliers[0]['id'] as int) : null));
    String qty = item['qty']?.toString() ?? '1';
    DateTime tanggal =
        DateTime.tryParse(item['tanggal_masuk']?.toString() ?? '') ??
        DateTime.now();
    String keterangan = item['keterangan'] ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit Barang Masuk'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedItemId,
                  items: _items
                      .map(
                        (it) => DropdownMenuItem(
                          value: it['id'] as int,
                          child: Text(it['nama_barang'] ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => selectedItemId = v ?? selectedItemId,
                  decoration: const InputDecoration(labelText: 'Barang'),
                ),
                if (_suppliers.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: selectedSupplierId,
                    items: _suppliers
                        .map(
                          (s) => DropdownMenuItem(
                            value: s['id'] as int,
                            child: Text(s['nama_supplier'] ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedSupplierId = v,
                    decoration: const InputDecoration(
                      labelText: 'Supplier (opsional)',
                    ),
                  ),
                TextFormField(
                  initialValue: qty,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Qty required' : null,
                  onSaved: (v) => qty = v ?? '1',
                ),
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: tanggal.toIso8601String().split('T').first,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Tanggal (YYYY-MM-DD)',
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: tanggal,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) {
                      tanggal = d;
                      setState(() {});
                    }
                  },
                ),
                TextFormField(
                  initialValue: keterangan,
                  decoration: const InputDecoration(labelText: 'Keterangan'),
                  onSaved: (v) => keterangan = v ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              _formKey.currentState!.save();
              final auth = Provider.of<AuthService>(context, listen: false);
              final payload = {
                'id_barang': selectedItemId,
                if (selectedSupplierId != null)
                  'id_supplier': selectedSupplierId,
                'qty': int.tryParse(qty) ?? 1,
                'tanggal_masuk': tanggal.toIso8601String(),
                'keterangan': keterangan,
              };
              final ok = await auth.updateBarangMasuk(
                item['id'] is int
                    ? item['id']
                    : int.parse(item['id'].toString()),
                payload,
              );
              if (!mounted) return;
              try {
                Navigator.pop(c, ok);
              } catch (_) {}
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Diperbarui')));
      await _loadAll();
    } else if (result == false) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.lastError ?? 'Gagal')));
    }
  }

  Future<void> _showRejectDialog(Map<String, dynamic> item) async {
    final _formKey = GlobalKey<FormState>();
    String reason = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reject Barang Masuk'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            decoration: const InputDecoration(labelText: 'Alasan penolakan'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Alasan required' : null,
            onSaved: (v) => reason = v ?? '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              _formKey.currentState!.save();
              Navigator.pop(c, true);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    final res = await auth.rejectBarangMasuk(
      item['id'] is int ? item['id'] : int.parse(item['id'].toString()),
      reason: reason,
    );
    if (!mounted) return;
    if (res) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ditolak')));
      await _loadAll();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.lastError ?? 'Gagal')));
    }
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus barang masuk'),
        content: const Text(
          'Menghapus akan mengurangi histori dan mengembalikan stok. Lanjutkan?',
        ),
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
    if (ok != true) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    final id = entry['id'] is int
        ? entry['id']
        : int.parse(entry['id'].toString());
    final res = await auth.deleteBarangMasuk(id);
    if (!mounted) return;
    if (res) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dihapus')));
      await _loadAll();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.lastError ?? 'Gagal')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Barang Masuk')),
      drawer: const RoleDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: _entries.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Belum ada riwayat barang masuk')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _entries.length,
                      itemBuilder: (context, i) {
                        final e = _entries[i];
                        final tanggalRaw = e['tanggal_masuk'];
                        String tanggalStr = '';
                        if (tanggalRaw != null) {
                          try {
                            tanggalStr = tanggalRaw.toString().split('T').first;
                          } catch (_) {
                            tanggalStr = tanggalRaw.toString();
                          }
                        }
                        final status = (e['status'] ?? 'pending').toString();
                        return Card(
                          child: ListTile(
                            title: Text(e['nama_barang'] ?? ''),
                            subtitle: Text(
                              'Qty: ${e['qty'] ?? ''} • Tanggal: $tanggalStr\nSupplier: ${e['nama_supplier'] ?? '-'}\nOleh: ${e['user_name'] ?? '-'}\nKeterangan: ${e['keterangan'] ?? ''}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (status == 'pending')
                                  const Chip(
                                    label: Text('Pending'),
                                    backgroundColor: Colors.orangeAccent,
                                  )
                                else if (status == 'approved')
                                  const Chip(
                                    label: Text('Approved'),
                                    backgroundColor: Colors.greenAccent,
                                  )
                                else
                                  const Chip(
                                    label: Text('Rejected'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    final auth = Provider.of<AuthService>(
                                      context,
                                      listen: false,
                                    );
                                    if (v == 'view')
                                      return await _showDetail(e);
                                    if (v == 'approve') {
                                      final ok = await auth.approveBarangMasuk(
                                        e['id'] is int
                                            ? e['id']
                                            : int.parse(e['id'].toString()),
                                      );
                                      if (!mounted) return;
                                      if (ok) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Approved'),
                                          ),
                                        );
                                        await _loadAll();
                                      } else {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              auth.lastError ?? 'Gagal',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                    if (v == 'reject')
                                      return await _showRejectDialog(e);
                                    if (v == 'edit')
                                      return await _showEditDialog(e);
                                    if (v == 'delete')
                                      return await _deleteEntry(e);
                                    if (v == 'print') {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Cetak belum diimplementasikan',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (c) {
                                    final List<PopupMenuEntry<String>> items = [
                                      const PopupMenuItem(
                                        value: 'view',
                                        child: Text('View Detail'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'approve',
                                        child: Text('Approve'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'reject',
                                        child: Text('Reject'),
                                      ),
                                    ];
                                    if (status == 'pending')
                                      items.add(
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                      );
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    );
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'print',
                                        child: Text('Cetak'),
                                      ),
                                    );
                                    return items;
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMasukDialog,
        child: const Icon(Icons.add),
        tooltip: 'Input Barang Masuk',
      ),
    );
  }
}
