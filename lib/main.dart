
import 'package:stylr/services/wardrobe_storage.dart';
import 'package:flutter/material.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await WardrobeStorage.init();

  runApp(const StylrApp());
}



// Email: demo@stylr.com



// Password: 12345678