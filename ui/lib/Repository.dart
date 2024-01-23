import 'dart:math';

import 'package:logging/logging.dart';
import 'package:ui/AppException.dart';
import 'package:ui/Pet.dart';
import 'package:ui/Server.dart';
import 'package:ui/InMemoryRepo.dart';
import 'package:ui/LocalDatabase.dart';

class Repository {
  /// LISTENER TOPIC SECTION
  static final String UI_UPDATE = "ui update";
  static final String WEBSOCKET = "WEBSOCKET";
  ///

  static final Logger logger = Logger("RepositoryLogger");
  static Repository? _instance;
  static Future<Repository> get instance async => _instance ??= await _init_repository();

  Repository._();

  List<void Function(String topic, Object? data)> listeners = [];
  void notify_listeners(String topic, Object? data) {
    logger.info(["notifying listeners"]);
    for (var element in listeners) {element(topic, data);}
  }
  Repository add_listener(void Function(String topic, Object? data) f) {
    logger.info(["listener subscribed"]);
    listeners.add(f);
    return this;
  }


  Future<void> reinitialize_repos() async {
    List<DBPet>? entities;
    if(await (await LocalDatabase.instance).uninitialized) {
      try {
        entities ??= await (await Server.instance).get_all();
        await (await LocalDatabase.instance).bulkAdd(entities);
        await (await LocalDatabase.instance).set_initialized();
      } on ServerException catch (_) {
        logger.warning("server could not be reached for db initialization");
      }
    }
    entities ??= await (await LocalDatabase.instance).get_all();
    await (await InMemoryRepo.instance).bulkAdd(entities);


  }

  static Future<Repository> _init_repository() async {
    Repository repository = Repository._();

    repository.reinitialize_repos();
    (await Server.instance).add_listener((topic, data) async {
      if(topic == Server.WEBSOCKET) {
        DBPet entity = data as DBPet;
        try {
          await (await InMemoryRepo.instance).get(entity.id);
          logger.warning("already have ${entity.toMap()}, skipping");
          return ;
        } on AppException catch (_) {
          ;
        }
        await (await LocalDatabase.instance).add(entity);
        await (await InMemoryRepo.instance).add(entity);
        (await Repository.instance).notify_listeners(WEBSOCKET, entity);
      }
      if(topic == Server.CONNECTION) {
        (await Repository.instance).notify_listeners(UI_UPDATE, null);
      }
    });

    (await LocalDatabase.instance).add_listener((topic, data) async {
      if(topic == LocalDatabase.INITIALIZED) {
        (await Repository.instance).notify_listeners(UI_UPDATE, null);
      }
    });

    (await InMemoryRepo.instance).add_listener((topic, data) async {
      (await Repository.instance).notify_listeners(UI_UPDATE, null);
    });


    return repository;
  }

  Future<List<DBPet>> get_all() async {
    logger.info("Get all called");
    return (await InMemoryRepo.instance).get_all();
  }

  Future<DBPet> get(int id) async {
    logger.info("Get $id called");
    DBPet entity = await (await InMemoryRepo.instance).get(id);
    if(!entity.hasDetails) {
      entity = await (await Server.instance).get(id);
      await (await LocalDatabase.instance).update(entity);
      await (await InMemoryRepo.instance).update(entity);
    }
    return entity;
  }

  Future<void> add(DBPet entity) async {
    logger.info("Add ${entity.toMap()} called");
    await (await Server.instance).add(entity);
    // TODO skipped since add happens through WS. source of bugs in case this is not true
    // await (await LocalDatabase.instance).add(entity);
    // await (await InMemoryRepo.instance).add(entity);
  }

  Future<void> delete(DBPet entity) async {
    logger.info("Delete ${entity.toMap()} called");
    await (await Server.instance).delete(entity);
    await (await LocalDatabase.instance).delete(entity);
    await (await InMemoryRepo.instance).delete(entity);
  }
}