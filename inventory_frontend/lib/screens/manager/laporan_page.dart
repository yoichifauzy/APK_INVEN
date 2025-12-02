import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/role_drawer.dart';

class ManagerLaporanPage extends StatefulWidget {
  const ManagerLaporanPage({Key? key}) : super(key: key);

  @override
  State<ManagerLaporanPage> createState() => _ManagerLaporanPageState();
}

class _ManagerLaporanPageState extends State<ManagerLaporanPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final items = await auth.getRequestBarang();
    setState(() {
      _requests = items;
      _loading = false;
    });
  }

  Map<String, int> _aggregateByItem() {
    final Map<String, int> acc = {};
    for (var r in _requests) {
      final name = (r['nama_barang'] is String && r['nama_barang'] != '')
          ? r['nama_barang']
          : (r['barang'] is Map
                ? (r['barang']['nama_barang'] ?? r['barang']['name'])
                : 'Unknown');
      final parsed = int.tryParse(r['qty']?.toString() ?? '0') ?? 0;
      final int qty = parsed;
      acc[name] = (acc[name] ?? 0) + qty;
    }
    return acc;
  }

  @override
  Widget build(BuildContext context) {
    final report = _aggregateByItem();
    final totalRequests = _requests.length;
    final totalItems = report.values.fold(0, (sum, value) => sum + value);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const RoleDrawer(),
      appBar: AppBar(
        title: const Text('Laporan — Rekap Permintaan'),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final scaffold = Scaffold.of(ctx);
              if (scaffold.isDrawerOpen) {
                Navigator.pop(ctx);
              } else {
                scaffold.openDrawer();
              }
            },
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.teal.shade700),
              ),
            )
          : _requests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada data laporan',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Data permintaan akan muncul di sini',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Summary Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          'Total Request',
                          totalRequests.toString(),
                          Icons.request_page_outlined,
                          Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          'Total Item',
                          totalItems.toString(),
                          Icons.inventory_2_outlined,
                          Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Report List
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                color: Colors.teal.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rekap Permintaan per Barang',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // List
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(0),
                            itemCount: report.entries.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              final entry = report.entries.elementAt(index);
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
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
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getQuantityColor(entry.value),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    entry.value.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getQuantityColor(int quantity) {
    return Colors.green.shade600;
  }
}
