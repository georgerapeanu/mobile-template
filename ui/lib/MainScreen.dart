import 'dart:developer';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:ui/LocalDatabase.dart';
import 'package:ui/Pet.dart';
import 'package:ui/Repository.dart';
import 'package:ui/Server.dart';

import 'AppException.dart';
import 'Debouncer.dart';

class AddEntityScreen extends StatefulWidget {
  const AddEntityScreen({super.key});

  @override
  State<AddEntityScreen> createState() => AddEntityScreenState();
}

class AddEntityScreenState extends State<AddEntityScreen> {
  final _formKey = GlobalKey<FormState>();

  bool isValidDateTime(String s) {
    try {
      DateTime.parse(s);
    } catch(e) {
      return false;
    }
    return true;
  }

  DBPet entity = DBPet(0, "", "", 0, 0, "", "", "", true);

  @override
  Widget build(BuildContext context) {
    Color red = Color.fromRGBO(255, 0, 0, 1);
    Color green = Color.fromRGBO(0, 255, 0, 1);
    return Scaffold(
        appBar: AppBar(
          title: Column(children: [Text("Add pet")]),
          backgroundColor: Color(0x7f7f7f),
        ),
        body: Form(
            key: _formKey,
            child: ListView(
              children: [
                Row(
                    children: [
                      Text("Name:"),
                      Expanded(child: TextFormField(
                        onChanged: (value) => entity.name = value,
                        validator: (value) {
                          if(value == null || value.isEmpty) {
                            return 'Name should be nonempty';
                          }
                          return null;
                        },
                      ))
                    ]
                ),
                Row(
                    children: [
                      Text("Breed:"),
                      Expanded(child: TextFormField(
                        onChanged: (value) => entity.breed = value,
                        validator: (value) {
                          if(value == null || value.isEmpty) {
                            return 'Breed should be nonempty';
                          }
                          return null;
                        },
                      ))
                    ]
                ),
                Row(
                    children: [
                      Text("Age:"),
                      Expanded(child: TextFormField(
                        onChanged: (value) => entity.age = int.tryParse(value),
                        validator: (value) {
                          if(value == null || value.isEmpty || int.tryParse(value) == null) {
                            return 'Age should be a valid integer';
                          }
                          return null;
                        },
                      ))
                    ]
                ),
                Row(
                    children: [
                      Text("Weight:"),
                      Expanded(child: TextFormField(
                        onChanged: (value) => entity.weight = int.tryParse(value),
                        validator: (value) {
                          if(value == null || value.isEmpty || int.tryParse(value) == null) {
                            return 'Weight should be a valid integer';
                          }
                          return null;
                        },
                      ))
                    ]
                ),
                Row(
                    children: [
                      Text("Owner:"),
                      Expanded(child: TextFormField(
                        onChanged: (value) => entity.owner = value,
                        validator: (value) {
                          if(value == null || value.isEmpty) {
                            return 'Owner should be nonempty';
                          }
                          return null;
                        },
                      ))
                    ]
                ),
                Row(
                    children: [
                      Text("Location:"),
                      Expanded(child: TextFormField(
                        onChanged: (value) => entity.location = value,
                        validator: (value) {
                          if(value == null || value.isEmpty) {
                            return 'Location should be nonempty';
                          }
                          return null;
                        },
                      ))
                    ]
                ),
                Row(
                    children: [
                      Text("Description:"),
                      Expanded(child: TextFormField(
                        onChanged: (value) => entity.description = value,
                        validator: (value) {
                          if(value == null || value.isEmpty) {
                            return 'Description should be nonempty';
                          }
                          return null;
                        },
                      ))
                    ]
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate returns true if the form is valid, or false otherwise.
                    if (_formKey.currentState!.validate()) {
                      // If the form is valid, display a snackbar. In the real world,
                      // you'd often call a server or save the information in a database.

                      try {
                        await (await Repository.instance).add(entity);
                        Navigator.pop(context);
                      }  on Exception catch (ex) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ex.toString())),
                        );
                      }
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            )
        )
    );
  }

}

class DeleteEntityScreen extends StatelessWidget {
  const DeleteEntityScreen({super.key, required this.entity});

  final DBPet entity;

  @override
  Widget build(BuildContext context) {
    Color red = Color.fromRGBO(255, 0, 0, 1);
    Color green = Color.fromRGBO(0, 255, 0, 1);
    List<Widget> toDisplay = [];
    toDisplay.add(Text("Breed: ${entity.breed}"));
    toDisplay.add(Text("Age: ${entity.age}"));
    toDisplay.add(Text("weight: ${entity.weight}"));
    toDisplay.add(Text("Owner: ${entity.owner}"));
    toDisplay.add(Text("Location: ${entity.location}"));
    toDisplay.add(Text("Description: ${entity.description}"));
    return Scaffold(
        appBar: AppBar(
          title: Column(children: [Text("Delete entity?")]),
          backgroundColor: Color(0x7f7f7f),
        ),
        body: Column(
            children:toDisplay + [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    color: Colors.white,
                    width: 175,
                    child: TextButton(
                        onPressed: () async {
                          try {
                            await (await Repository.instance).delete(entity);
                            Navigator.pop(context);
                          }  on Exception catch (ex) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ex.toString())),
                            );
                          }
                        },
                        child: Text("Delete")
                    ),
                  ),
                  Container(
                      color: Colors.white,
                      width: 175,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Cancel"),
                      )
                  ),
                ],
              )
            ]
        )
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  List<DBPet> entities = [];
  String? breed = "";
  String? location = "";
  int? age;
  var isLoading = false;
  final debouncer = Debouncer(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    async_init();
  }

  Future<void> async_init() async {
    entities = await (await Server.instance).search(breed: breed, location: location, age: age);
    Server server = await (Server.instance);
    server.add_listener((String topic, Object? data) {
      if(topic == Repository.START_LOADING_OPERATION) {
        isLoading = true;
      } else if (topic == Server.END_LOADING_OPERATION) {
        isLoading = false;
      }
      setState(() {

      });
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget =  Column(
        children: [
          Row(
              children: [
                Text("Breed:"),
                Expanded(child: TextFormField(
                    onChanged: (value) {
                      debouncer.run(() async {
                        breed = value;
                        entities = await (await Server.instance).search(
                            breed: breed, location: location, age: age);
                        setState(() {});
                      });
                    },
                  initialValue: breed,
                )),
              ]
          ),
          Row(
              children: [
                Text("Location:"),
                Expanded(child: TextFormField(
                  onChanged: (value) {
                    debouncer.run(() async {
                      location = value;
                      entities = await (await Server.instance).search(
                          breed: breed, location: location, age: age);
                      setState(() {});
                    });
                  },
                  initialValue: location,
                )),
              ]
          ),
          Row(
              children: [
                Text("Age:"),
                Expanded(child: TextFormField(
                  onChanged: (value) {
                    debouncer.run(() async {
                      age = int.tryParse(value);
                      entities = await (await Server.instance).search(
                          breed: breed, location: location, age: age);
                      setState(() {});
                    });
                  },
                  initialValue: (age == null ? "":age.toString()),
                )),
              ]
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: entities.length,
                  itemBuilder: (context, index) {
                    DBPet entity = entities[index];
                    List<Widget> toDisplay = [];
                    toDisplay.add(Text("Breed: ${entity.breed}"));
                    toDisplay.add(Text("Age: ${entity.age}"));
                    toDisplay.add(Text("weight: ${entity.weight}"));
                    toDisplay.add(Text("Owner: ${entity.owner}"));
                    toDisplay.add(Text("Location: ${entity.location}"));
                    toDisplay.add(
                        Text("Description: ${entity.description}"));

                    return Card(
                      color: Color(0x7f7f7f),
                      child: Column(
                        children: [
                          ExpansionTile(
                              title: Text("${index + 1}. ${entity.name}"),
                              children: toDisplay
                          ),
                        ],
                      ),
                    );
                  }
              )
          )
        ]
    );
    bodyWidget = Stack(
      children: [
        bodyWidget,
        // Center the loading indicator
        if(isLoading) Center(
          child: CircularProgressIndicator(),
        )
      ],
    );
    return Scaffold(
        appBar: AppBar(
          title: Text("Search screen"),
          backgroundColor: Color.fromRGBO(127, 127, 127, 1),
        ),
        body: bodyWidget
    );
  }
}

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
      setState(() {

      });
    });
  }

  void fetchState() async {
    Repository repo = await (Repository.instance);
    entities = await repo.get_all();
    isConnected = (await Server.instance).isConnected;
    dbUninitialized = await (await LocalDatabase.instance).uninitialized;
    setState(() {

    });
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