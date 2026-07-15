import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';

/// Real camera for the AI Outfit Analyzer.
/// Live preview via `camera`; on capture → the Capture Preview screen.
/// (AI analysis is wired later when the OpenAI key is available.)
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _index = 0;
  bool _initializing = true;
  bool _gridOn = true;
  bool _flashOn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  Future<void> _setup() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _error = 'No camera found on this device.';
          _initializing = false;
        });
        return;
      }
      await _startController(_index);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not access the camera.\n$e';
          _initializing = false;
        });
      }
    }
  }

  Future<void> _startController(int index) async {
    final old = _controller;
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    await old?.dispose();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _index = index;
      _initializing = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startController(_index);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;
    try {
      final file = await c.takePicture();
      if (!mounted) return;
      context.push(Routes.capturePreview, extra: file);
    } catch (e) {
      _toast('Capture failed: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1440, imageQuality: 90);
    if (file == null || !mounted) return;
    context.push(Routes.capturePreview, extra: file);
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null || kIsWeb) return; // flash control unsupported on web
    try {
      final next = !_flashOn;
      await c.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => _flashOn = next);
    } catch (_) {
      _toast('Flash not supported on this camera');
    }
  }

  Future<void> _flip() async {
    if (_cameras.length < 2) return;
    setState(() => _initializing = true);
    await _startController((_index + 1) % _cameras.length);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(),
          if (_gridOn && _controller != null) const _GridOverlay(),
          _topBar(),
          _bottomControls(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_error != null || _controller == null) {
      return _cameraUnavailable();
    }
    return Center(
      child: CameraPreview(_controller!),
    );
  }

  Widget _cameraUnavailable() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_rounded, color: Colors.white38, size: 72),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Camera unavailable',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Choose from Gallery'),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _circleButton(
              icon: Icons.close_rounded,
              onTap: () => context.canPop() ? context.pop() : context.go(Routes.home),
            ),
            Row(
              children: [
                if (!kIsWeb)
                  _circleButton(
                    icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    active: _flashOn,
                    onTap: _toggleFlash,
                  ),
                const SizedBox(width: 8),
                _circleButton(
                  icon: Icons.grid_3x3_rounded,
                  active: _gridOn,
                  onTap: () => setState(() => _gridOn = !_gridOn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomControls() {
    final ready = _controller != null && _controller!.value.isInitialized;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _circleButton(icon: Icons.photo_library_rounded, onTap: _pickFromGallery),
              _ShutterButton(onTap: ready ? _capture : null),
              _circleButton(
                icon: Icons.cameraswitch_rounded,
                onTap: _cameras.length > 1 ? _flip : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback? onTap, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: onTap == null ? Colors.white38 : Colors.white, size: 22),
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter(), child: const SizedBox.expand());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 0.6;
    for (var i = 1; i < 3; i++) {
      final dx = size.width / 3 * i;
      final dy = size.height / 3 * i;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
