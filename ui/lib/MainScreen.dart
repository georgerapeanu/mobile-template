import 'dart:developer';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:ui/LocalDatabase.dart';
import 'package:ui/Pet.dart';
import 'package:ui/Repository.dart';
import 'package:ui/Server.dart';

import 'AddEntityScreen.dart';
import 'AppException.dart';
import 'Debouncer.dart';
import 'DeleteEntityScreen.dart';
import 'SearchScreen.dart';



class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  List<DBPet> entities = [];
  bool isConnected = false;
  bool dbUninitialized = false;
  bool isLoading = false;
  static final Logger logger = Logger("MainScreenLogger");
  @override
  void initState() {
    super.initState();
    async_init();
  }

  void async_init() async {
    Repository repo = await (Repository.instance);
    repo.add_listener((String topic, Object? data) {
      if(topic == Repository.WEBSOCKET) {
        DBPet entity = data as DBPet;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pet ${entity.name} received from server. Check him out!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if(topic == Repository.START_LOADING_OPERATION) {
        isLoading = true;
      } else if(topic == Repository.END_LOADING_OPERATION){
        isLoading = false;
      }
      fetchState();
    });
    Server server = await (Server.instance);
    server.add_listener((String topic, Object? data) {
      if (topic == Server.START_LOADING_OPERATION) {
        isLoading = true;
      } else if (topic == Server.END_LOADING_OPERATION) {
        isLoading = false;
      }
      if(mounted) {
        setState(() {

        });
      }
    });
  }

  void fetchState() async {
    Repository repo = await (Repository.instance);
    entities = await repo.get_all();
    isConnected = (await Server.instance).isConnected;
    dbUninitialized = await (await LocalDatabase.instance).uninitialized;
    if(mounted) {
      setState(() {

      });
    }
  }

  Widget entityView(int index, DBPet entity) {
    Color red = Color.fromRGBO(255, 0, 0, 1);
    Color green = Color.fromRGBO(0, 255, 0, 1);
    List<Widget> toDisplay = [];
    if(entity.hasDetails) {
      toDisplay.add(Text("Breed: ${entity.breed}"));
      toDisplay.add(Text("Age: ${entity.age}"));
      toDisplay.add(Text("weight: ${entity.weight}"));
      toDisplay.add(Text("Owner: ${entity.owner}"));
      toDisplay.add(Text("Location: ${entity.location}"));
      toDisplay.add(Text("Description: ${entity.description}"));
    } else {
      toDisplay.add(Text("Server could not be reached and local DB does not have the data for this pet, please retry the connection and reopen the pet"));
    }
    if(isConnected) {
      toDisplay.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Update
              // Container(
              //   color: Colors.white,
              //   width: 175,
              //   child: TextButton(
              //       onPressed: () async {
              //         await Navigator.push(
              //             context,
              //             MaterialPageRoute(builder: (context) => UpdateEntityScreen(entity: entity)
              //         );
              //         setState(() {});
              //       },
              //       child: Text("Update")
              //   ),
              // ),
              // Delete
              Container(
                  color: Colors.white,
                  width: 175,
                  child: TextButton(
                    onPressed: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DeleteEntityScreen(entity: entity))
                      );
                      setState(() {});
                    },
                    child: Text("Delete"),
                  )
              ),
            ],
          )
      );
    }
    return Card(
      color: Color(0x7f7f7f),
      child: Column(
        children: [
          ExpansionTile(
            title: Text("${index + 1}. ${entity.name}"),
            children: toDisplay,
            onExpansionChanged: (expanded) async {
              if(expanded) {
                try {
                  await (await Repository.instance).get(entity.id);
                } on AppException catch (ex) {
                  logger.severe("Something happened ${ex.toString()}");
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color red = Color.fromRGBO(255, 0, 0, 1);
    Color green = Color.fromRGBO(0, 255, 0, 1);

    List<Widget> toDisplay = [];

    if(dbUninitialized) {
      toDisplay.add(
        Text(
          "Server could not be reached and no local data is available"
        )
      );
      toDisplay.add(
        TextButton(
            onPressed: () async {
              await (await Server.instance).retry_connection();
              (await Repository.instance).reinitialize_repos();
            }
            , child: Text("Retry connection")
        )
      );
    } else {
      if(isConnected) {
        toDisplay.add(Container(
            width: 400,
            child: TextButton(
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEntityScreen())
                  );
                  setState(() {});
                },
                child: Text("Add")
            )
        ));
        toDisplay.add(Container(
            width: 400,
            child: TextButton(
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchScreen())
                  );
                  setState(() {});
                },
                child: Text("Search")
            )
        ));
      } else {
        toDisplay.add(
          TextButton(
              onPressed: () async {
                await (await Server.instance).retry_connection();
              }
              , child: Text("Retry connection")
          )
        );
      }
      toDisplay.add(
          Expanded(
              child: ListView.builder(
                  itemCount: entities.length,
                  itemBuilder: (context, index) {
                    return entityView(index, entities[index]);
                  }
              )
          )
      );
    }

    Widget bodyWidget = Column(children: toDisplay);
    bodyWidget = Stack(
      children: [
        bodyWidget,
        // Center the loading indicator
        if(isLoading) Center(
          child: CircularProgressIndicator(backgroundColor: Color.fromRGBO(127, 127, 127, 0.5)),
        )
      ],
    );
      return Scaffold(
          appBar: AppBar(
            title: Column(children: [
              Text("Pets app"),
              Text("Device is ${isConnected ? "online":"offline"}", style: TextStyle(color: isConnected ? green:red),)]),
            backgroundColor: Color.fromRGBO(127, 127, 127, 1),
          ),
          body: bodyWidget
      );
  }
}