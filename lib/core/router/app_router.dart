import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/home', builder: (context, state) => const ImdadDashboardScreen()),
      GoRoute(path: '/stores', builder: (context, state) => const StoresScreen()),
      GoRoute(path: '/employees', builder: (context, state) => const EmployeesScreen()),
      GoRoute(path: '/search_asset', builder: (context, state) => const AssetSearchScreen()),
      GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
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
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 100, color: Color(0xFF1A5F7A)),
              SizedBox(height: 24),
              Text('إمداد', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1A5F7A))),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Color(0xFF1A5F7A)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Dashboard Screen ---
class ImdadDashboardScreen extends StatelessWidget {
  const ImdadDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نظام إمداد اللوجستي'),
          centerTitle: true,
          backgroundColor: const Color(0xFF1A5F7A),
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(context, 'المخازن والعهد', Icons.account_balance, Colors.blue, '/stores'),
              _buildStatCard(context, 'سجل الموظفين', Icons.badge, Colors.green, '/employees'),
              _buildStatCard(context, 'بحث برقم القطعة', Icons.manage_search, Colors.orange, '/search_asset'),
              _buildStatCard(context, 'التقارير', Icons.insights, Colors.purple, '/reports'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, IconData icon, Color color, String route) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push(route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// --- Asset Search Screen (البحث برقم القطعة) ---
class AssetSearchScreen extends ConsumerStatefulWidget {
  const AssetSearchScreen({super.key});
  @override
  ConsumerState<AssetSearchScreen> createState() => _AssetSearchScreenState();
}

class _AssetSearchScreenState extends ConsumerState<AssetSearchScreen> {
  final _searchController = TextEditingController();
  Asset? _foundAsset;
  Employee? _holder;
  Store? _store;
  bool _searched = false;

  void _performSearch() async {
    final db = ref.read(databaseProvider);
    final serial = _searchController.text.trim();
    if (serial.isEmpty) return;

    final asset = await (db.select(db.assets)..where((t) => t.serialNumber.equals(serial))).getSingleOrNull();
    
    Employee? holder;
    Store? store;
    
    if (asset != null) {
      if (asset.employeeId != null) {
        holder = await (db.select(db.employees)..where((t) => t.id.equals(asset.employeeId!))).getSingleOrNull();
      }
      if (asset.storeId != null) {
        store = await (db.select(db.stores)..where((t) => t.id.equals(asset.storeId!))).getSingleOrNull();
      }
    }

    setState(() {
      _foundAsset = asset;
      _holder = holder;
      _store = store;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('بحث برقم القطعة'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'أدخل رقم القطعة (السلاح/العهدة)',
                  suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _performSearch),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
              const SizedBox(height: 24),
              if (_searched) 
                _foundAsset == null 
                  ? const Text('عذراً، لم يتم العثور على أي قطعة بهذا الرقم.')
                  : Card(
                      color: Colors.blueGrey[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('تفاصيل القطعة: ${_foundAsset!.type}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const Divider(),
                            Text('رقم التسلسل: ${_foundAsset!.serialNumber}'),
                            const SizedBox(height: 8),
                            if (_foundAsset!.status == 'assigned' && _holder != null) ...[
                              const Text('الحالة: مصروفة (عُهدة)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              Text('المستلم: ${_holder!.name}'),
                              Text('تاريخ الصرف: ${_foundAsset!.assignedAt?.toString().split(' ')[0] ?? 'غير محدد'}'),
                            ] else ...[
                              const Text('الحالة: موجودة في المخزن', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              Text('الموقع: ${_store?.name ?? 'غير محدد'}'),
                            ],
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Employees Screen (مع ميزة عرض العهد) ---
class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('سجل الموظفين والعهد'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: StreamBuilder<List<Employee>>(
          stream: db.select(db.employees).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final list = snapshot.data!;
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final emp = list[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(emp.name),
                  subtitle: const Text('اضغط لعرض العُهد المستلمة'),
                  onTap: () => _showAssets(context, db, emp),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addEmployee(context, db),
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }

  void _showAssets(BuildContext context, AppDatabase db, Employee emp) async {
    final assets = await (db.select(db.assets)..where((t) => t.employeeId.equals(emp.id))).get();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('عُهد الموظف: ${emp.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              if (assets.isEmpty) const Text('لا توجد عُهد مسجلة لهذا الموظف.'),
              ...assets.map((a) => ListTile(
                title: Text(a.type),
                subtitle: Text('رقم: ${a.serialNumber}'),
                leading: const Icon(Icons.security),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _addEmployee(BuildContext context, AppDatabase db) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة موظف جديد'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'اسم الموظف')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(onPressed: () {
            if (controller.text.isNotEmpty) {
              db.into(db.employees).insert(EmployeesCompanion.insert(name: controller.text));
              Navigator.pop(context);
            }
          }, child: const Text('إضافة')),
        ],
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
        appBar: AppBar(title: const Text('المخازن والعهد'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: StreamBuilder<List<Store>>(
          stream: db.select(db.stores).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final store = snapshot.data![index];
                return ListTile(
                  title: Text(store.name),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _addAssetToStore(context, db, store),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(onPressed: () => _addStore(context, db), child: const Icon(Icons.add_business)),
      ),
    );
  }

  void _addStore(BuildContext context, AppDatabase db) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مخزن جديد'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'اسم المخزن')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(onPressed: () {
            if (controller.text.isNotEmpty) {
              db.into(db.stores).insert(StoresCompanion.insert(name: controller.text));
              Navigator.pop(context);
            }
          }, child: const Text('إضافة')),
        ],
      ),
    );
  }

  void _addAssetToStore(BuildContext context, AppDatabase db, Store store) {
    final serialController = TextEditingController();
    final typeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة عُهدة لمخزن ${store.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: typeController, decoration: const InputDecoration(hintText: 'نوع العُهدة (مثلاً: كلاشينكوف)')),
            TextField(controller: serialController, decoration: const InputDecoration(hintText: 'رقم القطعة')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(onPressed: () {
            if (serialController.text.isNotEmpty) {
              db.into(db.assets).insert(AssetsCompanion.insert(
                serialNumber: serialController.text,
                type: typeController.text,
                storeId: drift.Value(store.id),
                status: const drift.Value('in_store'),
              ));
              Navigator.pop(context);
            }
          }, child: const Text('إضافة')),
        ],
      ),
    );
  }
}

// --- Reports & Settings ---
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('التقارير')), body: const Center(child: Text('جاري تحليل البيانات...')));
  }
}
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('الإعدادات')), body: const Center(child: Text('الإعدادات')));
  }
}
