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

// 2. جدول الموظفين
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get militaryId => text().unique()(); // الرقم العسكري / الوظيفي
  TextColumn get rank => text()(); // الرتبة
  TextColumn get department => text()(); // الإدارة / القسم
  TextColumn get status => text().withDefault(const Constant('active0'))(); // active, suspended, retired
}

// 3. جدول المخازن
class Stores extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text().withDefault(const Constant('main'))(); // main, sub
  TextColumn get location => text()();
}

// 4. جدول العهد والأصول العامة والأسلحة والاتصالات
class Assets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serialNumber => text().unique()(); // رقم القطعة / التسلسلي / الباركود
  TextColumn get category => text()(); // weapon, vehicle, comms, equipment, ammo
  TextColumn get name => text()(); // نوع السلاح أو اسم الجهاز
  TextColumn get status => text().withDefault(const Constant('in_store'))(); // in_store, assigned, maintenance, disposed
  IntColumn get storeId => integer().references(Stores, #id).nullable()();
  IntColumn get employeeId => integer().references(Employees, #id).nullable()();
  DateTimeColumn get receivedDate => dateTime().nullable()();
  TextColumn get specs => text().nullable()(); // مواصفات إضافية (مثل المحرك، الهيكل، التشغيلة)
}

// 5. جدول حركة العهد والأصول (Audit & Movement History)
class AssetMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assetId => integer().references(Assets, #id)();
  IntColumn get fromEmployeeId => integer().references(Employees, #id).nullable()();
  IntColumn get toEmployeeId => integer().references(Employees, #id).nullable()();
  TextColumn get movementType => text()(); // issue, return, transfer, disposal, maintenance
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
  TextColumn get signatureRef => text().nullable()(); // مرجع التوقيع الإلكتروني
}

// 6. جدول سجل العمليات العام (Audit Logs)
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text()();
  TextColumn get action => text()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get details => text()();
}

@DriftDatabase(tables: [Users, Employees, Stores, Assets, AssetMovements, AuditLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // ترقية النسخة للنسخة المؤسסية

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        await m.createTable(users);
        await m.createTable(assetMovements);
        await m.createTable(auditLogs);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'imdad_enterprise.db'));
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
