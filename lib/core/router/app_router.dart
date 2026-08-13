import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

// موفر لحفظ المستخدم الحالي الجلوس (Session State)
final currentUserProvider = StateProvider<User?>((ref) => null);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const ImdadEnterpriseDashboard()),
      GoRoute(path: '/stores', builder: (context, state) => const StoresManagementScreen()),
      GoRoute(path: '/employees', builder: (context, state) => const EmployeesManagementScreen()),
      GoRoute(path: '/assets', builder: (context, state) => const AssetsInventoryScreen()),
      GoRoute(path: '/movements', builder: (context, state) => const AssetMovementsScreen()),
      GoRoute(path: '/reports', builder: (context, state) => const EnterpriseReportsScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
});

// --- Login Screen (تسجيل الدخول وصلاحيات الأدوار) ---
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin123');

  void _login() async {
    final db = ref.read(databaseProvider);
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // التحقق أو إنشاء حساب افتراضي للمدير
    var user = await (db.select(db.users)..where((t) => t.username.equals(username))).getSingleOrNull();
    if (user == null && username == 'admin') {
      await db.into(db.users).insert(UsersCompanion.insert(
        username: 'admin',
        fullName: 'مدير النظام العام',
        role: 'admin',
        passwordHash: 'admin123',
      ));
      user = await (db.select(db.users)..where((t) => t.username.equals('admin'))).getSingleOrNull();
    }

    if (user != null && user.passwordHash == password) {
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) context.go('/home');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في اسم المستخدم أو كلمة المرور')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F3E52),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 80, color: Color(0xFF1A5F7A)),
                    const SizedBox(height: 16),
                    const Text('نظام إمداد المؤسسي', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A5F7A))),
                    const SizedBox(height: 8),
                    const Text('الإدارة الحكومية واللوجستية المتكاملة', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'اسم المستخدم', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock)),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
                        child: const Text('تسجيل الدخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Enterprise Dashboard (لوحة التحكم الاحترافية) ---
class ImdadEnterpriseDashboard extends ConsumerWidget {
  const ImdadEnterpriseDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('لوحة التحكم - ${currentUser?.fullName ?? 'مدير النظام'}'),
          backgroundColor: const Color(0xFF1A5F7A),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(currentUserProvider.notifier).state = null;
                context.go('/');
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _card(context, 'المخازن والمواقع', Icons.store, Colors.blue, '/stores'),
              _card(context, 'سجل الموظفين', Icons.badge, Colors.green, '/employees'),
              _card(context, 'العهد والأصول والأسلحة', Icons.security, Colors.orange, '/assets'),
              _card(context, 'حركات الصرف والنقل', Icons.swap_horiz, Colors.indigo, '/movements'),
              _card(context, 'التقارير الشاملة', Icons.analytics, Colors.purple, '/reports'),
              _card(context, 'الإعدادات والنسخ', Icons.settings_applications, Colors.teal, '/settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, String title, IconData icon, Color color, String route) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// --- Placeholder Screens for Modules ---
class StoresManagementScreen extends StatelessWidget {
  const StoresManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('إدارة المخازن الرئيسية والفرعية')), body: const Center(child: Text('وحدة المخازن والمواقع الجغرافية نشطة')));
}

class EmployeesManagementScreen extends StatelessWidget {
  const EmployeesManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('إدارة الموظفين والكوادر')), body: const Center(child: Text('وحدة الموظفين نشطة')));
}

class AssetsInventoryScreen extends StatelessWidget {
  const AssetsInventoryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('إدارة الأسلحة والعهد والمركبات')), body: const Center(child: Text('وحدة الأصول التخصصية نشطة')));
}

class AssetMovementsScreen extends StatelessWidget {
  const AssetMovementsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('سجل حركات الصرف والإرجاع والتسوية')), body: const Center(child: Text('وحدة الحركات اللوجستية نشطة')));
}

class EnterpriseReportsScreen extends StatelessWidget {
  const EnterpriseReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('التقارير الحكومية المؤسسية')), body: const Center(child: Text('وحدة التقارير نشطة')));
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('الإعدادات والنسخ الاحتياطي')), body: const Center(child: Text('وحدة الإعدادات نشطة')));
}
