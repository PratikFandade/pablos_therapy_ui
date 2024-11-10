import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Session extends StatefulWidget {
  final String name;
  const Session({super.key, required this.name});

  @override
  SessionState createState() => SessionState();
}

class SessionState extends State<Session> {
  double _scaleFactor = 0.5;
  bool useMicInput = true;
  bool _isRecording = false;
  bool _isPlaying = false;
  final myRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  double volume = 0.0;
  double minVolume = -45.0;
  Timer? timer;
  var logger = Logger();
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8000/ws/chat'));
  }

  Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/myFile.m4a';
  }

  Future<void> requestPermissionAndStartRecording() async {
    if (await myRecorder.hasPermission()) {
      startRecording();
    } else {
      logger.e("Microphone Access is denied");
    }
  }

  Future<bool> startRecording() async {
    if (await myRecorder.hasPermission()) {
      if (!await myRecorder.isRecording()) {
        await myRecorder
        .startStream(RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          bitRate: 16000,
          numChannels: 1
        ))
        .then((stream) => stream.listen((audioChunk) {
          if (_channel != null) {
            _channel?.sink.add(audioChunk);
          }
        }));
        setState(() {
          _isRecording = true;
        });
      }
      startTimer();
      return true;
    } else {
      return false;
    }
  }

  Future<void> stopRecording() async {
    await myRecorder.stop();
    timer?.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> playAudio() async {
    final path = await getFilePath();
    await _audioPlayer.play(DeviceFileSource(path));

    setState(() {
      _isPlaying = true;
    });
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  startTimer() async {
    timer ??= Timer.periodic(
      const Duration(milliseconds: 50), (timer) => updateVolume());
  }

  updateVolume() async {
    Amplitude ampl = await myRecorder.getAmplitude();
    if (ampl.current > minVolume) {
      setState(() {
        volume = (ampl.current - minVolume) / minVolume;
        _scaleFactor = 0.5 - (volume * 1.25);
      });
    }
  }

  int volume0to(int maxVolumeToDisplay) {
    return (volume * maxVolumeToDisplay).round().abs();
  }

  @override
  void dispose() {
    timer?.cancel();
    myRecorder.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Session'),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: _scaleFactor,
                child: const SizedBox(
                  width: 300,
                  height: 300,
                  child: RiveAnimation.asset('images/pablo.riv'),
                ),
              ),
              Text(
                'Ye Sab Kuch Nai Hota h ${widget.name}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Padhle Chutiye! 😒',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                "VOLUME\n${volume0to(100)}",
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: _isRecording ? stopRecording : requestPermissionAndStartRecording,
                child: Text(_isRecording ? 'Stop Streaming' : 'Start Streaming'),
              ),
//              ElevatedButton(
//                onPressed: _isPlaying ? stopAudio : playAudio,
//                child: Text(_isPlaying ? 'Stop Playing' : 'Play'),
//              )
            ],
          ),
        ),
      ),
    );
  }
}

