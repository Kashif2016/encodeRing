import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_player_app/providers/audio_provider.dart';
import 'package:audio_player_app/utils/audio_functions.dart';
import 'package:audio_player_app/translations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_player_app/screens/audio_list_screen.dart';
import 'package:flutter/services.dart'; // Import the services package
import 'dart:ui';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  late final AudioFunctions _audioFunctions;
  late String _languageCode;
  Audio? _currentAudio;

  @override
  void initState() {
    super.initState();
    _audioFunctions = AudioFunctions(context);
    _setLanguageCode();
    _setFullScreenMode(); // Set full screen mode
  }

  void _setLanguageCode() {
    final locale = PlatformDispatcher.instance.locale;
    switch (locale.languageCode) {
      case 'de':
        _languageCode = 'de';
        break;
      case 'ja':
        _languageCode = 'ja';
        break;
      default:
        _languageCode = 'en';
    }
  }

  void _setFullScreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<bool> _onWillPop() async {
    SystemNavigator.pop(); // Exit the app
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // Removed the AppBar to hide the top bar
        resizeToAvoidBottomInset: false, // Adjust layout when keyboard is shown
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey, Colors.black],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: _buildAudioIdTextField(context, audioProvider),
                  ),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioIdTextField(
      BuildContext context, AudioProvider audioProvider) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Translations.getTranslation(_languageCode, 'input'),
            style: TextStyle(
              fontSize: 35.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 15.0),
          Text(
            Translations.getTranslation(_languageCode, 'enter_product_id'),
            style: TextStyle(
              fontSize: 15.0,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 35.0),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12.0), // Increased border radius
              ),
              filled: true,
              fillColor: Colors.grey,
            ),
          ),
          SizedBox(height: 25.0),
          GestureDetector(
            onTap: () => _audioFunctions.scanQR(context, _controller),
            child: Text(
              Translations.getTranslation(_languageCode, 'enter_with_qr'),
              style: TextStyle(
                fontSize: 10.0,
                color: Colors.white, // Change color to indicate it's clickable
                decoration: TextDecoration.none, // Remove underline
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () async {
              final file = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AudioListScreen()),
              );
              if (file != null && file is File) {
                setState(() {
                  String audioId = file.path.split('/').last;
                  _currentAudio = Audio(
                    id: audioId,
                    title: audioId,
                    artist: 'Unknown Artist',
                    imageUrl: 'assets/images/defaultAudioImage.jpg',
                    url: file.path,
                    date: DateTime.now().toString(),
                  );
                });
                _audioFunctions.audioPlayer.setFilePath(file.path);
                _audioFunctions.audioPlayer.play();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_outlined, size: 30.0, color: Colors.white),
                SizedBox(height: 5.0),
                Text(
                  Translations.getTranslation(_languageCode, 'home'),
                  style: TextStyle(fontSize: 10.0, color: Colors.white),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {},
                child: Column(
                  children: [
                    Icon(Icons.add, size: 30.0, color: Colors.white),
                    SizedBox(height: 5.0),
                    Text(
                      Translations.getTranslation(_languageCode, 'plus'),
                      style: TextStyle(fontSize: 10.0, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
