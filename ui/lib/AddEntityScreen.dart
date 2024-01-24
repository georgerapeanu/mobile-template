
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Pet.dart';
import 'Repository.dart';
import 'Server.dart';

class AddEntityScreen extends StatefulWidget {
  const AddEntityScreen({super.key});

  @override
  State<AddEntityScreen> createState() => AddEntityScreenState();
}

class AddEntityScreenState extends State<AddEntityScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void initState() {
    Server.instance.then((server) {
      server.add_listener((topic, data) {
        if(topic == Server.START_LOADING_OPERATION) {
          isLoading = true;
        } else if(topic == Server.END_LOADING_OPERATION) {
          isLoading = false;
        }
        if(mounted) {
          setState(() {

          });
        }
      });
    });
  }

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
        body: Stack(
          children: [
            Form(
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
            ),
            if(isLoading) Center(
              child: CircularProgressIndicator(backgroundColor: Color.fromRGBO(127, 127, 127, 0.5)),
            )
          ],
        )
    );
  }

}
