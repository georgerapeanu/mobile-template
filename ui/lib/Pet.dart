//Generic
//Should implement a server variant, a localdb variant

class DBPet {
  int id;
  String name;
  String? breed;
  int? age;
  int? weight;
  String? owner;
  String? location;
  String? description;
  bool hasDetails;

  DBPet(this.id, this.name, this.breed, this.age, this.weight, this.owner,
      this.location, this.description, this.hasDetails);

  // Convert DBPet to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'age': age,
      'weight': weight,
      'owner': owner,
      'location': location,
      'description': description,
      'hasDetails': hasDetails ? 1:0
    };
  }

  // Create DBPet from Map
  factory DBPet.fromMap(Map<String, dynamic> map) {
    return DBPet(
      map['id'],
      map['name'],
      map['breed'],
      map['age'],
      map['weight'],
      map['owner'],
      map['location'],
      map['description'],
      map['hasDetails'] == 1
    );
  }


  static String get tableName => 'pet';

  static String get createTableQuery => '''
    CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY,
      name TEXT,
      breed TEXT,
      age INTEGER,
      weight INTEGER,
      owner TEXT,
      location TEXT,
      description TEXT,
      hasDetails INTEGER
    )
  ''';
}

class ServerPet {
  int id;
  String name;
  String? breed;
  int? age;
  int? weight;
  String? owner;
  String? location;
  String? description;

  ServerPet(this.id, this.name, this.breed, this.age, this.weight, this.owner,
      this.location, this.description);

  // Convert ServerPet to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'age': age,
      'weight': weight,
      'owner': owner,
      'location': location,
      'description': description,
    };
  }

  // Create ServerPet from Map
  factory ServerPet.fromMap(Map<String, dynamic> map) {
    return ServerPet(
      map['id'],
      map['name'],
      map['breed'],
      map['age'],
      map['weight'],
      map['owner'],
      map['location'],
      map['description'],
    );
  }

  // Convert DBPet to ServerPet
  factory ServerPet.fromDBPet(DBPet DBPet) {
    return ServerPet(
      DBPet.id,
      DBPet.name,
      DBPet.breed,
      DBPet.age,
      DBPet.weight,
      DBPet.owner,
      DBPet.location,
      DBPet.description,
    );
  }

  // Convert ServerPet to DBPet
  DBPet toDBPet() {
    return DBPet(
      id,
      name,
      breed,
      age,
      weight,
      owner,
      location,
      description,
      (breed != null)
    );
  }
}
