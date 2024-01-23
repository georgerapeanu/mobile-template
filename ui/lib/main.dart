import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:ui/MainScreen.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.loggerName} : ${record.time}: ${record.message}');
  });

  runApp(
      const MaterialApp(
          home: Directionality(
              textDirection: TextDirection.ltr,
              child: MainScreen()
          )
      )
  );
}