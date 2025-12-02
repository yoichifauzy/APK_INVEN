import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _barangMasuk = [];
  List<Map<String, dynamic>> _barangKeluar = [];

  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final items = await auth.getItems();
      final suppliers = await auth.getSuppliers();
      final users = await auth.getUsers();
      final masuk = await auth.getBarangMasuk();
      final keluar = await auth.getBarangKeluar();

      setState(() {
        _items = items.map((e) => Map<String, dynamic>.from(e)).toList();
        _suppliers = suppliers
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _users = users.map((e) => Map<String, dynamic>.from(e)).toList();
        _barangMasuk = masuk.map((e) => Map<String, dynamic>.from(e)).toList();
        _barangKeluar = keluar
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (e) {
      setState(() => _error = 'Gagal memuat data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: const RoleDrawer(),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.teal.shade700),
              ),
            )
          : _error != null
          ? _buildError()
          : FadeTransition(
              opacity: _fadeAnim,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Overview',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      _buildTopStats(),
                      const SizedBox(height: 20),
                      _buildStockChart(),
                      const SizedBox(height: 20),
                      Builder(
                        builder: (context) {
                          final width = MediaQuery.of(context).size.width;
                          if (width < 800) {
                            return Column(
                              children: [
                                _buildSupplierCard(),
                                const SizedBox(height: 16),
                                _buildRoleDistribution(),
                              ],
                            );
                          }

                          // Use Expanded so children never exceed available width
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildSupplierCard()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildRoleDistribution()),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildInOutTables(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text(_error ?? 'Error'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadData, child: const Text('Coba lagi')),
        ],
      ),
    );
  }

  Widget _buildTopStats() {
    final totalItems = _items.length;
    final totalSuppliers = _suppliers.length;
    final totalUsers = _users.length;
    final masukCount = _barangMasuk.length;
    final keluarCount = _barangKeluar.length;

    final width = MediaQuery.of(context).size.width;
    // Show 3 columns on wide screens, 2 columns on tablet/mobile/inspect.
    final crossCount = width > 1000 ? 3 : 2;
    final aspect = width > 1000 ? 3.0 : 2.2;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: aspect,
      children: [
        _statCard(
          'Items',
          totalItems.toString(),
          Icons.inventory_2_outlined,
          Colors.blue.shade600,
        ),
        _statCard(
          'Suppliers',
          totalSuppliers.toString(),
          Icons.local_shipping_outlined,
          Colors.green.shade600,
        ),
        _statCard(
          'Users',
          totalUsers.toString(),
          Icons.people_outline,
          Colors.purple.shade600,
        ),
        _statCard(
          'Barang Masuk',
          masukCount.toString(),
          Icons.download_outlined,
          Colors.green.shade700,
        ),
        _statCard(
          'Barang Keluar',
          keluarCount.toString(),
          Icons.upload_outlined,
          Colors.orange.shade700,
        ),
        _statCard(
          'Low Stock',
          _computeLowStock().toString(),
          Icons.warning_amber_rounded,
          Colors.red.shade600,
        ),
      ],
    );
  }

  int _computeLowStock() {
    int c = 0;
    for (var it in _items) {
      final stock = (it['stok'] ?? it['stock'] ?? 0) as num;
      final minStock = (it['stok_minimum'] ?? it['min_stock'] ?? 0) as num;
      if (stock <= minStock) c++;
    }
    return c;
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
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
          // Allow the text area to take remaining space and ellipsize if needed
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockChart() {
    // Build simple horizontal bar chart of top items by stock
    if (_items.isEmpty) return const SizedBox();
    final itemsWithStock = _items
        .map(
          (e) => {
            'name': e['nama_barang'] ?? e['nama'] ?? e['name'] ?? 'Item',
            'stok': (e['stok'] ?? e['stock'] ?? 0) as num,
          },
        )
        .toList();
    itemsWithStock.sort(
      (a, b) => (b['stok'] as num).compareTo(a['stok'] as num),
    );
    final top = itemsWithStock.take(6).toList();
    final maxStock = top.isNotEmpty
        ? (top.first['stok'] as num).toDouble()
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grafik Stok (Top ${top.length})',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 12),
          ...top.map((it) {
            final name = it['name'];
            final stok = (it['stok'] as num).toDouble();
            final fraction = maxStock > 0 ? (stok / maxStock) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stok.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction.clamp(0.0, 1.0),
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade600,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSupplierCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suppliers',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 10),
          ..._suppliers
              .take(6)
              .map(
                (s) => ListTile(
                  leading: const Icon(Icons.local_shipping),
                  title: Text(s['nama_supplier'] ?? s['name'] ?? 'Supplier'),
                  subtitle: Text(s['alamat'] ?? ''),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/admin/suppliers'),
            child: const Text('Lihat semua'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDistribution() {
    final Map<String, int> counts = {};
    for (var u in _users) {
      final role =
          (u['role'] ??
                  (u['roles'] is List
                      ? (u['roles'] as List).isNotEmpty
                            ? u['roles'][0]
                            : 'user'
                      : 'user'))
              .toString();
      counts[role] = (counts[role] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role Distribution',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 10),
          ...counts.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(e.key, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text(e.value.toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/admin/users'),
            child: const Text('Manage users'),
          ),
        ],
      ),
    );
  }

  Widget _buildInOutTables() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        Widget masukCard = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Barang Masuk',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
              const SizedBox(height: 8),
              ..._barangMasuk
                  .take(6)
                  .map(
                    (m) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.download_rounded,
                        color: Colors.green.shade700,
                      ),
                      title: Text(
                        m['nama_barang'] ?? m['barang']?['nama'] ?? 'Barang',
                      ),
                      subtitle: Text('Qty: ${m['qty'] ?? m['jumlah'] ?? '-'}'),
                    ),
                  )
                  .toList(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/admin/masuk'),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
        );

        Widget keluarCard = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Barang Keluar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
              const SizedBox(height: 8),
              ..._barangKeluar
                  .take(6)
                  .map(
                    (m) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.upload_rounded,
                        color: Colors.orange.shade700,
                      ),
                      title: Text(
                        m['nama_barang'] ?? m['barang']?['nama'] ?? 'Barang',
                      ),
                      subtitle: Text('Qty: ${m['qty'] ?? m['jumlah'] ?? '-'}'),
                    ),
                  )
                  .toList(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/admin/keluar'),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            children: [masukCard, const SizedBox(height: 16), keluarCard],
          );
        }

        final half = (constraints.maxWidth - 16) / 2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: half, child: masukCard),
            const SizedBox(width: 16),
            SizedBox(width: half, child: keluarCard),
          ],
        );
      },
    );
  }
}
