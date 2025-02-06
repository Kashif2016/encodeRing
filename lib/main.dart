import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_player_app/providers/audio_provider.dart';
import 'package:audio_player_app/screens/home_screen.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';

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
    final expiryDate = DateTime(2025, 02, 09); // Example expiry date
    return currentDate.isBefore(expiryDate);
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
        home: isProd
            ? HomeScreen()
            : FutureBuilder<bool>(
                future: _checkDate(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData && snapshot.data == true) {
                    return HomeScreen();
                  } else {
                    return Scaffold(
                      appBar: AppBar(
                        title: Text('License Expired'),
                      ),
                      body: Center(
                        child: Text(
                            'Your license has expired.\nContact developer',
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
