import 'package:flutter/material.dart';
import '../../widgets/role_drawer.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manager Dashboard')),
      drawer: const RoleDrawer(),
      body: const Center(child: Text('Manager widgets: approvals, low stock')),
    );
  }
}
