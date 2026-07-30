import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/admin_service.dart';
import 'admin_scaffold.dart';

/// AI Trend Tuning (Module 5): adjust the Fit Score factor weights. The backend
/// normalises them to sum to 100%, so the sliders are relative — the live
/// percentage shows each factor's share of the total.
class AdminWeightsTab extends ConsumerWidget {
  const AdminWeightsTab({super.key});

  static const _labels = {
    'trendMatch': 'Trend Match',
    'colorHarmony': 'Color Harmony',
    'styleConsistency': 'Style Consistency',
    'silhouetteBalance': 'Silhouette Balance',
    'accessories': 'Accessories',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminAsync<Map<String, num>>(
      value: ref.watch(adminFitWeightsProvider),
      onRetry: () => ref.invalidate(adminFitWeightsProvider),
      builder: (weights) => _Editor(initial: weights, labels: _labels),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.initial, required this.labels});
  final Map<String, num> initial;
  final Map<String, String> labels;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late Map<String, double> _values;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Stored as fractions (0.30…); edit on a 0–100 scale for finer control.
    _values = {
      for (final e in widget.initial.entries) e.key: e.value.toDouble() * 100,
    };
  }

  double get _total =>
      _values.values.fold(0.0, (sum, v) => sum + v).clamp(0.0001, double.infinity);

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Send raw values; the backend normalises to sum 1.0.
      await ref.read(adminRepoProvider).saveFitWeights(
            _values.map((k, v) => MapEntry(k, v)),
          );
      ref.invalidate(adminFitWeightsProvider);
      messenger
          .showSnackBar(const SnackBar(content: Text('Weights saved ✨')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Adjust how much each factor counts toward the Fit Score. Shares are '
          'shown as a percentage of the total and always add up to 100%.',
          style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 20),
        AdminCard(
          child: Column(
            children: [
              for (final key in widget.labels.keys)
                _Row(
                  label: widget.labels[key]!,
                  value: _values[key]!,
                  share: _values[key]! / _total,
                  onChanged: (v) => setState(() => _values[key] = v),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save Weights'),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.share,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double share;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              Text('${(share * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          Slider(
            value: value.clamp(0, 100),
            max: 100,
            activeColor: AppColors.ink,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
