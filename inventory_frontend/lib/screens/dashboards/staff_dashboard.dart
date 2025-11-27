import 'package:flutter/material.dart';
import '../../widgets/role_drawer.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Dashboard')),
      drawer: const RoleDrawer(),
      body: const Center(
        child: Text('Staff widgets: create request, my requests'),
      ),
    );
  }
}
