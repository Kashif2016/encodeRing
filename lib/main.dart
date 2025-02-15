import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_player_app/providers/audio_provider.dart';
import 'package:audio_player_app/screens/home_screen.dart';
import 'package:audio_player_app/screens/audio_list_screen.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void _setupLogging() {
  Logger.root.level = Level.ALL; // Set the logging level
  Logger.root.onRecord.listen((record) {});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final bool isProd = false; // Set this flag to true for production

  Future<bool> _checkDate() async {
    // Replace with your actual date checking logic
    final currentDate = DateTime.now();
    final expiryDate = DateTime(2025, 02, 24); // Example expiry date
    return currentDate.isBefore(expiryDate);
  }

  Future<bool> _audioFilesExist() async {
    try {
      final directory = await getDownloadDirectory();
      final files = directory
          .listSync()
          .where((file) => file.path.endsWith('.wav'))
          .toList();
      return files.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      if (await _requestPermission(Permission.storage)) {
        final directory = Directory('/storage/emulated/0/Download/Encode');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory;
      } else {
        throw Exception('Storage permission not granted');
      }
    } else if (Platform.isIOS) {
      final directory = Directory(
          '${(await getApplicationDocumentsDirectory()).path}/Encode');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      final result = await permission.request();
      return result == PermissionStatus.granted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: MaterialApp(
        title: 'Audio player',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FutureBuilder<bool>(
          future: isProd ? _audioFilesExist() : _checkDate(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data == true) {
              return FutureBuilder<bool>(
                future: _audioFilesExist(),
                builder: (context, audioSnapshot) {
                  if (audioSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (audioSnapshot.hasError) {
                    return Center(child: Text('Error: ${audioSnapshot.error}'));
                  } else if (audioSnapshot.hasData &&
                      audioSnapshot.data == true) {
                    return AudioListScreen();
                  } else {
                    return HomeScreen();
                  }
                },
              );
            } else {
              return Scaffold(
                appBar: AppBar(
                  title: Text('License Expired'),
                ),
                body: Center(
                  child: Text('Your license has expired.\nContact developer',
                      style: TextStyle(fontSize: 18)),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

void main() {
  _setupLogging();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(MyApp());
  });
}
