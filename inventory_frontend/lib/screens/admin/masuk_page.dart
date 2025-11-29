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
                    decoration: const InputDecoration(
                      labelText: 'Barang',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 12),
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
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 12),
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
                  readOnly: true,
                  controller: TextEditingController(
                    text: tanggal.toIso8601String().split('T').first,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Tanggal (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Keterangan',
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
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade600),
            ),
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
          content: const Text('Barang masuk berhasil disimpan'),
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
          content: Text(auth.lastError ?? 'Gagal menyimpan'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showDetail(Map<String, dynamic> e) async {
    final tanggal = _formatDate(e['tanggal_masuk']?.toString());
    
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Detail Barang Masuk #${e['id'] ?? ''}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                    Text('Supplier: ${e['nama_supplier'] ?? '-'}'),
                    Text('Qty: ${e['qty'] ?? ''}'),
                    Text('Tanggal: $tanggal'),
                    Text('Operator: ${e['user_name'] ?? '-'}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Keterangan:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(e['keterangan'] ?? '-'),
              if ((e['reject_reason'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Alasan Penolakan:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(
                  e['reject_reason'] ?? '',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const RoleDrawer(),
      appBar: AppBar(
        title: const Text('Data Barang Masuk'),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.teal.shade700),
              ),
            )
          : _entries.isEmpty
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
                        'Belum ada data barang masuk',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Data barang masuk akan muncul di sini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  color: Colors.teal.shade700,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    itemBuilder: (context, i) {
                      final e = _entries[i];
                      final status = (e['status'] ?? 'pending').toString();
                      final tanggal = _formatDate(e['tanggal_masuk']?.toString());
                      
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
                                'Supplier: ${e['nama_supplier'] ?? '-'}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Qty: ${e['qty'] ?? ''}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tanggal: $tanggal',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Operator: ${e['user_name'] ?? '-'}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (e['keterangan'] != null && 
                                  e['keterangan'].toString().isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      'Keterangan: ${e['keterangan']}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          trailing: _statusChip(status),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMasukDialog,
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}