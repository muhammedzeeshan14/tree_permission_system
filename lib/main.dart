import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'services/connectivity_service.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await ConnectivityService.instance.init();
  await SupabaseService.init();

  // Stage 2: auto-sync when coming back online.
  ConnectivityService.instance.onStatus.listen((online) {
    if (online && SupabaseService.isReady) {
      SyncService.instance.syncNow();
    }
  });

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print(details.exceptionAsString());
    print(details.stack);
  };

  runApp(const TPMSApp());

}