import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// هذا السطر إلزامي لتوليد الأكواد تلقائياً في السحاب
part 'database_manager.g.dart';

// تعريف الجداول الافتراضية بنظام "إمداد"
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class Stores extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class Audits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()();
}

// ربط الجداول وقاعدة البيانات
@DriftDatabase(tables: [Employees, Stores, Audits])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

// دالة فتح الاتصال المتوافقة مع أندرويد سحابياً ومحلياً
QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'imdad_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// ==========================================
// تعريف الـ Providers لـ Riverpod (تمنع أخطاء التعريف السابقة)
// ==========================================

// مزود قاعدة البيانات الرئيسي (Singleton)
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// مزود بيانات الموظفين
final employeeDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.employees; 
});

// مزود بيانات المخازن
final storeDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.stores; 
});

// مزود بيانات التدقيق
final auditDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.audits; 
});
