import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'dart:io';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MaterialApp(
    home: MyHomePage(),
  ));
}


class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AudioCache audioCache1= AudioCache();// variable which state is going to change
  AudioPlayer audioPlayer1 = AudioPlayer();
  bool isAudioPlayed = true;

  @override
  void initState() {
    super.initState();
    playAudio();
  }
  void playAudio() async {
    audioPlayer1= await audioCache1.play('Voix.m4a');
  }
  @override
  void dispose() {
    audioPlayer1.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: GestureDetector(
        onTap: () {
          audioPlayer1.stop();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CameraApp()),
          );
        },

        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/money.jpg'),
              fit: BoxFit.fill,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 340,
                bottom: 100,
                left: 150,
                right: 90,
                child: Text('tap anywhere ',
                  style: TextStyle(
                    fontSize: 60,
                    color: Colors.black,
                    fontFamily: 'Cursive',
                  ),
                ),
              ),
            ],

          ),
        ),
      ),
    );

  }
}
class CameraApp extends StatefulWidget {
  const CameraApp({super.key});

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  AudioCache audioCache2= AudioCache();// variable which state is going to change
  AudioPlayer audioPlayer2 = AudioPlayer();
  bool isAudioPlayed = true;
  late CameraController _controller;
  void playAudio2() async {
    audioPlayer2= await audioCache2.play('sound3.mp3');
  }

  @override
  void initState() {
    super.initState();
    playAudio2();
    _controller = CameraController(cameras[0], ResolutionPreset.max);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('access was denied');
            break;
          default:
            print(e.description);
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () async {
          audioPlayer2.stop();
          if (!_controller.value.isInitialized) {
            return null;}
          if (_controller.value.isTakingPicture) {
            return null;}
          try {
            await _controller.setFlashMode(FlashMode.auto);
            XFile file = await _controller.takePicture();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ImagePreview(file)));
          }
          on CameraException catch (e) {
            debugPrint('Error occured while taking pic ');
            return null;
          }
        },
        child: CameraPreview(_controller),

      ),);
  }}
class ImagePreview extends StatefulWidget {
  ImagePreview(this.file, {super.key});
  XFile file;

  @override
  State<ImagePreview> createState() => _ImagePreviewState();

}

class _ImagePreviewState extends State<ImagePreview> {
  AudioCache audioCache3= AudioCache();
  AudioPlayer audioPlayer3 = AudioPlayer();
  void playAudio3() async {
    audioPlayer3 = await audioCache3.play('sound3.mp3');
  }
  @override
  void initState(){
    super.initState();
    playAudio3();
  }

  @override
  Widget build(BuildContext context) {
    File picture = File(widget.file.path);
    return Scaffold(
      appBar: AppBar(title: Text('your photo')),
      body: Center(
          child: Image.file(picture)
      ),
    );
  }
}