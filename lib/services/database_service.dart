import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alert.dart';
import '../models/gic_investment.dart';
import '../models/mortgage.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'maple_alerts.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE alerts (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            type TEXT NOT NULL,
            deadline TEXT NOT NULL,
            reminderEnabled INTEGER NOT NULL DEFAULT 1,
            isPremium INTEGER NOT NULL DEFAULT 0,
            metadata TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE gics (
            id TEXT PRIMARY KEY,
            institution TEXT NOT NULL,
            amount REAL NOT NULL,
            purchaseDate TEXT NOT NULL,
            termMonths INTEGER NOT NULL,
            interestRate REAL NOT NULL,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE mortgages (
            id TEXT PRIMARY KEY,
            lender TEXT NOT NULL,
            amount REAL NOT NULL,
            renewalDate TEXT NOT NULL,
            interestRate REAL NOT NULL,
            mortgageType TEXT NOT NULL,
            notes TEXT
          )
        ''');
      },
    );
  }

  // ─── Alerts CRUD ────────────────────────────────────────────────────────────

  Future<void> insertAlert(Alert alert) async {
    final db = await database;
    final map = alert.toMap();
    map['metadata'] = jsonEncode(alert.metadata);
    await db.insert(
      'alerts',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Alert>> getAlerts() async {
    final db = await database;
    final rows = await db.query('alerts', orderBy: 'deadline ASC');
    return rows.map((row) {
      final mutableRow = Map<String, dynamic>.from(row);
      final metaRaw = mutableRow['metadata'];
      if (metaRaw is String && metaRaw.isNotEmpty) {
        try {
          mutableRow['metadata'] = jsonDecode(metaRaw) as Map<String, dynamic>;
        } catch (_) {
          mutableRow['metadata'] = <String, dynamic>{};
        }
      } else {
        mutableRow['metadata'] = <String, dynamic>{};
      }
      return Alert.fromMap(mutableRow);
    }).toList();
  }

  Future<void> updateAlert(Alert alert) async {
    final db = await database;
    final map = alert.toMap();
    map['metadata'] = jsonEncode(alert.metadata);
    await db.update(
      'alerts',
      map,
      where: 'id = ?',
      whereArgs: [alert.id],
    );
  }

  Future<void> deleteAlert(String id) async {
    final db = await database;
    await db.delete('alerts', where: 'id = ?', whereArgs: [id]);
  }

  // ─── GICs CRUD ──────────────────────────────────────────────────────────────

  Future<void> insertGic(GicInvestment gic) async {
    final db = await database;
    await db.insert(
      'gics',
      gic.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<GicInvestment>> getGics() async {
    final db = await database;
    final rows = await db.query('gics', orderBy: 'purchaseDate ASC');
    return rows.map(GicInvestment.fromMap).toList();
  }

  Future<void> updateGic(GicInvestment gic) async {
    final db = await database;
    await db.update(
      'gics',
      gic.toMap(),
      where: 'id = ?',
      whereArgs: [gic.id],
    );
  }

  Future<void> deleteGic(String id) async {
    final db = await database;
    await db.delete('gics', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Mortgages CRUD ─────────────────────────────────────────────────────────

  Future<void> insertMortgage(Mortgage mortgage) async {
    final db = await database;
    await db.insert(
      'mortgages',
      mortgage.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Mortgage>> getMortgages() async {
    final db = await database;
    final rows = await db.query('mortgages', orderBy: 'renewalDate ASC');
    return rows.map(Mortgage.fromMap).toList();
  }

  Future<void> updateMortgage(Mortgage mortgage) async {
    final db = await database;
    await db.update(
      'mortgages',
      mortgage.toMap(),
      where: 'id = ?',
      whereArgs: [mortgage.id],
    );
  }

  Future<void> deleteMortgage(String id) async {
    final db = await database;
    await db.delete('mortgages', where: 'id = ?', whereArgs: [id]);
  }
}
