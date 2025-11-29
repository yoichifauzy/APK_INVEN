import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({Key? key}) : super(key: key);

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _items = [];
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
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final items = await auth.getItems();
      final masuk = await auth.getBarangMasuk();
      final keluar = await auth.getBarangKeluar();

      setState(() {
        _items = items.map((e) => Map<String, dynamic>.from(e)).toList();
        _barangMasuk = masuk.map((e) => Map<String, dynamic>.from(e)).toList();
        _barangKeluar = keluar.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      _error = "Gagal memuat data: $e";
    } finally {
      _loading = false;
      setState(() {});
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
        title: const Text("Staff Dashboard"),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
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
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          Text(_error ?? "Error"),
          ElevatedButton(onPressed: _loadData, child: const Text("Coba lagi")),
        ],
      ),
    );
  }

  Widget _buildContent() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Dashboard Staff",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                )),

        const SizedBox(height: 10),
        _buildTopStats(),

        const SizedBox(height: 20),
        _buildQuickActions(),   // <-- tambahin disini

        const SizedBox(height: 20),
        _buildStockChart(),

        const SizedBox(height: 20),
        _buildInOutTables(),
      ],
    ),
  );
}


  Widget _buildTopStats() {
    final totalItems = _items.length;
    final masukCount = _barangMasuk.length;
    final keluarCount = _barangKeluar.length;

    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 1000 ? 3 : 2;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _statCard("Items", totalItems.toString(), Icons.inventory_2_outlined,
            Colors.blue.shade600),
        _statCard("Barang Masuk", masukCount.toString(),
            Icons.download_outlined, Colors.green.shade700),
        _statCard("Barang Keluar", keluarCount.toString(),
            Icons.upload_outlined, Colors.orange.shade700),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8, spreadRadius: 1)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockChart() {
    if (_items.isEmpty) return const SizedBox();
    final items = _items
        .map((e) => {
              "name": e["nama_barang"] ?? e["name"] ?? "Item",
              "stok": (e["stok"] ?? e["stock"] ?? 0) as num
            })
        .toList();

    items.sort((a, b) => (b["stok"] as num).compareTo(a["stok"] as num));
    final top = items.take(5).toList();
    final maxStock = top.first["stok"] as num;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Top Stock",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
          const SizedBox(height: 10),
          ...top.map((it) {
            final name = it["name"];
            final stok = it["stok"] as num;
            final fraction = stok / maxStock;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(name),
                    Text(stok.toString()),
                  ]),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction.clamp(0, 1),
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
          }),
        ],
      ),
    );
  }

  Widget _buildInOutTables() {
    return Column(
      children: [
        _miniCard("Recent Barang Masuk", _barangMasuk, Icons.download_rounded,
            '/staff/masuk', Colors.green.shade700),
        const SizedBox(height: 16),
        _miniCard("Recent Barang Keluar", _barangKeluar, Icons.upload_rounded,
            '/staff/keluar', Colors.orange.shade700),
      ],
    );
  }

  Widget _miniCard(String title, List<Map<String, dynamic>> data, IconData icon,
      String route, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
          const SizedBox(height: 10),
          ...data.take(6).map((e) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: color),
              title: Text(e["nama_barang"] ?? e["barang"]?["nama"] ?? "Barang"),
              subtitle: Text("Qty: ${e["qty"] ?? e["jumlah"] ?? "-"}"),
            );
          }),
          TextButton(onPressed: () => Navigator.pushNamed(context, route),
              child: const Text("Lihat semua")),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _actionButton(Icons.add_shopping_cart, "Request", Colors.teal.shade700,
          () => Navigator.pushNamed(context, '/staff/create-request')),
      _actionButton(Icons.track_changes, "Tracking", Colors.blue.shade600,
          () => Navigator.pushNamed(context, '/staff/tracking')),
      _actionButton(Icons.history, "Riwayat", Colors.orange.shade600,
          () => Navigator.pushNamed(context, '/staff/riwayat')),
    ],
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
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800)),
          ],
        ),
      ),
    ),
  );
}




}
