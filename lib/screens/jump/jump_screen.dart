import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/jump_model.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/progress_chart.dart';

class JumpScreen extends StatelessWidget {
  const JumpScreen({super.key});

  Future<void> _showManualJumpSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ManualJumpSheet(),
    );
  }

  Future<void> _startCamera(BuildContext context) async {
    final result = await Navigator.of(context).push<JumpModel>(
      MaterialPageRoute(builder: (_) => const JumpCameraScreen()),
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI jump recorded: ${result.heightCm.toStringAsFixed(1)} cm')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        final chartValues = app.jumpRecords.reversed.map((e) => e.heightCm).toList();
        final chartDates = app.jumpRecords.reversed.map((e) => e.timestamp).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Vertical Jump')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              GlowCard(
                accent: AppTheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jump Measurement', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                      'Measure vertical jump with AI pose detection or log jumps manually when you only have the result value.',
                      style: TextStyle(color: AppTheme.subtleText),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _startCamera(context),
                            icon: const Icon(Icons.videocam_rounded),
                            label: const Text('AI Camera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showManualJumpSheet(context),
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Manual Entry'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4,
                children: [
                  _JumpStat(label: 'Best Jump', value: '${app.bestJumpCm.toStringAsFixed(1)} cm'),
                  _JumpStat(label: 'Average Jump', value: '${app.averageJumpCm.toStringAsFixed(1)} cm'),
                  _JumpStat(label: 'Entries', value: app.jumpRecords.length.toString()),
                  _JumpStat(label: '4-Week Trend', value: '${app.jumpImprovementLast4Weeks.toStringAsFixed(1)} cm'),
                ],
              ),
              const SizedBox(height: 16),
              GlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ProgressChart(values: chartValues, dates: chartDates),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Jump History', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (app.jumpRecords.isEmpty)
                const GlowCard(
                  child: Text(
                    'No jump attempts recorded yet. Add a manual jump or run the AI camera workflow.',
                    style: TextStyle(color: AppTheme.subtleText),
                  ),
                )
              else
                ...app.jumpRecords.map((jump) => _JumpTile(jump: jump)),
            ],
          ),
        );
      },
    );
  }
}

class _JumpStat extends StatelessWidget {
  const _JumpStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.subtleText)),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _JumpTile extends StatelessWidget {
  const _JumpTile({required this.jump});

  final JumpModel jump;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: jump.method == 'ai' ? AppTheme.primary.withOpacity(0.15) : AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              jump.method == 'ai' ? Icons.auto_fix_high_rounded : Icons.straighten_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${jump.heightCm.toStringAsFixed(1)} cm', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${jump.method.toUpperCase()} • airtime ${jump.airtimeSeconds.toStringAsFixed(2)} s',
                  style: const TextStyle(color: AppTheme.subtleText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualJumpSheet extends StatefulWidget {
  const _ManualJumpSheet();

  @override
  State<_ManualJumpSheet> createState() => _ManualJumpSheetState();
}

class _ManualJumpSheetState extends State<_ManualJumpSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final height = double.tryParse(_controller.text.trim());
    if (height == null || height <= 0) return;
    await context.read<AppState>().addManualJump(height);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manual Jump Entry', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Jump height (cm)'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _save, child: const Text('Save Jump')),
          ),
        ],
      ),
    );
  }
}

class JumpCameraScreen extends StatefulWidget {
  const JumpCameraScreen({super.key});

  @override
  State<JumpCameraScreen> createState() => _JumpCameraScreenState();
}

class _JumpCameraScreenState extends State<JumpCameraScreen> {
  CameraController? _controller;
  bool _ready = false;
  bool _recording = false;
  bool _analyzing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera available on this device.');
        return;
      }

      CameraDescription selected = cameras.first;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selected = camera;
          break;
        }
      }

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (error) {
      setState(() => _error = 'Camera initialization failed: $error');
    }
  }

  Future<void> _toggleRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      if (!_recording) {
        await controller.prepareForVideoRecording();
        await controller.startVideoRecording();
        setState(() => _recording = true);
      } else {
        final file = await controller.stopVideoRecording();
        setState(() {
          _recording = false;
          _analyzing = true;
        });
        final jump = await context.read<AppState>().addAiJumpFromVideo(file.path);
        if (!mounted) return;
        setState(() => _analyzing = false);
        if (jump != null) {
          Navigator.pop(context, jump);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to analyze jump video. Try again with better lighting.')),
          );
        }
      }
    } catch (error) {
      setState(() {
        _recording = false;
        _analyzing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $error')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.read<AppState>().jumpAiService.progress;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('AI Jump Measurement')),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
          : !_ready || _controller == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    Center(child: CameraPreview(_controller!)),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Record a full-body side view. Start before takeoff and stop after landing.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _analyzing ? null : _toggleRecording,
                            icon: Icon(_recording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded),
                            label: Text(_recording ? 'Stop & Analyze' : 'Start Recording'),
                          ),
                        ),
                      ),
                    ),
                    if (_analyzing)
                      Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                          child: ValueListenableBuilder<double>(
                            valueListenable: progress,
                            builder: (context, value, _) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: CircularProgressIndicator(value: value > 0 ? value : null),
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Analyzing jump… ${(value * 100).toStringAsFixed(0)}%'),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
