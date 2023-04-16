import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MaterialApp(
    home: MyHomePage(),
  ));
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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AudioCache audioCache1 =
      AudioCache(); // variable which state is going to change
  AudioPlayer audioPlayer1 = AudioPlayer();
  bool isAudioPlayed = true;

  @override
  void initState() {
    super.initState();
    playAudio();
  }

  void playAudio() async {
    audioPlayer1 = await audioCache1.play('Voix.m4a');
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
            MaterialPageRoute(builder: (context) => const CameraApp()),
          );
        },
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/money.jpg'),
              fit: BoxFit.fill,
            ),
          ),
          child: Stack(
            // ignore: prefer_const_literals_to_create_immutables
            children: [
              const Positioned(
                top: 340,
                bottom: 100,
                left: 150,
                right: 90,
                child: Text(
                  'tap anywhere ',
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
  AudioCache audioCache2 =
      AudioCache(); // variable which state is going to change
  AudioPlayer audioPlayer2 = AudioPlayer();
  bool isAudioPlayed = true;
  late CameraController _controller;
  void playAudio2() async {
    audioPlayer2 = await audioCache2.play('sound3.mp3');
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
            return;
          }
          if (_controller.value.isTakingPicture) {
            return;
          }
          try {
            await _controller.setFlashMode(FlashMode.auto);
            XFile file = await _controller.takePicture();
            // ignore: use_build_context_synchronously
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ImagePreview(file)));
          } on CameraException catch (e) {
            debugPrint('Error occured while taking pic ');
            return;
          }
        },
        child: CameraPreview(_controller),
      ),
    );
  }
}

// ignore: must_be_immutable
class ImagePreview extends StatefulWidget {
  ImagePreview(this.file, {super.key});
  XFile file;

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}
class _ImagePreviewState extends State<ImagePreview> {
  String url = 'http://192.168.1.14:5000/predict';
  Future<String> fetchdata(File imageFile) async {
    // Create a multipart request with the image file in the request body
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    // Send the request to the server
    var response = await request.send();

    // Check if the response was successful
    if (response.statusCode == 200) {
      // Decode the response JSON and extract the predicted label
      var decoded = await response.stream.bytesToString();
      final predictedLabel = jsonDecode(decoded)['prediction'];

      // Return the predicted label
      return predictedLabel.toString();
    } else {
      // If the response was not successful, throw an error
      throw Exception('Failed to fetch data');
    }
  }

  AudioCache audioCache3 = AudioCache();
  AudioPlayer audioPlayer3 = AudioPlayer();
  void playAudio3() async {
    audioPlayer3 = await audioCache3.play('sound3.mp3');
  }

  @override
  Widget build(BuildContext context) {
    File picture = File(widget.file.path);
    String output = 'Initial Output';
    FlutterTts flutterTts = FlutterTts();
    flutterTts.setLanguage("ar");
    Future<String> _getImageAndPredict() async {
      // Get an image from the device's photo gallery

      if (picture != null) {
        // Call the fetchdata method to get the predicted label
        try {
          output = await fetchdata(File(widget.file.path));
        } catch (e) {
          // Handle any errors that occur during the fetch
          output = 'Error: $e';
        }
      } else {
        // If the user did not pick an image, set the output to an empty string
        output = '';
      }
      return output;
      // Update the UI with the predicted label or an error message
      setState(() {});
    }

    @override
    void initState() {
      super.initState();
      playAudio3();
      _getImageAndPredict;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your Photo')),
      body: Column(
        children: [
          Expanded(
            child: Image.file(
              picture,
              fit: BoxFit.fitWidth,
            ),
          ),
          FutureBuilder<String>(
              future: _getImageAndPredict(),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  String ttsText = snapshot.data ?? ""; // Get the data from snapshot or use empty string if null
                  flutterTts.speak(ttsText); // Use flutterTts to speak the text
                  return Text(ttsText);
                } else {
                  return Text(output);
                }
              }),
        ],
      ),
    );
  }
}

