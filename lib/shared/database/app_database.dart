import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get fullName => text()();
  TextColumn get role => text()(); 
  TextColumn get passwordHash => text()();
}

class Locations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get supervisor => text()();
  TextColumn get description => text().nullable()();
}

class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get militaryId => text().unique()();
  TextColumn get rank => text()();
  TextColumn get department => text()();
  IntColumn get locationId => integer().references(Locations, #id).nullable()(); 
  TextColumn get status => text().withDefault(const Constant('active'))(); 
}

class Stores extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text().withDefault(const Constant('main'))(); 
  TextColumn get location => text()();
}

// جدول الأصناف والعهد مدعوم بالكميات (الوارده والمتبقية)
class Assets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serialNumber => text().unique()(); // رقم القطعة أو كود الصنف
  TextColumn get category => text()(); 
  TextColumn get name => text()(); // اسم الصنف
  
  // حقول الكميات الجديدة لإدارة المخزون
  IntColumn get totalQuantity => integer().withDefault(const Constant(1))(); // الكمية الواردة الإجمالية
  IntColumn get remainingQuantity => integer().withDefault(const Constant(1))(); // الكمية المتبقية في المخزن
  
  TextColumn get assetStatus => text().withDefault(const Constant('ready'))(); 
  TextColumn get status => text().withDefault(const Constant('in_store'))(); // in_store, assigned
  IntColumn get storeId => integer().references(Stores, #id).nullable()();
  IntColumn get employeeId => integer().references(Employees, #id).nullable()();
  IntColumn get locationId => integer().references(Locations, #id).nullable()(); 
  DateTimeColumn get receivedDate => dateTime().nullable()();
  TextColumn get specs => text().nullable()(); 
}

class AssetMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assetId => integer().references(Assets, #id)();
  IntColumn get fromEmployeeId => integer().references(Employees, #id).nullable()();
  IntColumn get toEmployeeId => integer().references(Employees, #id).nullable()();
  IntColumn get quantityMoved => integer().withDefault(const Constant(1))();
  TextColumn get movementType => text()(); 
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
}

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
  int get schemaVersion => 6; // إصدار جديد لضمان تطبيق هيكل الكميات

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      await m.createAll();
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'imdad_enterprise_v6.db'));
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
