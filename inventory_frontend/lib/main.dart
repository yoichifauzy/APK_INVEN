import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Use dart:io Platform to detect desktop vs Android emulator
// guarded by kIsWeb so it won't be imported on web builds
import 'dart:io' show Platform;
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboards/admin_dashboard.dart';
import 'screens/dashboards/operator_dashboard.dart';
import 'screens/dashboards/manager_dashboard.dart';
import 'screens/dashboards/staff_dashboard.dart';
import 'screens/staff/create_request.dart';
import 'screens/staff/tracking_page.dart';
import 'screens/staff/riwayat_permintaan_page.dart';
import 'screens/dashboards/supplier_dashboard.dart';
import 'screens/admin/users_page.dart';
import 'screens/admin/suppliers_page.dart';
import 'screens/admin/items_page.dart';
import 'screens/admin/masuk_page.dart';
import 'screens/admin/keluar_page.dart';
import 'screens/admin/reports_page.dart';
import 'screens/admin/requests_page.dart';
import 'screens/account_settings.dart';
import 'screens/operator/process_keluar_page.dart';
import 'screens/manager/requests_all_page.dart';
import 'screens/manager/laporan_page.dart';
import 'screens/manager/items_page.dart';
import 'screens/manager/approve_requests_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // configure baseUrl automatically depending on platform/emulator
  String getDefaultBaseUrl() {
    // Web uses localhost
    if (kIsWeb) return 'http://127.0.0.1:8000';
    // Android emulator needs 10.0.2.2 to reach host machine.
    // Desktop (Windows/Mac/Linux) and iOS simulator can use localhost.
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
      // iOS simulator and desktop use localhost
      return 'http://127.0.0.1:8000';
    } catch (e) {
      // Fallback
      return 'http://127.0.0.1:8000';
    }
  }

  final authService = AuthService(baseUrl: getDefaultBaseUrl());
  await authService.loadFromStorage();

  runApp(
    ChangeNotifierProvider(create: (_) => authService, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventory App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/admin/users': (context) => const UsersPage(),
        '/admin/suppliers': (context) => const SuppliersPage(),
        '/admin/items': (context) => const ItemsPage(),
        '/admin/masuk': (context) => const BarangMasukPage(),
        '/admin/keluar': (context) => const BarangKeluarPage(),
        '/admin/reports': (context) => const ReportsPage(),
        '/admin/requests': (context) => const RequestsPage(),
        '/staff/tracking': (context) => const StaffTrackingPage(),
        '/staff/riwayat': (context) => const RiwayatPermintaanPage(),
        '/manager/requests': (context) => const ManagerRequestsPage(),
        '/manager/laporan': (context) => const ManagerLaporanPage(),
        '/manager/items': (context) => const ManagerItemsPage(),
        '/manager/approve': (context) => const ManagerApprovePage(),
        '/operator/process-keluar': (context) => const ProcessKeluarPage(),
        '/operator/riwayat': (context) => const BarangKeluarPage(),
        // keep a single canonical dashboard route ('/dashboard'). Do not register '/operator' to avoid duplicates.
        '/account': (context) => const AccountSettingsPage(),
        '/manager': (context) => const ManagerDashboard(),
        '/staff': (context) => const StaffDashboard(),
        '/staff/create-request': (context) => const CreateRequestPage(),
        '/supplier': (context) => const SupplierDashboard(),
        '/dashboard': (context) => const _RoleDashboardRouter(),
      },
    );
  }
}

class _RoleDashboardRouter extends StatelessWidget {
  const _RoleDashboardRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final roles = auth.user?.roles ?? [];

    if (roles.contains('admin')) return const AdminDashboard();
    if (roles.contains('operator')) return const OperatorDashboard();
    if (roles.contains('manager')) return const ManagerDashboard();
    if (roles.contains('staff') || roles.contains('karyawan'))
      return const StaffDashboard();
    if (roles.contains('supplier')) return const SupplierDashboard();

    // default: show landing
    return const LandingScreen();
  }
}
