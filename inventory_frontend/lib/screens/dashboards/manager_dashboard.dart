import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({Key? key}) : super(key: key);

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _approveRequests = [];
  List<Map<String, dynamic>> _allRequests = [];
  List<Map<String, dynamic>> _laporan = [];

  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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
      final requests = await auth.getRequestBarang();

      setState(() {
        _items = items.map((e) => Map<String, dynamic>.from(e)).toList();
        _approveRequests =
            requests.map((e) => Map<String, dynamic>.from(e)).toList();
        _allRequests =
            requests.map((e) => Map<String, dynamic>.from(e)).toList();
        _laporan = _generateLaporanData(requests);
      });
    } catch (e) {
      setState(() => _error = 'Gagal memuat data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _generateLaporanData(List<dynamic> requests) {
    final Map<String, int> aggregated = {};
    
    for (var r in requests) {
      final name = (r['nama_barang'] is String && r['nama_barang'] != '')
          ? r['nama_barang']
          : (r['barang'] is Map
                ? (r['barang']['nama_barang'] ?? r['barang']['name'])
                : 'Unknown');
      final qty = int.tryParse(r['qty']?.toString() ?? '0') ?? 0;
      aggregated[name] = (aggregated[name] ?? 0) + qty;
    }
    
    return aggregated.entries
        .map((e) => {'nama_barang': e.key, 'total_qty': e.value})
        .toList();
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
        title: const Text('Manager Dashboard'),
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
                          _buildRecentTables(),
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
          ElevatedButton(
            onPressed: _loadData, 
            child: const Text('Coba lagi')
          ),
        ],
      ),
    );
  }

  Widget _buildTopStats() {
    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 1000 ? 4 : 2;
    final aspect = width > 1000 ? 2.5 : 2.2;

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
          _items.length.toString(),
          Icons.inventory_2_outlined,
          Colors.blue.shade600,
          () => Navigator.pushNamed(context, '/manager/items'),
        ),
        _statCard(
          'Approve Request',
          _approveRequests.length.toString(),
          Icons.check_circle_outline,
          Colors.orange.shade700,
          () => Navigator.pushNamed(context, '/manager/approve'),
        ),
        _statCard(
          'Semua Request',
          _allRequests.length.toString(),
          Icons.receipt_long_outlined,
          Colors.green.shade600,
          () => Navigator.pushNamed(context, '/manager/requests'),
        ),
        _statCard(
          'Laporan',
          _laporan.length.toString(),
          Icons.analytics_outlined,
          Colors.purple.shade600,
          () => Navigator.pushNamed(context, '/manager/laporan'),
        ),
      ],
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTables() {
    Widget approveCard = _buildRequestCard(
      'Approve Requests',
      _approveRequests,
      Icons.check_circle_outline,
      Colors.orange.shade700,
      '/manager/approve',
    );

    Widget allCard = _buildRequestCard(
      'Semua Requests',
      _allRequests,
      Icons.receipt_long_outlined,
      Colors.green.shade600,
      '/manager/requests',
    );

    Widget laporanCard = _buildLaporanCard();

    final width = MediaQuery.of(context).size.width;
    if (width < 900) {
      return Column(
        children: [
          approveCard, 
          const SizedBox(height: 16), 
          allCard,
          const SizedBox(height: 16),
          laporanCard,
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: approveCard,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: allCard,
            ),
          ],
        ),
        const SizedBox(height: 16),
        laporanCard,
      ],
    );
  }

  Widget _buildRequestCard(
    String title,
    List<Map<String, dynamic>> data,
    IconData icon,
    Color iconColor,
    String route,
  ) {
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
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 8),
          ...data.take(6).map((m) {
            final name = m['nama_barang'] ?? m['barang']?['nama'] ?? 'Request';
            final qty = m['qty'] ?? m['jumlah'] ?? '-';
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: iconColor),
              title: Text(
                name,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('Qty: $qty'),
            );
          }).toList(),
          if (data.length > 6)
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, route),
                child: const Text('Lihat semua'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLaporanCard() {
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
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Colors.purple.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Rekap Laporan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._laporan.take(5).map((item) {
            final name = item['nama_barang'] ?? 'Unknown';
            final totalQty = item['total_qty'] ?? 0;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.inventory_2_outlined,
                color: Colors.purple.shade600,
                size: 20,
              ),
              title: Text(
                name,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('Total: $totalQty'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  totalQty.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
          if (_laporan.length > 5)
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/manager/laporan'),
                child: const Text('Lihat semua'),
              ),
            ),
        ],
      ),
    );
  }
}