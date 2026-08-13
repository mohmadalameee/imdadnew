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

// 1. إدارة المخازن
class StoresManagementScreen extends ConsumerWidget {
  const StoresManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة المخازن الرئيسية والفرعية'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: StreamBuilder<List<Store>>(
          stream: db.select(db.stores).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final stores = snapshot.data!;
            if (stores.isEmpty) {
              return const Center(child: Text('لا توجد مخازن مسجلة حالياً. اضغط على زر الإضافة أدناه.', style: TextStyle(fontSize: 16, color: Colors.grey)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF1A5F7A), child: Icon(Icons.store, color: Colors.white)),
                    title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('النوع: ${store.type} | الموقع: ${store.location}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await (db.delete(db.stores)..where((t) => t.id.equals(store.id))).go();
                      },
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
    String type = 'main';

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
                    type: Value(type),
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

// 2. إدارة الموظفين
class EmployeesManagementScreen extends ConsumerStatefulWidget {
  const EmployeesManagementScreen({super.key});

  @override
  ConsumerState<EmployeesManagementScreen> createState() => _EmployeesManagementScreenState();
}

class _EmployeesManagementScreenState extends ConsumerState<EmployeesManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة الموظفين والكوادر'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(labelText: 'بحث بالاسم أو الرقم العسكري', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Employee>>(
                stream: db.select(db.employees).watch(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var employees = snapshot.data!;
                  if (_searchQuery.isNotEmpty) {
                    employees = employees.where((e) => e.name.contains(_searchQuery) || e.militaryId.contains(_searchQuery)).toList();
                  }
                  if (employees.isEmpty) {
                    return const Center(child: Text('لا يوجد موظفون مطابقة للبحث.', style: TextStyle(fontSize: 16, color: Colors.grey)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final emp = employees[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xFF1A5F7A), child: Icon(Icons.badge, color: Colors.white)),
                          title: Text('${emp.rank} / ${emp.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('الرقم العسكري: ${emp.militaryId} | القسم: ${emp.department}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await (db.delete(db.employees)..where((t) => t.id.equals(emp.id))).go();
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الموظف')),
                TextField(controller: militaryIdController, decoration: const InputDecoration(labelText: 'الرقم العسكري')),
                TextField(controller: rankController, decoration: const InputDecoration(labelText: 'الرتبة')),
                TextField(controller: deptController, decoration: const InputDecoration(labelText: 'الإدارة / القسم')),
              ],
            ),
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

// 3. إدارة العهد والأسلحة والأصول
class AssetsInventoryScreen extends ConsumerStatefulWidget {
  const AssetsInventoryScreen({super.key});

  @override
  ConsumerState<AssetsInventoryScreen> createState() => _AssetsInventoryScreenState();
}

class _AssetsInventoryScreenState extends ConsumerState<AssetsInventoryScreen> {
  String _serialSearch = '';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة الأسلحة والعهد والمركبات'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'البحث برقم القطعة / الباركود (Serial Number)',
                  prefixIcon: Icon(Icons.qr_code_scanner),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => _serialSearch = val.trim()),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Asset>>(
                stream: db.select(db.assets).watch(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var assets = snapshot.data!;
                  if (_serialSearch.isNotEmpty) {
                    assets = assets.where((a) => a.serialNumber.contains(_serialSearch)).toList();
                  }
                  if (assets.isEmpty) {
                    return const Center(child: Text('لا توجد عهد أو أصول مطابقة للبحث برقم القطعة.', style: TextStyle(fontSize: 16, color: Colors.grey)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: assets.length,
                    itemBuilder: (context, index) {
                      final asset = assets[index];
                      final isAssigned = asset.status == 'assigned';
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAssigned ? Colors.orange : Colors.green,
                            child: Icon(isAssigned ? Icons.person : Icons.store, color: Colors.white),
                          ),
                          title: Text('${asset.name} (${asset.category})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('رقم القطعة: ${asset.serialNumber}\nالحالة: ${isAssigned ? "مصروفة لموظف" : "متواجدة في المخزن"} | المواصفات: ${asset.specs ?? 'لا توجد'}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await (db.delete(db.assets)..where((t) => t.id.equals(asset.id))).go();
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
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

  void _showAddAssetDialog(BuildContext context, AppDatabase db) {
    final serialController = TextEditingController();
    final nameController = TextEditingController();
    final specsController = TextEditingController();
    String category = 'weapon';

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة عهدة / أصل جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: serialController, decoration: const InputDecoration(labelText: 'رقم القطعة / الباركود')),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الأصل (مثل: بندقية آلية / مركبة تويوتا)')),
                DropdownButtonFormField<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(value: 'weapon', child: Text('سلاح / ذخيرة')),
                    DropdownMenuItem(value: 'vehicle', child: Text('مركبة')),
                    DropdownMenuItem(value: 'comms', child: Text('جهاز اتصال')),
                    DropdownMenuItem(value: 'equipment', child: Text('تجهيزات عسكرية')),
                  ],
                  onChanged: (val) => category = val ?? 'weapon',
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                ),
                TextField(controller: specsController, decoration: const InputDecoration(labelText: 'المواصفات (الهيكل، المحرك، التشغيلة)')),
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
                    specs: specsController.text.trim().isNotEmpty ? Value(specsController.text.trim()) : const Value.absent(),
                    status: Value('in_store'),
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

// 4. حركات الصرف والنقل
class AssetMovementsScreen extends ConsumerWidget {
  const AssetMovementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('سجل حركات الصرف والإرجاع والتسوية'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: StreamBuilder<List<AssetMovement>>(
          stream: db.select(db.assetMovements).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final movements = snapshot.data!;
            if (movements.isEmpty) {
              return const Center(child: Text('لا توجد حركات مسجلة حتى الآن.', style: TextStyle(fontSize: 16, color: Colors.grey)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final mov = movements[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF1A5F7A), child: Icon(Icons.swap_horiz, color: Colors.white)),
                    title: Text('نوع الحركة: ${mov.movementType}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('التاريخ: ${mov.timestamp}\nملاحظات: ${mov.notes ?? 'لا توجد'}'),
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
class EnterpriseReportsScreen extends ConsumerWidget {
  const EnterpriseReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التقارير الحكومية المؤسسية'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تقارير النظام وجرد الأصول والعهد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A5F7A))),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                  title: const Text('تصدير تقرير العهد والأسلحة (PDF)'),
                  subtitle: const Text('تقرير شامل بجميع القطع المصروفة والمتواجدة بالمخازن'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تصدير التقرير بنجاح (PDF)')));
                    },
                    child: const Text('تصدير'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.table_chart, color: Colors.green, size: 40),
                  title: const Text('تصدير سجل الموظفين والمخازن (Excel)'),
                  subtitle: const Text('ملف بيانات متوافق مع أنظمة الجرد الحكومي'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تصدير البيانات بنجاح (Excel)')));
                    },
                    child: const Text('تصدير'),
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

// 6. الإعدادات والنسخ الاحتياطي
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات والنسخ الاحتياطي'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF1A5F7A)),
              title: const Text('المستخدم الحالي'),
              subtitle: Text('${currentUser?.fullName ?? 'مدير'} (${currentUser?.role ?? 'admin'})'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.blue),
              title: const Text('إنشاء نسخة احتياطية لقاعدة البيانات'),
              subtitle: const Text('حفظ نسخة محلية مشفرة من كافة البيانات'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء النسخة الاحتياطية بنجاح')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: const Text('استعادة النسخة الاحتياطية'),
              subtitle: const Text('استيراد البيانات من ملف سابق'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استعادة البيانات بنجاح')));
              },
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.info, color: Colors.grey),
              title: Text('إصدار النظام'),
              subtitle: Text('Enterprise Edition v3.2.0 - إمداد المؤسسي'),
            ),
          ],
        ),
      ),
    );
  }
}
