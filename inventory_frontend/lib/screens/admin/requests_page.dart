import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/role_drawer.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({Key? key}) : super(key: key);

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _requests = [];
  Timer? _pollTimer;
  Map<String, Map<String, dynamic>> _userMap = {};
  final Map<int, bool> _actionLoading = {};

  @override
  void initState() {
    super.initState();
    _load();
    // Poll every 10 seconds to reflect changes (e.g. manager approvals)
    // Use background polling so we don't show a full-screen loader repeatedly.
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      if (!_loading) _load(background: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // If `background` is true we refresh data silently without showing the
  // full-screen loading indicator (useful for polling).
  Future<void> _load({bool background = false}) async {
    if (!background) setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final items = await auth.getRequestBarang();
    // Load users once so we can resolve approver IDs -> username/role
    final users = await auth.getUsers();
    _userMap = {
      for (final u in users)
        '${u['id'] ?? u['user_id'] ?? u['uid'] ?? u['ID'] ?? ''}': u,
    };
    setState(() {
      // Show requests that are pending OR already approved by a manager
      _requests = items.where((r) {
        final status = (r['status'] ?? '').toString();
        if (status == 'pending') return true;
        // include requests that have an approver (e.g. approved by manager)
        return _extractApproverFromMap(r) != null;
      }).toList();
      if (!background) _loading = false;
    });
  }

  // Extract an approver/manager name from common response keys.
  // Returns null when no approver info is present.
  String? _extractApproverFromMap(Map<String, dynamic> r) {
    final keys = [
      'approved_by_name',
      'approved_by_username',
      'approved_by_user_name',
      'approved_by',
      'approved_by_user',
      'manager_name',
      'manager',
      'approved_by_nama',
    ];

    for (final k in keys) {
      if (!r.containsKey(k)) continue;
      final v = r[k];
      if (v == null) continue;

      // nested object (user) -> pick name/username
      if (v is Map) {
        final nested =
            v['nama'] ?? v['name'] ?? v['username'] ?? v['user_name'];
        if (nested is String && nested.isNotEmpty) return nested;
        final nid = v['id'] ?? v['user_id'];
        if (nid != null) {
          final found = _userMap['${nid}'];
          if (found != null) {
            final uname = found['username'] ?? found['name'] ?? found['nama'];
            final role = found['role'] ?? found['role_name'] ?? found['level'];
            if (uname != null && uname.toString().isNotEmpty) {
              return role != null ? '${uname} (${role})' : uname.toString();
            }
          }
        }
      }

      // string value: either username or numeric id
      if (v is String && v.isNotEmpty) {
        final numId = int.tryParse(v);
        if (numId != null) {
          final found = _userMap['$numId'];
          if (found != null) {
            final uname = found['username'] ?? found['name'] ?? found['nama'];
            final role = found['role'] ?? found['role_name'] ?? found['level'];
            if (uname != null && uname.toString().isNotEmpty) {
              return role != null ? '${uname} (${role})' : uname.toString();
            }
          }
        }
        return v;
      }

      // fallback: stringified value
      final s = v.toString();
      if (s.isNotEmpty) {
        final numId = int.tryParse(s);
        if (numId != null) {
          final found = _userMap['$numId'];
          if (found != null) {
            final uname = found['username'] ?? found['name'] ?? found['nama'];
            final role = found['role'] ?? found['role_name'] ?? found['level'];
            if (uname != null && uname.toString().isNotEmpty) {
              return role != null ? '${uname} (${role})' : uname.toString();
            }
          }
        }
        return s;
      }
    }

    return null;
  }

  Future<void> _approve(int id) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    _actionLoading[id] = true;
    setState(() {});
    final ok = await auth.updateRequestStatus(id, 'approved');
    _actionLoading[id] = false;
    setState(() {});
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request disetujui')));
      // Refresh in background to avoid blocking UI with full-screen loader
      _load(background: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'Gagal menyetujui request')),
      );
    }
  }

  Future<void> _reject(int id) async {
    final TextEditingController reason = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Alasan penolakan'),
          content: TextField(
            controller: reason,
            decoration: const InputDecoration(hintText: 'Alasan'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, reason.text),
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );
    if (res == null) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    _actionLoading[id] = true;
    setState(() {});
    final ok = await auth.updateRequestStatus(id, 'rejected', reason: res);
    _actionLoading[id] = false;
    setState(() {});
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request ditolak')));
      _load(background: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'Gagal menolak request')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const RoleDrawer(),
      appBar: AppBar(title: const Text('Admin — Pending Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _requests.length,
                itemBuilder: (ctx, i) {
                  final r = _requests[i];

                  String barangName() {
                    final nb = r['nama_barang'];
                    if (nb is String && nb.isNotEmpty) return nb;
                    final b = r['barang'];
                    if (b is Map) {
                      final n = b['nama_barang'] ?? b['name'];
                      if (n is String) return n;
                    }
                    return 'Barang';
                  }

                  String requesterName() {
                    final rn = r['user_name'];
                    if (rn is String && rn.isNotEmpty) return rn;
                    final u = r['user'];
                    if (u is Map) {
                      final n = u['nama'] ?? u['name'];
                      if (n is String) return n;
                    }
                    return '-';
                  }

                  final status = (r['status'] ?? '').toString();
                  final approver = _extractApproverFromMap(r);

                  return Card(
                    child: ListTile(
                      title: Text(barangName()),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Peminta: ${requesterName()} — Jumlah: ${r['qty']}',
                          ),
                          const SizedBox(height: 6),
                          // Use Wrap so long approver badge will wrap instead of
                          // causing a RenderFlex overflow on narrow screens.
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Status: ',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(status),
                              if (approver != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.6,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 14,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Disetujui oleh: $approver',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: status == 'pending'
                          ? (_actionLoading[r['id']] == true
                                ? SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        ),
                                        onPressed: () => _approve(r['id']),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _reject(r['id']),
                                      ),
                                    ],
                                  ))
                          : null,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
