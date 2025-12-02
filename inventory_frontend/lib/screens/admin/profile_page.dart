import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.user;
    final isManager = (user?.roles ?? []).contains('manager');
    final titleText = isManager ? 'Profile — Manager' : 'Profile — Admin';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const RoleDrawer(),
      appBar: AppBar(
        title: Text(titleText),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await auth.fetchUser();
        },
        color: Colors.teal.shade700,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Colorful header card for Manager, fallback to simple white card for Admin
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isManager ? null : Colors.white,
                gradient: isManager
                    ? LinearGradient(
                        colors: [Colors.green.shade50, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: isManager
                              ? Colors.green.shade100
                              : Colors.teal.shade50,
                          child: Icon(
                            Icons.person,
                            size: 44,
                            color: isManager
                                ? Colors.green.shade800
                                : Colors.teal.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? '-',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.green.shade900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                user?.email ?? '-',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: (user?.roles ?? [])
                                    .map(
                                      (r) => Chip(
                                        label: Text(r.toString()),
                                        backgroundColor: Colors.green.shade100,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        // small badge for manager
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: const [
                              Icon(
                                Icons.manage_accounts,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Manager',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    // read-only biodata section similar to operator
                    const Text(
                      'Biodata',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_pin),
                      title: const Text('Nama'),
                      subtitle: Text(user?.name ?? '-'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(user?.email ?? '-'),
                    ),
                    if ((user?.roles ?? []).isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.badge),
                        title: const Text('Peran'),
                        subtitle: Text((user?.roles ?? []).join(', ')),
                      ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Informasi lain',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Halaman ini hanya menampilkan biodata manager. Untuk mengubah data akun, buka Pengaturan Akun.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/admin/account'),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
