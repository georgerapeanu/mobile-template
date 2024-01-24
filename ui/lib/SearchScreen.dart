import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Debouncer.dart';
import 'Pet.dart';
import 'Repository.dart';
import 'Server.dart';

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
      if(mounted) {
        setState(() {

        });
      }
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
