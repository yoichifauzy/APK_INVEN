import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/role_drawer.dart';
import '../services/auth_service.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  String _name = '';
  String _email = '';
  String _password = '';
  String _passwordConfirm = '';

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.user;
    if (user != null) {
      _name = user.name;
      _email = user.email;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    if (_password.isNotEmpty && _password != _passwordConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password konfirmasi tidak sama'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.user;
    if (user == null) return;

    setState(() => _loading = true);
    final payload = <String, dynamic>{'nama': _name, 'email': _email};
    if (_password.isNotEmpty) payload['password'] = _password;

    final ok = await auth.updateUser(user.id, payload);
    setState(() => _loading = false);
    if (ok) {
      await auth.fetchUser();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil tersimpan'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.lastError ?? 'Gagal menyimpan'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const RoleDrawer(),
      appBar: AppBar(
        title: const Text('Pengaturan Akun'),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.teal.shade700),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                final auth = Provider.of<AuthService>(context, listen: false);
                await auth.fetchUser();
                final user = auth.user;
                if (user != null) {
                  setState(() {
                    _name = user.name;
                    _email = user.email;
                  });
                }
              },
              color: Colors.teal.shade700,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Profil',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: _name,
                              decoration: const InputDecoration(
                                labelText: 'Nama',
                                border: OutlineInputBorder(),
                              ),
                              onSaved: (v) => _name = v?.trim() ?? '',
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Nama wajib diisi'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: _email,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onSaved: (v) => _email = v?.trim() ?? '',
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Email wajib diisi';
                                if (!v.contains('@'))
                                  return 'Format email tidak valid';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            const Text(
                              'Ganti Password (opsional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Password baru',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              onSaved: (v) => _password = v ?? '',
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Konfirmasi password',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              onSaved: (v) => _passwordConfirm = v ?? '',
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Simpan'),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: () async {
                                    final auth = Provider.of<AuthService>(
                                      context,
                                      listen: false,
                                    );
                                    await auth.logout();
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/',
                                    );
                                  },
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
