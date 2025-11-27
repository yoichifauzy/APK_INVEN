import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/role_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _type = 'stock';
  String _format = 'json';
  bool _loading = false;
  List<Map<String, dynamic>> _rows = [];
  String? _error;

  DateTime? _from;
  DateTime? _to;
  int? _category;
  int? _supplier;

  @override
  void initState() {
    super.initState();
    // Auto-load stock report when an admin opens the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.isAuthenticated &&
          auth.user != null &&
          auth.user!.hasRole('admin')) {
        // default type is 'stock'
        _load();
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final fromStr = _from != null
        ? _from!.toIso8601String().split('T').first
        : null;
    final toStr = _to != null ? _to!.toIso8601String().split('T').first : null;
    final data = await auth.getReport(
      _type,
      format: 'json',
      from: fromStr,
      to: toStr,
      category: _category,
      supplier: _supplier,
    );
    setState(() {
      _rows = data;
      _error = auth.lastError;
    });
    setState(() => _loading = false);
  }

  Future<void> _openExport(String format) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final fromStr = _from != null
        ? _from!.toIso8601String().split('T').first
        : null;
    final toStr = _to != null ? _to!.toIso8601String().split('T').first : null;
    final url = auth.getReportUrl(
      _type,
      format: format,
      from: fromStr,
      to: toStr,
      category: _category,
      supplier: _supplier,
    );
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open export URL')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Laporan')),
        drawer: const RoleDrawer(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Anda harus login untuk melihat laporan.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }
    // Only admin may view reports
    if (auth.user == null || !auth.user!.hasRole('admin')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Laporan')),
        drawer: const RoleDrawer(),
        body: const Center(
          child: Text('Akses ditolak: halaman ini hanya untuk admin.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      drawer: const RoleDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(
                      value: 'stock',
                      child: Text('Stok Barang'),
                    ),
                    DropdownMenuItem(
                      value: 'request',
                      child: Text('Request Barang'),
                    ),
                    DropdownMenuItem(
                      value: 'masuk',
                      child: Text('Barang Masuk'),
                    ),
                    DropdownMenuItem(
                      value: 'keluar',
                      child: Text('Barang Keluar'),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _type = v ?? 'stock';
                    });
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('Tampilkan'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _openExport('csv'),
                  child: const Text('Export Excel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _openExport('html'),
                  child: const Text('Export PDF'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rows.isEmpty
                  ? const Center(child: Text('No data'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _type == 'stock'
                          ? _buildStockTable(_rows)
                          : DataTable(
                              columns: _rows.first.keys
                                  .map((k) => DataColumn(label: Text(k)))
                                  .toList(),
                              rows: _rows
                                  .map(
                                    (r) => DataRow(
                                      cells: r.values
                                          .map((v) => DataCell(Text('$v')))
                                          .toList(),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockTable(List<Map<String, dynamic>> rows) {
    // Expected keys from API: kode_barang, nama_barang, kategori, stok, lokasi, supplier
    final columns = [
      'Kode Barang',
      'Nama Barang',
      'Kategori',
      'Stok Saat Ini',
      'Lokasi',
      'Supplier',
    ];

    return DataTable(
      columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
      rows: rows.map((r) {
        final kode = r['kode_barang'] ?? r['kode'] ?? r['code'] ?? '';
        final nama = r['nama_barang'] ?? r['nama'] ?? '';
        final kategori = r['kategori'] ?? r['nama_kategori'] ?? '';
        final stok = r['stok'] ?? r['stok_saat_ini'] ?? r['jumlah'] ?? '';
        final lokasi = r['lokasi'] ?? '';
        final supplier = r['supplier'] ?? r['nama_supplier'] ?? '';

        return DataRow(
          cells: [
            DataCell(Text('$kode')),
            DataCell(Text('$nama')),
            DataCell(Text('$kategori')),
            DataCell(Text('$stok')),
            DataCell(Text('$lokasi')),
            DataCell(Text('$supplier')),
          ],
        );
      }).toList(),
    );
  }
}
