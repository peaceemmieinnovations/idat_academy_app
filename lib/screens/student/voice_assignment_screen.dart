import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../theme/app_theme.dart';

class VoiceAssignmentScreen extends StatefulWidget {
  const VoiceAssignmentScreen({super.key});

  @override
  State<VoiceAssignmentScreen> createState() => _VoiceAssignmentScreenState();
}

class _VoiceAssignmentScreenState extends State<VoiceAssignmentScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _transcript = TextEditingController();
  bool _listening = false;
  bool _available = false;
  String _text = '';

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    setState(() => _available = available);
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Speech recognition is unavailable. Check microphone and speech permissions.'),
      ));
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (mounted) setState(() {
          _text = result.recognizedWords;
          _transcript.value = _transcript.value.copyWith(
            text: _text,
            selection: TextSelection.collapsed(offset: _text.length),
          );
        });
      },
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 5),
    );
  }

  void _submit() {
    if (_text.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Voice draft saved. It will be submitted when your assignment is ready.'),
    ));
  }

  @override
  void dispose() {
    _speech.stop();
    _transcript.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Voice Assignment')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(children: [
                Icon(Icons.mic_rounded, color: Colors.white, size: 42),
                SizedBox(height: 10),
                Text('Speak your answer', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('Your words are converted into an editable assignment draft.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 24),
            Center(child: Semantics(
              button: true,
              label: _listening ? 'Stop listening' : 'Start voice transcription',
              child: InkWell(
                onTap: _toggleListening,
                borderRadius: BorderRadius.circular(48),
                child: Ink(
                  width: 96, height: 96,
                  decoration: BoxDecoration(color: _listening ? AppColors.error : AppColors.secondary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: .3), blurRadius: 20)]),
                  child: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 40),
                ),
              ),
            )),
            const SizedBox(height: 12),
            Text(_listening ? 'Listening… tap to finish' : (_available ? 'Tap to continue speaking' : 'Tap to begin'), textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
            const SizedBox(height: 28),
            Text('Your transcript', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            TextField(
              controller: _transcript,
              onChanged: (value) => _text = value,
              minLines: 8,
              maxLines: 14,
              decoration: const InputDecoration(hintText: 'Your spoken answer will appear here. You can edit it before submitting.'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _text.trim().isEmpty ? null : _submit, icon: const Icon(Icons.save_rounded), label: const Text('Save assignment draft')),
          ],
        ),
      );
}
