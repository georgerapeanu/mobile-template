import 'dart:io';
import 'dart:math';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'package:ui/AppException.dart';
import 'package:ui/Pet.dart';


class LocalDatabase {
  /// LISTENER TOPIC SECTION
  static final BULK_ADD = "bulk add";
  static final ADDED = "addded";
  static final UPDATED = "updated";
  static final DELETED = "deleted";
  static final INITIALIZED = "initialized";
  ///

  static const _dbName = "pets.db";
  static const _dbVersion = 1;

  static LocalDatabase? _instance;
  static Future<LocalDatabase> get instance async => _instance ??= await _init_local_db();

  static final Logger logger = Logger("LocalDatabaseLogger");
  Database? _database_instance;

  Future<Database> get _database async => _database_instance ??= await _init_database();

  Future<bool> get uninitialized async {
    var result = await (await _database).query("custom_flags", limit: 1);
    return (result.first['uninitialized'] == 1);
  }

  List<void Function(String topic, Object? data)> listeners = [];
  void notify_listeners(String topic, Object? data) {
    logger.info(["notifying listeners"]);
    for (var element in listeners) {element(topic, data);}
  }
  LocalDatabase add_listener(void Function(String topic, Object? data) f) {
    logger.info(["listener subscribed"]);
    listeners.add(f);
    return this;
  }

  LocalDatabase._();

  static Future<LocalDatabase> _init_local_db() async {
    var instance =  LocalDatabase._();
    return instance;
  }

  Future<Database> _init_database() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);

    return openDatabase(
        path,
        version: _dbVersion,
        onCreate: (Database db, int version) async {
          var result = await db.execute(DBPet.createTableQuery);
          await db.execute('''CREATE TABLE custom_flags (
            uninitialized BOOL
          )''');
          await db.insert("custom_flags", {'uninitialized':1});
          return result;
        }
    );
  }

  Future<void> set_initialized() async {
    await (await _database).update("custom_flags", {'uninitialized': 0});
    notify_listeners(INITIALIZED, null);
  }

  Future<void> add(DBPet entity) async {
    entity = DBPet.fromMap(entity.toMap());
    logger.info("add ${entity.toMap()} called");
    Database db = await _database;
    try {
      await db.transaction((txn) async {
        await txn.insert(DBPet.tableName, entity.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
      });
      logger.info("Added to local storage ${entity.toMap()}");
      notify_listeners(ADDED, entity);
    } on DatabaseException catch (_) {
      logger.severe("Local storage error encountered");
      throw DBException("Local storage error encountered");
    }
  }

  Future<void> update(DBPet entity) async {
    entity = DBPet.fromMap(entity.toMap());
    logger.info("update ${entity.toMap()} called");
    Database db = await _database;
    try {
      await db.transaction((txn) async {
        await txn.update(DBPet.tableName, entity.toMap(), where: 'id = ?', whereArgs: [entity.id]);
      });
      logger.info("Updated to local storage ${entity.toMap()}");
      notify_listeners(UPDATED, entity);
    } on DatabaseException catch (_) {
      logger.severe("Local storage error encountered");
      throw DBException("Local storage error encountered");
    }
  }

  Future<void> delete(DBPet entity) async {
    entity = DBPet.fromMap(entity.toMap());
    logger.info("delete ${entity.toMap()} called");
    Database db = await _database;
    try {
      await db.transaction((txn) async {
        await txn.delete(DBPet.tableName,  where: 'id = ?', whereArgs: [entity.id]);
      });
      logger.info("Deleted from local storage ${entity.toMap()}");
      notify_listeners(DELETED, entity);
    } on DatabaseException catch (_) {
      logger.severe("Local storage error encountered");
      throw DBException("Local storage error encountered");
    }
  }

  Future<List<DBPet>> get_all() async {
    logger.info("Get all called");
    try {
      return (await (await _database).query(DBPet.tableName))
          .map((g) => DBPet.fromMap(g))
          .toList();
    } on DatabaseException catch(_) {
      logger.severe("Local storage error encountered");
      throw DBException("Local storage error encountered");
    }
  }

  Future<DBPet> get(int id) async {
    logger.info("Get $id called");
    try {
      var entities = (await (await _database).query(
          DBPet.tableName, where: 'id = ?', whereArgs: [id])).map((g) =>
          DBPet.fromMap(g)).toList();
      if (entities.length != 1) {
        throw DBException("Entity not found");
      }

      return entities[0];
    } on DatabaseException catch(_) {
      logger.severe("Local storage error encountered");
      throw DBException("Local storage error encountered");
    }
  }

  Future<void> bulkAdd(List<DBPet> entities) async {
    List<Map<String, dynamic>> entityMaps = entities.map((entity) {
      return DBPet.fromMap(entity.toMap()).toMap();
    }).toList();

    logger.info("bulkAdd called with ${entities.length} entities");

    Database db = await _database;
    try {
      await db.transaction((txn) async {
        for (var entityMap in entityMaps) {
          await txn.insert(DBPet.tableName, entityMap, conflictAlgorithm: ConflictAlgorithm.fail);
        }
      });
      logger.info("Added ${entities.length} entities to local storage");
      notify_listeners(BULK_ADD, entities);
    } on DatabaseException catch (_) {
      logger.severe("Local storage error encountered");
      throw DBException("Local storage error encountered");
    }
  }
}