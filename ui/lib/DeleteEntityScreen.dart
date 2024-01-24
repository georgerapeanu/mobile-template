import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Pet.dart';
import 'Repository.dart';
import 'Server.dart';

class DeleteEntityScreen extends StatefulWidget {
  const DeleteEntityScreen({super.key, required this.entity});

  final DBPet entity;

  @override
  State<StatefulWidget> createState() => DeleteEntityState();
}

class DeleteEntityState extends State<DeleteEntityScreen> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    Server.instance.then((server) {
      server.add_listener((topic, data) {
        if(topic == Server.START_LOADING_OPERATION) {
          isLoading = true;
        } else if(topic == Server.END_LOADING_OPERATION){
          isLoading = false;
        }
        if(mounted) {
          setState(() {

          });
        }
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    Color red = Color.fromRGBO(255, 0, 0, 1);
    Color green = Color.fromRGBO(0, 255, 0, 1);
    List<Widget> toDisplay = [];
    DBPet entity = widget.entity;
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
        body: Stack(
          children: [
            Column(
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
            ),
            if(isLoading) Center(
              child: CircularProgressIndicator(backgroundColor: Color.fromRGBO(127, 127, 127, 0.5)),
            )
          ],
        )
    );
  }
}
