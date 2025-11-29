import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller; // Controls the camera preview & capture
  bool _isLoading = true; // Shows loading state during initialization
  String? _error; // Stores error message if something goes wrong

  @override
  void initState() {
    super.initState();
    _requestPermissionThenInit(); // Ask for camera permission first, then initialize camera
  }

  // Request camera permission, then initialize camera if granted
  Future<void> _requestPermissionThenInit() async {
    var status = await Permission.camera.request(); // Ask for camera access
    if (!status.isGranted) {
      setState(() {
        _error = "Camera permission denied"; // Permission denied
        _isLoading = false;
      });
      return;
    }
    _initCamera(); // Permission granted → initialize camera
  }

  // Initialize the camera and setup controller
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras(); // Get list of available cameras

      if (cameras.isEmpty) {
        setState(() {
          _error = "No camera found"; // No camera detected on device
          _isLoading = false;
        });
        return;
      }

      // Try to get the front camera, otherwise fallback to first camera
      final frontCam = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Create camera controller with high resolution and no audio
      _controller = CameraController(
        frontCam,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize(); // Initialize camera hardware

      if (mounted) {
        setState(() => _isLoading = false); // Camera ready → stop loading
      }
    } catch (e) {
      // Catch and show any camera initialization errors
      setState(() {
        _error = "Camera initialization failed: $e";
        _isLoading = false;
      });
    }
  }

  // Capture an image and return the file path back to previous screen
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final pic = await _controller!.takePicture(); // Capture the image
      Navigator.pop(context, pic.path); // Return the image path
    } catch (e) {
      // Show error message in a snackbar
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while camera is initializing
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show error message if camera fails or permission denied
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Scan ID & Face")),
      body: Center(
        child: !_controller!.value.isInitialized
            ? const Text("Camera not ready") // If controller failed
            : Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(
                    3.14159), // Mirror the front camera preview
                child: CameraPreview(_controller!), // Show camera feed
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture, // Capture button
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
