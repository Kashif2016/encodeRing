import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Import the services package
import 'dart:ui';
import 'package:audio_player_app/translations.dart';
import 'package:audio_player_app/screens/play_audio_screen.dart';
import 'package:audio_player_app/screens/home_screen.dart'; // Import HomeScreen
import 'package:audio_player_app/utils/audio_functions.dart';

class AudioListScreen extends StatefulWidget {
  const AudioListScreen({super.key});

  @override
  AudioListScreenState createState() => AudioListScreenState();
}

class AudioListScreenState extends State<AudioListScreen> {
  List<FileSystemEntity> _audioFiles = [];
  late String _languageCode;
  final TextEditingController _controller = TextEditingController();
  late final AudioFunctions _audioFunctions;

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
    _setLanguageCode();
    _setFullScreenMode();
    _audioFunctions = AudioFunctions(context);
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final crossAxisCount = isLandscape ? 3 : 2;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Show the first audio file at the top
                    if (_audioFiles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: Stack(
                          children: [
                            Card(
                              color: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: InkWell(
                                onTap: () => _audioFunctions.scanQR(
                                    context, _controller),
                                onLongPress: () {
                                  _showDeleteConfirmationDialog(
                                      context, _audioFiles[0] as File);
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16.0),
                                  child: Image.asset(
                                    'assets/images/defaultAudioImage.jpg',
                                    width: screenWidth *
                                        2 /
                                        3, // Two-thirds of the screen width
                                    fit: BoxFit.fitWidth,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8.0,
                              left: 8.0,
                              child: Container(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  _audioFiles[0].path.split('/').last,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Grid of remaining audio files
                    if (_audioFiles.length > 1)
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          children:
                              List.generate(_audioFiles.length - 1, (index) {
                            final file = _audioFiles[index + 1] as File;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Align column to the start
                              children: [
                                Card(
                                  color: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: InkWell(
                                    onTap: () => _audioFunctions.scanQR(
                                        context, _controller),
                                    onLongPress: () {
                                      _showDeleteConfirmationDialog(
                                          context, file);
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16.0),
                                      child: Image.asset(
                                        'assets/images/defaultAudioImage.jpg',
                                        width: screenWidth *
                                            1 /
                                            3, // Half of the remaining 2/3 screen height
                                        fit: BoxFit.fitWidth,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    file.path.split('/').last,
                                    textAlign: TextAlign
                                        .start, // Align text to the left
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
}
