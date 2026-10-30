import 'package:flutter/material.dart';

import '../models/mood_entry.dart';
import '../services/app_scope.dart';
import '../services/personal_insights_service.dart';
import '../utils/formatters.dart';
import 'day_signals_import_screen.dart';

class PresentModeScreen extends StatefulWidget {
  const PresentModeScreen({super.key});

  @override
  State<PresentModeScreen> createState() => _PresentModeScreenState();
}

class _PresentModeScreenState extends State<PresentModeScreen> {
  final _queryController = TextEditingController();
  String? _answer;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _answerQuery() {
    final app = AppScope.of(context);
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _answer = PersonalInsightsService.answerQuery(
        query: query,
        transactions: app.transactions,
        moods: app.moods,
        tasks: app.tasks,
        signals: app.daySignals,
        currency: app.currency,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final forecast = PersonalInsightsService.forecast(
      moods: app.moods,
      signals: app.daySignals,
      tasks: app.tasks,
    );
    final alerts = PersonalInsightsService.alerts(
      tasks: app.tasks,
      signals: app.daySignals,
      overBudgetCategories: app.overBudgetCategories,
      todayExpense: app.todayExpense,
      transactions: app.transactions,
    );
    final moodLabel = forecast.likelyMood == null
        ? 'Not enough check-ins'
        : '${moodOptionFor(forecast.likelyMood!).label} is most common';

    return Scaffold(
      appBar: AppBar(title: const Text('Present mode')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'A local snapshot of what you have logged. Nothing is synced or '
            'sent elsewhere from this screen.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            context,
            title: 'Today',
            icon: Icons.notifications_active_outlined,
            child: alerts.isEmpty
                ? const Text('No alerts from your tracked data right now.')
                : Column(
                    children: [
                      for (final alert in alerts)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.info_outline_rounded,
                            color: colors.primary,
                          ),
                          title: Text(alert.title),
                          subtitle: Text(alert.detail),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            context,
            title: 'Tomorrow, at a glance',
            icon: Icons.auto_awesome_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _forecastValue(
                  context,
                  'Mood pattern',
                  moodLabel,
                  '${forecast.moodObservations} recent check-ins',
                ),
                const SizedBox(height: 12),
                _forecastValue(
                  context,
                  'Capacity estimate',
                  forecast.estimatedCapacity == null
                      ? 'Not enough recent signals'
                      : '${forecast.estimatedCapacity}/100',
                  '${forecast.signalObservations} recent daily signals; '
                      'planning aid only, not a health prediction',
                ),
                const SizedBox(height: 14),
                Text(
                  forecast.recommendation,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'These are simple summaries of your own entries, not '
                  'medical or causal conclusions.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            context,
            title: 'Ask about your records',
            icon: Icons.manage_search_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _queryController,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'e.g. How many minutes did I exercise last week?',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _answerQuery(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _answerQuery,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Get report'),
                  ),
                ),
                if (_answer != null) ...[
                  const SizedBox(height: 8),
                  Text(_answer!, style: theme.textTheme.bodyLarge),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            context,
            title: 'Import records',
            icon: Icons.file_upload_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paste a normalized daily-signal CSV or JSON export. '
                  'Review it before saving; imported values fill missing '
                  'fields without erasing existing check-ins.',
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DaySignalsImportScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Review an import'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Calendar, finance-provider, health-platform, and email '
                  'connections are not configured in this offline build.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            context,
            title: 'Money today',
            icon: Icons.account_balance_wallet_outlined,
            child: Text(
              'Tracked expenses: ${formatMoney(app.todayExpense, app.currency)}',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _forecastValue(
    BuildContext context,
    String title,
    String value,
    String detail,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelLarge),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.titleMedium),
        Text(
          detail,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
