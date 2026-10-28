import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ParsedVoiceLog {
  final String transcript;
  final int waterMl;
  final int workoutMinutes;
  final String workoutType;
  final double? expenseAmount;
  final String? expenseCategory;
  final String? moodKey;

  const ParsedVoiceLog({
    required this.transcript,
    this.waterMl = 0,
    this.workoutMinutes = 0,
    this.workoutType = '',
    this.expenseAmount,
    this.expenseCategory,
    this.moodKey,
  });

  bool get hasEntries =>
      waterMl > 0 ||
      workoutMinutes > 0 ||
      expenseAmount != null ||
      moodKey != null;

  static ParsedVoiceLog parse(String text) {
    final normalized = text.trim();
    final lower = normalized.toLowerCase();

    var waterMl = 0;
    final millilitres = RegExp(
      r'\b(\d+(?:\.\d+)?)\s*(?:ml|millilit(?:er|re)s?)\s*(?:of\s*)?water\b',
      caseSensitive: false,
    ).firstMatch(normalized);
    final glasses = RegExp(
      r'\b(\d+(?:\.\d+)?)\s*(?:glass(?:es)?|cups?)\s*(?:of\s*)?water\b',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (millilitres != null) {
      waterMl = double.parse(millilitres.group(1)!).round();
    } else if (glasses != null) {
      waterMl = (double.parse(glasses.group(1)!) * 250).round();
    }

    final workoutMatch = RegExp(
      r'\b(\d+)\s*(?:min(?:ute)?s?)\s*(?:of\s*)?(jog(?:ged|ging)?|run(?:ning)?|walk(?:ing)?|workout|cardio)\b|'
      r'\b(jog(?:ged|ging)?|run(?:ning)?|walk(?:ing)?|workout|cardio)\b[^0-9]{0,20}(\d+)\s*(?:min(?:ute)?s?)\b',
      caseSensitive: false,
    ).firstMatch(normalized);
    final workoutMinutes = workoutMatch == null
        ? 0
        : int.parse(workoutMatch.group(1) ?? workoutMatch.group(4)!);
    final workoutType = workoutMatch == null
        ? ''
        : (workoutMatch.group(2) ?? workoutMatch.group(3) ?? 'workout')
            .toLowerCase();

    final expenseMatch = RegExp(
      r'(?:[$€£₹]\s*((?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d{1,2})?)|'
      r'\b((?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d{1,2})?)\s*(?:dollars?|bucks|rupees?|euros?|pounds?)\b)',
      caseSensitive: false,
    ).firstMatch(normalized);
    final rawAmount = expenseMatch?.group(1) ?? expenseMatch?.group(2);
    final expenseAmount = rawAmount == null
        ? null
        : double.tryParse(rawAmount.replaceAll(',', ''));
    String? expenseCategory;
    if (expenseAmount != null) {
      if (RegExp(r'\b(lunch|breakfast|dinner|food|meal|coffee)\b')
          .hasMatch(lower)) {
        expenseCategory = 'Food';
      } else if (RegExp(r'\b(uber|taxi|bus|train|fuel|transport)\b')
          .hasMatch(lower)) {
        expenseCategory = 'Transport';
      } else if (RegExp(r'\b(shop|shopping|store)\b').hasMatch(lower)) {
        expenseCategory = 'Shopping';
      } else if (RegExp(r'\b(bill|rent|electricity)\b').hasMatch(lower)) {
        expenseCategory = 'Bills';
      } else {
        expenseCategory = 'Other';
      }
    }

    String? moodKey;
    if (RegExp(r'\b(anxious|anxiety|stressed|stressful|overwhelmed)\b')
        .hasMatch(lower)) {
      moodKey = 'low';
    } else if (RegExp(r'\b(sad|miserable|awful|terrible)\b').hasMatch(lower)) {
      moodKey = 'bad';
    } else if (RegExp(r'\b(happy|great|excited|wonderful)\b').hasMatch(lower)) {
      moodKey = 'great';
    } else if (RegExp(r'\b(calm|content|good|grateful)\b').hasMatch(lower)) {
      moodKey = 'good';
    } else if (RegExp(r'\b(okay|fine|neutral)\b').hasMatch(lower)) {
      moodKey = 'okay';
    }

    return ParsedVoiceLog(
      transcript: normalized,
      waterMl: waterMl,
      workoutMinutes: workoutMinutes,
      workoutType: workoutType,
      expenseAmount: expenseAmount,
      expenseCategory: expenseCategory,
      moodKey: moodKey,
    );
  }
}

class VoiceLogButton extends StatelessWidget {
  final Future<void> Function(ParsedVoiceLog log) onSave;

  const VoiceLogButton({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        icon: const Icon(Icons.mic_none_rounded),
        label: const Text('Speak a quick log'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _VoiceLogDialog(onSave: onSave),
        ),
      );
}

class _VoiceLogDialog extends StatefulWidget {
  final Future<void> Function(ParsedVoiceLog log) onSave;

  const _VoiceLogDialog({required this.onSave});

  @override
  State<_VoiceLogDialog> createState() => _VoiceLogDialogState();
}

class _VoiceLogDialogState extends State<_VoiceLogDialog> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _transcriptController = TextEditingController();
  bool _isListening = false;
  bool _isSaving = false;
  bool _speechAvailable = true;
  String? _errorMessage;

  ParsedVoiceLog get _parsed =>
      ParsedVoiceLog.parse(_transcriptController.text);

  @override
  void dispose() {
    _speech.cancel();
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    try {
      final available = await _speech.initialize(
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _errorMessage = error.errorMsg;
          });
        },
        onStatus: (status) {
          if (mounted && status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );
      if (!mounted) return;
      if (!available) {
        setState(() {
          _speechAvailable = false;
          _errorMessage =
              'Speech recognition is unavailable. You can type your log below.';
        });
        return;
      }

      setState(() {
        _errorMessage = null;
        _isListening = true;
      });
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _transcriptController.text = result.recognizedWords;
            _transcriptController.selection = TextSelection.collapsed(
              offset: _transcriptController.text.length,
            );
          });
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _speechAvailable = false;
        _errorMessage = 'Could not start speech recognition: $error';
      });
    }
  }

  Future<void> _save() async {
    final parsed = _parsed;
    if (!parsed.hasEntries || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(parsed);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Could not save this log: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsed;
    return AlertDialog(
      title: const Text('Voice stream'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Speak naturally, then check the extracted items before saving. Your audio is not saved by this app; speech recognition is provided by your device and may use its network service.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Water glasses/cups are estimated as 250 ml each.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _isSaving ? null : _toggleListening,
                icon:
                    Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded),
                label: Text(_isListening
                    ? 'Stop listening'
                    : _speechAvailable
                        ? 'Start speaking'
                        : 'Try speech again'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _transcriptController,
                onChanged: (_) => setState(() {}),
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Transcript (editable)',
                  hintText:
                      'e.g. Drank 2 glasses of water, jogged 20 minutes, spent \$14 on lunch, feeling anxious.',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 12),
              Text('Detected entries',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              ..._previewRows(parsed),
              if (!parsed.hasEntries)
                const Text('No supported entries detected yet.'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: parsed.hasEntries && !_isSaving ? _save : null,
          child: Text(_isSaving ? 'Saving…' : 'Save entries'),
        ),
      ],
    );
  }

  List<Widget> _previewRows(ParsedVoiceLog parsed) => [
        if (parsed.waterMl > 0)
          _preview(Icons.water_drop_outlined, 'Water', '+${parsed.waterMl} ml'),
        if (parsed.workoutMinutes > 0)
          _preview(Icons.directions_run_rounded, 'Exercise',
              '${parsed.workoutMinutes} min ${parsed.workoutType}'),
        if (parsed.expenseAmount != null)
          _preview(Icons.payments_outlined, 'Expense',
              '${parsed.expenseAmount!.toStringAsFixed(2)} · ${parsed.expenseCategory}'),
        if (parsed.moodKey != null)
          _preview(Icons.mood_outlined, 'Mood', parsed.moodKey!),
      ];

  Widget _preview(IconData icon, String title, String value) => ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(value),
      );
}
