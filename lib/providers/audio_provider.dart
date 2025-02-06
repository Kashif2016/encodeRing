import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers
import 'package:logging/logging.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audio_player_app/config/config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:audio_player_app/translations.dart';
import 'dart:ui';

class Audio {
  final String id;
  final String title;
  final String artist;
  final String imageUrl;
  final String url;
  final String date;

  Audio({
    required this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.url,
    required this.date,
  });
}

class AudioProvider with ChangeNotifier {
  final List<Audio> _audios = [];
  final List<Audio> _recentAudios = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Logger _logger = Logger('AudioProvider');
  Completer<void>? _downloadCompleter;
  late String _languageCode;

  List<Audio> get audios => _audios;
  List<Audio> get recentAudios => _recentAudios;

  AudioProvider() {
    _setLanguageCode();
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

  Future<void> fetchAudio(BuildContext context, String id) async {
    _downloadCompleter = Completer<void>();
    _showLoadingDialog(context); // Show loading dialog

    try {
      // Get the appropriate directory for storing downloaded files
      final directory = await getDownloadDirectory();
      final file = await getFile(directory, id);

      // Manually manage audio file details
      final fileName = "$id.wav";
      final audio = Audio(
        id: fileName,
        title: fileName,
        artist: Translations.getTranslation(_languageCode, 'unknown_artist'),
        imageUrl: 'assets/images/defaultAudioImage.jpg',
        url: file.path,
        date: DateTime.now().toString(),
      );

      // Check if the audio file already exists in the list
      if (!_audios.any((existingAudio) => existingAudio.url == audio.url)) {
        _audios.add(audio);
        _addRecentAudio(audio);
        notifyListeners();
      }

      // Play the audio file
      await _audioPlayer.play(DeviceFileSource(file.path));
    } catch (e) {
      _logger.severe('Error fetching audio: $e');
    } finally {
      if (context.mounted) Navigator.of(context).pop(); // Close loading dialog
      _downloadCompleter?.complete();
    }
  }

  Future<File> getFile(Directory directory, String id) async {
    final file = File('${directory.path}/$id.wav');

    // Check if the file already exists
    if (await file.exists()) {
      // Use the existing file
      _logger.info('File already exists. Using the existing file.');
    } else {
      // Download the audio file
      final audioFileResponse =
          await http.get(Uri.parse('${Config.baseUrl}/$id.wav'));
      if (audioFileResponse.statusCode != 200) {
        throw Exception('Failed to download audio file');
      }
      await file.writeAsBytes(audioFileResponse.bodyBytes);

      // Verify that the file was written correctly
      if (!await file.exists()) {
        throw Exception('Failed to write audio file');
      }
    }

    return file;
  }

  Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Request storage permissions
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

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor:
              Colors.grey[850], // Set the background color to dark grey
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white), // Set spinner color to white
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Translations.getTranslation(
                              _languageCode, 'downloading'),
                          style: TextStyle(
                              color: Colors.white), // Set text color to white
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      _downloadCompleter?.complete();
                      Navigator.of(context).pop(); // Close loading dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.black, // Set button background color to black
                      foregroundColor:
                          Colors.white, // Set button text color to white
                    ),
                    child: Text(
                      Translations.getTranslation(_languageCode, 'cancel'),
                      style: TextStyle(
                          color:
                              Colors.white), // Set button text color to white
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addRecentAudio(Audio audio) {
    _recentAudios.removeWhere((a) => a.id == audio.id);
    _recentAudios.insert(0, audio);
    if (_recentAudios.length > 10) {
      _recentAudios.removeLast();
    }
    notifyListeners();
  }

  Future<void> playAudio(String url) async {
    try {
      await _audioPlayer.play(DeviceFileSource(url));
    } catch (e) {
      _logger.severe("Error playing audio", e);
    }
  }

  void stopAudio() {
    _audioPlayer.stop();
  }

  void deleteAudio(String id) {
    _audios.removeWhere((audio) => audio.id == id);
    notifyListeners();
  }

  void addAudio(Audio audio) {
    // Check if the audio file already exists in the list
    if (!_audios.any((existingAudio) => existingAudio.url == audio.url)) {
      _audios.add(audio);
      notifyListeners();
    }
  }

  void clearAudios() {
    _audios.clear();
    notifyListeners();
  }
}
