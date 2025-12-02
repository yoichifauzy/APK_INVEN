import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_drawer.dart';
import '../../services/auth_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _users = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(() {
      // rebuild when search changes
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final users = await auth.getUsers();
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  Future<void> _showUserDialog({Map<String, dynamic>? user}) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController nameCtrl = TextEditingController(
      text: user?['nama'] ?? user?['name'] ?? '',
    );
    final TextEditingController emailCtrl = TextEditingController(
      text: user?['email'] ?? '',
    );
    final TextEditingController passwordCtrl = TextEditingController();
    String role = user?['role'] ?? 'karyawan';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              user == null ? 'Tambah User' : 'Edit User',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Form(
                          key: _formKey,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth > 520;
                              return Column(
                                children: [
                                  if (wide)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: TextFormField(
                                              controller: nameCtrl,
                                              decoration: const InputDecoration(
                                                labelText: 'Nama',
                                                filled: true,
                                              ),
                                              validator: (v) =>
                                                  (v == null || v.isEmpty)
                                                  ? 'Nama required'
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                            ),
                                            child: TextFormField(
                                              controller: emailCtrl,
                                              decoration: const InputDecoration(
                                                labelText: 'Email',
                                                filled: true,
                                              ),
                                              validator: (v) =>
                                                  (v == null || v.isEmpty)
                                                  ? 'Email required'
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        TextFormField(
                                          controller: nameCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Nama',
                                            filled: true,
                                          ),
                                          validator: (v) =>
                                              (v == null || v.isEmpty)
                                              ? 'Nama required'
                                              : null,
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: emailCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Email',
                                            filled: true,
                                          ),
                                          validator: (v) =>
                                              (v == null || v.isEmpty)
                                              ? 'Email required'
                                              : null,
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 12),

                                  if (user == null)
                                    TextFormField(
                                      controller: passwordCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                        filled: true,
                                      ),
                                      obscureText: true,
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Password required'
                                          : null,
                                    ),

                                  const SizedBox(height: 12),

                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: DropdownButtonFormField<String>(
                                      value: role,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'admin',
                                          child: Text('admin'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'operator',
                                          child: Text('operator'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'manajer',
                                          child: Text('manajer'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'karyawan',
                                          child: Text('karyawan'),
                                        ),
                                      ],
                                      onChanged: (v) =>
                                          setState(() => role = v ?? role),
                                      decoration: const InputDecoration(
                                        labelText: 'Role',
                                        filled: true,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Simpan'),
                              onPressed: () async {
                                if (!_formKey.currentState!.validate()) return;
                                final auth = Provider.of<AuthService>(
                                  context,
                                  listen: false,
                                );
                                bool ok = false;
                                final nama = nameCtrl.text.trim();
                                final email = emailCtrl.text.trim();
                                final password = passwordCtrl.text;
                                if (user == null) {
                                  ok = await auth.createUser({
                                    'nama': nama,
                                    'email': email,
                                    'password': password,
                                    'role': role,
                                  });
                                } else {
                                  ok = await auth.updateUser(
                                    user['id'] is int
                                        ? user['id']
                                        : int.parse(user['id'].toString()),
                                    {
                                      'nama': nama,
                                      'email': email,
                                      'role': role,
                                    },
                                  );
                                }
                                Navigator.pop(context, ok);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // dispose controllers
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();

    if (result == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Berhasil')));
      await _loadUsers();
    } else if (result == false) {
      final auth = Provider.of<AuthService>(context, listen: false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.lastError ?? 'Gagal')));
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus user'),
        content: Text(
          'Hapus ${user['nama'] ?? user['name'] ?? user['email']} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    final id = user['id'] is int
        ? user['id']
        : int.parse(user['id'].toString());
    final ok = await auth.deleteUser(id);
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Terhapus')));
      await _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'Gagal menghapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _users.where((u) {
      final name = (u['nama'] ?? u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString().toLowerCase();
      if (query.isEmpty) return true;
      return name.contains(query) ||
          email.contains(query) ||
          role.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin — Manajemen User')),
      drawer: const RoleDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari nama, email, atau role',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daftar pengguna',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${filtered.length} pengguna',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  }

                  final u = filtered[index - 1];
                  final name = u['nama'] ?? u['name'] ?? '';
                  final email = u['email'] ?? '';
                  final role = (u['role'] ?? '').toString();

                  Color badgeColor(String r) {
                    switch (r) {
                      case 'admin':
                        return Colors.teal.shade100;
                      case 'operator':
                        return Colors.blue.shade100;
                      case 'manajer':
                        return Colors.orange.shade100;
                      default:
                        return Colors.grey.shade200;
                    }
                  }

                  String initials(String s) {
                    final parts = s.toString().split(' ');
                    if (parts.isEmpty) return '';
                    if (parts.length == 1)
                      return parts.first.substring(0, 1).toUpperCase();
                    return (parts[0][0] + parts[1][0]).toUpperCase();
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 1,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade50,
                        child: Text(
                          initials(name),
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor(role),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              role,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showUserDialog(user: u),
                          ),
                          IconButton(
                            tooltip: 'Hapus',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(u),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
        tooltip: 'Tambah user',
      ),
    );
  }
}
