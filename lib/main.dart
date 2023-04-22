import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:video_player/video_player.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/animation.dart';
import 'dart:async';
import 'dart:math' as math ;
double percentage = 0.0;
const double pi = 3.14159265358979323846;
Color beige = Color(0xFFF5F5DC);



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
  late VideoPlayerController _controller1;
  late Future<void> _initializeVideoPlayerFuture;
  FlutterTts flutterTts1 = FlutterTts();
  String ttsText1 = "yorja annakr ala ayi makan fi achacha li fateh al camera ";
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _controller1 = VideoPlayerController.asset('assets/video.mp4');
    _initializeVideoPlayerFuture = _controller1.initialize();
    _controller1.setLooping(true);
    _controller1.play();
    speak();
  }

  void speak() async {
    await flutterTts1.setLanguage("ar");
    await flutterTts1.setPitch(1);
    await flutterTts1.setSpeechRate(0.5);
    const duration = Duration(seconds: 6);
    await flutterTts1.speak(ttsText1);
    _timer = Timer.periodic(duration, (_) {
      if (mounted) {
        flutterTts1.speak(ttsText1);
      }
    });

  }

  @override
  void dispose() {
    _controller1.dispose();
    flutterTts1.stop();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          flutterTts1.stop();
          _timer?.cancel();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraApp()),
          );
        },
        child: SizedBox.expand(
          child: FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller1.value.size?.width ?? 0,
                    height: _controller1.value.size?.height ?? 0,
                    child: VideoPlayer(_controller1),
                  ),
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
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
  FlutterTts flutterTts2 = FlutterTts();
  String ttsText2 = "yorja annakr ala ayi makan fi achacha li fateh al camera ";
  Timer? _timer2;
  late CameraController _controller;
  void speak2() async {
    await flutterTts2.setLanguage("ar");
    await flutterTts2.setPitch(1);
    await flutterTts2.setSpeechRate(0.5);
    const duration = Duration(seconds: 6);
    await flutterTts2.speak(ttsText2);
    _timer2 = Timer.periodic(duration, (_) {
      if (mounted) {
        flutterTts2.speak(ttsText2);
      }
    });

  }

  @override
  void initState() {
    super.initState();
    speak2();
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
  void dispose() {
    flutterTts2.stop();
    _timer2?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () async {
          flutterTts2.stop();
          _timer2?.cancel();
          if (!_controller.value.isInitialized) {
            return;
          }
          if (_controller.value.isTakingPicture) {
            return;
          }
          try {
            await _controller.setFlashMode(FlashMode.off);
            XFile file = await _controller.takePicture();
            // ignore: use_build_context_synchronously
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ImagePreview(file)));
          } on CameraException catch (e) {
            debugPrint('Error occured while taking pic ');
            return;
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(_controller),
        ),
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
class _ImagePreviewState extends State<ImagePreview> with TickerProviderStateMixin {
  final double angle = 2 * math.pi * percentage;
  bool _isImageTapped = false;
  late String output;
  String url = 'http://192.168.1.21:5000/predict';

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

      _getImageAndPredict;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: beige,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 550, // adjust this value to get the desired height
              child: AnimatedContainer(
                duration: Duration(milliseconds: 1000),
                transform: Matrix4.identity()
                  ..scale(_isImageTapped ? 1.5 : 1.0)
                  ..rotateZ(_isImageTapped ? 0.25 * pi : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.file(
                    picture,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<String>(
                future: _getImageAndPredict(),
                builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    String ttsText = snapshot.data ?? ""; // Get the data from snapshot or use empty string if null
                    flutterTts.speak(ttsText); // Use flutterTts to speak the text
                    return AnimatedOpacity(
                      duration: Duration(milliseconds: 500),
                      opacity: 1,
                      child: Text(
                        ttsText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    );
                  } else {
                    return Text(
                      output,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );

  }
}






