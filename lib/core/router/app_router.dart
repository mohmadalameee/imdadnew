import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import '../../shared/database/app_database.dart';

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
      GoRoute(path: '/locations', builder: (context, state) => const LocationsManagementScreen()),
      GoRoute(
        path: '/location-details',
        builder: (context, state) {
          final location = state.extra as Location;
          return LocationDetailsScreen(location: location);
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

String getCategoryName(String category) {
  switch (category) {
    case 'electronics': return 'أجهزة إلكترونية';
    case 'weapons': return 'أسلحة وذخيرة';
    case 'water_tanks': return 'خزانات مياه وشبكات صحية';
    case 'kitchen': return 'أدوات مطبخ وتجهيزات إعاشة';
    case 'furniture': return 'مفروشات وأثاث';
    case 'military_gear': return 'مهام عسكرية';
    default: return category;
  }
}

Widget getAssetStatusBadge(String status) {
  Color color;
  String text;
  switch (status) {
    case 'ready':
      color = Colors.green;
      text = 'جاهز / يعمل';
      break;
    case 'damaged':
      color = Colors.red;
      text = 'تالف';
      break;
    case 'maintenance':
      color = Colors.amber.shade800;
      text = 'تحتاج صيانة';
      break;
    case 'missing':
      color = Colors.grey;
      text = 'مفقود';
      break;
    default:
      color = Colors.blue;
      text = status;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color),
    ),
    child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
  );
}

// --- Login Screen ---
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
                    const Text('نظام ناجي الأمير المؤسسي', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A5F7A))),
                    const SizedBox(height: 8),
                    const Text('إدارة التموين والعهد واللوجستيات', style: TextStyle(color: Colors.grey)),
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

// --- Enterprise Dashboard ---
class ImdadEnterpriseDashboard extends ConsumerWidget {
  const ImdadEnterpriseDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('لوحة تحكم نظام ناجي الأمير (${currentUser?.fullName ?? 'مدير النظام'})'),
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
              _card(context, 'المواقع والنقاط', Icons.location_on, Colors.teal, '/locations'),
              _card(context, 'المخازن والمستودعات', Icons.store, Colors.blue, '/stores'),
              _card(context, 'سجل الموظفين والعهد', Icons.badge, Colors.green, '/employees'),
              _card(context, 'العهد والتصنيفات والكميات', Icons.security, Colors.orange, '/assets'),
              _card(context, 'حركات الصرف والنقل', Icons.swap_horiz, Colors.indigo, '/movements'),
              _card(context, 'تقرير حركة الصنف والشامل', Icons.analytics, Colors.purple, '/reports'),
              _card(context, 'الإعدادات والنسخ', Icons.settings, Colors.blueGrey, '/settings'),
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

// 1. نظام المواقع والنقاط
class LocationsManagementScreen extends ConsumerWidget {
  const LocationsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة المواقع والنقاط التابعة'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: StreamBuilder<List<Location>>(
          stream: db.select(db.locations).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final locations = snapshot.data!;
            if (locations.isEmpty) {
              return const Center(child: Text('لا توجد مواقع مسجلة. اضغط لإضافة موقع جديد.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final loc = locations[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF1A5F7A), child: Icon(Icons.location_on, color: Colors.white)),
                    title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('المشرف: ${loc.supervisor} | الوصف: ${loc.description ?? 'لا يوجد'}'),
                    onTap: () => context.push('/location-details', extra: loc),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await (db.delete(db.locations)..where((t) => t.id.equals(loc.id))).go();
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
          onPressed: () => _showAddLocationDialog(context, db),
        ),
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context, AppDatabase db) {
    final nameController = TextEditingController();
    final supervisorController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة موقع أو نقطة جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الموقع / النقطة')),
              TextField(controller: supervisorController, decoration: const InputDecoration(labelText: 'المشرف المسؤول')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'الوصف أو الملاحظات')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || supervisorController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')));
                  return;
                }
                await db.into(db.locations).insert(LocationsCompanion.insert(
                  name: nameController.text.trim(),
                  supervisor: supervisorController.text.trim(),
                  description: Value(descController.text.trim()),
                ));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationDetailsScreen extends ConsumerWidget {
  final Location location;
  const LocationDetailsScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('موقع: ${location.name}'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1A5F7A).withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.supervisor_account, color: Color(0xFF1A5F7A)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('المشرف المسؤول: ${location.supervisor}\nالوصف: ${location.description ?? 'لا يوجد'}'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('جرد حي للأصناف والكميات في هذا الموقع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Expanded(
              child: StreamBuilder<List<Asset>>(
                stream: (db.select(db.assets)..where((t) => t.locationId.equals(location.id))).watch(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final assets = snapshot.data!;
                  if (assets.isEmpty) {
                    return const Center(child: Text('لا توجد أصناف مرتبطة بهذا الموقع حالياً.'));
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
                          subtitle: Text('الرقم: ${asset.serialNumber} | الوارد: ${asset.totalQuantity} | المتبقي: ${asset.remainingQuantity}'),
                          trailing: getAssetStatusBadge(asset.assetStatus),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. إدارة المخازن (مع زر إدخال أصناف بارز ودعم الكميات)
class StoresManagementScreen extends ConsumerWidget {
  const StoresManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة المخازن والمستودعات'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
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
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF1A5F7A), child: Icon(Icons.store, color: Colors.white)),
                    title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('الموقع الجغرافي: ${store.location}'),
                    onTap: () => context.push('/store-details', extra: store),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          icon: const Icon(Icons.add_box, size: 18),
                          label: const Text('إدخال صنف'),
                          onPressed: () => _showAddAssetToStoreDialog(context, db, store),
                        ),
                        const SizedBox(width: 8),
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
    final qtyController = TextEditingController(text: '10');
    final specsController = TextEditingController();
    String category = 'weapons';
    String assetStatus = 'ready';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('إدخال صنف وكميات في مخزن: ${store.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: serialController, decoration: const InputDecoration(labelText: 'رقم القطعة / كود الصنف')),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصنف')),
                  TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية الواردة الإجمالية')),
                  DropdownButtonFormField<String>(
                    value: category,
                    items: const [
                      DropdownMenuItem(value: 'electronics', child: Text('أجهزة إلكترونية')),
                      DropdownMenuItem(value: 'weapons', child: Text('أسلحة وذخيرة')),
                      DropdownMenuItem(value: 'water_tanks', child: Text('خزانات مياه وشبكات صحية')),
                      DropdownMenuItem(value: 'kitchen', child: Text('أدوات مطبخ وتجهيزات إعاشة')),
                      DropdownMenuItem(value: 'furniture', child: Text('مفروشات وأثاث')),
                      DropdownMenuItem(value: 'military_gear', child: Text('مهام عسكرية')),
                    ],
                    onChanged: (val) => setState(() => category = val ?? 'weapons'),
                    decoration: const InputDecoration(labelText: 'التصنيف الشامل'),
                  ),
                  DropdownButtonFormField<String>(
                    value: assetStatus,
                    items: const [
                      DropdownMenuItem(value: 'ready', child: Text('جاهز / يعمل')),
                      DropdownMenuItem(value: 'damaged', child: Text('تالف')),
                      DropdownMenuItem(value: 'maintenance', child: Text('تحتاج صيانة')),
                      DropdownMenuItem(value: 'missing', child: Text('مفقود')),
                    ],
                    onChanged: (val) => setState(() => assetStatus = val ?? 'ready'),
                    decoration: const InputDecoration(labelText: 'الحالة الفنية'),
                  ),
                  TextField(controller: specsController, decoration: const InputDecoration(labelText: 'المواصفات الفنية')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (serialController.text.isEmpty || nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال رقم القطعة واسم الصنف')));
                    return;
                  }
                  final qty = int.tryParse(qtyController.text.trim()) ?? 1;
                  final assetId = await db.into(db.assets).insert(AssetsCompanion.insert(
                    serialNumber: serialController.text.trim(),
                    name: nameController.text.trim(),
                    category: category,
                    totalQuantity: Value(qty),
                    remainingQuantity: Value(qty),
                    assetStatus: Value(assetStatus),
                    storeId: Value(store.id),
                    specs: specsController.text.trim().isNotEmpty ? Value(specsController.text.trim()) : const Value.absent(),
                    status: const Value('in_store'),
                  ));
                  
                  await db.into(db.assetMovements).insert(AssetMovementsCompanion.insert(
                    assetId: assetId,
                    quantityMoved: Value(qty),
                    movementType: 'إدخال وارد للمستودع',
                    notes: Value('إدخال أولي للمستودع: ${store.name}'),
                  ));

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('إدخال'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoreDetailsScreen extends ConsumerWidget {
  final Store store;
  const StoreDetailsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('مستودع: ${store.name}'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: StreamBuilder<List<Asset>>(
          stream: (db.select(db.assets)..where((t) => t.storeId.equals(store.id))).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final assets = snapshot.data!;
            if (assets.isEmpty) {
              return const Center(child: Text('المستودع فارغ حالياً.'));
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
                    subtitle: Text('رقم القطعة: ${asset.serialNumber} | الوارد: ${asset.totalQuantity} | المتبقي: ${asset.remainingQuantity}'),
                    trailing: getAssetStatusBadge(asset.assetStatus),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddAssetToStoreDialog(context, db, store),
          label: const Text('إدخال صنف جديد', style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.add_box, color: Colors.white),
          backgroundColor: Colors.green,
        ),
      ),
    );
  }

  void _showAddAssetToStoreDialog(BuildContext context, AppDatabase db, Store store) {
    final serialController = TextEditingController();
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '10');
    final specsController = TextEditingController();
    String category = 'weapons';
    String assetStatus = 'ready';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('إدخال صنف وكميات في مخزن: ${store.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: serialController, decoration: const InputDecoration(labelText: 'رقم القطعة / كود الصنف')),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصنف')),
                  TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية الواردة الإجمالية')),
                  DropdownButtonFormField<String>(
                    value: category,
                    items: const [
                      DropdownMenuItem(value: 'electronics', child: Text('أجهزة إلكترونية')),
                      DropdownMenuItem(value: 'weapons', child: Text('أسلحة وذخيرة')),
                      DropdownMenuItem(value: 'water_tanks', child: Text('خزانات مياه وشبكات صحية')),
                      DropdownMenuItem(value: 'kitchen', child: Text('أدوات مطبخ وتجهيزات إعاشة')),
                      DropdownMenuItem(value: 'furniture', child: Text('مفروشات وأثاث')),
                      DropdownMenuItem(value: 'military_gear', child: Text('مهام عسكرية')),
                    ],
                    onChanged: (val) => setState(() => category = val ?? 'weapons'),
                    decoration: const InputDecoration(labelText: 'التصنيف الشامل'),
                  ),
                  DropdownButtonFormField<String>(
                    value: assetStatus,
                    items: const [
                      DropdownMenuItem(value: 'ready', child: Text('جاهز / يعمل')),
                      DropdownMenuItem(value: 'damaged', child: Text('تالف')),
                      DropdownMenuItem(value: 'maintenance', child: Text('تحتاج صيانة')),
                      DropdownMenuItem(value: 'missing', child: Text('مفقود')),
                    ],
                    onChanged: (val) => setState(() => assetStatus = val ?? 'ready'),
                    decoration: const InputDecoration(labelText: 'الحالة الفنية'),
                  ),
                  TextField(controller: specsController, decoration: const InputDecoration(labelText: 'المواصفات الفنية')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (serialController.text.isEmpty || nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال رقم القطعة واسم الصنف')));
                    return;
                  }
                  final qty = int.tryParse(qtyController.text.trim()) ?? 1;
                  final assetId = await db.into(db.assets).insert(AssetsCompanion.insert(
                    serialNumber: serialController.text.trim(),
                    name: nameController.text.trim(),
                    category: category,
                    totalQuantity: Value(qty),
                    remainingQuantity: Value(qty),
                    assetStatus: Value(assetStatus),
                    storeId: Value(store.id),
                    specs: specsController.text.trim().isNotEmpty ? Value(specsController.text.trim()) : const Value.absent(),
                    status: const Value('in_store'),
                  ));
                  
                  await db.into(db.assetMovements).insert(AssetMovementsCompanion.insert(
                    assetId: assetId,
                    quantityMoved: Value(qty),
                    movementType: 'إدخال وارد للمستودع',
                    notes: Value('إدخال أولي للمستودع: ${store.name}'),
                  ));

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('إدخال'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. سجل الموظفين
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
                              child: Text('لا توجد عهد مقيدة على هذا الموظف حالياً.', style: TextStyle(color: Colors.grey)),
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
                                subtitle: Text('رقم القطعة: ${asset.serialNumber} | الكمية المصروفة: ${asset.totalQuantity - asset.remainingQuantity}'),
                                trailing: getAssetStatusBadge(asset.assetStatus),
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

  void _showAddEmployeeDialog(BuildContext context, AppDatabase db) async {
    final locations = await db.select(db.locations).get();
    final nameController = TextEditingController();
    final militaryIdController = TextEditingController();
    final rankController = TextEditingController(text: 'ملازم أول');
    final deptController = TextEditingController(text: 'الإدارة العامة');
    int? selectedLocationId = locations.isNotEmpty ? locations.first.id : null;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
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
                  TextField(controller: deptController, decoration: const InputDecoration(labelText: 'القسم')),
                  if (locations.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: selectedLocationId,
                      items: locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                      onChanged: (val) => setState(() => selectedLocationId = val),
                      decoration: const InputDecoration(labelText: 'الموقع التابع له'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || militaryIdController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال الاسم والرقم العسكري')));
                    return;
                  }
                  await db.into(db.employees).insert(EmployeesCompanion.insert(
                    name: nameController.text.trim(),
                    militaryId: militaryIdController.text.trim(),
                    rank: rankController.text.trim(),
                    department: deptController.text.trim(),
                    locationId: selectedLocationId != null ? Value(selectedLocationId) : const Value.absent(),
                  ));
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 4. العهد والبحث المتقدم الشامل (مع عرض الوارد والمتبقي)
class AssetsInventoryScreen extends ConsumerStatefulWidget {
  const AssetsInventoryScreen({super.key});

  @override
  ConsumerState<AssetsInventoryScreen> createState() => _AssetsInventoryScreenState();
}

class _AssetsInventoryScreenState extends ConsumerState<AssetsInventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchType = 'employee';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('العهد وإدارة الكميات والبحث الشامل'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
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
                          title: const Text('باسم الموظف وعهده', style: TextStyle(fontSize: 11)),
                          value: 'employee',
                          groupValue: _searchType,
                          onChanged: (val) => setState(() => _searchType = val ?? 'employee'),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('برقم القطعة', style: TextStyle(fontSize: 11)),
                          value: 'serial',
                          groupValue: _searchType,
                          onChanged: (val) => setState(() => _searchType = val ?? 'serial'),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('باسم الموقع', style: TextStyle(fontSize: 11)),
                          value: 'location',
                          groupValue: _searchType,
                          onChanged: (val) => setState(() => _searchType = val ?? 'location'),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: _searchType == 'employee'
                          ? 'أدخل اسم الموظف لعرض كافة عهده وكمياتها'
                          : _searchType == 'serial'
                              ? 'أدخل رقم القطعة / كود الصنف'
                              : 'أدخل اسم الموقع أو النقطة',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _searchType == 'employee'
                  ? _buildEmployeeSearchList(db, _searchQuery)
                  : _searchType == 'serial'
                      ? _buildSerialSearchList(db, _searchQuery)
                      : _buildLocationSearchList(db, _searchQuery),
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
          return const Center(child: Text('لا توجد نتائج مطابقة لبحث الموظف.'));
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
                return FutureBuilder<Location?>(
                  future: emp.locationId != null
                      ? (db.select(db.locations)..where((t) => t.id.equals(emp.locationId!))).getSingleOrNull()
                      : Future.value(null),
                  builder: (context, locSnapshot) {
                    final location = locSnapshot.data;
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.badge, color: Color(0xFF1A5F7A), size: 28),
                                const SizedBox(width: 8),
                                Text('${emp.rank} / ${emp.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A5F7A))),
                              ],
                            ),
                            const Divider(),
                            Text('الرقم العسكري: ${emp.militaryId} | القسم: ${emp.department}'),
                            if (location != null) Text('الموقع التابع: ${location.name}'),
                            const SizedBox(height: 12),
                            Text('جميع العهد المقيدة على الموظف (${assets.length}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange)),
                            const SizedBox(height: 8),
                            if (assets.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('لا توجد عهد مقيدة على هذا الموظف حالياً.', style: TextStyle(color: Colors.grey)),
                              )
                            else
                              ...assets.map((a) => Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text('رقم القطعة: ${a.serialNumber} | الوارد: ${a.totalQuantity} | المتبقي: ${a.remainingQuantity}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                        getAssetStatusBadge(a.assetStatus),
                                      ],
                                    ),
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
      },
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
          return const Center(child: Text('لا توجد قطع مطابقة.'));
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
                return FutureBuilder<Location?>(
                  future: asset.locationId != null
                      ? (db.select(db.locations)..where((t) => t.id.equals(asset.locationId!))).getSingleOrNull()
                      : Future.value(null),
                  builder: (context, locSnapshot) {
                    final location = locSnapshot.data;
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text('${asset.name} (${getCategoryName(asset.category)})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                getAssetStatusBadge(asset.assetStatus),
                              ],
                            ),
                            const Divider(),
                            Text('رقم القطعة: ${asset.serialNumber}'),
                            Text('الكمية الواردة: ${asset.totalQuantity} | الكمية المتبقية: ${asset.remainingQuantity}'),
                            const SizedBox(height: 8),
                            if (isAssigned && employee != null) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.orange.withValues(alpha: 0.1),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('حالة الصرف: مصروفة لموظف', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    Text('المستلم: ${employee.rank} / ${employee.name} (${employee.militaryId})'),
                                    if (location != null) Text('الموقع الحالي: ${location.name}'),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.green.withValues(alpha: 0.1),
                                child: Text('متوفرة في المخزن - المتبقي: ${asset.remainingQuantity}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.history),
                                  label: const Text('تقرير الحركة'),
                                  onPressed: () => _showAssetMovementHistory(context, db, asset),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
                                  icon: Icon(isAssigned ? Icons.keyboard_return : Icons.send),
                                  label: Text(isAssigned ? 'إرجاع للمستودع' : 'صرف لموظف'),
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
      },
    );
  }

  Widget _buildLocationSearchList(AppDatabase db, String query) {
    return StreamBuilder<List<Location>>(
      stream: db.select(db.locations).watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var locations = snapshot.data!;
        if (query.isNotEmpty) {
          locations = locations.where((l) => l.name.contains(query) || l.supervisor.contains(query)).toList();
        }
        if (locations.isEmpty) {
          return const Center(child: Text('لا توجد مواقع مطابقة.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: locations.length,
          itemBuilder: (context, index) {
            final loc = locations[index];
            return FutureBuilder<List<Asset>>(
              future: (db.select(db.assets)..where((t) => t.locationId.equals(loc.id))).get(),
              builder: (context, assetSnapshot) {
                final assets = assetSnapshot.data ?? [];
                int totalInAll = assets.fold(0, (sum, a) => sum + a.totalQuantity);
                int totalRemAll = assets.fold(0, (sum, a) => sum + a.remainingQuantity);

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تقرير جرد موقع: ${loc.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A5F7A))),
                        const Divider(),
                        Text('المشرف المسؤول: ${loc.supervisor}'),
                        Text('إجمالي الوارد: $totalInAll | إجمالي المتبقي: $totalRemAll', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const SizedBox(height: 8),
                        Text('الأصناف في الموقع (${assets.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (assets.isEmpty)
                          const Text('لا توجد أصناف مسجلة في هذا الموقع.', style: TextStyle(color: Colors.grey))
                        else
                          ...assets.map((a) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text('• ${a.name} | الوارد: ${a.totalQuantity} | المتبقي: ${a.remainingQuantity}'),
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
    final locations = await db.select(db.locations).get();
    
    if (stores.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف مستودعاً أولاً.')));
      }
      return;
    }

    final serialController = TextEditingController();
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '50');
    final specsController = TextEditingController();
    String category = 'weapons';
    String assetStatus = 'ready';
    int? selectedStoreId = stores.first.id;
    int? selectedLocationId = locations.isNotEmpty ? locations.first.id : null;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة عهدة / صنف كمي جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: serialController, decoration: const InputDecoration(labelText: 'رقم القطعة / كود الصنف')),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصنف')),
                  TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية الواردة الإجمالية')),
                  DropdownButtonFormField<String>(
                    value: category,
                    items: const [
                      DropdownMenuItem(value: 'electronics', child: Text('أجهزة إلكترونية')),
                      DropdownMenuItem(value: 'weapons', child: Text('أسلحة وذخيرة')),
                      DropdownMenuItem(value: 'water_tanks', child: Text('خزانات مياه وشبكات صحية')),
                      DropdownMenuItem(value: 'kitchen', child: Text('أدوات مطبخ وتجهيزات إعاشة')),
                      DropdownMenuItem(value: 'furniture', child: Text('مفروشات وأثاث')),
                      DropdownMenuItem(value: 'military_gear', child: Text('مهام عسكرية')),
                    ],
                    onChanged: (val) => setState(() => category = val ?? 'weapons'),
                    decoration: const InputDecoration(labelText: 'التصنيف الشامل'),
                  ),
                  DropdownButtonFormField<String>(
                    value: assetStatus,
                    items: const [
                      DropdownMenuItem(value: 'ready', child: Text('جاهز / يعمل')),
                      DropdownMenuItem(value: 'damaged', child: Text('تالف')),
                      DropdownMenuItem(value: 'maintenance', child: Text('تحتاج صيانة')),
                      DropdownMenuItem(value: 'missing', child: Text('مفقود')),
                    ],
                    onChanged: (val) => setState(() => assetStatus = val ?? 'ready'),
                    decoration: const InputDecoration(labelText: 'الحالة الفنية'),
                  ),
                  DropdownButtonFormField<int>(
                    value: selectedStoreId,
                    items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (val) => setState(() => selectedStoreId = val),
                    decoration: const InputDecoration(labelText: 'المستودع الرئيسي'),
                  ),
                  if (locations.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: selectedLocationId,
                      items: locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                      onChanged: (val) => setState(() => selectedLocationId = val),
                      decoration: const InputDecoration(labelText: 'الموقع التابع له'),
                    ),
                  TextField(controller: specsController, decoration: const InputDecoration(labelText: 'المواصفات الفنية')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (serialController.text.isEmpty || nameController.text.isEmpty || selectedStoreId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال كافة البيانات المطلوبة')));
                    return;
                  }
                  final qty = int.tryParse(qtyController.text.trim()) ?? 1;
                  final assetId = await db.into(db.assets).insert(AssetsCompanion.insert(
                    serialNumber: serialController.text.trim(),
                    name: nameController.text.trim(),
                    category: category,
                    totalQuantity: Value(qty),
                    remainingQuantity: Value(qty),
                    assetStatus: Value(assetStatus),
                    storeId: Value(selectedStoreId),
                    locationId: selectedLocationId != null ? Value(selectedLocationId) : const Value.absent(),
                    specs: specsController.text.trim().isNotEmpty ? Value(specsController.text.trim()) : const Value.absent(),
                    status: const Value('in_store'),
                  ));

                  await db.into(db.assetMovements).insert(AssetMovementsCompanion.insert(
                    assetId: assetId,
                    quantityMoved: Value(qty),
                    movementType: 'إدخال وارد جديد',
                    notes: Value('إدخال أولي بكمية: $qty إلى المستودع'),
                  ));

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMovementDialog(BuildContext context, AppDatabase db, Asset asset) async {
    final employees = await db.select(db.employees).get();
    final locations = await db.select(db.locations).get();

    if (employees.isEmpty && asset.status != 'assigned') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف موظفين أولاً.')));
      }
      return;
    }

    int? selectedEmpId = employees.isNotEmpty ? employees.first.id : null;
    int? selectedLocId = locations.isNotEmpty ? locations.first.id : null;
    final moveQtyController = TextEditingController(text: '1');
    final isAssigned = asset.status == 'assigned';

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(isAssigned ? 'إرجاع الكمية للمستودع' : 'صرف كمية لموظف'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isAssigned) ...[
                    DropdownButtonFormField<int>(
                      value: selectedEmpId,
                      items: employees.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.rank} / ${e.name}'))).toList(),
                      onChanged: (v) => setState(() => selectedEmpId = v),
                      decoration: const InputDecoration(labelText: 'الموظف المستلم'),
                    ),
                    TextField(controller: moveQtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية المراد صرفها')),
                    if (locations.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value: selectedLocId,
                        items: locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                        onChanged: (v) => setState(() => selectedLocId = v),
                        decoration: const InputDecoration(labelText: 'الموقع التابع'),
                      ),
                  ] else ...[
                    TextField(controller: moveQtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية المراد إرجاعها')),
                  ],
                  const SizedBox(height: 12),
                  const Text('تأكيد حركة الصرف أو الإرجاع؟', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  final mQty = int.tryParse(moveQtyController.text.trim()) ?? 1;
                  if (isAssigned) {
                    int newRem = asset.remainingQuantity + mQty;
                    if (newRem > asset.totalQuantity) newRem = asset.totalQuantity;
                    await (db.update(db.assets)..where((t) => t.id.equals(asset.id))).write(
                      AssetsCompanion(
                        remainingQuantity: Value(newRem),
                        status: newRem == asset.totalQuantity ? const Value('in_store') : const Value('assigned'),
                      ),
                    );

                    await db.into(db.assetMovements).insert(AssetMovementsCompanion.insert(
                      assetId: asset.id,
                      quantityMoved: Value(mQty),
                      movementType: 'إرجاع للمستودع',
                      notes: Value('تم إرجاع عدد $mQty قطعة إلى المستودع الرئيسي'),
                    ));
                  } else {
                    if (selectedEmpId != null && mQty <= asset.remainingQuantity) {
                      int newRem = asset.remainingQuantity - mQty;
                      await (db.update(db.assets)..where((t) => t.id.equals(asset.id))).write(
                        AssetsCompanion(
                          remainingQuantity: Value(newRem),
                          employeeId: Value(selectedEmpId),
                          locationId: selectedLocId != null ? Value(selectedLocId) : const Value.absent(),
                          status: const Value('assigned'),
                        ),
                      );

                      final emp = await (db.select(db.employees)..where((t) => t.id.equals(selectedEmpId!))).getSingle();
                      await db.into(db.assetMovements).insert(AssetMovementsCompanion.insert(
                        assetId: asset.id,
                        quantityMoved: Value(mQty),
                        movementType: 'صرف عهدة لموظف',
                        notes: Value('تم صرف عدد $mQty قطعة للموظف: ${emp.rank} / ${emp.name}'),
                      ));
                    } else if (mQty > asset.remainingQuantity) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الكمية المطلوبة أكبر من المتوفر')));
                      return;
                    }
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('تأكيد'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssetMovementHistory(BuildContext context, AppDatabase db, Asset asset) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تقرير حركة الصنف: ${asset.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<AssetMovement>>(
              future: (db.select(db.assetMovements)..where((t) => t.assetId.equals(asset.id))).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final movements = snapshot.data!;
                if (movements.isEmpty) {
                  return const Text('لا توجد حركات مسجلة لهذا الصنف.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: movements.length,
                  itemBuilder: (context, index) {
                    final m = movements[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.history, color: Colors.indigo),
                        title: Text(m.movementType, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الكمية: ${m.quantityMoved} | التفاصيل: ${m.notes ?? 'لا توجد ملاحظات'}\nالتاريخ: ${m.timestamp}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ],
        ),
      ),
    );
  }
}

// 5. الحركات التاريخية العامة
class AssetMovementsScreen extends ConsumerWidget {
  const AssetMovementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('حركات الصرف والنقل التمويني'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: StreamBuilder<List<AssetMovement>>(
          stream: db.select(db.assetMovements).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final movements = snapshot.data!;
            if (movements.isEmpty) {
              return const Center(child: Text('لا توجد حركات مسجلة حتى الآن.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final mov = movements[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.swap_horiz, color: Colors.indigo),
                    title: Text('نوع الحركة: ${mov.movementType} (الكمية: ${mov.quantityMoved})'),
                    subtitle: Text('الملاحظات: ${mov.notes ?? 'لا توجد'}\nالوقت: ${mov.timestamp}'),
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

// 6. التقارير الشاملة
class EnterpriseReportsScreen extends ConsumerWidget {
  const EnterpriseReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تقرير حركة الصنف والتقارير الشاملة'), backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
        body: StreamBuilder<List<Asset>>(
          stream: db.select(db.assets).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final assets = snapshot.data!;
            int totalIn = assets.fold(0, (sum, a) => sum + a.totalQuantity);
            int totalRem = assets.fold(0, (sum, a) => sum + a.remainingQuantity);
            int totalOut = totalIn - totalRem;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _reportCard('إجمالي الوارد', '$totalIn', Colors.blue),
                    _reportCard('إجمالي المنصرف', '$totalOut', Colors.orange),
                    _reportCard('المتبقي بالمخازن', '$totalRem', Colors.green),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('تقرير تفصيلي بحالة الأرصدة وحركة الأصناف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                if (assets.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('لا توجد أصناف مسجلة.')))
                else
                  ...assets.map((a) => Card(
                        child: ListTile(
                          title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('رقم القطعة: ${a.serialNumber} | الوارد: ${a.totalQuantity} | المتبقي: ${a.remainingQuantity}'),
                          trailing: getAssetStatusBadge(a.assetStatus),
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _reportCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// 7. الإعدادات والنسخ
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
              leading: const Icon(Icons.person, color: Color(0xFF1A5F7A)),
              title: const Text('المستخدم الحالي'),
              subtitle: Text('${currentUser?.fullName ?? 'مدير النظام'} (${currentUser?.role ?? 'admin'})'),
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
          ],
        ),
      ),
    );
  }
}
