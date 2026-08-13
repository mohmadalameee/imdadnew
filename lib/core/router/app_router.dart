import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/database/app_database.dart';

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
        builder: (context, state) => const StoresScreen(),
      ),
      GoRoute(
        path: '/employees',
        builder: (context, state) => const EmployeesScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

// --- Splash Screen ---
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
              Text('نظام إدارة اللوجستيات الذكي', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Dashboard Screen ---
class ImdadDashboardScreen extends ConsumerWidget {
  const ImdadDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const Text('مرحباً بك، المدير', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
          onTap: (index) {
            if (index == 1) context.push('/settings');
          },
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
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Stores Screen ---
class StoresScreen extends ConsumerWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة المخازن'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: StreamBuilder<List<Store>>(
          stream: db.select(db.stores).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final stores = snapshot.data!;
            if (stores.isEmpty) return const Center(child: Text('لا توجد مخازن مسجلة حالياً.'));
            return ListView.builder(
              itemCount: stores.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.store),
                title: Text(stores[index].name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => db.delete(db.stores).delete(stores[index]),
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addDialog(context, db, 'مخزن'),
          backgroundColor: const Color(0xFF1A5F7A),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

// --- Employees Screen ---
class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة الموظفين'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: StreamBuilder<List<Employee>>(
          stream: db.select(db.employees).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final employees = snapshot.data!;
            if (employees.isEmpty) return const Center(child: Text('لا يوجد موظفون مسجلون حالياً.'));
            return ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.person),
                title: Text(employees[index].name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => db.delete(db.employees).delete(employees[index]),
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addDialog(context, db, 'موظف'),
          backgroundColor: const Color(0xFF1A5F7A),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

// --- Orders Screen (Static for now) ---
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة الطلبات'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: const Center(child: Text('نظام الطلبات قيد المزامنة مع المخازن.')),
      ),
    );
  }
}

// --- Reports Screen ---
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التقارير والإحصائيات'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
              Card(
                child: ListTile(
                  leading: Icon(Icons.trending_up, color: Colors.green),
                  title: Text('نسبة نمو المخزون'),
                  subtitle: Text('15% زيادة عن الشهر الماضي'),
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(Icons.warning_amber, color: Colors.orange),
                  title: Text('تنبيهات العجز'),
                  subtitle: Text('لا توجد تنبيهات حالية'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Settings Screen ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: ListView(
          children: const [
            ListTile(leading: Icon(Icons.language), title: Text('اللغة'), subtitle: Text('العربية')),
            ListTile(leading: Icon(Icons.notifications), title: Text('التنبيهات'), trailing: Icon(Icons.chevron_right)),
            ListTile(leading: Icon(Icons.info_outline), title: Text('عن التطبيق'), subtitle: Text('نسخة 1.0.0')),
          ],
        ),
      ),
    );
  }
}

// --- Helper Dialog ---
void _addDialog(BuildContext context, AppDatabase db, String type) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('إضافة $type جديد'),
      content: TextField(controller: controller, decoration: InputDecoration(hintText: 'اسم ال$type')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              if (type == 'مخزن') {
                db.into(db.stores).insert(StoresCompanion.insert(name: controller.text));
              } else {
                db.into(db.employees).insert(EmployeesCompanion.insert(name: controller.text));
              }
              Navigator.pop(context);
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    ),
  );
}
