import 'package:flutter/material.dart';

import '../models/day_signals.dart';
import '../services/app_scope.dart';
import '../services/day_signals_import_service.dart';

class DaySignalsImportScreen extends StatefulWidget {
  const DaySignalsImportScreen({super.key});

  @override
  State<DaySignalsImportScreen> createState() => _DaySignalsImportScreenState();
}

class _DaySignalsImportScreenState extends State<DaySignalsImportScreen> {
  final _inputController = TextEditingController();
  List<DaySignals>? _preview;
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _previewImport() {
    try {
      final parsed = DaySignalsImportService.parse(_inputController.text);
      setState(() {
        _preview = parsed;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _preview = null;
        _error = error.message;
      });
    } catch (error) {
      setState(() {
        _preview = null;
        _error = 'Could not read the export: $error';
      });
    }
  }

  Future<void> _saveImport() async {
    final preview = _preview;
    if (preview == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await AppScope.of(context).importDaySignals(preview);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${preview.length} daily records.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not save the import: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Review daily-signal import')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Paste a CSV or JSON export using the supported field names. '
            'All fields are optional except dateKey (YYYY-MM-DD). Values '
            'are checked before they can be added to your tracker.',
          ),
          const SizedBox(height: 10),
          const SelectableText(
            'CSV: dateKey,sleepQuality,workoutMinutes,waterMl\n'
            'JSON: [{"dateKey":"2026-10-30","sleepQuality":4,'
            '"workoutMinutes":20,"waterMl":500}]',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _inputController,
            minLines: 8,
            maxLines: 16,
            enabled: !_isSaving,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'Paste CSV or JSON here',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : _previewImport,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Validate and preview'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
          ],
          if (_preview case final preview?) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${preview.length} daily records ready to import',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    for (final signal in preview.take(5))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(_summary(signal)),
                      ),
                    if (preview.length > 5)
                      Text('and ${preview.length - 5} more…'),
                    const SizedBox(height: 6),
                    Text(
                      'For matching dates, provided values update the '
                      'existing entry; omitted values are preserved.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _preview == null || _isSaving ? null : _saveImport,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Saving…' : 'Import reviewed records'),
          ),
        ),
      ),
    );
  }

  String _summary(DaySignals signal) {
    final details = <String>[];
    if (signal.sleepQuality != null) {
      details.add('sleep ${signal.sleepQuality}/5');
    }
    if (signal.workoutMinutes != null) {
      details.add('${signal.workoutMinutes} exercise min');
    }
    if (signal.waterMl != null) details.add('${signal.waterMl} ml water');
    if (signal.focusScore != null) details.add('focus ${signal.focusScore}/10');
    return details.isEmpty
        ? '${signal.dateKey}: no signal values'
        : '${signal.dateKey}: ${details.join(' · ')}';
  }
}
