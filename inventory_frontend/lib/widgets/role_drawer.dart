import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RoleDrawer extends StatelessWidget {
  const RoleDrawer({super.key});

  // Helper function to check if current route matches menu route
  bool _isCurrentRoute(BuildContext context, String routeName) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    return currentRoute == routeName;
  }

  // Helper function to build menu item with active state
  Widget _buildMenuItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String routeName,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.teal.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Colors.teal.shade700 : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? Colors.teal.shade800 : Colors.grey.shade800,
          ),
        ),
        trailing: isActive
            ? Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.teal.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.user;

    List<Widget> buildMenu() {
      if (user == null) return [];
      final roles = user.roles;
      final List<Widget> items = [];

      // Dashboard menu - active check
      items.add(
        _buildMenuItem(
          context: context,
          title: 'Dashboard',
          icon: Icons.dashboard,
          routeName: '/dashboard',
          isActive: _isCurrentRoute(context, '/dashboard'),
          onTap: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          ),
        ),
      );

      // Separator
      items.add(const SizedBox(height: 8));

      if (roles.contains('admin')) {
        items.addAll([
          _buildMenuItem(
            context: context,
            title: 'Manajemen User',
            icon: Icons.people,
            routeName: '/admin/users',
            isActive: _isCurrentRoute(context, '/admin/users'),
            onTap: () => Navigator.pushNamed(context, '/admin/users'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Data Supplier',
            icon: Icons.local_shipping,
            routeName: '/admin/suppliers',
            isActive: _isCurrentRoute(context, '/admin/suppliers'),
            onTap: () => Navigator.pushNamed(context, '/admin/suppliers'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Data Kategori',
            icon: Icons.category,
            routeName: '/admin/categories',
            isActive: _isCurrentRoute(context, '/admin/categories'),
            onTap: () => Navigator.pushNamed(context, '/admin/categories'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Data Barang',
            icon: Icons.inventory_2,
            routeName: '/admin/items',
            isActive: _isCurrentRoute(context, '/admin/items'),
            onTap: () => Navigator.pushNamed(context, '/admin/items'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Data Barang Masuk',
            icon: Icons.download,
            routeName: '/admin/masuk',
            isActive: _isCurrentRoute(context, '/admin/masuk'),
            onTap: () => Navigator.pushNamed(context, '/admin/masuk'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Data Barang Keluar',
            icon: Icons.upload,
            routeName: '/admin/keluar',
            isActive: _isCurrentRoute(context, '/admin/keluar'),
            onTap: () => Navigator.pushNamed(context, '/admin/keluar'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Laporan',
            icon: Icons.insert_drive_file,
            routeName: '/admin/reports',
            isActive: _isCurrentRoute(context, '/admin/reports'),
            onTap: () => Navigator.pushNamed(context, '/admin/reports'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Approve Requests',
            icon: Icons.request_page,
            routeName: '/admin/requests',
            isActive: _isCurrentRoute(context, '/admin/requests'),
            onTap: () => Navigator.pushNamed(context, '/admin/requests'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Pengaturan Akun',
            icon: Icons.settings,
            routeName: '/admin/account',
            isActive: _isCurrentRoute(context, '/admin/account'),
            onTap: () => Navigator.pushNamed(context, '/admin/account'),
          ),
        ]);
      }

      if (roles.contains('manager')) {
        items.addAll([
          _buildMenuItem(
            context: context,
            title: 'Persetujuan Request',
            icon: Icons.check_circle_outline,
            routeName: '/manager/approve',
            isActive: _isCurrentRoute(context, '/manager/approve'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/manager/approve');
            },
          ),
          _buildMenuItem(
            context: context,
            title: 'Semua Request',
            icon: Icons.list_alt,
            routeName: '/manager/requests',
            isActive: _isCurrentRoute(context, '/manager/requests'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/manager/requests');
            },
          ),
          _buildMenuItem(
            context: context,
            title: 'Laporan',
            icon: Icons.insert_chart,
            routeName: '/manager/laporan',
            isActive: _isCurrentRoute(context, '/manager/laporan'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/manager/laporan');
            },
          ),
          _buildMenuItem(
            context: context,
            title: 'Data Barang',
            icon: Icons.inventory_2,
            routeName: '/manager/items',
            isActive: _isCurrentRoute(context, '/manager/items'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/manager/items');
            },
          ),
          _buildMenuItem(
            context: context,
            title: 'Profile',
            icon: Icons.person,
            routeName: '/admin/profile',
            isActive: _isCurrentRoute(context, '/admin/profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/profile');
            },
          ),
          _buildMenuItem(
            context: context,
            title: 'Pengaturan Akun',
            icon: Icons.settings,
            routeName: '/admin/account',
            isActive: _isCurrentRoute(context, '/admin/account'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/account');
            },
          ),
        ]);
      }

      // Operator (staf gudang)
      if (roles.contains('operator')) {
        items.addAll([
          _buildMenuItem(
            context: context,
            title: 'Proses Barang Keluar',
            icon: Icons.upload_outlined,
            routeName: '/operator/process-keluar',
            isActive: _isCurrentRoute(context, '/operator/process-keluar'),
            onTap: () =>
                Navigator.pushNamed(context, '/operator/process-keluar'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Data Barang Masuk',
            icon: Icons.download,
            routeName: '/admin/masuk',
            isActive: _isCurrentRoute(context, '/admin/masuk'),
            onTap: () => Navigator.pushNamed(context, '/admin/masuk'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Data Barang (Lihat)',
            icon: Icons.inventory_2,
            routeName: '/admin/items',
            isActive: _isCurrentRoute(context, '/admin/items'),
            onTap: () => Navigator.pushNamed(context, '/admin/items'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Riwayat Proses',
            icon: Icons.history,
            routeName: '/operator/riwayat',
            isActive: _isCurrentRoute(context, '/operator/riwayat'),
            onTap: () => Navigator.pushNamed(context, '/operator/riwayat'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Profile',
            icon: Icons.person,
            routeName: '/operator/profile',
            isActive: _isCurrentRoute(context, '/operator/profile'),
            onTap: () => Navigator.pushNamed(context, '/operator/profile'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Pengaturan Akun',
            icon: Icons.settings,
            routeName: '/account',
            isActive: _isCurrentRoute(context, '/account'),
            onTap: () => Navigator.pushNamed(context, '/account'),
          ),
        ]);
      }

      // accept both 'staff' and Indonesian 'karyawan'
      if (roles.contains('staff') || roles.contains('karyawan')) {
        items.addAll([
          _buildMenuItem(
            context: context,
            title: 'Request Barang',
            icon: Icons.add_shopping_cart,
            routeName: '/staff/create-request',
            isActive: _isCurrentRoute(context, '/staff/create-request'),
            onTap: () => Navigator.pushNamed(context, '/staff/create-request'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Tracking Request',
            icon: Icons.track_changes,
            routeName: '/staff/tracking',
            isActive: _isCurrentRoute(context, '/staff/tracking'),
            onTap: () => Navigator.pushNamed(context, '/staff/tracking'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Riwayat Permintaan',
            icon: Icons.history,
            routeName: '/staff/riwayat',
            isActive: _isCurrentRoute(context, '/staff/riwayat'),
            onTap: () => Navigator.pushNamed(context, '/staff/riwayat'),
          ),
          _buildMenuItem(
            context: context,
            title: 'Profile',
            icon: Icons.person,
            routeName: '/staff/profile',
            isActive: _isCurrentRoute(context, '/staff/profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/staff/profile');
            },
          ),
          _buildMenuItem(
            context: context,
            title: 'Pengaturan Akun',
            icon: Icons.settings,
            routeName: '/staff/account',
            isActive: _isCurrentRoute(context, '/staff/account'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/staff/account');
            },
          ),
        ]);
      }

      if (roles.contains('supplier')) {
        items.add(
          _buildMenuItem(
            context: context,
            title: 'Orders',
            icon: Icons.local_shipping,
            routeName: '/supplier/orders',
            isActive: _isCurrentRoute(context, '/supplier/orders'),
            onTap: () {},
          ),
        );
      }

      // Generic Profile entry
      if (!roles.contains('operator') &&
          !roles.contains('manager') &&
          !roles.contains('staff') &&
          !roles.contains('karyawan')) {
        items.add(
          _buildMenuItem(
            context: context,
            title: 'Profile',
            icon: Icons.person,
            routeName: roles.contains('admin') ? '/admin/profile' : '/account',
            isActive: roles.contains('admin')
                ? _isCurrentRoute(context, '/admin/profile')
                : _isCurrentRoute(context, '/account'),
            onTap: () {
              if (roles.contains('admin')) {
                Navigator.pushNamed(context, '/admin/profile');
              } else {
                Navigator.pushNamed(context, '/account');
              }
            },
          ),
        );
      }

      // Logout section with divider
      items.add(const SizedBox(height: 16));
      items.add(const Divider());
      items.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade600),
            title: Text(
              'Logout',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              if (roles.contains('admin') ||
                  roles.contains('operator') ||
                  roles.contains('manager') ||
                  roles.contains('staff') ||
                  roles.contains('karyawan')) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Apakah anda ingin logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Ya, Logout'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                Navigator.pop(context);
                await auth.logout();
                Navigator.pushReplacementNamed(context, '/');
              } else {
                Navigator.pop(context);
                await auth.logout();
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      );

      return items;
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.name ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade200),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.name.isNotEmpty == true
                    ? user!.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, Colors.teal.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: buildMenu(),
            ),
          ),
        ],
      ),
    );
  }
}
