import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_player_app/screens/qr_scan_screen.dart';
import 'package:audio_player_app/screens/play_audio_screen.dart'; // Import PlayAudioScreen
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:audio_player_app/providers/audio_provider.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioFunctions {
  final Logger _logger = Logger('AudioProvider');
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> _audioFiles = [];
  int _currentIndex = 0;

  AudioPlayer get audioPlayer => _audioPlayer;

  AudioFunctions(BuildContext context) {
    _initVolume();
  }

  Future<void> _initVolume() async {
    FlutterVolumeController.showSystemUI;
  }

  Future<void> fetchAudio(BuildContext context, String id) async {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    if (id.isNotEmpty) {
      await audioProvider.fetchAudio(context, id);
      _audioFiles = audioProvider.audios.map((audio) => audio.url).toList();
      _currentIndex = 0;
      if (_audioFiles.isNotEmpty) {
        String fileName = '$id.wav';
        final audio =
            audioProvider.audios.firstWhere((audio) => audio.id == fileName);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayAudioScreen(
              audioId: audio.id,
              imageUrl: audio.imageUrl,
              audioUrl: audio.url,
            ),
          ),
        );
      }
    } else {
      _audioFiles = [];
      _currentIndex = 0;
      _audioPlayer.stop();
    }
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

  void scanQR(BuildContext context, TextEditingController controller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScanScreen(
          onScanned: (scannedText) {
            controller.text = scannedText;
          },
        ),
      ),
    );
  }

  void playPause() {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void previous() {
    if (_audioFiles.isNotEmpty && _currentIndex > 0) {
      _currentIndex--;
      _audioPlayer.setUrl(_audioFiles[_currentIndex]);
      _audioPlayer.play();
    }
  }

  void next() {
    if (_audioFiles.isNotEmpty && _currentIndex < _audioFiles.length - 1) {
      _currentIndex++;
      _audioPlayer.setUrl(_audioFiles[_currentIndex]);
      _audioPlayer.play();
    }
  }

  void volumeUp() async {
    double currentVolume = (await FlutterVolumeController.getVolume()) ?? 0.0;
    double newVolume = (currentVolume + 0.1).clamp(0.0, 1.0);
    await FlutterVolumeController.setVolume(newVolume);
  }

  void volumeDown() async {
    double currentVolume = (await FlutterVolumeController.getVolume()) ?? 0.0;
    double newVolume = (currentVolume - 0.1).clamp(0.0, 1.0);
    await FlutterVolumeController.setVolume(newVolume);
  }
}
