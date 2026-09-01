import 'package:flutter/material.dart';

import '../models/note.dart';
import '../services/app_scope.dart';
import '../utils/formatters.dart';
import 'add_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _query = '';

// ==========================================================================
// NEW NOTE
// ==========================================================================

  void _openNewNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddNoteScreen(),
      ),
    );
  }

// ==========================================================================
// BUILD
// ==========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final app = AppScope.of(context);
    final query = _query.trim().toLowerCase();

    final notes = app.notes.where((note) {
      if (query.isEmpty) {
        return true;
      }

      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) {
          return a.pinned ? -1 : 1;
        }

        return b.updatedAt.compareTo(a.updatedAt);
      });

    final pinnedNotes = notes.where((note) => note.pinned).toList();

    final regularNotes = notes.where((note) => !note.pinned).toList();

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: colors.surface,
      floatingActionButton: _buildFloatingActionButton(context),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                120 + bottomInset,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildHeader(
                      context,
                      totalNotes: app.notes.length,
                      visibleNotes: notes.length,
                    ),
                    const SizedBox(height: 22),
                    _buildSearchBar(context),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildQuickStats(
                        context,
                        total: notes.length,
                        pinned: pinnedNotes.length,
                      ),
                      const SizedBox(height: 25),
                    ] else
                      const SizedBox(height: 24),
                    if (notes.isEmpty)
                      _buildEmptyState(
                        context,
                        isSearching: query.isNotEmpty,
                      )
                    else ...[
                      if (pinnedNotes.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          icon: Icons.push_pin_rounded,
                          title: 'Pinned',
                          count: pinnedNotes.length,
                        ),
                        const SizedBox(height: 12),
                        ...pinnedNotes.map(
                          (note) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: 13,
                            ),
                            child: _NoteTile(
                              note: note,
                            ),
                          ),
                        ),
                        if (regularNotes.isNotEmpty) const SizedBox(height: 12),
                      ],
                      if (regularNotes.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          icon: Icons.notes_rounded,
                          title: 'All Notes',
                          count: regularNotes.length,
                        ),
                        const SizedBox(height: 12),
                        ...regularNotes.map(
                          (note) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: 13,
                            ),
                            child: _NoteTile(
                              note: note,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ==========================================================================
// HEADER
// ==========================================================================

  Widget _buildHeader(
    BuildContext context, {
    required int totalNotes,
    required int visibleNotes,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Notes',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$visibleNotes',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                totalNotes == 0
                    ? 'Capture your thoughts and ideas.'
                    : totalNotes == 1
                        ? 'One thought saved in your collection.'
                        : '$totalNotes thoughts saved in your collection.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        _buildHeaderIcon(context),
      ],
    );
  }

  Widget _buildHeaderIcon(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.18),
            colors.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(
        Icons.auto_stories_rounded,
        color: colors.primary,
        size: 27,
      ),
    );
  }

// ==========================================================================
// SEARCH BAR
// ==========================================================================

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _query = value;
          });
        },
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search your notes...',
          hintStyle: TextStyle(
            color: colors.onSurfaceVariant.withValues(
              alpha: 0.78,
            ),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Icon(
              Icons.search_rounded,
              color: colors.primary,
              size: 23,
            ),
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    setState(() {
                      _query = '';
                    });
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                )
              : null,
          filled: true,
          fillColor: colors.surfaceContainerHighest.withValues(
            alpha: 0.48,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(19),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(19),
            borderSide: BorderSide(
              color: colors.outlineVariant.withValues(
                alpha: 0.35,
              ),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(19),
            borderSide: BorderSide(
              color: colors.primary.withValues(alpha: 0.55),
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

// ==========================================================================
// QUICK STATS
// ==========================================================================

  Widget _buildQuickStats(
    BuildContext context, {
    required int total,
    required int pinned,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.notes_rounded,
            value: '$total',
            label: total == 1 ? 'Note' : 'Notes',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.push_pin_rounded,
            value: '$pinned',
            label: 'Pinned',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.edit_note_rounded,
            value: _query.isEmpty ? 'All' : 'Found',
            label: 'View',
          ),
        ),
      ],
    );
  }

// ==========================================================================
// SECTION HEADER
// ==========================================================================

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 17,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Spacer(),
        Container(
          width: 35,
          height: 1,
          color: colors.outlineVariant.withValues(
            alpha: 0.45,
          ),
        ),
      ],
    );
  }

// ==========================================================================
// EMPTY STATE
// ==========================================================================

  Widget _buildEmptyState(
    BuildContext context, {
    required bool isSearching,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 44,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.primary.withValues(alpha: 0.055),
            colors.surfaceContainerHighest.withValues(
              alpha: 0.18,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: colors.outlineVariant.withValues(
            alpha: 0.38,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary.withValues(alpha: 0.15),
                  colors.secondary.withValues(alpha: 0.07),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.edit_note_rounded,
              size: 40,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSearching ? 'No notes found' : 'Your notes are empty',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try searching with another word or phrase.'
                : 'Turn your ideas, thoughts, plans, and memories into notes.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (!isSearching) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openNewNote,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Create your first note',
              ),
            ),
          ],
        ],
      ),
    );
  }

// ==========================================================================
// FLOATING ACTION BUTTON
// ==========================================================================

  Widget _buildFloatingActionButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FloatingActionButton.extended(
      elevation: 6,
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      onPressed: _openNewNote,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'New Note',
        style: TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================================
// STAT CARD
// ============================================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(
          alpha: 0.32,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 17,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NOTE TILE
// ============================================================================

class _NoteTile extends StatelessWidget {
  final AppNote note;

  const _NoteTile({
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) {
        return _confirmDelete(
          context,
          note,
        );
      },
      background: const SizedBox.shrink(),
      secondaryBackground: _buildDeleteBackground(context),
      onDismissed: (_) {
        final removed = note;

        app.deleteNote(note.id);

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                90,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              content: Text(
                removed.title.trim().isEmpty
                    ? 'Note deleted'
                    : 'Deleted "${removed.title.trim()}"',
              ),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  app.addNote(removed);
                },
              ),
            ),
          );
      },
      child: _buildCard(context, app, note),
    );
  }

// ==========================================================================
// DELETE BACKGROUND
// ==========================================================================

  Widget _buildDeleteBackground(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.only(
        right: 22,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colors.error.withValues(alpha: 0.05),
            colors.error.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(21),
      ),
      alignment: Alignment.centerRight,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colors.error,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.error.withValues(alpha: 0.20),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 23,
        ),
      ),
    );
  }

// ==========================================================================
// NOTE CARD
// ==========================================================================

  Widget _buildCard(BuildContext context, dynamic app, AppNote note) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final title =
        note.title.trim().isEmpty ? 'Untitled note' : note.title.trim();

    final content = note.content.trim();

    final preview = content.isEmpty ? 'No additional text' : content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddNoteScreen(
                existing: note,
              ),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: note.pinned
                  ? colors.primary.withValues(alpha: 0.30)
                  : colors.outlineVariant.withValues(alpha: 0.48),
              width: note.pinned ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: note.pinned ? 0.055 : 0.035,
                ),
                blurRadius: note.pinned ? 20 : 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNoteIcon(context, note),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPinButton(context, app, note),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              formatDate(note.updatedAt),
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (note.pinned) ...[
                            const SizedBox(width: 9),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(
                                  alpha: 0.09,
                                ),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                'Pinned',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ==========================================================================
// NOTE ICON
// ==========================================================================

  Widget _buildNoteIcon(BuildContext context, AppNote note) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.16),
            colors.secondary.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.07),
        ),
      ),
      child: Icon(
        note.pinned ? Icons.push_pin_rounded : Icons.description_outlined,
        color: colors.primary,
        size: 23,
      ),
    );
  }

// ==========================================================================
// PIN BUTTON
// ==========================================================================

  Widget _buildPinButton(BuildContext context, dynamic app, AppNote note) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: note.pinned
          ? colors.primary.withValues(alpha: 0.09)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () {
          note.pinned = !note.pinned;
          app.updateNote(note);
        },
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            note.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            size: 20,
            color: note.pinned ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

// ==========================================================================
// DELETE CONFIRMATION
// ==========================================================================

  Future<bool> _confirmDelete(
    BuildContext context,
    AppNote note,
  ) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          icon: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: colors.error,
              size: 29,
            ),
          ),
          title: Text(
            'Delete note?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            note.title.trim().isEmpty
                ? 'This note will be removed. You can undo this immediately after deleting.'
                : '"${note.title.trim()}" will be removed. You can undo this immediately after deleting.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
