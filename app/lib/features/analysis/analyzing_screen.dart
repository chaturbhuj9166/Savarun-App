import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import 'data/analysis_service.dart';

/// Runs the real AI analysis on the captured photo, then routes to the result.
class AnalyzingScreen extends ConsumerStatefulWidget {
  const AnalyzingScreen({super.key, required this.file});
  final XFile file;

  @override
  ConsumerState<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends ConsumerState<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  String? _error;

  static const _steps = [
    'Detecting clothing items…',
    'Reading color palette…',
    'Analyzing fit & silhouette…',
    'Matching trends…',
    'Building your Style DNA…',
  ];
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _cycleSteps();
    _run();
  }

  Future<void> _cycleSteps() async {
    while (mounted && _error == null) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _step = (_step + 1) % _steps.length);
    }
  }

  Future<void> _run() async {
    try {
      final analysis = await ref.read(analysisServiceProvider).analyze(widget.file);
      if (!mounted) return;
      context.pushReplacement(Routes.analysisResult, extra: analysis);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Center(
            child: _error == null ? _loading() : _errorView(),
          ),
        ),
      ),
    );
  }

  Widget _loading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotationTransition(
          turns: _spin,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 3)),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 48),
          ),
        ),
        const SizedBox(height: 40),
        const Text('Analyzing your outfit', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(_steps[_step], key: ValueKey(_step), style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _errorView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          const Text('Analysis failed', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(_error ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _step = 0;
                    });
                    _cycleSteps();
                    _run();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
