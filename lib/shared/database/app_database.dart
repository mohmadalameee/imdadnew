import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get rank => text().nullable()(); // الرتبة أو المسمى الوظيفي
}

class Stores extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get location => text().nullable()();
}

// جدول الأسلحة والعهد
class Assets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serialNumber => text().withLength(min: 1, max: 50)(); // رقم القطعة
  TextColumn get type => text()(); // نوع السلاح أو العهدة
  TextColumn get status => text().withDefault(const Constant('in_store'))(); // in_store أو assigned
  IntColumn get storeId => integer().references(Stores, #id).nullable()(); // المخزن المتواجدة فيه
  IntColumn get employeeId => integer().references(Employees, #id).nullable()(); // الموظف المستلم
  DateTimeColumn get assignedAt => dateTime().nullable()(); // تاريخ الصرف
}

class Audits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Employees, Stores, Assets, Audits])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // ترقية النسخة لدعم الجداول الجديدة

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(assets);
        await m.addColumn(employees, employees.rank);
        await m.addColumn(stores, stores.location);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'imdad.db'));
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
