import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:ui/AppException.dart';
import 'package:ui/Pet.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

//autoretry would be nice to be opt-in
// online/offline based on websocket
class Server {
  /// LISTENER TOPIC SECTION
  static final ADDED = "addded";
  static final UPDATED = "updated";
  static final DELETED = "deleted";
  static final CONNECTION = "connection";
  static final WEBSOCKET = "websocket";
  static final START_LOADING_OPERATION = "loading";
  static final END_LOADING_OPERATION = "end loading";
  ///


  static const _host = "10.0.2.2";
  static const _port = 2309;
  static const _httpBase = 'http://$_host:$_port';
  static const _wsBase = 'ws://$_host:$_port';
  static final auto_retry = false;

  static Server? _instance;
  static Future<Server> get instance async => _instance ??= await _initServer();

  static final Logger logger = Logger("ServerLogger");
  static final Map<String,String> headers = {
    'Content-type' : 'application/json',
    'Accept': 'application/json',
  };
  late WebSocketChannel channel;


  bool _isConnected = false;
  bool get isConnected => _isConnected;

  List<void Function(String topic, Object? data)> listeners = [];
  void notify_listeners(String topic, Object? data) {
    logger.info(["notifying listeners"]);
    for (var element in listeners) {element(topic, data);}
  }
  Server add_listener(void Function(String topic, Object? data) f) {
    logger.info(["listener subscribed"]);
    listeners.add(f);
    return this;
  }

  Server._() {
  }

  static Future<Server> _initServer() async {
    Server server = Server._();
    server.retry_connection();
    return server;
  }

  Future<List<DBPet>> get_all() async {
    logger.info("Server get all called");
    notify_listeners(START_LOADING_OPERATION, null);
    try {
      final response = await http.get(
          Uri.parse('$_httpBase/pets'), headers: headers);
      if (response.statusCode == 200) {
        logger.info("Received 200 response");
        final List<dynamic> entitiesJson = jsonDecode(response.body);
        List<DBPet> result = entitiesJson.map((entity) =>
            ServerPet.fromMap(entity).toDBPet()).toList();
        return result;
      } else {
        logger.severe("Get all request failed");
        throw ServerException('Failed to get all from server');
      }
    } on http.ClientException catch (_) {
      logger.severe("Get all request failed");
      throw ServerException('Failed to get all from server');
    } on SocketException catch (_) {
      logger.severe("Get all request failed");
      throw ServerException('Failed to get all from server');
    } finally {
      notify_listeners(END_LOADING_OPERATION, null);
    }
  }

  Future<DBPet> get(int id) async {
    logger.info("Server get/$id called");
    notify_listeners(START_LOADING_OPERATION, null);
    try {
      final response =
          await http.get(Uri.parse('$_httpBase/pet/$id'), headers: headers);
      if (response.statusCode == 200) {
        logger.info("Received 200 response");
        final dynamic entityJson = jsonDecode(response.body);
        DBPet result = ServerPet.fromMap(entityJson).toDBPet();
        return result;
      } else {
        logger.severe("Get/$id request failed");
        throw ServerException('Failed to get/$id from server');
      }
    } on http.ClientException catch (_) {
      logger.severe("Get/$id request failed");
      throw ServerException('Failed to get/$id from server');
    } on SocketException catch (_) {
      logger.severe("Get/$id request failed");
      throw ServerException('Failed to get/$id from server');
    } finally {
      notify_listeners(END_LOADING_OPERATION, null);
    }
  }

  Future<void> add(DBPet entity) async {
    logger.info("Server add ${entity.toMap()} called");
    notify_listeners(START_LOADING_OPERATION, null);
    try {
      final response = await http.post(Uri.parse('$_httpBase/pet'),
          body: jsonEncode(ServerPet.fromDBPet(entity).toMap()),
          headers: headers);
      if (response.statusCode == 200) {
        logger.info("Received 200 response");
        notify_listeners(ADDED, entity);
        return;
      } else {
        logger.severe("Add ${entity.toMap()} request failed");
        throw ServerException('Failed to add to server');
      }
    } on http.ClientException catch (_) {
      logger.severe("Add ${entity.toMap()} request failed");
      throw ServerException('Failed to add to server');
    } on SocketException catch (_) {
      logger.severe("Add ${entity.toMap()} request failed");
      throw ServerException('Failed to add to server');
    } finally {
      notify_listeners(END_LOADING_OPERATION, null);
    }
  }

  //TODO update doesnt work? check put vs patch
  Future<void> update(DBPet entity) async {
    logger.info("Server update ${entity.toMap()} called");
    notify_listeners(START_LOADING_OPERATION, null);
    try {
      final response = await http.put(Uri.parse('$_httpBase/pet/${entity.id}'),
          body: jsonEncode(ServerPet.fromDBPet(entity).toMap()),
          headers: headers);
      if (response.statusCode == 200) {
        logger.info("Received 200 response");
        notify_listeners(UPDATED, entity);
        return;
      } else {
        logger.severe("update ${entity.toMap()} request failed");
        throw ServerException('Failed to update to server');
      }
    } on http.ClientException catch (_) {
      logger.severe("update ${entity.toMap()} request failed");
      throw ServerException('Failed to update to server');
    } on SocketException catch (_) {
      logger.severe("update ${entity.toMap()} request failed");
      throw ServerException('Failed to update to server');
    } finally {
      notify_listeners(END_LOADING_OPERATION, null);
    }
  }

  Future<void> delete(DBPet entity) async {
    logger.info("Server delete ${entity.toMap()} called");
    notify_listeners(START_LOADING_OPERATION, null);
    try {
      final response = await http
          .delete(Uri.parse('$_httpBase/pet/${entity.id}'), headers: headers);
      if (response.statusCode == 200) {
        logger.info("Received 200 response");
        notify_listeners(DELETED, entity);
        return;
      } else {
        logger.severe("delete ${entity.toMap()} request failed");
        throw ServerException('Failed to delete from server');
      }
    } on http.ClientException catch (_) {
      logger.severe("delete ${entity.toMap()} request failed");
      throw ServerException('Failed to delete from server');
    } on SocketException catch (_) {
      logger.severe("delete ${entity.toMap()} request failed");
      throw ServerException('Failed to delete from server');
    } finally {
      notify_listeners(END_LOADING_OPERATION, null);
    }
  }

  Future<void> retry_connection() async {
    logger.info("Retry called");

    if (_isConnected) {
      logger.warning("Already connected, skipping retry");
      return;
    }
    notify_listeners(START_LOADING_OPERATION, null);
    channel = WebSocketChannel.connect(Uri.parse(_wsBase));
    try {
      await channel.ready;
      _isConnected = true;
      notify_listeners(CONNECTION, null);
      channel.stream.listen(
          (event) {
            var pet = ServerPet.fromMap(jsonDecode(event)).toDBPet();
            logger.info("Received ${pet.toMap()} from server");
            notify_listeners(WEBSOCKET, pet);
          },
          onError: (_) {
            logger.info("error happened");
            this._isConnected = false;
            notify_listeners(CONNECTION, null);
            if (auto_retry) {
              Timer(Duration(seconds: 5), () {
                retry_connection();
              });
            }
          },
          onDone: () {
            logger.info("done happened");
            this._isConnected = false;
            notify_listeners(CONNECTION, null);
            if (auto_retry) {
              Timer(Duration(seconds: 5), () {
                retry_connection();
              });
            }
          }
      );
    } on WebSocketChannelException catch (_) {
      logger.info("initial exception happened happened");
      this._isConnected = false;
      notify_listeners(CONNECTION, null);
      if (auto_retry) {
        Timer(Duration(seconds: 5), () {
          retry_connection();
        });
      }
    } on SocketException catch (_) {
      logger.info("initial exception happened happened");
      this._isConnected = false;
      notify_listeners(CONNECTION, null);
      if (auto_retry) {
        Timer(Duration(seconds: 5), () {
          retry_connection();
        });
      }
    } finally {
      notify_listeners(END_LOADING_OPERATION, null);
    }
  }

  Future<List<DBPet>> search({String? breed, int? age, String? location}) async {
    logger.info("Server search called");
    notify_listeners(START_LOADING_OPERATION, null);
    try {
      final response = await http
          .get(Uri.parse('$_httpBase/search'), headers: headers);
      if (response.statusCode == 200) {
        logger.info("Received 200 response");
        final List<dynamic> entitiesJson = jsonDecode(response.body);
        List<DBPet> entities = entitiesJson.map((entity) =>
            ServerPet.fromMap(entity).toDBPet()).toList();
        if(breed != null) {
          entities = entities.where((entity) => entity.breed!.contains(breed)).toList();
        }
        if(location != null) {
          entities = entities.where((entity) => entity.location!.contains(location)).toList();
        }
        if(age != null) {
          entities = entities.where((entity) => entity.age == age).toList();
        }
        entities.sort((DBPet a, DBPet b) {
          if(a.weight != b.weight) {
            return -a.weight!.compareTo(b.weight!);
          }
          return a.age!.compareTo(b.age!);
        });
        return entities;
      } else {
        logger.severe("Search request failed");
        throw ServerException('Failed to search on server');
      }
    } on http.ClientException catch (_) {
      logger.severe("Search request failed");
      throw ServerException('Failed to search on server');
    } on SocketException catch (_) {
      logger.severe("Search request failed");
      throw ServerException('Failed to search on server');
    } finally {
      notify_listeners(END_LOADING_OPERATION, null);
    }
  }
}