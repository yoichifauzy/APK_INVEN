import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class OperatorDashboard extends StatefulWidget {
  const OperatorDashboard({Key? key}) : super(key: key);

  @override
  State<OperatorDashboard> createState() => _OperatorDashboardState();
}

class _OperatorDashboardState extends State<OperatorDashboard> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _barangKeluar = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      final requests = await auth.getRequestBarang();
      final keluar = await auth.getBarangKeluar();
      final items = await auth.getItems();

      setState(() {
        _barangKeluar = keluar.map((e) => Map<String, dynamic>.from(e)).toList();
        _pendingRequests = requests
            .where((r) => (r['status'] ?? '') == 'approved')
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _items = items.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      setState(() => _error = 'Gagal memuat data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Operator Dashboard'),
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
              : SingleChildScrollView(
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
                      _buildQuickActions(),
                      const SizedBox(height: 20),
                      _buildPendingRequests(),
                      const SizedBox(height: 20),
                      _buildRecentBarangKeluar(),
                    ],
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
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStats() {
    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 1000 ? 3 : 2;
    final aspect = width > 1000 ? 2.2 : 2.2;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: aspect,
      children: [
        _statCard(
          'Process Keluar',
          _pendingRequests.length.toString(),
          Icons.upload_outlined,
          Colors.orange.shade700,
          () => Navigator.pushNamed(context, '/operator/process-keluar'),
        ),
        _statCard(
          'Barang Keluar',
          _barangKeluar.length.toString(),
          Icons.inventory_outlined,
          Colors.green.shade600,
          () => Navigator.pushNamed(context, '/operator/riwayat'),
        ),
        _statCard(
          'Data Barang',
          _items.length.toString(),
          Icons.inventory_2_outlined,
          Colors.blue.shade600,
          () => Navigator.pushNamed(context, '/admin/items'),
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

  Widget _buildQuickActions() {
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
            'Quick Actions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionButton(
                Icons.upload_outlined,
                'Process\nKeluar',
                Colors.orange.shade700,
                () => Navigator.pushNamed(context, '/operator/process-keluar'),
              ),
              _actionButton(
                Icons.inventory_outlined,
                'Barang\nKeluar',
                Colors.green.shade600,
                () => Navigator.pushNamed(context, '/operator/riwayat'),
              ),
              _actionButton(
                Icons.inventory_2_outlined,
                'Data\nBarang',
                Colors.blue.shade600,
                () => Navigator.pushNamed(context, '/admin/items'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRequests() {
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
                Icons.pending_actions,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pending Process',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._pendingRequests.take(5).map((request) {
            final name = request['nama_barang'] ?? 
                        request['barang']?['nama_barang'] ?? 
                        request['barang']?['nama'] ?? 'Request';
            final qty = request['qty'] ?? '-';
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.inventory_2_outlined,
                color: Colors.orange.shade600,
                size: 20,
              ),
              title: Text(
                name,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('Qty: $qty'),
            );
          }).toList(),
          if (_pendingRequests.length > 5)
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/operator/process-keluar'),
                child: const Text('Lihat semua'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentBarangKeluar() {
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
                Icons.history_outlined,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Barang Keluar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._barangKeluar.take(5).map((item) {
            final name = item['nama_barang'] ?? 
                        item['barang']?['nama_barang'] ?? 
                        item['barang']?['nama'] ?? 'Barang';
            final qty = item['qty'] ?? item['jumlah'] ?? '-';
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.upload_outlined,
                color: Colors.green.shade600,
                size: 20,
              ),
              title: Text(
                name,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('Qty: $qty'),
            );
          }).toList(),
          if (_barangKeluar.length > 5)
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/operator/riwayat'),
                child: const Text('Lihat semua'),
              ),
            ),
        ],
      ),
    );
  }
}