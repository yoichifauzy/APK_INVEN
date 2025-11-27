import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/role_drawer.dart';

class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({Key? key}) : super(key: key);

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _selectedItem;
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final items = await auth.getItems();
    setState(() {
      _items = items;
      if (_items.isNotEmpty) _selectedItem = _items.first;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (_selectedItem == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih barang')));
      return;
    }
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    setState(() => _loading = true);
    final payload = {
      'id_barang': _selectedItem!['id'],
      'qty': qty,
      'keterangan': _notesController.text,
    };
    // Use AuthService.create via POST through the provided endpoint helper
    final success = await auth.createRequest(payload);
    setState(() => _loading = false);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request berhasil dibuat')));
      // navigate directly to tracking so staff can see status
      Navigator.pushReplacementNamed(context, '/staff/tracking');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'Gagal membuat request')),
      );
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const RoleDrawer(),
      appBar: AppBar(
        title: const Text('Create Request'),
        // show hamburger menu instead of back button
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Barang'),
                  const SizedBox(height: 8),
                  DropdownButton<Map<String, dynamic>>(
                    isExpanded: true,
                    value: _selectedItem,
                    items: _items
                        .map(
                          (it) => DropdownMenuItem(
                            value: it,
                            child: Text(
                              it['nama_barang'] ?? it['name'] ?? 'Unknown',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedItem = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah (qty)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan (opsional)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.send),
                    label: const Text('Kirim Request'),
                  ),
                ],
              ),
      ),
    );
  }
}
