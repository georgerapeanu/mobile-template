import 'dart:io';

import 'package:logging/logging.dart';
import 'package:ui/AppException.dart';
import 'package:ui/Pet.dart';


class InMemoryRepo {
  /// LISTENER TOPIC SECTION
  static final BULK_ADD = "bulk add";
  static final ADDED = "addded";
  static final UPDATED = "updated";
  static final DELETED = "deleted";
  ///


  static InMemoryRepo? _instance;
  static Future<InMemoryRepo> get instance async => _instance ??= InMemoryRepo._();

  static final Logger logger = Logger("InMemoryRepoLogger");
  List<DBPet> entities = [];

  List<void Function(String topic, Object? data)> listeners = [];
  void notify_listeners(String topic, Object? data) {
    logger.info(["notifying listeners"]);
    for (var element in listeners) {element(topic, data);}
  }
  InMemoryRepo add_listener(void Function(String topic, Object? data) f) {
    logger.info(["listener subscribed"]);
    listeners.add(f);
    return this;
  }


  InMemoryRepo._();

  Future<void> add(DBPet entity) async {
    entity = DBPet.fromMap(entity.toMap());
    logger.info("add ${entity.toMap()} called");
    if(entities.where((memoryEntity) => entity.id == memoryEntity.id).isNotEmpty) {
      throw AppException("in memory repo contains element");
    }
    entities.add(entity);
    notify_listeners(ADDED, entity);
  }

  Future<void> update(DBPet entity) async {
    entity = DBPet.fromMap(entity.toMap());
    logger.info("update ${entity.toMap()} called");
    if(entities.where((memoryEntity) => entity.id == memoryEntity.id).isEmpty) {
      throw AppException("in memory repo does not contains element");
    }
    for(int i = 0; i < entities.length; i++) {
      if(entities[i].id == entity.id) {
        entities[i] = entity;
      }
    }
    notify_listeners(UPDATED, entity);
  }

  Future<void> delete(DBPet entity) async {
    entity = DBPet.fromMap(entity.toMap());
    logger.info("delete ${entity.toMap()} called");
    if(entities.where((memoryEntity) => entity.id == memoryEntity.id).isEmpty) {
      throw AppException("in memory repo does not contains element");
    }
    DBPet memory_entity = entities.where((memoryEntity) => entity.id == memoryEntity.id).first;
    entities.remove(memory_entity);
    notify_listeners(DELETED, entity);
  }

  Future<List<DBPet>> get_all() async {
    logger.info("get all called");
    return entities;
  }

  Future<DBPet> get(int id) async {
    logger.info("get by id $id called");
    if(entities.where((memoryEntity) => id == memoryEntity.id).isEmpty) {
      throw AppException("in memory repo does not contains element");
    }
    return entities.where((memoryEntity) => id == memoryEntity.id).first;
  }

  Future<void> bulkAdd(List<DBPet> entitiesToAdd) async {
    List<DBPet> newEntities = [];
    logger.info("bulkAdd with ${entitiesToAdd.length} entities called");

    for (var entity in entitiesToAdd) {
      DBPet newEntity = DBPet.fromMap(entity.toMap());

      if (newEntities.any((memoryEntity) => newEntity.id == memoryEntity.id)) {
        throw AppException("In-memory repository already contains an element with ID ${newEntity.id}");
      }

      newEntities.add(newEntity);
    }

    entities.addAll(newEntities);
    logger.info("Added ${newEntities.length} entities to in-memory repository");
    notify_listeners(BULK_ADD, newEntities);
  }

}