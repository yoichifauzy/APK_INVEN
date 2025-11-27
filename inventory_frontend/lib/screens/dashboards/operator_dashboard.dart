import 'package:flutter/material.dart';
import '../../widgets/role_drawer.dart';

class OperatorDashboard extends StatelessWidget {
  const OperatorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operator Dashboard')),
      drawer: const RoleDrawer(),
      // Operator dashboard intentionally empty for now per request
      body: const Center(child: SizedBox.shrink()),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Text('Buka', style: TextStyle(color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
