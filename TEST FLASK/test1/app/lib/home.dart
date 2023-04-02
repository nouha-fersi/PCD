import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final picker = ImagePicker();
  String url = 'http://192.168.100.37:5000/predict';
  var data;
  String output = 'Initial Output';

  Future<String> fetchdata(File imageFile) async {
    // Create a multipart request with the image file in the request body
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    // Send the request to the server
    var response = await request.send();

    // Check if the response was successful
    if (response.statusCode == 200) {
      // Decode the response JSON and extract the predicted label
      var decoded = await response.stream.bytesToString();
      final predictedLabel = jsonDecode(decoded)['label'];

      // Return the predicted label
      return predictedLabel.toString();
    } else {
      // If the response was not successful, throw an error
      throw Exception('Failed to fetch data');
    }
  }

  Future<void> _getImageAndPredict() async {
    // Get an image from the device's photo gallery
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Call the fetchdata method to get the predicted label
      try {
        output = await fetchdata(File(pickedFile.path));
      } catch (e) {
        // Handle any errors that occur during the fetch
        output = 'Error: $e';
      }
    } else {
      // If the user did not pick an image, set the output to an empty string
      output = '';
    }

    // Update the UI with the predicted label or an error message
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Simple Flask App')),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
                onPressed: () {
                  // Call the _getImageAndPredict method when the button is pressed
                  _getImageAndPredict();
                },
                child: Text(
                  'Pick Image',
                  style: TextStyle(fontSize: 20),
                )),
            Text(
              output,
              style: TextStyle(fontSize: 40, color: Colors.green),
            )
          ]),
        ),
      ),
    );
  }
}
