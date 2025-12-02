import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/role_drawer.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as xls;
import '../../utils/download_helper_io.dart'
    if (dart.library.html) '../../utils/download_helper_web.dart'
    as dh;

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _type = 'stock';
  String _format = 'json';
  bool _loading = false;
  List<Map<String, dynamic>> _rows = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  DateTime? _from;
  DateTime? _to;
  int? _category;
  int? _supplier;
  bool _showDebug = false;
  Map<String, Map<String, dynamic>> _userMap = {};
  Map<String, Map<String, dynamic>> _requestMap = {};
  Map<String, Map<String, dynamic>> _requestById = {}; // keyed by id_request

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.isAuthenticated &&
          auth.user != null &&
          auth.user!.hasRole('admin')) {
        _load();
      }
    });
    // Use onChanged on the TextField instead of a controller listener to avoid
    // 'used after disposed' issues when the widget is disposed and the
    // controller still fires listeners.
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = Provider.of<AuthService>(context, listen: false);
    final fromStr = _from != null
        ? _from!.toIso8601String().split('T').first
        : null;
    final toStr = _to != null ? _to!.toIso8601String().split('T').first : null;
    try {
      final data = await auth.getReport(
        _type,
        format: _format,
        from: fromStr,
        to: toStr,
        category: _category,
        supplier: _supplier,
      );

      // Debug: print structure of first data
      if (data.isNotEmpty) {
        print('=== DEBUG REPORT DATA ===');
        print('Jenis laporan: $_type');
        print('Jumlah data: ${data.length}');
        print('Data pertama keys: ${data.first.keys.toList()}');
        print('Data pertama: ${data.first}');
      }

      // build user lookup for resolving karyawan/nama fields in reports
      try {
        final users = await auth.getUsers();
        _userMap = {
          for (final u in users)
            '${u['id'] ?? u['user_id'] ?? u['uid'] ?? u['ID'] ?? ''}': u,
        };
      } catch (_) {
        _userMap = {};
      }

      // also fetch raw requests so we can try to resolve karyawan when
      // the report row doesn't include user info (match by tanggal/barang/qty)
      try {
        final reqs = await auth.getRequestBarang();
        _requestMap = {};
        _requestById = {};
        for (final r in reqs) {
          final rid =
              (r['id'] ?? r['request_id'] ?? r['id_request'] ?? r['requestId']);
          if (rid != null) {
            _requestById['${rid}'] = r;
          }
          final t =
              (r['tanggal_request'] ?? r['tanggal'] ?? r['created_at'] ?? '')
                  .toString()
                  .split('T')
                  .first
                  .trim();
          final barang =
              (r['nama_barang'] ??
                      r['barang_name'] ??
                      r['barang'] ??
                      r['item_name'] ??
                      r['barang_nama'] ??
                      '')
                  .toString()
                  .toLowerCase()
                  .trim();
          final qty = (r['qty'] ?? r['jumlah'] ?? r['quantity'] ?? '')
              .toString();
          final key = '$t||$barang||$qty';
          if (!_requestMap.containsKey(key)) _requestMap[key] = r;
        }
      } catch (_) {
        _requestMap = {};
      }

      // If this is stock report and API did not include unit info,
      // try to enrich rows by fetching items and mapping unit (satuan).
      List<Map<String, dynamic>> finalRows = List.from(data);
      if (_type == 'stock' && finalRows.isNotEmpty) {
        // Quick check if at least one row already has a unit
        bool anyHasUnit = finalRows.any((r) {
          final u = _getUnitValue(r);
          return u != '-' && u.isNotEmpty;
        });
        if (!anyHasUnit) {
          try {
            final items = await auth.getItems();
            if (items.isNotEmpty) {
              // Build a lookup map by possible code keys
              final Map<String, Map<String, dynamic>> byCode = {};
              for (var it in items) {
                final k = (it['kode_barang'] ?? it['kode'] ?? it['code'])
                    ?.toString();
                if (k != null) byCode[k] = it;
              }

              for (var row in finalRows) {
                final currentUnit = _getUnitValue(row);
                if (currentUnit == '-' || currentUnit.isEmpty) {
                  final kode =
                      (row['kode_barang'] ?? row['kode'] ?? row['code'])
                          ?.toString();
                  String foundUnit = '-';
                  if (kode != null && byCode.containsKey(kode)) {
                    final matched = byCode[kode]!;
                    foundUnit = _getUnitValue(matched);
                  } else {
                    // try match by name
                    final name =
                        (row['nama_barang'] ?? row['nama'] ?? row['name'])
                            ?.toString();
                    if (name != null && name.isNotEmpty) {
                      final m = items.firstWhere((it) {
                        final n =
                            (it['nama_barang'] ?? it['nama'] ?? it['name'])
                                ?.toString();
                        return n != null &&
                            n.toLowerCase() == name.toLowerCase();
                      }, orElse: () => <String, dynamic>{});
                      if (m.isNotEmpty) foundUnit = _getUnitValue(m);
                    }
                  }

                  if (foundUnit != '-' && foundUnit.isNotEmpty) {
                    // store under 'satuan' so UI picks it up
                    row['satuan'] = foundUnit;
                  }
                }
              }
            }
          } catch (_) {
            // ignore enrich failures, keep original rows
          }
        }
      }
      // If this is request report, try to resolve missing karyawan by matching
      // against request_barang rows we fetched above.
      if (_type == 'request' && finalRows.isNotEmpty) {
        for (final row in finalRows) {
          // if karyawan already present, skip
          final kVal = row['karyawan'];
          final resolved = _resolvePerson(kVal, 'karyawan');
          if (resolved != null) {
            row['karyawan'] = resolved;
            continue;
          }

          // build key from report row
          final t = (row['tanggal'] ?? row['tanggal_request'] ?? '')
              .toString()
              .split('T')
              .first
              .trim();
          final barang =
              (row['barang'] ?? row['nama_barang'] ?? row['item'] ?? '')
                  .toString()
                  .toLowerCase()
                  .trim();
          final qty = (row['qty'] ?? row['jumlah'] ?? '').toString();
          final key = '$t||$barang||$qty';
          final matched = _requestMap[key];
          if (matched != null) {
            final idUser =
                matched['id_user'] ?? matched['user_id'] ?? matched['uid'];
            if (idUser != null) {
              final found = _userMap['${idUser}'];
              if (found != null) {
                row['karyawan'] =
                    (found['nama'] ?? found['name'] ?? found['username'])
                        .toString();
              } else {
                row['karyawan'] = 'id_user:${idUser}';
              }
            }
          }
        }
      }

      // If this is masuk report, try to resolve missing operator by matching
      // against barang_masuk rows fetched from the API.
      if (_type == 'masuk' && finalRows.isNotEmpty) {
        try {
          final masukList = await auth.getBarangMasuk();
          final Map<String, Map<String, dynamic>> masukMap = {};
          for (final m in masukList) {
            final t =
                (m['tanggal_masuk'] ?? m['tanggal'] ?? m['created_at'] ?? '')
                    .toString()
                    .split('T')
                    .first
                    .trim();
            final barang =
                (m['barang'] ?? m['nama_barang'] ?? m['item_name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .trim();
            final qty = (m['qty'] ?? m['jumlah'] ?? m['quantity'] ?? '')
                .toString();
            final key = '$t||$barang||$qty';
            if (!masukMap.containsKey(key)) masukMap[key] = m;
          }

          for (final row in finalRows) {
            final opVal = row['operator'];
            final resolvedOp = _resolvePerson(opVal, 'operator');
            if (resolvedOp != null) {
              row['operator'] = resolvedOp;
              continue;
            }

            final t = (row['tanggal_masuk'] ?? row['tanggal'] ?? '')
                .toString()
                .split('T')
                .first
                .trim();
            final barang =
                (row['barang'] ?? row['nama_barang'] ?? row['item'] ?? '')
                    .toString()
                    .toLowerCase()
                    .trim();
            final qty = (row['qty'] ?? row['jumlah'] ?? '').toString();
            final key = '$t||$barang||$qty';
            final matched = masukMap[key];
            if (matched != null) {
              final idUser =
                  matched['id_user'] ??
                  matched['user_id'] ??
                  matched['operator_id'] ??
                  matched['operator'];
              if (idUser != null) {
                final found = _userMap['${idUser}'];
                if (found != null) {
                  row['operator'] =
                      (found['nama'] ?? found['name'] ?? found['username'])
                          .toString();
                } else {
                  row['operator'] = 'id_user:${idUser}';
                }
              }
            }
          }
        } catch (_) {
          // ignore enrichment failures
        }
      }

      // If this is keluar report, try to resolve missing operator by matching
      // against barang_keluar rows fetched from the API. Use several
      // fallback heuristics (exact, normalized name, date+qty) because
      // payloads may differ between endpoints.
      if (_type == 'keluar' && finalRows.isNotEmpty) {
        try {
          final keluarList = await auth.getBarangKeluar();

          // Helpers and lookup maps
          String _norm(String s) => s
              .toString()
              .toLowerCase()
              .replaceAll(RegExp(r"[^a-z0-9\s]"), '')
              .replaceAll(RegExp(r"\s+"), ' ')
              .trim();

          final Map<String, Map<String, dynamic>> keluarExact = {};
          final Map<String, List<Map<String, dynamic>>> keluarByDateQty = {};

          for (final k in keluarList) {
            final t =
                (k['tanggal_keluar'] ?? k['tanggal'] ?? k['created_at'] ?? '')
                    .toString()
                    .split('T')
                    .first
                    .trim();
            final barangRaw =
                (k['barang'] ?? k['nama_barang'] ?? k['item_name'] ?? '')
                    .toString();
            final barang = barangRaw.toLowerCase().trim();
            final barangNorm = _norm(barangRaw);
            final qty = (k['qty'] ?? k['jumlah'] ?? k['quantity'] ?? '')
                .toString();

            final key = '$t||$barang||$qty';
            final keyNorm = '$t||$barangNorm||$qty';
            keluarExact.putIfAbsent(key, () => k);
            keluarExact.putIfAbsent(keyNorm, () => k);

            final dateQtyKey = '$t||$qty';
            keluarByDateQty.putIfAbsent(dateQtyKey, () => []).add(k);
          }

          for (final row in finalRows) {
            // If operator already present or resolvable directly, keep it
            final opVal = row['operator'];
            final resolvedOp = _resolvePerson(opVal, 'operator');
            if (resolvedOp != null) {
              row['operator'] = resolvedOp;
            }

            if (row['operator'] == null || row['operator'].toString().isEmpty) {
              final t = (row['tanggal_keluar'] ?? row['tanggal'] ?? '')
                  .toString()
                  .split('T')
                  .first
                  .trim();
              final barangRaw =
                  (row['barang'] ?? row['nama_barang'] ?? row['item'] ?? '')
                      .toString();
              final barang = barangRaw.toLowerCase().trim();
              final barangNorm = _norm(barangRaw);
              final qty = (row['qty'] ?? row['jumlah'] ?? '').toString();

              Map<String, dynamic>? matched;
              final key = '$t||$barang||$qty';
              final keyNorm = '$t||$barangNorm||$qty';
              if (keluarExact.containsKey(key)) matched = keluarExact[key];
              if (matched == null && keluarExact.containsKey(keyNorm))
                matched = keluarExact[keyNorm];

              if (matched == null) {
                final dateQtyKey = '$t||$qty';
                final candidates = keluarByDateQty[dateQtyKey] ?? [];
                if (candidates.isNotEmpty) {
                  for (final c in candidates) {
                    final cName =
                        (c['barang'] ??
                                c['nama_barang'] ??
                                c['item_name'] ??
                                '')
                            .toString()
                            .toLowerCase();
                    if (cName.contains(barang) || barang.contains(cName)) {
                      matched = c;
                      break;
                    }
                  }
                  matched ??= candidates.first;
                }
              }

              if (matched != null) {
                dynamic opCandidate =
                    matched['operator'] ??
                    matched['user'] ??
                    matched['user_id'] ??
                    matched['id_user'] ??
                    matched['operator_id'];
                String? resolved;
                if (opCandidate != null) {
                  if (opCandidate is int ||
                      (opCandidate is String &&
                          int.tryParse(opCandidate) != null)) {
                    final found = _userMap['${opCandidate}'];
                    if (found != null)
                      resolved =
                          (found['nama'] ?? found['name'] ?? found['username'])
                              ?.toString();
                    else
                      resolved = 'id_user:${opCandidate}';
                  } else {
                    resolved =
                        _resolvePerson(opCandidate, 'operator') ??
                        opCandidate.toString();
                  }
                }

                if (resolved != null) row['operator'] = resolved;

                // request_from fallback
                if ((row['request_from'] == null ||
                    row['request_from'] == '-' ||
                    row['request_from'].toString().isEmpty)) {
                  final rf =
                      matched['request_from'] ??
                      matched['request_from_name'] ??
                      matched['source'] ??
                      matched['request_from_id'];
                  if (rf != null) {
                    if (rf is int ||
                        (rf is String && int.tryParse(rf.toString()) != null)) {
                      final found = _userMap['${rf}'];
                      if (found != null)
                        row['request_from'] =
                            (found['nama'] ??
                                    found['name'] ??
                                    found['username'])
                                .toString();
                      else
                        row['request_from'] = 'id:${rf}';
                    } else {
                      row['request_from'] = rf.toString();
                    }
                  }
                }
              }
            }
          }
          // additional fallback: if still missing request_from but id_request present,
          // try to resolve from _requestById map we built earlier
          for (final row in finalRows) {
            if (row['request_from'] == null ||
                row['request_from'] == '-' ||
                row['request_from'].toString().isEmpty) {
              final idReq =
                  row['id_request'] ??
                  row['request_id'] ??
                  row['id_request_id'];
              if (idReq != null) {
                final req = _requestById['${idReq}'];
                if (req != null) {
                  final uname =
                      req['user']?['name'] ??
                      req['user']?['nama'] ??
                      req['requested_by'] ??
                      req['peminta'] ??
                      req['request_from'];
                  if (uname != null && uname.toString().isNotEmpty) {
                    row['request_from'] = uname.toString();
                    continue;
                  }
                  // try id inside request
                  final uid = req['id_user'] ?? req['user_id'] ?? req['uid'];
                  if (uid != null) {
                    final found = _userMap['${uid}'];
                    if (found != null) {
                      row['request_from'] =
                          (found['nama'] ?? found['name'] ?? found['username'])
                              .toString();
                    } else {
                      row['request_from'] = 'id:${uid}';
                    }
                  }
                }
              }
            }
          }
        } catch (_) {
          // ignore enrichment failures
        }
      }

      setState(() {
        _rows = finalRows;
      });
    } catch (e) {
      setState(() {
        _error = auth.lastError ?? 'Gagal memuat data laporan: $e';
        _rows = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Client-side PDF export using `pdf` + `printing` packages.
  Future<void> _exportPdf() async {
    try {
      final rows = _filteredRows;
      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk diekspor')),
        );
        return;
      }

      // Determine keys (same filtering as table)
      final rawKeys = rows.first.keys.toList();
      final keys = rawKeys.where((k) {
        final s = k.toString().toLowerCase();
        if (s == 'id_request' || s == 'request_user_id') return false;
        return true;
      }).toList();

      final doc = pw.Document();
      final headers = keys.map((k) => k.toString()).toList();
      final data = rows
          .map((r) => keys.map((k) => (r[k] ?? '-').toString()).toList())
          .toList();

      doc.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(level: 0, child: pw.Text('Laporan: $_type')),
            pw.SizedBox(height: 8),
            pw.Text('Generated: ${DateTime.now().toLocal()}'),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: headers,
              data: data,
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (pdf.PdfPageFormat format) async => doc.save(),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal ekspor PDF: $e')));
    }
  }

  // Client-side Excel (XLSX) export using `excel` and share via `share_plus`.
  Future<void> _exportExcel() async {
    try {
      final rows = _filteredRows;
      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk diekspor')),
        );
        return;
      }

      final rawKeys = rows.first.keys.toList();
      final keys = rawKeys.where((k) {
        final s = k.toString().toLowerCase();
        if (s == 'id_request' || s == 'request_user_id') return false;
        return true;
      }).toList();

      final xls.Excel workbook = xls.Excel.createExcel();
      final sheetName = 'Laporan';
      final xls.Sheet sheet = workbook[sheetName];

      // header row
      sheet.appendRow(keys.map((k) => k.toString()).toList());

      for (final row in rows) {
        final r = keys.map((k) => (row[k] ?? '-').toString()).toList();
        sheet.appendRow(r);
      }

      final bytes = workbook.encode();
      if (bytes == null) throw Exception('Gagal membuat file Excel');

      final fileName =
          'laporan_${_type}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      // Use platform-specific save helper (web / io)
      await dh.saveFileBytes(bytes, fileName);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal ekspor Excel: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredRows {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows.where((r) {
      return r.values
          .map((v) => v?.toString().toLowerCase() ?? '')
          .any((s) => s.contains(q));
    }).toList();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  Widget _buildDateFilter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => _selectDate(context, true),
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(
            _from != null
                ? 'Dari: ${_from!.toLocal().toString().split(' ')[0]}'
                : 'Dari Tanggal',
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _selectDate(context, false),
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(
            _to != null
                ? 'Sampai: ${_to!.toLocal().toString().split(' ')[0]}'
                : 'Sampai Tanggal',
          ),
        ),
        if (_from != null || _to != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                setState(() {
                  _from = null;
                  _to = null;
                });
              },
              tooltip: 'Hapus filter tanggal',
            ),
          ),
      ],
    );
  }

  // Function to get unit value from data
  String _getUnitValue(Map<String, dynamic> row) {
    // Check for direct keys first
    final directKeys = [
      'satuan',
      'unit',
      'uom',
      'unit_name',
      'unit_label',
      'measure',
    ];
    for (var key in directKeys) {
      if (row.containsKey(key) && row[key] != null) {
        return row[key].toString();
      }
    }

    // Check for nested keys (like barang.satuan)
    for (var key in row.keys) {
      final value = row[key];
      if (value is Map<String, dynamic>) {
        // If value is a map, check for unit inside it
        for (var nestedKey in directKeys) {
          if (value.containsKey(nestedKey) && value[nestedKey] != null) {
            return value[nestedKey].toString();
          }
        }
      }
    }

    return '-';
  }

  // Try to resolve a person/user name from various value shapes returned by API.
  // Returns a String name when found, otherwise null.
  String? _resolvePerson(dynamic v, [String? key]) {
    if (v == null) return null;

    final nameKeys = [
      'nama',
      'name',
      'username',
      'user_name',
      'full_name',
      'nama_karyawan',
      'karyawan',
      'peminta',
      'requester',
      'requested_by',
      'created_by',
    ];

    // If it's a Map, check common name keys and nested ids
    if (v is Map) {
      for (final nk in nameKeys) {
        if (v.containsKey(nk) && v[nk] != null) {
          final val = v[nk];
          if (val is String && val.isNotEmpty) return val;
        }
      }

      // check id lookup
      final nid = v['id'] ?? v['user_id'] ?? v['uid'] ?? v['employee_id'];
      if (nid != null) {
        final found = _userMap['${nid}'];
        if (found != null) {
          final uname = found['username'] ?? found['name'] ?? found['nama'];
          if (uname != null && uname.toString().isNotEmpty)
            return uname.toString();
        }
      }

      // Recursively search nested maps/lists
      for (final val in v.values) {
        final res = _resolvePerson(val);
        if (res != null) return res;
      }
      return null;
    }

    // If it's an iterable, try elements
    if (v is Iterable) {
      for (final e in v) {
        final res = _resolvePerson(e);
        if (res != null) return res;
      }
      return null;
    }

    // If it's an int, try lookup
    if (v is int) {
      final found = _userMap['${v}'];
      if (found != null) {
        final uname = found['username'] ?? found['name'] ?? found['nama'];
        if (uname != null && uname.toString().isNotEmpty)
          return uname.toString();
      }
      return null;
    }

    // If it's a string, if key suggests a user field, return it (likely already a name)
    if (v is String) {
      final lk = key?.toLowerCase() ?? '';
      final looksLikeUserKey =
          lk.contains('user') ||
          lk.contains('karyawan') ||
          lk.contains('peminta') ||
          lk.contains('requester') ||
          lk.contains('approver') ||
          lk.contains('pemohon');
      if (looksLikeUserKey) {
        final maybeId = int.tryParse(v);
        if (maybeId != null) {
          final found = _userMap['${maybeId}'];
          if (found != null) {
            final uname = found['username'] ?? found['name'] ?? found['nama'];
            if (uname != null && uname.toString().isNotEmpty)
              return uname.toString();
          }
        }
        // return the string as-is (likely a name)
        if (v.isNotEmpty) return v;
      }
    }

    return null;
  }

  Widget _buildDebugViewer() {
    if (_rows.isEmpty) return const SizedBox.shrink();
    final first = _rows.first;
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Data Structure:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                first.toString(),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keys: ${first.keys.toList()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // Check specifically for unit/satuan
            const SizedBox(height: 4),
            Text(
              'Satuan found: ${_getUnitValue(first)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getUnitValue(first) != '-' ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
      crossFadeState: _showDebug
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRows = _filteredRows;

    return Scaffold(
      drawer: const RoleDrawer(),
      appBar: AppBar(
        title: const Text('Laporan'),
        leading: Builder(
          builder: (ctx) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  DropdownButton<String>(
                                    value: _type,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'stock',
                                        child: Text('Stok Barang'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'request',
                                        child: Text('Request Barang'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'masuk',
                                        child: Text('Barang Masuk'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'keluar',
                                        child: Text('Barang Keluar'),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _type = v ?? 'stock'),
                                  ),

                                  // Filter tanggal
                                  _buildDateFilter(),

                                  SizedBox(
                                    width: 420,
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (v) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'Cari data laporan...',
                                        prefixIcon: const Icon(Icons.search),
                                        filled: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        suffixIcon:
                                            _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {});
                                                },
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _load,
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('Tampilkan'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _exportExcel,
                                    icon: const Icon(Icons.grid_on),
                                    label: const Text('Excel'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _exportPdf,
                                    icon: const Icon(Icons.picture_as_pdf),
                                    label: const Text('PDF'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.teal.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      '${filteredRows.length} baris',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.teal.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Toggle debug view',
                                    icon: Icon(
                                      _showDebug
                                          ? Icons.bug_report
                                          : Icons.bug_report_outlined,
                                      color: _showDebug
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                    onPressed: () => setState(
                                      () => _showDebug = !_showDebug,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Error message
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _error = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Debug viewer
                      if (_showDebug && _rows.isNotEmpty) _buildDebugViewer(),

                      // Loading atau data table
                      Expanded(
                        child: _loading
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.teal.shade700,
                                  ),
                                ),
                              )
                            : filteredRows.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Tidak ada data laporan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Pilih jenis laporan dan klik "Tampilkan"',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : (_type == 'stock'
                                  ? _buildStockTable(filteredRows)
                                  : _buildGenericTable(filteredRows)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenericTable(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return const Center(child: Text('No data'));

    // Filter out internal fields we don't want to show in the table
    final rawKeys = rows.first.keys.toList();
    final keys = rawKeys.where((k) {
      final s = k.toString().toLowerCase();
      if (s == 'id_request' || s == 'request_user_id') return false;
      return true;
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800),
            child: DataTable(
              columnSpacing: 20,
              headingRowColor: MaterialStateProperty.all(Colors.teal.shade50),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.teal.shade900,
                fontSize: 14,
              ),
              dataRowHeight: 52,
              columns: keys.map((k) {
                String title = k.toString();
                title = title.replaceAll('_', ' ');
                title = title[0].toUpperCase() + title.substring(1);
                return DataColumn(
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                );
              }).toList(),
              rows: List.generate(rows.length, (i) {
                final r = rows[i];
                return DataRow(
                  color: MaterialStateProperty.resolveWith<Color?>((states) {
                    if (i.isEven) {
                      return Colors.white;
                    } else {
                      return Colors.grey.shade50;
                    }
                  }),
                  cells: keys.map((key) {
                    final value = r[key];
                    String displayText = '${value ?? '-'}';

                    // Try resolving person/requester name from various shapes
                    // Only try to resolve person names for fields that are
                    // likely to contain user info (or when the value itself
                    // clearly contains name-like keys). This avoids cases
                    // where a non-user field (eg. qty) contains nested
                    // structures and the resolver pulls out names.
                    bool shouldResolve = false;
                    final keyStr = key.toString().toLowerCase();
                    if (keyStr.contains('user') ||
                        keyStr.contains('karyawan') ||
                        keyStr.contains('peminta') ||
                        keyStr.contains('pemohon') ||
                        keyStr.contains('request') ||
                        keyStr.contains('requester') ||
                        keyStr.contains('approver') ||
                        keyStr.contains('operator') ||
                        keyStr.contains('created_by')) {
                      shouldResolve = true;
                    } else if (value is Map) {
                      const nameKeys = [
                        'nama',
                        'name',
                        'username',
                        'user_name',
                        'full_name',
                      ];
                      for (var nk in nameKeys) {
                        if (value.containsKey(nk)) {
                          shouldResolve = true;
                          break;
                        }
                      }
                    } else if (value is Iterable) {
                      final firstElem = value.isNotEmpty ? value.first : null;
                      if (firstElem is Map) {
                        const nameKeys = [
                          'nama',
                          'name',
                          'username',
                          'user_name',
                          'full_name',
                        ];
                        for (var nk in nameKeys) {
                          if (firstElem.containsKey(nk)) {
                            shouldResolve = true;
                            break;
                          }
                        }
                      }
                    }

                    if (shouldResolve) {
                      // Special-case for request/request_from: prefer explicit
                      // `request_from` or `request_user_id` returned by the API
                      if (keyStr.contains('request')) {
                        final rf = r['request_from'];
                        if (rf != null &&
                            rf.toString().trim().isNotEmpty &&
                            rf.toString() != '-') {
                          displayText = rf.toString();
                        } else {
                          final reqUid =
                              r['request_user_id'] ??
                              r['request_user'] ??
                              r['requester_id'] ??
                              r['id_request_user'];
                          if (reqUid != null) {
                            final found = _userMap['${reqUid}'];
                            if (found != null) {
                              displayText =
                                  (found['nama'] ??
                                          found['name'] ??
                                          found['username'])
                                      .toString();
                            } else {
                              displayText = 'id:${reqUid}';
                            }
                          } else {
                            final person = _resolvePerson(value, key);
                            if (person != null) displayText = person;
                          }
                        }
                      } else {
                        final person = _resolvePerson(value, key);
                        if (person != null) {
                          displayText = person;
                        }
                      }
                    }

                    // Format khusus untuk nilai tertentu
                    if (value is num) {
                      if (key.toString().contains('harga') ||
                          key.toString().contains('total') ||
                          key.toString().contains('price')) {
                        displayText = 'Rp ${value.toStringAsFixed(0)}';
                      }
                    }

                    return DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Text(
                          displayText,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            color:
                                key.toString().contains('satuan') ||
                                    key.toString().contains('unit')
                                ? Colors.green.shade700
                                : Colors.grey.shade800,
                            fontWeight:
                                key.toString().contains('satuan') ||
                                    key.toString().contains('unit')
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockTable(List<Map<String, dynamic>> rows) {
    final columns = [
      'Kode Barang',
      'Nama Barang',
      'Kategori',
      'Stok Saat Ini',
      'Satuan',
      'Lokasi',
      'Supplier',
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 900),
            child: DataTable(
              columnSpacing: 24,
              headingRowColor: MaterialStateProperty.all(Colors.teal.shade50),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.teal.shade900,
                fontSize: 14,
              ),
              dataRowHeight: 56,
              columns: columns.map((c) {
                return DataColumn(
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      c,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ),
                );
              }).toList(),
              rows: List.generate(rows.length, (i) {
                final r = rows[i];
                final kode = r['kode_barang'] ?? r['kode'] ?? r['code'] ?? '-';
                final nama =
                    r['nama_barang'] ?? r['nama'] ?? r['nama_barang'] ?? '-';
                final kategori =
                    r['kategori'] ?? r['nama_kategori'] ?? r['category'] ?? '-';
                final stok =
                    r['stok'] ?? r['stok_saat_ini'] ?? r['jumlah'] ?? '0';

                // Get unit value - now using the improved function
                final satuan = _getUnitValue(r);

                final lokasi = r['lokasi'] ?? r['storage_location'] ?? '-';
                final supplier =
                    r['supplier'] ?? r['nama_supplier'] ?? r['vendor'] ?? '-';

                // Highlight stok rendah (jika kurang dari 10)
                bool lowStock = false;
                if (stok is num) {
                  lowStock = stok < 10;
                } else if (stok is String) {
                  final numValue = int.tryParse(stok);
                  lowStock = numValue != null && numValue < 10;
                }

                return DataRow(
                  color: MaterialStateProperty.resolveWith<Color?>((states) {
                    if (lowStock) return Colors.orange.shade50;
                    return i.isEven ? Colors.white : Colors.grey.shade50;
                  }),
                  cells: [
                    DataCell(
                      Text(
                        '$kode',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '$nama',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          color: Colors.grey.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '$kategori',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: lowStock
                              ? Colors.orange.shade100
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: lowStock
                                ? Colors.orange.shade300
                                : Colors.green.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '$stok',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: lowStock
                                ? Colors.orange.shade900
                                : Colors.green.shade800,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          satuan,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '$lokasi',
                        style: TextStyle(
                          color: Colors.brown.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '$supplier',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
