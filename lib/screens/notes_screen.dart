import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../models/note.dart';
import '../utils/formatters.dart';
import 'add_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _query = '';

  void _openNewNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddNoteScreen(),
      ),
    );
  }

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

    final pinnedNotes = notes
        .where((note) => note.pinned)
        .toList();

    final regularNotes = notes
        .where((note) => !note.pinned)
        .toList();

    final bottomInset =
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: colors.surface,

      floatingActionButton:
          _buildFloatingActionButton(context),

      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics:
              const BouncingScrollPhysics(),

          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                110 + bottomInset,
              ),

              sliver: SliverList(
                delegate:
                    SliverChildListDelegate(
                  [
                    _buildHeader(
                      context,
                      totalNotes:
                          app.notes.length,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildSearchBar(context),

                    const SizedBox(
                      height: 22,
                    ),

                    if (notes.isEmpty)
                      _buildEmptyState(
                        context,
                        isSearching:
                            query.isNotEmpty,
                      )
                    else ...[
                      if (pinnedNotes
                          .isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          icon: Icons
                              .push_pin_rounded,
                          title: 'Pinned',
                          count:
                              pinnedNotes.length,
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        ...pinnedNotes.map(
                          (note) => Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 12,
                            ),
                            child: _NoteTile(
                              note: note,
                            ),
                          ),
                        ),

                        if (regularNotes
                            .isNotEmpty)
                          const SizedBox(
                            height: 10,
                          ),
                      ],

                      if (regularNotes
                          .isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          icon: Icons
                              .notes_rounded,
                          title: 'All Notes',
                          count:
                              regularNotes.length,
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        ...regularNotes.map(
                          (note) => Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 12,
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

  // ===============================================================
  // HEADER
  // ===============================================================

  Widget _buildHeader(
    BuildContext context, {
    required int totalNotes,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Notes',
                style: theme
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                totalNotes == 0
                    ? 'Capture your thoughts and ideas.'
                    : '$totalNotes ${totalNotes == 1 ? 'note' : 'notes'} in your collection',
                style: theme
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color:
                      colors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          width: 14,
        ),

        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.primary.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            color: colors.primary,
            size: 24,
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // SEARCH
  // ===============================================================

  Widget _buildSearchBar(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return TextField(
      onChanged: (value) {
        setState(() {
          _query = value;
        });
      },

      textInputAction:
          TextInputAction.search,

      decoration: InputDecoration(
        hintText: 'Search your notes...',

        hintStyle: TextStyle(
          color: colors.onSurfaceVariant,
        ),

        prefixIcon: Icon(
          Icons.search_rounded,
          color:
              colors.onSurfaceVariant,
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
                  color: colors
                      .onSurfaceVariant,
                ),
              )
            : null,

        filled: true,

        fillColor: colors
            .surfaceContainerHighest
            .withValues(
          alpha: 0.55,
        ),

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colors
                .outlineVariant
                .withValues(
              alpha: 0.35,
            ),
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colors.primary
                .withValues(
              alpha: 0.65,
            ),
            width: 1.3,
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // SECTION HEADER
  // ===============================================================

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
        Icon(
          icon,
          size: 18,
          color: colors.primary,
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          title,
          style: theme
              .textTheme
              .titleSmall
              ?.copyWith(
            fontWeight:
                FontWeight.w800,
          ),
        ),

        const SizedBox(
          width: 7,
        ),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: colors.primary
                .withValues(
              alpha: 0.09,
            ),
            borderRadius:
                BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: theme
                .textTheme
                .labelSmall
                ?.copyWith(
              color: colors.primary,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // EMPTY STATE
  // ===============================================================

  Widget _buildEmptyState(
    BuildContext context, {
    required bool isSearching,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: colors
            .surfaceContainerHighest
            .withValues(
          alpha: 0.35,
        ),
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: colors
              .outlineVariant
              .withValues(
            alpha: 0.45,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: colors.primary
                  .withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.edit_note_rounded,
              size: 36,
              color: colors.primary,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Text(
            isSearching
                ? 'No notes found'
                : 'Your notes are empty',
            textAlign:
                TextAlign.center,
            style: theme
                .textTheme
                .titleLarge
                ?.copyWith(
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            isSearching
                ? 'Try a different search term.'
                : 'Start writing down your thoughts, ideas, and important moments.',
            textAlign:
                TextAlign.center,
            style: theme
                .textTheme
                .bodyMedium
                ?.copyWith(
              color:
                  colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),

          if (!isSearching) ...[
            const SizedBox(
              height: 22,
            ),

            FilledButton.icon(
              onPressed: _openNewNote,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Create your first note',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===============================================================
  // FLOATING ACTION BUTTON
  // ===============================================================

  Widget _buildFloatingActionButton(
    BuildContext context,
  ) {
    return FloatingActionButton.extended(
      elevation: 4,
      onPressed: _openNewNote,
      icon: const Icon(
        Icons.add_rounded,
      ),
      label: const Text(
        'New Note',
        style: TextStyle(
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }
}

// =================================================================
// NOTE TILE
// =================================================================

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

      direction:
          DismissDirection.endToStart,

      confirmDismiss: (_) {
        return _confirmDelete(
          context,
          note,
        );
      },

      background: const SizedBox(),

      secondaryBackground:
          _buildDeleteBackground(
        context,
      ),

      onDismissed: (_) {
        final removed = note;

        app.deleteNote(note.id);

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior:
                  SnackBarBehavior.floating,

              margin:
                  const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                90,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              content: Text(
                removed.title.trim().isEmpty
                    ? 'Note deleted'
                    : 'Deleted "${removed.title.trim()}"',
              ),

              action:
                  SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  app.addNote(removed);
                },
              ),
            ),
          );
      },

      child: _buildCard(
        context,
        app,
      ),
    );
  }

  // ===============================================================
  // DELETE BACKGROUND
  // ===============================================================

  Widget _buildDeleteBackground(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding:
          const EdgeInsets.only(
        right: 22,
      ),

      decoration: BoxDecoration(
        color: colors.error.withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),

      alignment:
          Alignment.centerRight,

      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.error,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  // ===============================================================
  // NOTE CARD
  // ===============================================================

  Widget _buildCard(
    BuildContext context,
    dynamic app,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final title =
        note.title.trim().isEmpty
            ? 'Untitled note'
            : note.title.trim();

    final content =
        note.content.trim();

    final preview = content.isEmpty
        ? 'No additional text'
        : content;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddNoteScreen(
                existing: note,
              ),
            ),
          );
        },

        child: Ink(
          decoration:
              BoxDecoration(
            color: colors.surface,

            borderRadius:
                BorderRadius.circular(20),

            border: Border.all(
              color: note.pinned
                  ? colors.primary
                      .withValues(
                    alpha: 0.28,
                  )
                  : colors.outlineVariant
                      .withValues(
                    alpha: 0.55,
                  ),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: 0.035,
                ),
                blurRadius: 16,
                offset:
                    const Offset(0, 5),
              ),
            ],
          ),

          child: Padding(
            padding:
                const EdgeInsets.all(16),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                _buildNoteIcon(
                  context,
                ),

                const SizedBox(
                  width: 13,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style: theme
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .w800,
                                letterSpacing:
                                    -0.15,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          _buildPinButton(
                            context,
                            app,
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      Text(
                        preview,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style: theme
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          color: colors
                              .onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Row(
                        children: [
                          Icon(
                            Icons
                                .schedule_rounded,
                            size: 14,
                            color: colors
                                .onSurfaceVariant,
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          Flexible(
                            child: Text(
                              formatDate(
                                note.updatedAt,
                              ),
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style: theme
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                color: colors
                                    .onSurfaceVariant,
                                fontWeight:
                                    FontWeight
                                        .w500,
                              ),
                            ),
                          ),

                          if (note.pinned) ...[
                            const SizedBox(
                              width: 10,
                            ),

                            Container(
                              width: 4,
                              height: 4,
                              decoration:
                                  BoxDecoration(
                                color: colors
                                    .primary,
                                shape:
                                    BoxShape
                                        .circle,
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Text(
                              'Pinned',
                              style: theme
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                color: colors
                                    .primary,
                                fontWeight:
                                    FontWeight
                                        .w700,
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

  // ===============================================================
  // NOTE ICON
  // ===============================================================

  Widget _buildNoteIcon(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      width: 46,
      height: 46,

      decoration:
          BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            colors.primary
                .withValues(
              alpha: 0.16,
            ),
            colors.secondary
                .withValues(
              alpha: 0.08,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(14),
      ),

      child: Icon(
        note.pinned
            ? Icons.push_pin_rounded
            : Icons.description_outlined,
        color: colors.primary,
        size: 22,
      ),
    );
  }

  // ===============================================================
  // PIN BUTTON
  // ===============================================================

  Widget _buildPinButton(
    BuildContext context,
    dynamic app,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius:
            BorderRadius.circular(10),

        onTap: () {
          // ---------------------------------------------------------
          // FIX:
          // AppNote does not have copyWith().
          //
          // We therefore update the existing mutable AppNote
          // instance and pass it back through updateNote().
          // ---------------------------------------------------------

          note.pinned = !note.pinned;

          app.updateNote(note);
        },

        child: Padding(
          padding:
              const EdgeInsets.all(5),

          child: Icon(
            note.pinned
                ? Icons.push_pin_rounded
                : Icons.push_pin_outlined,

            size: 21,

            color: note.pinned
                ? colors.primary
                : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // DELETE CONFIRMATION
  // ===============================================================

  Future<bool> _confirmDelete(
    BuildContext context,
    AppNote note,
  ) async {
    final colors =
        Theme.of(context).colorScheme;

    final result =
        await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              24,
            ),
          ),

          icon: Container(
            width: 52,
            height: 52,

            decoration:
                BoxDecoration(
              color: colors.error
                  .withValues(
                alpha: 0.10,
              ),
              shape:
                  BoxShape.circle,
            ),

            child: Icon(
              Icons
                  .delete_outline_rounded,
              color: colors.error,
              size: 26,
            ),
          ),

          title: const Text(
            'Delete note?',
            textAlign:
                TextAlign.center,
          ),

          content: Text(
            note.title.trim().isEmpty
                ? 'This note will be removed. You can undo this immediately after deleting.'
                : '“${note.title.trim()}” will be removed. You can undo this immediately after deleting.',
            textAlign:
                TextAlign.center,
          ),

          actionsAlignment:
              MainAxisAlignment.center,

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

            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    colors.error,
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