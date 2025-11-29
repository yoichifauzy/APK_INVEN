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

  Widget _statusChip(String? status) {
    status = status ?? '';
    Color color;
    Color textColor;
    String statusText;
    
    switch (status) {
      case 'pending':
        color = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        statusText = 'Pending';
        break;
      case 'approved':
        color = Colors.green.shade50;
        textColor = Colors.green.shade800;
        statusText = 'Approved';
        break;
      case 'done':
        color = Colors.lightGreen.shade50;
        textColor = Colors.lightGreen.shade800;
        statusText = 'Done';
        break;
      case 'rejected':
        color = Colors.red.shade50;
        textColor = Colors.red.shade800;
        statusText = 'Rejected';
        break;
      default:
        color = Colors.grey.shade50;
        textColor = Colors.grey.shade800;
        statusText = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'approved':
        return Icons.check_circle_outline;
      case 'done':
        return Icons.done_all;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _statusIconColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'approved':
        return Colors.green.shade700;
      case 'done':
        return Colors.lightGreen.shade700;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '-';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  Future<void> _showDetail(Map<String, dynamic> e) async {
    final tanggalRaw = e['tanggal_keluar'] ?? e['tanggal'] ?? e['tanggal_keluar'];
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Barang: ${e['nama_barang'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Keperluan: ${e['keterangan'] ?? '-'}'),
                    Text('Jumlah keluar: ${e['qty'] ?? e['jumlah_keluar'] ?? ''}'),
                    Text('Tanggal: $tanggal'),
                    Text(
                      'Operator: ${e['user_name'] ?? e['operator']?['nama'] ?? e['operator']?['name'] ?? '-'}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Cetak belum diimplementasikan'),
                  backgroundColor: Colors.orange.shade600,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
            ),
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
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Qty required' : null,
                  onSaved: (v) => qty = v ?? '1',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: keterangan,
                  decoration: const InputDecoration(
                    labelText: 'Keperluan / Keterangan',
                    border: OutlineInputBorder(),
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data berhasil diperbarui'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadAll();
    } else if (result == false) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.lastError ?? 'Gagal memperbarui data'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Barang Keluar'),
        content: const Text('Menghapus akan mengurangi histori. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
            child: const Text('Batal'),
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
    if (ok != true) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    final id = entry['id'] is int
        ? entry['id']
        : int.parse(entry['id'].toString());
    final res = await auth.deleteBarangKeluar(id);
    if (!mounted) return;
    if (res) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data berhasil dihapus'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadAll();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.lastError ?? 'Gagal menghapus data'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[50],
    appBar: AppBar(
      title: const Text('Data Barang Keluar'),
      backgroundColor: Colors.teal.shade700,
      elevation: 0,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    
      drawer: const RoleDrawer(),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.teal.shade700),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: Colors.teal.shade700,
              child: _entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.output_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada riwayat barang keluar',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Data barang keluar akan muncul di sini',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
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
                                color: _statusIconColor(status).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _statusIcon(status),
                                color: _statusIconColor(status),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              e['nama_barang'] ?? '',
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
                                  'Qty: ${e['qty'] ?? e['jumlah_keluar'] ?? ''} • Tanggal: $tanggalStr',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Keperluan: ${e['keterangan'] ?? '-'}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Operator: ${e['user_name'] ?? e['operator']?['name'] ?? '-'}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _statusChip(status),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: Colors.grey.shade600,
                                  ),
                                  onSelected: (v) async {
                                    if (v == 'view') return await _showDetail(e);
                                    if (v == 'edit') return await _showEditDialog(e);
                                    if (v == 'delete') return await _deleteEntry(e);
                                    if (v == 'print') {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Cetak belum diimplementasikan'),
                                          backgroundColor: Colors.orange.shade600,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                    if (v == 'export') {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Export laporan belum diimplementasikan'),
                                          backgroundColor: Colors.orange.shade600,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (c) {
                                    return const [
                                      PopupMenuItem(
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility, size: 20),
                                            SizedBox(width: 8),
                                            Text('Detail'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'print',
                                        child: Row(
                                          children: [
                                            Icon(Icons.print, size: 20),
                                            SizedBox(width: 8),
                                            Text('Cetak'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'export',
                                        child: Row(
                                          children: [
                                            Icon(Icons.download, size: 20),
                                            SizedBox(width: 8),
                                            Text('Export laporan'),
                                          ],
                                        ),
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
                    title: const Text('Input Barang Keluar'),
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
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Qty required'
                                  : null,
                              onSaved: (v) => qty = int.tryParse(v ?? '1') ?? 1,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Keperluan / Keterangan',
                                border: OutlineInputBorder(),
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
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                        ),
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
                              SnackBar(
                                content: const Text('Tidak ada barang untuk dipilih'),
                                backgroundColor: Colors.orange.shade600,
                                behavior: SnackBarBehavior.floating,
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                        ),
                        child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (created == true) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Barang keluar berhasil disimpan'),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  await _loadAll();
                } else if (created == false) {
                  final auth = Provider.of<AuthService>(context, listen: false);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(auth.lastError ?? 'Gagal menyimpan data'),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}