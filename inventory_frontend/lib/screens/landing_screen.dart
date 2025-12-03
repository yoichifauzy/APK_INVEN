import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _blurAnim;
  late Animation<double> _scaleAnim;
  int _currentFeatureIndex = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.verified_user_outlined,
      'title': 'Akses Berbasis Role',
      'description': 'Kontrol akses multi-level dengan izin yang terperinci',
      'color': Color(0xFF26A69A),
      'gradient': [Color(0xFF26A69A), Color(0xFF4DB6AC)],
    },
    {
      'icon': Icons.analytics_outlined,
      'title': 'Analisis Real-Time',
      'description': 'Monitoring stok langsung dan prediksi cerdas',
      'color': Color(0xFF0097A7),
      'gradient': [Color(0xFF0097A7), Color(0xFF26C6DA)],
    },
    {
      'icon': Icons.autorenew_outlined,
      'title': 'Workflow Otomatis',
      'description': 'Proses permintaan hingga pengiriman yang terstruktur',
      'color': Color(0xFF00796B),
      'gradient': [Color(0xFF00796B), Color(0xFF26A69A)],
    },
    {
      'icon': Icons.device_hub_outlined,
      'title': 'Integrasi Siap Pakai',
      'description': 'Integrasi mulus dengan sistem yang sudah ada',
      'color': Color(0xFF00695C),
      'gradient': [Color(0xFF00695C), Color(0xFF0097A7)],
    },
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _blurAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      _controller.forward();
    });

    // Auto scroll features
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentFeatureIndex = (_currentFeatureIndex + 1) % _features.length;
          _pageController.animateToPage(
            _currentFeatureIndex,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        });
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: SweepGradient(
              center: Alignment.center,
              colors: [
                Colors.teal.shade900.withOpacity(0.8),
                Colors.teal.shade700.withOpacity(0.9),
                Colors.teal.shade800.withOpacity(0.8),
                Colors.teal.shade900.withOpacity(0.7),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
              transform: GradientRotation(
                _controller.value * 2 * 3.1416,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 768;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(child: _buildAnimatedBackground()),

          // Animated background particles
          ...List.generate(
            20,
            (index) => Positioned(
              left: (index * 47) % size.width,
              top: (index * 37) % size.height,
              child: Container(
                width: 2 + (index % 3).toDouble(),
                height: 2 + (index % 3).toDouble(),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1 + (index % 5) * 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
            child: SizedBox(
              height: size.height,
              child: Stack(
                children: [
                  // Left decorative element
                  Positioned(
                    left: -size.width * 0.2,
                    top: size.height * 0.3,
                    child: Container(
                      width: size.width * 0.4,
                      height: size.width * 0.4,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.teal.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Right decorative element
                  Positioned(
                    right: -size.width * 0.15,
                    bottom: size.height * 0.2,
                    child: Container(
                      width: size.width * 0.3,
                      height: size.width * 0.3,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.tealAccent.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Logo
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "SISTEM",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Text(
                                      "INVENTARIS",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Login button
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _blurAnim.value * 0.5),
                                  child: Opacity(
                                    opacity: _fadeAnim.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () =>
                                      Navigator.pushNamed(context, "/login"),
                                  child: _buildGlassCard(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.login_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 7),
                                        Text(
                                          "MASUK SISTEM",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Hero section
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnim.value,
                              child: Opacity(
                                opacity: _fadeAnim.value,
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Main title
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Platform Manajemen\n",
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 40 : 60,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "Inventaris Cerdas",
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 40 : 60,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white.withOpacity(0.9),
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Subtitle
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 20 : 150,
                                ),
                                child: Text(
                                  "Transformasikan operasi inventaris Anda dengan analisis berbasis AI, pelacakan real-time, dan workflow otomatis untuk efisiensi maksimal.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    color: Colors.white.withOpacity(0.8),
                                    height: 1.6,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Main CTA button
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () =>
                                      Navigator.pushNamed(context, "/login"),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.white.withOpacity(0.9),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.tealAccent
                                              .withOpacity(0.3),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                          offset: const Offset(0, 10),
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "MULAI SEKARANG",
                                          style: TextStyle(
                                            color: Colors.teal,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.teal,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Features carousel
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _features.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentFeatureIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final feature = _features[index];
                              final isActive = index == _currentFeatureIndex;

                              return AnimatedScale(
                                scale: isActive ? 1 : 0.9,
                                duration: const Duration(milliseconds: 300),
                                child: AnimatedOpacity(
                                  opacity: isActive ? 1 : 0.6,
                                  duration: const Duration(milliseconds: 300),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: _buildGlassCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: feature['gradient'],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              feature['icon'],
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            feature['title'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            feature['description'],
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Feature indicators
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 40),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _features.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: index == _currentFeatureIndex ? 32 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: index == _currentFeatureIndex
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}