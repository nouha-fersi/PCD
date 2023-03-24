import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'dart:io';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'TEST'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
   late AudioPlayer player;
  bool _isAudioPlayed = false;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
  }
 @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      
      onTap: () {
         if (!_isAudioPlayed){
          
        player.play(AssetSource('nou.mp3'));
        setState(() {
            _isAudioPlayed = true; // set flag to true
          });
          
        }
        else {
            player.stop();
             Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CameraApp()),
          );
          }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SafeArea(
          child: Center(
            child: Text('click'),
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
  late CameraController _controller;

  @override
  void initState() {
    super.initState();
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
      body: Stack(children: [
        Container(
          height: double.infinity,
          child: CameraPreview(_controller),
        ),
        Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              
              Center(
                child: Container(
                  margin: EdgeInsets.all(20.0),
                  child: MaterialButton(
                    onPressed: () async {
                    if (!_controller.value.isInitialized) {
                      return null;
                    }
                    if (_controller.value.isTakingPicture) {
                      return null;
                    }
                    try {
                      await _controller.setFlashMode(FlashMode.auto);
                      XFile file = await _controller.takePicture();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ImagePreview(file)));
                    } on CameraException catch (e) {
                      debugPrint('Error occured while taking pic ');
                      return null;
                    }
                  },
                  color: Colors.white,
                  child: Text('take'),
                  ),
                ),
              )
            ]),
      ]),
    );
  }
}
class ImagePreview extends StatefulWidget {
  ImagePreview(this.file, {super.key});
  XFile file;

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
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
