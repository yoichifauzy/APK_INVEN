import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RoleDrawer extends StatelessWidget {
  const RoleDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.user;

    List<Widget> buildMenu() {
      if (user == null) return [];
      final roles = user.roles;
      final List<Widget> items = [];

      items.add(
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: const Text('Dashboard'),
          onTap: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          ),
        ),
      );

      if (roles.contains('admin')) {
        items.addAll([
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manajemen User'),
            onTap: () =>
                Navigator.pushNamed(context, '/admin/users'),
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text('Data Supplier'),
            onTap: () =>
                Navigator.pushNamed(context, '/admin/suppliers'),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Data Barang'),
            onTap: () =>
                Navigator.pushNamed(context, '/admin/items'),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Data Barang Masuk'),
            onTap: () =>
                Navigator.pushNamed(context, '/admin/masuk'),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Data Barang Keluar'),
            onTap: () =>
                Navigator.pushNamed(context, '/admin/keluar'),
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: const Text('Laporan'),
            onTap: () =>
                Navigator.pushNamed(context, '/admin/reports'),
          ),
          ListTile(
            leading: const Icon(Icons.request_page),
            title: const Text('Approve Requests'),
            onTap: () =>
                Navigator.pushNamed(context, '/admin/requests'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan Akun'),
            onTap: () => Navigator.pushNamed(context, '/account'),
          ),
        ]);
      }

      if (roles.contains('manager')) {
        items.addAll([
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Persetujuan Request'),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              Navigator.pushNamed(context, '/manager/approve'); // GUNAKAN pushNamed
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Semua Request'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/manager/requests');
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_chart),
            title: const Text('Laporan'),
            onTap: () {
                Navigator.pop(context); // Tutup drawer
                Navigator.pushNamed(context, '/manager/laporan');
              },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Data Barang'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/manager/items');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan Akun'),
            onTap: () => Navigator.pushNamed(context, '/account'),
          ),
        ]);
      }

      // Operator (staf gudang)
      if (roles.contains('operator')) {
        items.addAll([
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Proses Barang Keluar'),
            onTap: () =>
                Navigator.pushNamed(context, '/operator/process-keluar'),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Data Barang Masuk'),
            onTap: () => Navigator.pushNamed(context, '/admin/masuk'),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Data Barang (Lihat)'),
            onTap: () => Navigator.pushNamed(context, '/admin/items'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Riwayat Proses'),
            onTap: () => Navigator.pushNamed(context, '/operator/riwayat'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan Akun'),
            onTap: () => Navigator.pushNamed(context, '/account'),
          ),
        ]);
      }

      // accept both 'staff' and Indonesian 'karyawan'
      if (roles.contains('staff') || roles.contains('karyawan')) {
        items.addAll([
          ListTile(
            leading: const Icon(Icons.add_shopping_cart),
            title: const Text('Request Barang'),
            onTap: () => Navigator.pushNamed(context, '/staff/create-request'),
          ),
          ListTile(
            leading: const Icon(Icons.track_changes),
            title: const Text('Tracking Request'),
            onTap: () =>
                Navigator.pushNamed(context, '/staff/tracking'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Riwayat Permintaan'),
            onTap: () =>
                Navigator.pushNamed(context, '/staff/riwayat'),
          ),
        ]);
      }

      if (roles.contains('supplier')) {
        items.add(
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text('Orders'),
            onTap: () {},
          ),
        );
      }

      items.add(const Divider());
      items.add(
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profile'),
          onTap: () {},
        ),
      );

      items.add(
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () async {
            await auth.logout();
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
      );

      return items;
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? ''),
            accountEmail: Text(user?.email ?? ''),
          ),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: buildMenu()),
          ),
        ],
      ),
    );
  }
}
