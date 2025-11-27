import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class BarangKeluarPage extends StatefulWidget {
  const BarangKeluarPage({Key? key}) : super(key: key);

  @override
  State<BarangKeluarPage> createState() => _BarangKeluarPageState();
}

class _BarangKeluarPageState extends State<BarangKeluarPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _entries = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final entries = await auth.getBarangKeluar();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _showDetail(Map<String, dynamic> e) async {
    final tanggalRaw =
        e['tanggal_keluar'] ?? e['tanggal'] ?? e['tanggal_keluar'];
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
              Text('Keperluan: ${e['keterangan'] ?? '-'}'),
              Text('Jumlah keluar: ${e['qty'] ?? e['jumlah_keluar'] ?? ''}'),
              Text('Tanggal: $tanggal'),
              Text(
                'Operator: ${e['user_name'] ?? e['operator']?['nama'] ?? e['operator']?['name'] ?? '-'}',
              ),
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
    String qty = (item['qty'] ?? item['jumlah_keluar'] ?? '1').toString();
    String keterangan = item['keterangan'] ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit Barang Keluar'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: qty,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Qty required' : null,
                  onSaved: (v) => qty = v ?? '1',
                ),
                TextFormField(
                  initialValue: keterangan,
                  decoration: const InputDecoration(
                    labelText: 'Keperluan / Keterangan',
                  ),
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
                'qty': int.tryParse(qty) ?? 1,
                'keterangan': keterangan,
                'tanggal_keluar': DateTime.now().toIso8601String(),
              };
              final ok = await auth.updateBarangKeluar(
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

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus barang keluar'),
        content: const Text('Menghapus akan mengurangi histori. Lanjutkan?'),
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
    final res = await auth.deleteBarangKeluar(id);
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
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Data Barang Keluar'),
      ),
      drawer: const RoleDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: _entries.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Belum ada riwayat barang keluar')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _entries.length,
                      itemBuilder: (context, i) {
                        final e = _entries[i];
                        final tanggalRaw = e['tanggal_keluar'];
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
                              'Qty: ${e['qty'] ?? e['jumlah_keluar'] ?? ''} • Tanggal: $tanggalStr\nKeperluan: ${e['keterangan'] ?? '-'}\nOperator: ${e['user_name'] ?? e['operator']?['name'] ?? '-'}',
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
                                else if (status == 'done')
                                  const Chip(
                                    label: Text('Done'),
                                    backgroundColor: Colors.lightGreen,
                                  )
                                else if (status == 'rejected')
                                  const Chip(
                                    label: Text('Rejected'),
                                    backgroundColor: Colors.redAccent,
                                  )
                                else
                                  const Chip(
                                    label: Text('Unknown'),
                                    backgroundColor: Colors.grey,
                                  ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'view')
                                      return await _showDetail(e);
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
                                    if (v == 'export') {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Export laporan belum diimplementasikan',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (c) {
                                    return const [
                                      PopupMenuItem(
                                        value: 'view',
                                        child: Text('Detail'),
                                      ),
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                      PopupMenuItem(
                                        value: 'print',
                                        child: Text('Cetak'),
                                      ),
                                      PopupMenuItem(
                                        value: 'export',
                                        child: Text('Export laporan'),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton:
          Provider.of<AuthService>(context).user?.hasRole('operator') == true
          ? FloatingActionButton(
              onPressed: () async {
                // Quick create dialog for demo
                final _formKey = GlobalKey<FormState>();
                int qty = 1;
                String keterangan = '';

                final created = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Input Barang Keluar (sederhana)'),
                    content: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              initialValue: '1',
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Qty required'
                                  : null,
                              onSaved: (v) => qty = int.tryParse(v ?? '1') ?? 1,
                            ),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Keperluan / Keterangan',
                              ),
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
                          final auth = Provider.of<AuthService>(
                            context,
                            listen: false,
                          );
                          // use first item for demo
                          final items = await auth.getItems();
                          if (items.isEmpty) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tidak ada barang untuk dipilih'),
                              ),
                            );
                            Navigator.pop(c, false);
                            return;
                          }
                          final payload = {
                            'id_barang': items[0]['id'],
                            'qty': qty,
                            'keterangan': keterangan,
                          };
                          final ok = await auth.createBarangKeluar(payload);
                          if (!mounted) return;
                          Navigator.pop(c, ok);
                        },
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                );

                if (created == true) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Barang keluar disimpan')),
                  );
                  await _loadAll();
                }
              },
              child: const Icon(Icons.add),
              tooltip: 'Input Barang Keluar',
            )
          : null,
    );
  }
}
