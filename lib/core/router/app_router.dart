import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import '../../shared/database/app_database.dart';

// موفر لحفظ المستخدم الحالي الجلوس (Session State)
final currentUserProvider = StateProvider<User?>((ref) => null);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const ImdadEnterpriseDashboard()),
      GoRoute(path: '/stores', builder: (context, state) => const StoresManagementScreen()),
      GoRoute(
        path: '/store-details',
        builder: (context, state) {
          final store = state.extra as Store;
          return StoreDetailsScreen(store: store);
        },
      ),
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

    var user = await (db.select(db.users)..where((t) => t.username.equals(username))).getSingleOrNull();
    if (user == null && username == 'admin') {
      await db.into(db.users).insert(UsersCompanion.insert(
        username: username,
        fullName: 'مدير النظام العام',
        role: 'admin',
        passwordHash: password,
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
              _card(context, 'الأصناف والعهد', Icons.security, Colors.orange, '/assets'),
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

// 1. إدارة المخازن
class StoresManagementScreen extends ConsumerWidget {
  const StoresManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة المخازن والمواقع'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: StreamBuilder<List<Store>>(
          stream: db.select(db.stores).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final stores = snapshot.data!;
            if (stores.isEmpty) {
              return const Center(child: Text('لا توجد مخازن مسجلة. أضف مخزناً أولاً.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF1A5F7A), child: Icon(Icons.store, color: Colors.white)),
                    title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('الموقع: ${store.location}'),
                    onTap: () => context.push('/store-details', extra: store),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_box, color: Colors.blue),
                          tooltip: 'إضافة صنف',
                          onPressed: () => _showAddAssetToStoreDialog(context, db, store),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await (db.delete(db.stores)..where((t) => t.id.equals(store.id))).go();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF1A5F7A),
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showAddStoreDialog(context, db),
        ),
      ),
    );
  }

  void _showAddStoreDialog(BuildContext context, AppDatabase db) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة مخزن جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المخزن')),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'الموقع الجغرافي')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await db.into(db.stores).insert(StoresCompanion.insert(
                    name: nameController.text.trim(),
                    location: locationController.text.trim(),
                    type: const Value('main'),
                  ));
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAssetToStoreDialog(BuildContext context, AppDatabase db, Store store) {
    final serialController = TextEditingController();
    final nameController = TextEditingController();
    String category = 'weapon';

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('إدخال صنف في مخزن: ${store.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: serialController, decoration: const InputDecoration(labelText: 'رقم القطعة / الباركود')),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصنف')),
                DropdownButtonFormField<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(value: 'weapon', child: Text('سلاح / ذخيرة')),
                    DropdownMenuItem(value: 'vehicle', child: Text('مركبة')),
                    DropdownMenuItem(value: 'comms', child: Text('جهاز اتصال')),
                  ],
                  onChanged: (val) => category = val ?? 'weapon',
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (serialController.text.isNotEmpty && nameController.text.isNotEmpty) {
                  await db.into(db.assets).insert(AssetsCompanion.insert(
                    serialNumber: serialController.text.trim(),
                    name: nameController.text.trim(),
                    category: category,
                    storeId: Value(store.id),
                    status: const Value('in_store'),
                  ));
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('إدخال'),
            ),
          ],
        ),
      ),
    );
  }
}

// 1.1 تفاصيل المخزن
class StoreDetailsScreen extends ConsumerWidget {
  final Store store;
  const StoreDetailsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('محتويات مخزن: ${store.name}'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: StreamBuilder<List<Asset>>(
          stream: (db.select(db.assets)..where((t) => t.storeId.equals(store.id))).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final assets = snapshot.data!;
            if (assets.isEmpty) {
              return const Center(child: Text('هذا المخزن فارغ حالياً.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assets.length,
              itemBuilder: (context, index) {
                final asset = assets[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.security, color: Color(0xFF1A5F7A)),
                    title: Text(asset.name),
                    subtitle: Text('رقم القطعة: ${asset.serialNumber} | الحالة: ${asset.status}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// 2. سجل الموظفين
class EmployeesManagementScreen extends ConsumerWidget {
  const EmployeesManagementScreen({super.key});

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
            final employees = snapshot.data!;
            if (employees.isEmpty) {
              return const Center(child: Text('لا توجد سجلات موظفين.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final emp = employees[index];
                return Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.badge, color: Colors.green),
                    title: Text('${emp.rank} / ${emp.name}'),
                    subtitle: Text('الرقم العسكري: ${emp.militaryId} | القسم: ${emp.department}'),
                    children: [
                      FutureBuilder<List<Asset>>(
                        future: (db.select(db.assets)..where((t) => t.employeeId.equals(emp.id))).get(),
                        builder: (context, assetSnapshot) {
                          if (!assetSnapshot.hasData) {
                            return const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator());
                          }
                          final empAssets = assetSnapshot.data!;
                          if (empAssets.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text('لا توجد عهد مصروفة لهذا الموظف حالياً.', style: TextStyle(color: Colors.grey)),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: empAssets.length,
                            itemBuilder: (context, aIndex) {
                              final asset = empAssets[aIndex];
                              return ListTile(
                                leading: const Icon(Icons.security, size: 20, color: Colors.orange),
                                title: Text(asset.name),
                                subtitle: Text('رقم القطعة: ${asset.serialNumber} | الحالة: مصروفة'),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF1A5F7A),
          child: const Icon(Icons.person_add, color: Colors.white),
          onPressed: () => _showAddEmployeeDialog(context, db),
        ),
      ),
    );
  }

  void _showAddEmployeeDialog(BuildContext context, AppDatabase db) {
    final nameController = TextEditingController();
    final militaryIdController = TextEditingController();
    final rankController = TextEditingController(text: 'ملازم أول');
    final deptController = TextEditingController(text: 'الإدارة العامة');

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة موظف جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الموظف')),
              TextField(controller: militaryIdController, decoration: const InputDecoration(labelText: 'الرقم العسكري')),
              TextField(controller: rankController, decoration: const InputDecoration(labelText: 'الرتبة')),
              TextField(controller: deptController, decoration: const InputDecoration(labelText: 'القسم')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && militaryIdController.text.isNotEmpty) {
                  await db.into(db.employees).insert(EmployeesCompanion.insert(
                    name: nameController.text.trim(),
                    militaryId: militaryIdController.text.trim(),
                    rank: rankController.text.trim(),
                    department: deptController.text.trim(),
                  ));
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. الأصناف والعهد (مع ميزة البحث المتقدم وفحص حالة القطعة)
class AssetsInventoryScreen extends ConsumerStatefulWidget {
  const AssetsInventoryScreen({super.key});

  @override
  ConsumerState<AssetsInventoryScreen> createState() => _AssetsInventoryScreenState();
}

class _AssetsInventoryScreenState extends ConsumerState<AssetsInventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchType = 'serial'; // 'serial' or 'employee'

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الأصناف والعهد والبحث المتقدم'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('بحث برقم القطعة'),
                          value: 'serial',
                          groupValue: _searchType,
                          onChanged: (val) => setState(() => _searchType = val ?? 'serial'),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('بحث باسم الموظف'),
                          value: 'employee',
                          groupValue: _searchType,
                          onChanged: (val) => setState(() => _searchType = val ?? 'employee'),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: _searchType == 'serial' ? 'أدخل رقم القطعة / الباركود' : 'أدخل اسم الموظف',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _searchType == 'serial'
                  ? _buildSerialSearchList(db, _searchQuery)
                  : _buildEmployeeSearchList(db, _searchQuery),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF1A5F7A),
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showAddAssetDialog(context, db),
        ),
      ),
    );
  }

  Widget _buildSerialSearchList(AppDatabase db, String query) {
    return StreamBuilder<List<Asset>>(
      stream: db.select(db.assets).watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var assets = snapshot.data!;
        if (query.isNotEmpty) {
          assets = assets.where((a) => a.serialNumber.contains(query)).toList();
        }
        if (assets.isEmpty) {
          return const Center(child: Text('لا توجد قطع مطابقة للبحث برقم القطعة.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: assets.length,
          itemBuilder: (context, index) {
            final asset = assets[index];
            final isAssigned = asset.status == 'assigned';
            return FutureBuilder<Employee?>(
              future: asset.employeeId != null
                  ? (db.select(db.employees)..where((t) => t.id.equals(asset.employeeId!))).getSingleOrNull()
                  : Future.value(null),
              builder: (context, empSnapshot) {
                final employee = empSnapshot.data;
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(isAssigned ? Icons.person : Icons.store, color: isAssigned ? Colors.orange : Colors.green),
                            const SizedBox(width: 8),
                            Text('${asset.name} (${asset.category})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Divider(),
                        Text('رقم القطعة: ${asset.serialNumber}'),
                        Text('المواصفات: ${asset.specs ?? 'لا توجد مواصفات'}'),
                        const SizedBox(height: 8),
                        if (isAssigned && employee != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.orange.withValues(alpha: 0.1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('حالة القطعة: مصروفة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                Text('المستلم: ${employee.rank} / ${employee.name}'),
                                Text('الرقم العسكري: ${employee.militaryId} | القسم: ${employee.department}'),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.green.withValues(alpha: 0.1),
                            child: const Text('حالة القطعة: متوفرة في المخازن', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
                              icon: Icon(isAssigned ? Icons.keyboard_return : Icons.send),
                              label: Text(isAssigned ? 'إرجاع للمخزن' : 'صرف لموظف'),
                              onPressed: () => _showMovementDialog(context, db, asset),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmployeeSearchList(AppDatabase db, String query) {
    return StreamBuilder<List<Employee>>(
      stream: db.select(db.employees).watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var employees = snapshot.data!;
        if (query.isNotEmpty) {
          employees = employees.where((e) => e.name.contains(query) || e.militaryId.contains(query)).toList();
        }
        if (employees.isEmpty) {
          return const Center(child: Text('لا يوجد موظفون مطابظون للبحث.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final emp = employees[index];
            return FutureBuilder<List<Asset>>(
              future: (db.select(db.assets)..where((t) => t.employeeId.equals(emp.id))).get(),
              builder: (context, assetSnapshot) {
                final assets = assetSnapshot.data ?? [];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.badge, color: Color(0xFF1A5F7A)),
                            const SizedBox(width: 8),
                            Text('${emp.rank} / ${emp.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Divider(),
                        Text('الرقم العسكري: ${emp.militaryId} | القسم: ${emp.department}'),
                        const SizedBox(height: 8),
                        Text('العهد المستلمة (${assets.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        if (assets.isEmpty)
                          const Text('لا توجد عهد مصروفة لهذا الموظف حالياً.', style: TextStyle(color: Colors.grey))
                        else
                          ...assets.map((a) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text('• ${a.name} (رقم القطعة: ${a.serialNumber}) - التصنيف: ${a.category}'),
                              )),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddAssetDialog(BuildContext context, AppDatabase db) async {
    final stores = await db.select(db.stores).get();
    if (stores.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف مخزناً أولاً.')));
      }
      return;
    }

    final serialController = TextEditingController();
    final nameController = TextEditingController();
    int? selectedStoreId = stores.first.id;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة صنف جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: serialController, decoration: const InputDecoration(labelText: 'رقم القطعة / الباركود')),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصنف')),
              DropdownButtonFormField<int>(
                value: selectedStoreId,
                items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (v) => selectedStoreId = v,
                decoration: const InputDecoration(labelText: 'المخزن'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (serialController.text.isNotEmpty && selectedStoreId != null) {
                  await db.into(db.assets).insert(AssetsCompanion.insert(
                    serialNumber: serialController.text.trim(),
                    name: nameController.text.trim(),
                    category: 'weapon',
                    storeId: Value(selectedStoreId),
                    status: const Value('in_store'),
                  ));
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMovementDialog(BuildContext context, AppDatabase db, Asset asset) async {
    final employees = await db.select(db.employees).get();
    if (employees.isEmpty && asset.status != 'assigned') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف موظفين أولاً.')));
      }
      return;
    }

    int? selectedEmpId = employees.isNotEmpty ? employees.first.id : null;
    final isAssigned = asset.status == 'assigned';

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(isAssigned ? 'إرجاع العهدة للمخزن' : 'صرف العهدة لموظف'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isAssigned)
                DropdownButtonFormField<int>(
                  value: selectedEmpId,
                  items: employees.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.rank} / ${e.name}'))).toList(),
                  onChanged: (v) => selectedEmpId = v,
                  decoration: const InputDecoration(labelText: 'الموظف المستلم'),
                ),
              const Text('هل تريد تأكيد العملية؟'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (isAssigned) {
                  await (db.update(db.assets)..where((t) => t.id.equals(asset.id))).write(
                    const AssetsCompanion(status: Value('in_store'), employeeId: Value(null)),
                  );
                } else {
                  if (selectedEmpId != null) {
                    await (db.update(db.assets)..where((t) => t.id.equals(asset.id))).write(
                      AssetsCompanion(status: const Value('assigned'), employeeId: Value(selectedEmpId)),
                    );
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. حركات الصرف والنقل
class AssetMovementsScreen extends ConsumerWidget {
  const AssetMovementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('حركات الصرف والنقل'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: StreamBuilder<List<AssetMovement>>(
          stream: db.select(db.assetMovements).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final movements = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final mov = movements[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.swap_horiz, color: Colors.indigo),
                    title: Text('نوع الحركة: ${mov.movementType}'),
                    subtitle: Text('التاريخ: ${mov.timestamp}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// 5. التقارير الشاملة
class EnterpriseReportsScreen extends StatelessWidget {
  const EnterpriseReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التقارير الشاملة'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: const Center(child: Text('وحدة التقارير نشطة وجاهزة للتصدير.')),
      ),
    );
  }
}

// 6. الإعدادات والنسخ
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات والنسخ'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('المستخدم'),
              subtitle: Text(currentUser?.fullName ?? 'مدير'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.blue),
              title: const Text('نسخة احتياطية'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
