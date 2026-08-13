import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// 1. جدول المستخدمين والصلاحيات (RBAC)
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get fullName => text()();
  TextColumn get role => text()(); // admin, supply_manager, storekeeper, custodian, vehicle_officer, weapon_officer, readonly
  TextColumn get passwordHash => text()();
}

// 2. جدول المواقع والنقاط التابعة للمؤسسة (Locations & Sites)
class Locations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // اسم الموقع / النقطة
  TextColumn get supervisor => text()(); // المشرف على الموقع
  TextColumn get description => text().nullable()();
}

// 3. جدول الموظفين
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get militaryId => text().unique()(); // الرقم العسكري / الوظيفي
  TextColumn get rank => text()(); // الرتبة
  TextColumn get department => text()(); // الإدارة / القسم
  IntColumn get locationId => integer().references(Locations, #id).nullable()(); // الموقع التابع له الموظف
  TextColumn get status => text().withDefault(const Constant('active'))(); // active, suspended, retired
}

// 4. جدول المخازن
class Stores extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text().withDefault(const Constant('main'))(); // main, sub
  TextColumn get location => text()();
}

// 5. جدول العهد والأصول والتموين (التصنيفات الستة والحالات الفنية الأربع)
class Assets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serialNumber => text().unique()(); // رقم القطعة / الباركود
  TextColumn get category => text()(); 
  // التصنيفات الستة:
  // electronics (أجهزة إلكترونية)
  // weapons (أسلحة وذخيرة)
  // water_tanks (خزانات مياه وشبكات صحية)
  // kitchen (أدوات مطبخ وتجهيزات إعاشة)
  // furniture (مفروشات وأثاث مكتبي وسكني)
  // military_gear (مهام عسكرية)
  
  TextColumn get name => text()(); // اسم الصنف
  
  TextColumn get assetStatus => text().withDefault(const Constant('ready'))(); 
  // الحالات الفنية الأربع:
  // ready (جاهز / يعمل)
  // damaged (تالف)
  // maintenance (تحتاج صيانة)
  // missing (مفقود)

  TextColumn get status => text().withDefault(const Constant('in_store'))(); // in_store, assigned
  IntColumn get storeId => integer().references(Stores, #id).nullable()();
  IntColumn get employeeId => integer().references(Employees, #id).nullable()();
  IntColumn get locationId => integer().references(Locations, #id).nullable()(); // الموقع المتواجد فيه القطعة
  DateTimeColumn get receivedDate => dateTime().nullable()();
  TextColumn get specs => text().nullable()(); // مواصفات إضافية
}

// 6. جدول حركة العهد والأصول (Audit & Movement History)
class AssetMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assetId => integer().references(Assets, #id)();
  IntColumn get fromEmployeeId => integer().references(Employees, #id).nullable()();
  IntColumn get toEmployeeId => integer().references(Employees, #id).nullable()();
  TextColumn get movementType => text()(); // issue, return, transfer, maintenance
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
}

// 7. جدول سجل العمليات العام (Audit Logs)
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text()();
  TextColumn get action => text()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get details => text()();
}

@DriftDatabase(tables: [Users, Locations, Employees, Stores, Assets, AssetMovements, AuditLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4; // ترقية النسخة لدعم المواقع والتصنيفات الجديدة

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 4) {
        await m.createTable(locations);
        try {
          await m.addColumn(employees, employees.locationId);
          await m.addColumn(assets, assets.assetStatus);
          await m.addColumn(assets, assets.locationId);
        } catch (_) {}
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'imdad_enterprise_v4.db'));
    return NativeDatabase.createInBackground(file);
  });
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() {
    database.close();
  });
  return database;
});
