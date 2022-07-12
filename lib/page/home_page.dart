import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:sound_stream/sound_stream.dart';
import 'package:speech_to_text_example/api/speech_api.dart';
import 'package:speech_to_text_example/main.dart';
import 'package:speech_to_text_example/widget/substring_highlighted.dart';

import '../utils.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
  //
}

class _HomePageState extends State<HomePage> {
  String text = 'Press the button and start speaking';
  bool isListening = false;

  RecorderStream _recorder = RecorderStream();
  PlayerStream _player = PlayerStream();

  List<Uint8List> _micChunks = [];
  bool _isRecording = false;
  bool _isPlaying = false;

  StreamSubscription _recorderStatus;
  StreamSubscription _playerStatus;
  StreamSubscription _audioStream;

  @override
  void initState() {
    super.initState();
    initPlugin();
  }

  @override
  void dispose() {
    _recorderStatus?.cancel();
    _playerStatus?.cancel();
    _audioStream?.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlugin() async {
    _recorderStatus = _recorder.status.listen((status) {
      if (mounted)
        setState(() {
          _isRecording = status == SoundStreamStatus.Playing;
        });
    });

    _audioStream = _recorder.audioStream.listen((data) {
      if (_isPlaying) {
        _player.writeChunk(data);
      } else {
        _micChunks.add(data);
      }
    });

    _playerStatus = _player.status.listen((status) {
      if (mounted)
        setState(() {
          _isPlaying = status == SoundStreamStatus.Playing;
        });
    });

    await Future.wait([
      _recorder.initialize(),
      _player.initialize(),
    ]);
  }

  void _play() async {
    await _player.start();

    if (_micChunks.isNotEmpty) {
      for (var chunk in _micChunks) {
        await _player.writeChunk(chunk);
      }
      _micChunks.clear();
    }
  }

  void _start() async {
    await _recorder.start();
  }

  void _stop() async {
    await _recorder.stop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(MyApp.title),
          centerTitle: true,
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.content_copy),
                onPressed: () async {
                  await FlutterClipboard.copy(text);

                  Scaffold.of(context).showSnackBar(
                    SnackBar(content: Text('✓   Copied to Clipboard')),
                  );
                },
              ),
            ),
          ],
        ),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Thanhf"),
            Text("Thanhf"),
            Text("Thanhf"),
            Text("Thanhf")
          ],
        ),
        // Column(
        //   children: [
        //     SingleChildScrollView(
        //       reverse: true,
        //       padding: const EdgeInsets.all(30).copyWith(bottom: 150),
        //       child: SubstringHighlight(
        //         text: text,
        //         terms: Command.all,
        //         textStyle: TextStyle(
        //           fontSize: 32.0,
        //           color: Colors.black,
        //           fontWeight: FontWeight.w400,
        //         ),
        //         textStyleHighlight: TextStyle(
        //           fontSize: 32.0,
        //           color: Colors.red,
        //           fontWeight: FontWeight.w400,
        //         ),
        //       ),
        //     ),
        //     IconButton(
        //       iconSize: 96.0,
        //       icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
        //       onPressed: _isPlaying ? _player.stop : _play,
        //     ),
        //     // Row(
        //     //   mainAxisAlignment: MainAxisAlignment.spaceAround,
        //     //   children: [
        //     //     IconButton(
        //     //         iconSize: 96.0,
        //     //         icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
        //     //         onPressed: () {
        //     //           _isRecording ? _stop() : _start();
        //     //         }
        //     //         // _isRecording ? _recorder.stop : _recorder.start,
        //     //         ),
        //     //
        //     //   ],
        //     // ),
        //   ],
        // ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AvatarGlow(
          animate: isListening,
          endRadius: 75,
          glowColor: Theme.of(context).primaryColor,
          child: FloatingActionButton(
              child: Icon(isListening ? Icons.mic : Icons.mic_none, size: 36),
              onPressed: toggleRecording),
        ),
      );

  toggleRecording() {
    _isRecording ? _stop() : _start();
    SpeechApi.toggleRecording(
      onResult: (text) => setState(() => this.text = text),
      onListening: (isListening) {
        setState(() => this.isListening = isListening);

        if (!isListening) {
          Future.delayed(Duration(seconds: 1), () {
            Utils.scanText(text);
          });
        }
      },
    );
  }
}
