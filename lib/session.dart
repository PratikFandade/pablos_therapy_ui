import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
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
  bool _isRecording = false;
  final myRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  double volume = 0.0;
  double minVolume = -45.0;
  Timer? timer;
  Timer? debounceTimer;
  final debounceDuration = Duration(milliseconds: 300);
  var logger = Logger();
  WebSocketChannel? _channel;
  late File _audioFile;
  Stream? broadcastStream;

  double vadThreshold = -35.0;
  bool isVoiceDetected = false;
  List<double> recentAmplitudes = [];
  final int maxSamples = 10;
  final int detectionDuration = 200;
  DateTime? speechStartTime;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    startTimer();
    requestPermissionAndStartRecording();
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8000/ws/chat'));
    broadcastStream = _channel?.stream.asBroadcastStream();
  }

  Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/myFile.wav';
  }

  Future<void> requestPermissionAndStartRecording() async {
    if (await myRecorder.hasPermission()) {
      await startRecording();
    } else {
      logger.e("Microphone Access is denied");
    }
  }

  Future<bool> startRecording() async {
    final path = await getFilePath();
    if (await myRecorder.hasPermission()) {
      if (!await myRecorder.isRecording()) {
        if(await File(path).exists()){
          File(path).delete();
        }
        await myRecorder.start(RecordConfig(encoder: AudioEncoder.wav), path: path);
        setState(() {
          _isRecording = true;
        });
      }
      return true;
    } else {
      return false;
    }
  }

  Future<void> stopRecording() async {
    await myRecorder.stop();
    final path = await getFilePath();
    File file = File(path);
    List<int> fileBytes = await file.readAsBytes();
    _channel!.sink.add(fileBytes);
    setState(() {
      _isRecording = false;
      isVoiceDetected = false;
    });
    listenWebSocket();
  }

  Future<void> listenWebSocket() async {
    broadcastStream?.listen(
      (data) {
        if (data is Uint8List) {
          _writeToFile(data);
        }
      },
      onError: (error) {
        print('WebSocket Error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );
  }

  String generateRandomString(int length) {
    const characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(length, (index) {
      int randomIndex = random.nextInt(characters.length);
      return characters[randomIndex];
    }).join();
  }

  Future<void> _writeToFile(Uint8List data) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/${generateRandomString(10)}.wav';

    _audioFile = File(filePath);
    await _audioFile.writeAsBytes(data);
    _playAudio();
  }

  Future<void> _playAudio() async {
    await _audioPlayer.play(DeviceFileSource(_audioFile.path));
    recentAmplitudes.clear();
    _audioPlayer.onPlayerComplete.listen((event) {
      requestPermissionAndStartRecording();
    });
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
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
    
    updateThreshold(ampl.current);

    if (ampl.current > vadThreshold) {
      speechStartTime ??= DateTime.now();

      if (DateTime.now().difference(speechStartTime!) >= Duration(milliseconds: detectionDuration) && !isVoiceDetected) {
        if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();

        debounceTimer = Timer(debounceDuration, () async {
          isVoiceDetected = true;
          await requestPermissionAndStartRecording();
        });
      }
    } else {
      speechStartTime = null;
      
      if (isVoiceDetected) {
        if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();

        debounceTimer = Timer(debounceDuration, () async {
          isVoiceDetected = false;
          await stopRecording();
        });
      }
    }
  }

  void updateThreshold(double newAmplitude) {
    const double multiplier = 0.075;

    // Add the new amplitude and ensure the list size does not exceed maxSamples
    recentAmplitudes.add(newAmplitude);
    if (recentAmplitudes.length > maxSamples) {
      recentAmplitudes.removeAt(0); // Remove the oldest element if size exceeds maxSamples
    }

    // Calculate threshold only when recentAmplitudes is full
    if (recentAmplitudes.length == maxSamples) {
      // Calculate the mean and standard deviation of recent amplitudes
      double mean = recentAmplitudes.reduce((a, b) => a + b) / recentAmplitudes.length;
      double variance = recentAmplitudes
          .map((value) => (value - mean) * (value - mean))
          .reduce((a, b) => a + b) / recentAmplitudes.length;
      double stddev = sqrt(variance);

      // Update the adaptive threshold
      vadThreshold = mean - (multiplier * stddev);
    }
  }

  int volume0to(int maxVolumeToDisplay) {
    return (volume * maxVolumeToDisplay).round().abs();
  }

  @override
  void dispose() {
    timer?.cancel();
    debounceTimer?.cancel();
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
              ElevatedButton(
                onPressed: _isRecording ? stopRecording : requestPermissionAndStartRecording,
                child: Text(_isRecording ? 'Stop Streaming' : 'Start Streaming'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

