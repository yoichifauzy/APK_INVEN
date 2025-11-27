import 'package:flutter/material.dart';
import '../../widgets/role_drawer.dart';

class SupplierDashboard extends StatelessWidget {
  const SupplierDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Dashboard')),
      drawer: const RoleDrawer(),
      body: const Center(
        child: Text('Supplier widgets: assigned orders, deliveries'),
      ),
    );
  }
}
