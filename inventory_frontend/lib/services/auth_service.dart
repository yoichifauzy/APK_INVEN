import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final String baseUrl; // e.g. http://10.0.2.2:8000

  String? lastError;

  AppUser? user;
  String? _token;

  AuthService({required this.baseUrl});

  final _rnd = Random();

  String _pick(List<String> options) => options[_rnd.nextInt(options.length)];

  String _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        if (decoded['message'] != null) return decoded['message'].toString();
        if (decoded['error'] != null) return decoded['error'].toString();
        if (decoded['errors'] != null) {
          final e = decoded['errors'];
          if (e is Map) {
            final first = e.values.first;
            if (first is List && first.isNotEmpty)
              return first.first.toString();
            return first.toString();
          }
        }
      }
      return body;
    } catch (_) {
      return body;
    }
  }

  String _formatResponseError(String action, http.Response res) {
    final detail = res.body.isNotEmpty ? _extractMessage(res.body) : '';
    if (res.statusCode == 400) {
      return _pick([
        "$action gagal: permintaan tidak valid. $detail",
        "$action: ada data yang tidak sesuai. $detail",
        "Permintaan gagal (400). Coba periksa input Anda. $detail",
      ]);
    }
    if (res.statusCode == 401) {
      return _pick([
        "Akses ditolak. Silakan login ulang.",
        "Tidak terotorisasi untuk $action. Sesi mungkin sudah kedaluwarsa.",
      ]);
    }
    if (res.statusCode == 403) {
      return _pick([
        "Akses ditolak (403). Anda tidak memiliki izin.",
        "Tidak cukup hak untuk melakukan aksi ini.",
      ]);
    }
    if (res.statusCode == 404) {
      return _pick([
        "$action gagal: sumber tidak ditemukan.",
        "Data tidak ditemukan (404). Coba periksa kembali.",
      ]);
    }
    if (res.statusCode == 422) {
      return _pick([
        "$action gagal: validasi error. ${detail}",
        "Ada kesalahan validasi: ${detail}",
      ]);
    }
    if (res.statusCode >= 500) {
      return _pick([
        "Server error (${res.statusCode}). Coba lagi nanti.",
        "Terjadi kesalahan pada server. Mohon coba beberapa saat lagi.",
      ]);
    }
    // default
    return "$action gagal: ${res.statusCode}${detail.isNotEmpty ? ' - $detail' : ''}";
  }

  String _formatNetworkError(Object e) {
    return _pick([
      'Terjadi masalah jaringan. Periksa koneksi Anda.',
      'Tidak dapat terhubung ke server. ${e.toString()}',
      'Network error: ${e.toString()}',
    ]);
  }

  bool get isAuthenticated => _token != null && user != null;

  Future<void> loadFromStorage() async {
    _token = await _storage.read(key: 'api_token');
    if (_token != null) {
      await fetchUser();
    }
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  Future<bool> login(String email, String password) async {
    try {
      final url = _apiUrl('/login');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        // expected response: { token: '...', user: { ... } }
        _token =
            body['token'] ?? body['access_token'] ?? body['data']?['token'];
        if (_token == null &&
            body['data'] != null &&
            body['data']['token'] != null) {
          _token = body['data']['token'];
        }

        // try to extract user
        Map<String, dynamic>? userJson;
        if (body['user'] != null)
          userJson = Map<String, dynamic>.from(body['user']);
        if (userJson == null &&
            body['data'] != null &&
            body['data']['user'] != null)
          userJson = Map<String, dynamic>.from(body['data']['user']);

        if (_token != null) {
          await _storage.write(key: 'api_token', value: _token);
        }

        if (userJson != null) {
          user = AppUser.fromJson(userJson);
        } else {
          // fetch user from /api/user
          await fetchUser();
        }

        notifyListeners();
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Login', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<void> fetchUser() async {
    if (_token == null) return;
    try {
      final url = _apiUrl('/user');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        // body might contain user data at root or inside data
        Map<String, dynamic> userJson = {};
        if (body['user'] != null)
          userJson = Map<String, dynamic>.from(body['user']);
        else if (body['data'] != null && body['data']['user'] != null)
          userJson = Map<String, dynamic>.from(body['data']['user']);
        else
          userJson = Map<String, dynamic>.from(body);

        user = AppUser.fromJson(userJson);
        notifyListeners();
        lastError = null;
      } else {
        // token invalid — clear
        await logout();
      }
    } catch (e) {
      lastError = _formatNetworkError(e);
    }
  }

  Uri _apiUrl(String path) {
    // path is like '/login' or 'login'
    final trimmedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$trimmedBase/api$p');
  }

  Future<void> logout() async {
    _token = null;
    user = null;
    await _storage.delete(key: 'api_token');
    notifyListeners();
  }

  // --- User management API (admin) ---
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final url = _apiUrl('/users');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // expect array at root or inside data
        List items = [];
        if (body is List)
          items = body;
        else if (body['data'] is List)
          items = body['data'];
        else if (body['users'] is List)
          items = body['users'];
        return List<Map<String, dynamic>>.from(
          items.map((e) => Map<String, dynamic>.from(e)),
        );
      }
      lastError = _formatResponseError('Get users', res);
      return [];
    } catch (e) {
      lastError = _formatNetworkError(e);
      return [];
    }
  }

  Future<bool> createUser(Map<String, dynamic> payload) async {
    try {
      // backend has /api/register which creates a user; try that first
      final urlRegister = _apiUrl('/register');
      final res = await http.post(
        urlRegister,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Create user', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> payload) async {
    try {
      final url = _apiUrl('/users/$id');
      final res = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Update user', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final url = _apiUrl('/users/$id');
      final res = await http.delete(url, headers: _headers);
      if (res.statusCode == 200 || res.statusCode == 204) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Delete user', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  // --- Supplier management ---
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    try {
      final url = _apiUrl('/suppliers');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List items = [];
        if (body is List)
          items = body;
        else if (body['data'] is List)
          items = body['data'];
        else if (body['suppliers'] is List)
          items = body['suppliers'];
        return List<Map<String, dynamic>>.from(
          items.map((e) => Map<String, dynamic>.from(e)),
        );
      }
      lastError = _formatResponseError('Get suppliers', res);
      return [];
    } catch (e) {
      lastError = _formatNetworkError(e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final url = _apiUrl('/categories');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List items = [];
        if (body is List)
          items = body;
        else if (body['data'] is List)
          items = body['data'];
        else if (body['categories'] is List)
          items = body['categories'];
        return List<Map<String, dynamic>>.from(
          items.map((e) => Map<String, dynamic>.from(e)),
        );
      }
      lastError = _formatResponseError('Get categories', res);
      return [];
    } catch (e) {
      lastError = _formatNetworkError(e);
      return [];
    }
  }

  Future<bool> createSupplier(Map<String, dynamic> payload) async {
    try {
      final url = _apiUrl('/suppliers');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Create supplier', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> updateSupplier(int id, Map<String, dynamic> payload) async {
    try {
      final url = _apiUrl('/suppliers/$id');
      final res = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Update supplier', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> deleteSupplier(int id) async {
    try {
      final url = _apiUrl('/suppliers/$id');
      final res = await http.delete(url, headers: _headers);
      if (res.statusCode == 200 || res.statusCode == 204) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Delete supplier', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  // --- Items (Barang) management ---
  Future<List<Map<String, dynamic>>> getItems() async {
    try {
      final url = _apiUrl('/items');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List items = [];
        if (body is List)
          items = body;
        else if (body['data'] is List)
          items = body['data'];
        else if (body['items'] is List)
          items = body['items'];
        return List<Map<String, dynamic>>.from(
          items.map((e) => Map<String, dynamic>.from(e)),
        );
      }
      lastError = _formatResponseError('Get items', res);
      return [];
    } catch (e) {
      lastError = _formatNetworkError(e);
      return [];
    }
  }

  Future<bool> createItem(Map<String, dynamic> payload) async {
    try {
      final url = _apiUrl('/items');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Create item', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> updateItem(int id, Map<String, dynamic> payload) async {
    try {
      final url = _apiUrl('/items/$id');
      final res = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Update item', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> deleteItem(int id) async {
    try {
      final url = _apiUrl('/items/$id');
      final res = await http.delete(url, headers: _headers);
      if (res.statusCode == 200 || res.statusCode == 204) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Delete item', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  // --- Barang Masuk (incoming items) ---
  Future<List<Map<String, dynamic>>> getBarangMasuk() async {
    try {
      final url = _apiUrl('/barang-masuk');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List items = [];
        if (body is List)
          items = body;
        else if (body['data'] is List)
          items = body['data'];
        else if (body['barang_masuk'] is List)
          items = body['barang_masuk'];
        return List<Map<String, dynamic>>.from(
          items.map((e) => Map<String, dynamic>.from(e)),
        );
      }
      lastError = _formatResponseError('Get barang masuk', res);
      return [];
    } catch (e) {
      lastError = _formatNetworkError(e);
      return [];
    }
  }

  // --- Request Barang (permintaan keluar) ---
  Future<List<Map<String, dynamic>>> getRequestBarang() async {
    try {
      final url = _apiUrl('/request-barang');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List items = [];
        if (body is List)
          items = body;
        else if (body['data'] is List)
          items = body['data'];
        else if (body['requests'] is List)
          items = body['requests'];
        else if (body['request_barang'] is List)
          items = body['request_barang'];
        return List<Map<String, dynamic>>.from(
          items.map((e) => Map<String, dynamic>.from(e)),
        );
      }
      lastError = _formatResponseError('Get requests', res);
      return [];
    } catch (e) {
      lastError = _formatNetworkError(e);
      return [];
    }
  }

  Future<bool> updateRequestStatus(
    int id,
    String status, {
    String? reason,
  }) async {
    try {
      final url = _apiUrl('/request-barang/$id/status');
      final body = {'status': status};
      if (reason != null) body['alasan_penolakan'] = reason;
      final res = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Update request status', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> createBarangMasuk(Map<String, dynamic> payload) async {
    try {
      final url = _apiUrl('/barang-masuk');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Create barang masuk', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  // --- Request Barang (create) ---
  Future<bool> createRequest(Map<String, dynamic> payload) async {
    try {
      final url = _apiUrl('/request-barang');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Create request', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> deleteBarangMasuk(int id) async {
    try {
      final url = _apiUrl('/barang-masuk/$id');
      final res = await http.delete(url, headers: _headers);
      if (res.statusCode == 200 || res.statusCode == 204) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Delete barang masuk', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> approveBarangMasuk(int id) async {
    try {
      final url = _apiUrl('/barang-masuk/$id/approve');
      final res = await http.patch(url, headers: _headers);
      if (res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Approve barang masuk', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> rejectBarangMasuk(int id, {String? reason}) async {
    try {
      final url = _apiUrl('/barang-masuk/$id/reject');
      final res = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({'reason': reason}),
      );
      if (res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Reject barang masuk', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> updateBarangMasuk(int id, Map<String, dynamic> payload) async {
    try {
      final url = _apiUrl('/barang-masuk/$id');
      final res = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Update barang masuk', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  // --- Barang Keluar (outgoing items) ---
  Future<List<Map<String, dynamic>>> getBarangKeluar() async {
    try {
      final url = _apiUrl('/barang-keluar');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List items = [];
        if (body is List)
          items = body;
        else if (body['data'] is List)
          items = body['data'];
        else if (body['barang_keluar'] is List)
          items = body['barang_keluar'];
        return List<Map<String, dynamic>>.from(
          items.map((e) => Map<String, dynamic>.from(e)),
        );
      }
      lastError = _formatResponseError('Get barang keluar', res);
      return [];
    } catch (e) {
      lastError = _formatNetworkError(e);
      return [];
    }
  }

  Future<bool> createBarangKeluar(Map<String, dynamic> payload) async {
    try {
      final url = _apiUrl('/barang-keluar');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Create barang keluar', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> updateBarangKeluar(int id, Map<String, dynamic> payload) async {
    try {
      final url = _apiUrl('/barang-keluar/$id');
      final res = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Update barang keluar', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> deleteBarangKeluar(int id) async {
    try {
      final url = _apiUrl('/barang-keluar/$id');
      final res = await http.delete(url, headers: _headers);
      if (res.statusCode == 200 || res.statusCode == 204) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Delete barang keluar', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  Future<bool> processRequestToKeluar(
    int requestId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final url = _apiUrl('/barang-keluar/process-request/$requestId');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _formatResponseError('Process request', res);
      return false;
    } catch (e) {
      lastError = _formatNetworkError(e);
      return false;
    }
  }

  // --- Reports ---
  Future<List<Map<String, dynamic>>> getReport(
    String type, {
    String format = 'json',
    String? from,
    String? to,
    int? category,
    int? supplier,
  }) async {
    try {
      final base = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final params = <String, String>{'type': type, 'format': format};
      if (from != null) params['from'] = from;
      if (to != null) params['to'] = to;
      if (category != null) params['category'] = '$category';
      if (supplier != null) params['supplier'] = '$supplier';
      final uri = Uri.parse(
        base + '/api/reports',
      ).replace(queryParameters: params);
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List) {
          return List<Map<String, dynamic>>.from(
            body.map((e) => Map<String, dynamic>.from(e)),
          );
        }
        return [];
      }
      lastError = _formatResponseError('Get report', res);
      return [];
    } catch (e) {
      lastError = _formatNetworkError(e);
      return [];
    }
  }

  String getReportUrl(
    String type, {
    String format = 'csv',
    String? from,
    String? to,
    int? category,
    int? supplier,
  }) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final params = <String, String>{'type': type, 'format': format};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    if (category != null) params['category'] = '$category';
    if (supplier != null) params['supplier'] = '$supplier';
    final uri = Uri.parse(
      base + '/api/reports',
    ).replace(queryParameters: params);
    return uri.toString();
  }
}
