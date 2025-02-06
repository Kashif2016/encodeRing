import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart'; // Import the services package
import 'package:audio_player_app/screens/home_screen.dart'; // Import HomeScreen

class PlayAudioScreen extends StatefulWidget {
  final String audioId;
  final String imageUrl;
  final String audioUrl;

  const PlayAudioScreen({
    super.key,
    required this.audioId,
    required this.imageUrl,
    required this.audioUrl,
  });

  @override
  _PlayAudioScreenState createState() => _PlayAudioScreenState();
}

class _PlayAudioScreenState extends State<PlayAudioScreen> {
  late AudioPlayer _audioPlayer;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setFullScreenMode();
    _initAudioPlayer();
  }

  void _setFullScreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initAudioPlayer() async {
    await _audioPlayer.setUrl(widget.audioUrl);
    _audioPlayer.play();
    setState(() {
      _isPlaying = true;
    });

    _audioPlayer.durationStream.listen((duration) {
      setState(() {
        _duration = duration ?? Duration.zero;
      });
    });

    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _position = position;
      });
    });

    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _isCompleted = true;
        });
      } else if (playerState.playing) {
        setState(() {
          _isPlaying = true;
          _isCompleted = false;
        });
      } else {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Opacity(
              opacity: 0.2, // Set the opacity to 50%
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/defaultAudioImage.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image:
                              AssetImage('assets/images/defaultAudioImage.jpg'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      widget.audioId,
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    Slider(
                      value: _position.inSeconds.toDouble(),
                      max: _duration.inSeconds.toDouble(),
                      activeColor: Colors.white, // Set active color to white
                      inactiveColor: Colors
                          .white54, // Set inactive color to a lighter white
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal:
                              20.0), // Add padding to the left and right
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_isCompleted) {
                          _audioPlayer.seek(Duration.zero);
                          _audioPlayer.play();
                        } else if (_isPlaying) {
                          _audioPlayer.pause();
                        } else {
                          _audioPlayer.play();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Background color
                        foregroundColor: Colors.white, // Text color
                        padding: EdgeInsets.all(20), // Button padding
                        shape: CircleBorder(), // Circular shape
                      ),
                      child: Icon(
                        _isCompleted
                            ? Icons.replay
                            : (_isPlaying ? Icons.pause : Icons.play_arrow),
                        size: 40.0,
                        color: Colors.white, // Set icon color to white
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
