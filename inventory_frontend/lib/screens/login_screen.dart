import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _email = '';
  String _password = '';
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  // Focus node untuk handle Enter key
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // Simple animation seperti landing screen
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation
    Future.delayed(const Duration(milliseconds: 200), () {
      _controller.forward();
    });

    // ✅ PERUBAHAN: Setup focus nodes
    _setupFocusNodes();
  }

  // ✅ PERUBAHAN BARU: METHOD UNTUK HANDLE FOCUS & ENTER KEY
  void _setupFocusNodes() {
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _formKey.currentState?.validate();
      }
    });

    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        _formKey.currentState?.validate();
      }
    });
  }

  // ✅ PERUBAHAN BARU: METHOD UNTUK HANDLE ENTER KEY
  void _handleFieldSubmit(String field) {
    switch (field) {
      case 'email':
        _passwordFocusNode.requestFocus();
        break;
      case 'password':
        _submitForm();
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Show a simple forgot-password dialog WITHOUT validation
  void _showForgotPasswordDialog() {
    final _fpController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Lupa Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan email Anda. Tidak ada validasi diterapkan.'),
            const SizedBox(height: 8),
            TextField(
              controller: _fpController,
              decoration: const InputDecoration(labelText: 'Email (opsional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              // No validation: just show a confirmation message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Jika email terdaftar, instruksi reset akan dikirim.',
                  ),
                  backgroundColor: Colors.green.shade600,
                ),
              );
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // BACKGROUND GRADIENT (optional - sama seperti landing)
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade600, Colors.teal.shade800],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // BACK BUTTON
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    width: size.width < 500 ? size.width * 0.9 : 400,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // SIMPLE ICON (seperti landing screen)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline,
                              size: 40,
                              color: Colors.teal.shade700,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // TITLE
                          const Text(
                            "Login Sistem",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),
                          Text(
                            "Masukkan email dan password Anda",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 25),

                          // ✅ PERUBAHAN: EMAIL FIELD DENGAN ENTER KEY
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                            onSaved: (v) => _email = v?.trim() ?? '',
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Email harus diisi'
                                : (v.contains('@')
                                      ? null
                                      : 'Format email tidak valid'),
                            onFieldSubmitted: (value) =>
                                _handleFieldSubmit('email'),
                          ),

                          const SizedBox(height: 16),

                          // ✅ PERUBAHAN: PASSWORD FIELD DENGAN ENTER KEY
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                            textInputAction: TextInputAction.go,
                            onSaved: (v) => _password = v ?? '',
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password harus diisi';
                              }
                              if (v.length < 3) {
                                return 'Password minimal 3 karakter';
                              }
                              return null;
                            },
                            onFieldSubmitted: (value) =>
                                _handleFieldSubmit('password'),
                          ),

                          const SizedBox(height: 8),

                          // FORGOT PASSWORD
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showForgotPasswordDialog(),
                              child: Text(
                                'Lupa Password?',
                                style: TextStyle(color: Colors.teal.shade700),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ✅ PERUBAHAN: ERROR MESSAGE YANG LEBIH INFORMATIF
                          if (_error != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Login Gagal',
                                          style: TextStyle(
                                            color: Colors.red.shade800,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _error!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),

                          // LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: _loading
                                ? ElevatedButton(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade700,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text('Logging in...'),
                                      ],
                                    ),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade700,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    onPressed: _submitForm,
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 20),

                          // ✅ PERUBAHAN: TAMBAH INFO TENTANG ENTER KEY
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.keyboard_rounded,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tekan Enter untuk login',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 15),

                          // CONTACT INFO
                          Text(
                            'Butuh bantuan?',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'admin@example.com',
                            style: TextStyle(
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    // Hilangkan keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final ok = await auth.login(_email, _password);

      setState(() => _loading = false);

      if (ok) {
        final roles = auth.user?.roles ?? [];
        String route = '/dashboard';

        if (roles.contains('admin')) {
          route = '/admin';
        } else if (roles.contains('manager')) {
          route = '/manager';
        } else if (roles.contains('staff') || roles.contains('karyawan')) {
          route = '/staff';
        } else if (roles.contains('supplier')) {
          route = '/supplier';
        }

        Navigator.pushReplacementNamed(context, route);
      } else {
        // ✅ PERUBAHAN: PESAN ERROR YANG LEBIH SPESIFIK
        String errorMessage = 'Login gagal';

        if (auth.lastError != null) {
          final error = auth.lastError!.toLowerCase();

          if (error.contains('network') || error.contains('connection')) {
            errorMessage =
                'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
          } else if (error.contains('timeout')) {
            errorMessage = 'Koneksi timeout. Silakan coba lagi.';
          } else if (error.contains('invalid') ||
              error.contains('credential')) {
            errorMessage =
                'Email atau password salah. Silakan periksa kembali.';
          } else if (error.contains('server')) {
            errorMessage =
                'Server sedang mengalami gangguan. Silakan coba lagi nanti.';
          } else if (error.contains('email') || error.contains('user')) {
            errorMessage = 'Email tidak ditemukan.';
          } else if (error.contains('password')) {
            errorMessage = 'Password salah.';
          } else {
            errorMessage = auth.lastError!;
          }
        } else {
          errorMessage = 'Email atau password salah. Silakan coba lagi.';
        }

        setState(() {
          _error = errorMessage;
        });

        // Clear password field on error
        _passwordController.clear();
        _passwordFocusNode.requestFocus();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Terjadi kesalahan tak terduga. Silakan coba lagi.';
      });
    }
  }
}
