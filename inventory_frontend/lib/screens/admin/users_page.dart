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

  @override
  void initState() {
    super.initState();
    _loadUsers();
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
    String nama = user?['nama'] ?? user?['name'] ?? '';
    String email = user?['email'] ?? '';
    String role = user?['role'] ?? 'karyawan';
    String password = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? 'Tambah User' : 'Edit User'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: nama,
                decoration: const InputDecoration(labelText: 'Nama'),
                onSaved: (v) => nama = v ?? '',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nama required' : null,
              ),
              TextFormField(
                initialValue: email,
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (v) => email = v ?? '',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Email required' : null,
              ),
              if (user == null)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onSaved: (v) => password = v ?? '',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password required' : null,
                ),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('admin')),
                  DropdownMenuItem(value: 'operator', child: Text('operator')),
                  DropdownMenuItem(value: 'manajer', child: Text('manajer')),
                  DropdownMenuItem(value: 'karyawan', child: Text('karyawan')),
                ],
                onChanged: (v) => role = v ?? role,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              _formKey.currentState!.save();
              final auth = Provider.of<AuthService>(context, listen: false);
              bool ok = false;
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
                  {'nama': nama, 'email': email, 'role': role},
                );
              }
              Navigator.pop(context, ok);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

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
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen User')),
      drawer: const RoleDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _users.length,
                itemBuilder: (context, i) {
                  final u = _users[i];
                  final name = u['nama'] ?? u['name'] ?? '';
                  final email = u['email'] ?? '';
                  final role = u['role'] ?? '';
                  return Card(
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text('$email • $role'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showUserDialog(user: u),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteUser(u),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Tambah user',
      ),
    );
  }
}
