import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import 'data/analysis_service.dart';

/// Runs the real AI analysis on the captured photo, then routes to the result.
///
/// Follows the design: cream canvas, the captured photo inside a soft purple
/// orbit, a percentage, and a checklist that ticks off as the analysis runs.
class AnalyzingScreen extends ConsumerStatefulWidget {
  const AnalyzingScreen({super.key, required this.file});
  final XFile file;

  @override
  ConsumerState<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends ConsumerState<AnalyzingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progress;
  late final AnimationController _orbit;
  late Future<Uint8List> _bytes;
  String? _error;

  /// Checklist labels and the percentage at which each one is marked done.
  static const _steps = <({String label, double at})>[
    (label: 'Detecting Clothes', at: 0.25),
    (label: 'Analyzing Colors', at: 0.50),
    (label: 'Checking Style', at: 0.72),
    (label: 'Calculating Score', at: 0.90),
  ];

  @override
  void initState() {
    super.initState();
    _bytes = widget.file.readAsBytes();
    // Creeps toward 95% while we wait; jumps to 100% when the result lands.
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
      upperBound: 0.95,
    )..forward();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _run();
  }

  Future<void> _run() async {
    try {
      final analysis =
          await ref.read(analysisServiceProvider).analyze(widget.file);
      if (!mounted) return;
      context.pushReplacement(Routes.analysisResult, extra: analysis);
    } catch (e) {
      if (mounted) setState(() => _error = _clean('$e'));
    }
  }

  /// Strips the exception/JSON wrapping so the user sees a readable message.
  String _clean(String raw) {
    final match = RegExp(r'"error"\s*:\s*"([^"]+)"').firstMatch(raw);
    if (match != null) return match.group(1)!;
    return raw.replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _progress.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _error == null ? _loading() : _errorView(),
        ),
      ),
    );
  }

  Widget _loading() {
    return Column(
      children: [
        const Spacer(),
        const Text(
          'Analyzing your\noutfit…',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const Spacer(),
        AnimatedBuilder(
          animation: Listenable.merge([_progress, _orbit]),
          builder: (context, _) {
            return Column(
              children: [
                SizedBox(
                  width: 200,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: FutureBuilder<Uint8List>(
                          future: _bytes,
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return const SizedBox(width: 150, height: 200);
                            }
                            return Opacity(
                              opacity: 0.55,
                              child: Image.memory(
                                snap.data!,
                                width: 150,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                      // Purple orbit ring sweeping around the figure.
                      Transform.rotate(
                        angle: _orbit.value * 6.283,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0015)
                            ..rotateX(1.15),
                          child: Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.55),
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${(_progress.value * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            );
          },
        ),
        const Spacer(),
        AnimatedBuilder(
          animation: _progress,
          builder: (context, _) => Column(
            children: [
              for (final s in _steps)
                _StepRow(label: s.label, done: _progress.value >= s.at),
            ],
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _errorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.inkMuted, size: 56),
        const SizedBox(height: 16),
        const Text(
          'Analysis failed',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _error ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go(Routes.home),
                child: const Center(child: Text('Back')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _error = null);
                  _progress
                    ..reset()
                    ..forward();
                  _run();
                },
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One checklist row — muted with a spinner until done, then ink with a tick.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.primary : AppColors.line,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: done ? FontWeight.w500 : FontWeight.w400,
                color: done ? AppColors.ink : AppColors.inkMuted,
              ),
            ),
          ),
          if (done)
            const Icon(Icons.check_rounded,
                size: 18, color: AppColors.primary)
          else
            const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                valueColor: AlwaysStoppedAnimation(AppColors.inkMuted),
              ),
            ),
        ],
      ),
    );
  }
}
