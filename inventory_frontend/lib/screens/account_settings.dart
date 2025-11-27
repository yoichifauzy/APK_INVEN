import 'package:flutter/material.dart';
import '../widgets/role_drawer.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Akun')),
      drawer: const RoleDrawer(),
      body: const Center(child: Text('Edit profil & password')),
    );
  }
}
