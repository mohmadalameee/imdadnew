import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const ImdadDashboardScreen(),
      ),
      GoRoute(
        path: '/stores',
        builder: (context, state) => const PlaceholderScreen(title: 'إدارة المخازن', icon: Icons.store),
      ),
      GoRoute(
        path: '/employees',
        builder: (context, state) => const PlaceholderScreen(title: 'إدارة الموظفين', icon: Icons.people),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const PlaceholderScreen(title: 'إدارة الطلبات', icon: Icons.shopping_cart),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const PlaceholderScreen(title: 'التقارير والإحصائيات', icon: Icons.bar_chart),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const PlaceholderScreen(title: 'الإعدادات', icon: Icons.settings),
      ),
    ],
  );
});

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 100, color: Color(0xFF1A5F7A)),
              SizedBox(height: 24),
              Text(
                'إمداد',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1A5F7A)),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Color(0xFF1A5F7A)),
              SizedBox(height: 24),
              Text(
                'نظام إدارة اللوجستيات الذكي',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImdadDashboardScreen extends StatefulWidget {
  const ImdadDashboardScreen({super.key});

  @override
  State<ImdadDashboardScreen> createState() => _ImdadDashboardScreenState();
}

class _ImdadDashboardScreenState extends State<ImdadDashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      context.push('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم إمداد'),
          centerTitle: true,
          backgroundColor: const Color(0xFF1A5F7A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مرحباً بك، المدير',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('إليك نظرة عامة على العمليات اليومية'),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard(context, 'المخازن', Icons.store, Colors.blue, '/stores'),
                    _buildStatCard(context, 'الموظفين', Icons.people, Colors.green, '/employees'),
                    _buildStatCard(context, 'الطلبات', Icons.shopping_cart, Colors.orange, '/orders'),
                    _buildStatCard(context, 'التقارير', Icons.bar_chart, Colors.purple, '/reports'),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF1A5F7A),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, IconData icon, Color color, String route) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: const Color(0xFF1A5F7A),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'شاشة $title',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'هذه الشاشة قيد التطوير حالياً وسيتم ربطها بقاعدة البيانات قريباً.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('العودة للرئيسية'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5F7A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
