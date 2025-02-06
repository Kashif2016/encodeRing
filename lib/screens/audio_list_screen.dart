import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Import the services package
import 'dart:ui';
import 'package:audio_player_app/translations.dart';
import 'package:audio_player_app/screens/play_audio_screen.dart';
import 'package:audio_player_app/screens/home_screen.dart'; // Import HomeScreen

class AudioListScreen extends StatefulWidget {
  const AudioListScreen({super.key});

  @override
  AudioListScreenState createState() => AudioListScreenState();
}

class AudioListScreenState extends State<AudioListScreen> {
  List<FileSystemEntity> _audioFiles = [];
  late String _languageCode;

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
    _setLanguageCode();
    _setFullScreenMode();
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

  Future<void> _loadAudioFiles() async {
    try {
      final directory = await getDownloadDirectory();
      final files = directory
          .listSync()
          .where((file) => file.path.endsWith('.wav'))
          .toList();
      setState(() {
        _audioFiles = files;
      });
    } catch (e) {
      // print('Error loading audio files: $e');
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

  void _deleteFile(File file) {
    file.delete();
    setState(() {
      _audioFiles.remove(file);
    });
  }

  void _showDeleteConfirmationDialog(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              Colors.grey[850], // Set the background color to dark grey
          title: Row(
            children: [
              Icon(Icons.delete,
                  color: Colors.white), // Set icon color to white
              SizedBox(width: 8.0),
              Text(
                Translations.getTranslation(_languageCode, 'delete'),
                style:
                    TextStyle(color: Colors.white), // Set text color to white
              ),
            ],
          ),
          contentPadding: EdgeInsets.symmetric(
              horizontal: 24.0, vertical: 20.0), // Adjust content padding
          actionsPadding: EdgeInsets.symmetric(
              horizontal: 15.0, vertical: 15.0), // Adjust actions padding
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.black, // Set button background color to black
                    foregroundColor:
                        Colors.white, // Set button text color to white
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0), // Adjust button padding
                  ),
                  child: Text(
                    Translations.getTranslation(_languageCode, 'cancel'),
                    style: TextStyle(
                        color: Colors.white), // Set button text color to white
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteFile(file);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.black, // Set button background color to black
                    foregroundColor:
                        Colors.white, // Set button text color to white
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0), // Adjust button padding
                  ),
                  child: Text(
                    Translations.getTranslation(_languageCode, 'ok'),
                    style: TextStyle(
                        color: Colors.white), // Set button text color to white
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final crossAxisCount = isLandscape ? 3 : 2;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black, // Set the background color to black
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            children: List.generate(_audioFiles.length, (index) {
              final file = _audioFiles[index] as File;
              return Card(
                color: Colors
                    .black, // Set the background color of the card to black
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayAudioScreen(
                            audioId: file.path.split('/').last,
                            imageUrl: 'assets/images/defaultAudioImage.jpg',
                            audioUrl: file.path,
                          ),
                        ),
                      );
                    },
                    onLongPress: () {
                      _showDeleteConfirmationDialog(context, file);
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            'assets/images/defaultAudioImage.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            file.path.split('/').last,
                            textAlign: TextAlign.left, // Align text to the left
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
