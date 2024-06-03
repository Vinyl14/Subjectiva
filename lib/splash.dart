import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.isNotEmpty ? cameras.first : null;
  runApp(FigmaToCodeApp(camera: firstCamera));
}

class FigmaToCodeApp extends StatelessWidget {
  final CameraDescription? camera;

  const FigmaToCodeApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      home: camera == null ? NoCameraScreen() : SplashScreen(camera: camera!),
    );
  }
}

class NoCameraScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'No camera available',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final CameraDescription camera;

  SplashScreen({required this.camera});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  final int _numPages = 2;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startPageViewTimer();
  }

  void _startPageViewTimer() {
    Future.delayed(Duration(seconds: 2)).then((_) {
      if (_currentPage < _numPages - 1) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startPageViewTimer();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainAppScreen(camera: widget.camera)),
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          SplashScreenPage5(),
          SplashScreenPage6(),
        ],
      ),
    );
  }
}

class SplashScreenPage5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: Color(0xFF8AC926)),
    );
  }
}

class SplashScreenPage6 extends StatefulWidget {
  @override
  _SplashScreenPage6State createState() => _SplashScreenPage6State();
}

class _SplashScreenPage6State extends State<SplashScreenPage6> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _positionAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: Color(0xFF8AC926)),
      child: Stack(
        children: [
          Center(
            child: SlideTransition(
              position: _positionAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Text(
                  'Subjektiva',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MainAppScreen extends StatefulWidget {
  final CameraDescription camera;

  MainAppScreen({required this.camera});

  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> with TickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  String _text = '';
  String _analysis = '';
  bool _showAnalysis = false;
  bool _flashOn = false;
  late AnimationController _animationController;
  Offset _topLeft = Offset(100, 100);
  Offset _topRight = Offset(300, 100);
  Offset _bottomLeft = Offset(100, 300);
  Offset _bottomRight = Offset(300, 300);
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
  }

  Future<void> _processImage() async {
    try {
      await _initializeControllerFuture;
      if (_flashOn) {
        await _controller.setFlashMode(FlashMode.torch);
      }
      final image = await _controller.takePicture();
      if (_flashOn) {
        await _controller.setFlashMode(FlashMode.off);
      }
      setState(() {
        _capturedImage = File(image.path);
      });
      final croppedImage = await _cropImage(File(image.path));
      final response = await _uploadImage(croppedImage);
      setState(() {
        _text = response['text'];
        _analysis = response['analysis'];
        _showAnalysis = true;
      });
      _animationController.forward();
    } catch (e) {
      print('Error: $e');
      setState(() {
        _showAnalysis = true;
        _text = 'Error';
        _analysis = e.toString();
      });
      _animationController.forward();
    }
  }

  Future<File> _cropImage(File imageFile) async {
    final originalImage = await decodeImageFromList(imageFile.readAsBytesSync());
    final scaleX = originalImage.width / _controller.value.previewSize!.width;
    final scaleY = originalImage.height / _controller.value.previewSize!.height;
    final cropRect = Rect.fromLTRB(
      _topLeft.dx * scaleX,
      _topLeft.dy * scaleY,
      _bottomRight.dx * scaleX,
      _bottomRight.dy * scaleY,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();
    canvas.drawImageRect(
      originalImage,
      cropRect,
      Rect.fromLTWH(0, 0, cropRect.width, cropRect.height),
      paint,
    );

    final croppedImage = await recorder.endRecording().toImage(
      cropRect.width.toInt(),
      cropRect.height.toInt(),
    );
    final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final croppedFile = File('${tempDir.path}/cropped_image.png');
    await croppedFile.writeAsBytes(buffer);
    return croppedFile;
  }

  Future<Map<String, dynamic>> _uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.249.225:5001/process-image'), // Update with your server IP and port
      )
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path))
        ..headers.addAll({
          "Content-Type": "multipart/form-data",
        });

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));

      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        return json.decode(response.body);
      } else {
        final response = await http.Response.fromStream(streamedResponse);
        print('Server Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to process image');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to connect to the server');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121F2F),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Main Menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _flashOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.green,
                        ),
                        onPressed: () {
                          setState(() {
                            _flashOn = !_flashOn;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Camera Preview or Captured Image
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _capturedImage == null
                        ? Stack(
                      children: [
                        FutureBuilder<void>(
                          future: _initializeControllerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              return CameraPreview(_controller);
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        ),
                        // Bounding Box
                        CustomPaint(
                          painter: BoundingBoxPainter(
                            topLeft: _topLeft,
                            topRight: _topRight,
                            bottomLeft: _bottomLeft,
                            bottomRight: _bottomRight,
                          ),
                          child: Container(),
                        ),
                        // Top Left Handle
                        Positioned(
                          left: _topLeft.dx - 10,
                          top: _topLeft.dy - 10,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _topLeft += details.delta;
                                _topRight = Offset(_topRight.dx, _topLeft.dy);
                                _bottomLeft = Offset(_topLeft.dx, _bottomLeft.dy);
                              });
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        // Top Right Handle
                        Positioned(
                          left: _topRight.dx - 10,
                          top: _topRight.dy - 10,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _topRight += details.delta;
                                _topLeft = Offset(_topLeft.dx, _topRight.dy);
                                _bottomRight = Offset(_topRight.dx, _bottomRight.dy);
                              });
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        // Bottom Left Handle
                        Positioned(
                          left: _bottomLeft.dx - 10,
                          top: _bottomLeft.dy - 10,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _bottomLeft += details.delta;
                                _topLeft = Offset(_bottomLeft.dx, _topLeft.dy);
                                _bottomRight = Offset(_bottomRight.dx, _bottomLeft.dy);
                              });
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        // Bottom Right Handle
                        Positioned(
                          left: _bottomRight.dx - 10,
                          top: _bottomRight.dy - 10,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _bottomRight += details.delta;
                                _topRight = Offset(_bottomRight.dx, _topRight.dy);
                                _bottomLeft = Offset(_bottomLeft.dx, _bottomRight.dy);
                              });
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    )
                        : Image.file(_capturedImage!),
                  ),
                ),
                // Camera Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FloatingActionButton(
                    onPressed: _processImage,
                    child: Icon(Icons.camera_alt),
                    backgroundColor: Colors.green,
                  ),
                ),
                // Bottom Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Icon(Icons.list, color: Colors.white, size: 36),
                      Icon(Icons.school, color: Colors.white, size: 36),
                      Icon(Icons.camera_alt, color: Colors.white, size: 36),
                      Icon(Icons.assignment, color: Colors.white, size: 36),
                    ],
                  ),
                ),
              ],
            ),
            if (_showAnalysis)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0)).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Text Analysis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          _text,
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          _analysis,
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 8.0),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _showAnalysis = false;
                                _capturedImage = null;
                              });
                              _animationController.reverse();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;

  BoundingBoxPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
