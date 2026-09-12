import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/birthday_contact.dart';
import '../services/app_scope.dart';
import '../services/app_state.dart';

const _uuid = Uuid();

const _birthdayRelationOptions = [
  'Family',
  'Parent',
  'Sibling',
  'Partner',
  'Friend',
  'Colleague',
  'Other',
];

class BirthdayContactsScreen extends StatefulWidget {
  const BirthdayContactsScreen({super.key});

  @override
  State<BirthdayContactsScreen> createState() =>
      _BirthdayContactsScreenState();
}

class _BirthdayContactsScreenState extends State<BirthdayContactsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;

  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _sortMode = 'Soonest';

  bool _darkMode = false;

  final List<String> _filters = [
    'All',
    'Today',
    'This Week',
    'This Month',
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _animationController.forward();

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<BirthdayContact> _filteredContacts(
    List<BirthdayContact> contacts,
    DateTime now,
  ) {
    final result = contacts.where((contact) {
      final matchesSearch =
          contact.name.toLowerCase().contains(_searchQuery) ||
          contact.relation.toLowerCase().contains(_searchQuery);

      if (!matchesSearch) return false;

      final days = contact.daysUntil(now);

      switch (_selectedFilter) {
        case 'Today':
          return days == 0;

        case 'This Week':
          return days >= 0 && days <= 7;

        case 'This Month':
          return days >= 0 && days <= 30;

        default:
          return true;
      }
    }).toList();

    result.sort((a, b) {
      if (_sortMode == 'Name') {
        return a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            );
      }

      if (_sortMode == 'Age') {
        return b
            .ageOn(b.nextOccurrence(now))
            .compareTo(a.ageOn(a.nextOccurrence(now)));
      }

      return a.nextOccurrence(now).compareTo(
            b.nextOccurrence(now),
          );
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    final baseTheme = Theme.of(context);

    final theme = _darkMode
        ? ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFFE85D75),
            scaffoldBackgroundColor: const Color(0xFF0B0B10),
          )
        : baseTheme;

    final colors = theme.colorScheme;

    final now = DateTime.now();

    final contacts = app.birthdayContacts.toList();

    final filtered = _filteredContacts(
      contacts,
      now,
    );

    final todayContacts = contacts.where(
      (contact) => contact.daysUntil(now) == 0,
    ).toList();

    final weekCount = contacts.where((contact) {
      final days = contact.daysUntil(now);
      return days >= 0 && days <= 7;
    }).length;

    final monthCount = contacts.where((contact) {
      final days = contact.daysUntil(now);
      return days >= 0 && days <= 30;
    }).length;

    BirthdayContact? nextBirthday;

    if (contacts.isNotEmpty) {
      final sorted = contacts.toList()
        ..sort(
          (a, b) => a.nextOccurrence(now).compareTo(
                b.nextOccurrence(now),
              ),
        );

      nextBirthday = sorted.first;
    }

    final bottomPadding =
        MediaQuery.of(context).padding.bottom + 115;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: _buildAppBar(
          context,
          colors,
        ),
        floatingActionButton: _buildFab(
          context,
          app,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              bottomPadding,
            ),
            children: [
              _AnimatedSection(
                controller: _animationController,
                delay: 0,
                child: _HeroCard(
                  contactCount: contacts.length,
                  todayCount: todayContacts.length,
                  nextBirthday: nextBirthday,
                  now: now,
                ),
              ),

              const SizedBox(height: 16),

              if (todayContacts.isNotEmpty)
                _AnimatedSection(
                  controller: _animationController,
                  delay: 80,
                  child: _TodayBirthdayCard(
                    contacts: todayContacts,
                    onMessage: (contact) {
                      _shareBirthdayMessage(
                        context,
                        contact,
                      );
                    },
                  ),
                ),

              if (todayContacts.isNotEmpty)
                const SizedBox(height: 16),

              _AnimatedSection(
                controller: _animationController,
                delay: 150,
                child: _Statistics(
                  today: todayContacts.length,
                  week: weekCount,
                  month: monthCount,
                  total: contacts.length,
                ),
              ),

              const SizedBox(height: 20),

              _AnimatedSection(
                controller: _animationController,
                delay: 210,
                child: _SearchBox(
                  controller: _searchController,
                  query: _searchQuery,
                ),
              ),

              const SizedBox(height: 12),

              _AnimatedSection(
                controller: _animationController,
                delay: 270,
                child: _FilterBar(
                  filters: _filters,
                  selected: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 18),

              _AnimatedSection(
                controller: _animationController,
                delay: 330,
                child: _QuickActions(
                  onMessage: () {
                    if (nextBirthday != null) {
                      _shareBirthdayMessage(
                        context,
                        nextBirthday,
                      );
                    } else {
                      _showBirthdayTips(context);
                    }
                  },
                  onGift: () {
                    _showGiftIdeas(context);
                  },
                ),
              ),

              const SizedBox(height: 20),

              _AnimatedSection(
                controller: _animationController,
                delay: 390,
                child: _ListToolbar(
                  sortMode: _sortMode,
                  resultCount: filtered.length,
                  onSortChanged: (value) {
                    setState(() {
                      _sortMode = value;
                    });
                  },
                  onShare: filtered.isEmpty
                      ? null
                      : () => _shareBirthdayList(
                            context,
                            filtered,
                          ),
                ),
              ),

              const SizedBox(height: 12),

              if (filtered.isEmpty)
                const _EmptyBirthdayState()
              else
                ...filtered.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final contact = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: _AnimatedSection(
                        controller: _animationController,
                        delay: 420 + index * 55,
                        child: _BirthdayCard(
                          contact: contact,
                          now: now,
                          onEdit: () => _editContact(
                            context,
                            app,
                            contact: contact,
                          ),
                          onDelete: () => _deleteContact(
                            context,
                            app,
                            contact,
                          ),
                          onMessage: () =>
                              _shareBirthdayMessage(
                            context,
                            contact,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ColorScheme colors,
  ) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.surface.withValues(alpha: .94),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 18,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERSONAL TRACKER',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Birthdays',
            style: TextStyle(
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      actions: [
        _AppBarButton(
          icon: _darkMode
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          tooltip: _darkMode
              ? 'Switch to light mode'
              : 'Switch to dark mode',
          onPressed: () {
            setState(() {
              _darkMode = !_darkMode;
            });
          },
        ),
        const SizedBox(width: 4),
        _AppBarButton(
          icon: Icons.auto_awesome_rounded,
          tooltip: 'Birthday tips',
          onPressed: () {
            _showBirthdayTips(context);
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildFab(
    BuildContext context,
    AppState app,
  ) {
    return FloatingActionButton.extended(
      onPressed: () => _editContact(
        context,
        app,
      ),
      elevation: 8,
      icon: const Icon(
        Icons.add_rounded,
      ),
      label: const Text(
        'Add Birthday',
        style: TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ========================================================================
  // ADD / EDIT
  // ========================================================================

  void _editContact(
    BuildContext context,
    AppState app, {
    BirthdayContact? contact,
  }) {
    final nameCtrl = TextEditingController(
      text: contact?.name ?? '',
    );

    final relationCtrl = TextEditingController(
      text: contact?.relation ?? 'Friend',
    );

    var selectedRelation = contact == null
        ? 'Friend'
        : _birthdayRelationOptions.contains(
            contact.relation,
          )
            ? contact.relation
            : 'Other';

    DateTime selectedDate =
        contact?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colors =
                Theme.of(context).colorScheme;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(
                  context,
                ).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius:
                      const BorderRadius.vertical(
                    top: Radius.circular(34),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: .25,
                      ),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 45,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colors.onSurface
                                .withValues(alpha: .15),
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient:
                                  const LinearGradient(
                                begin:
                                    Alignment.topLeft,
                                end:
                                    Alignment.bottomRight,
                                colors: [
                                  Color(0xFFE85D75),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                18,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE85D75,
                                  ).withValues(
                                    alpha: .25,
                                  ),
                                  blurRadius: 18,
                                  offset:
                                      const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.cake_rounded,
                              color: Colors.white,
                              size: 29,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact == null
                                      ? 'Add Birthday'
                                      : 'Edit Birthday',
                                  style:
                                      const TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Never forget someone special.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors
                                        .onSurface
                                        .withValues(
                                      alpha: .52,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      _BirthdayInput(
                        controller: nameCtrl,
                        label: 'Name',
                        hint: 'e.g. Snehith',
                        icon:
                            Icons.person_outline_rounded,
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue:
                            selectedRelation,
                        decoration:
                            _inputDecoration(
                          context,
                          'Relation',
                          Icons
                              .people_outline_rounded,
                        ),
                        items:
                            _birthdayRelationOptions
                                .map(
                                  (relation) =>
                                      DropdownMenuItem(
                                    value: relation,
                                    child: Text(
                                      relation,
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setSheetState(() {
                            selectedRelation =
                                value;

                            if (value != 'Other') {
                              relationCtrl.text =
                                  value;
                            }
                          });
                        },
                      ),

                      if (selectedRelation == 'Other') ...[
                        const SizedBox(height: 10),
                        _BirthdayInput(
                          controller: relationCtrl,
                          label: 'Custom relation',
                          hint:
                              'e.g. Mentor, Cousin',
                          icon:
                              Icons.edit_note_rounded,
                        ),
                      ],

                      const SizedBox(height: 12),

                      _DatePickerCard(
                        selectedDate: selectedDate,
                        onTap: () async {
                          final picked =
                              await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate:
                                DateTime(1900),
                            lastDate: DateTime(
                              DateTime.now().year + 5,
                            ),
                          );

                          if (picked != null) {
                            setSheetState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: () async {
                            if (nameCtrl.text
                                .trim()
                                .isEmpty) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  behavior:
                                      SnackBarBehavior
                                          .floating,
                                  content: Text(
                                    'Please enter a name',
                                  ),
                                ),
                              );
                              return;
                            }

                            final edited =
                                BirthdayContact(
                              id: contact?.id ??
                                  _uuid.v4(),
                              name: nameCtrl.text
                                  .trim(),
                              relation: relationCtrl
                                      .text
                                      .trim()
                                      .isEmpty
                                  ? 'Friend'
                                  : relationCtrl.text
                                      .trim(),
                              date: DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                              ),
                            );

                            if (contact == null) {
                              await app
                                  .addBirthdayContact(
                                edited,
                              );
                            } else {
                              await app
                                  .updateBirthdayContact(
                                edited,
                              );
                            }

                            if (!mounted ||
                                !sheetContext.mounted) {
                              return;
                            }

                            Navigator.pop(
                              sheetContext,
                            );

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                behavior:
                                    SnackBarBehavior
                                        .floating,
                                content: Text(
                                  contact == null
                                      ? '🎂 Birthday added'
                                      : '✨ Birthday updated',
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            contact == null
                                ? Icons.add_rounded
                                : Icons.check_rounded,
                          ),
                          label: Text(
                            contact == null
                                ? 'Add Birthday'
                                : 'Save Changes',
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ========================================================================
  // DELETE
  // ========================================================================

  void _deleteContact(
    BuildContext context,
    AppState app,
    BirthdayContact contact,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors =
            Theme.of(ctx).colorScheme;

        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Text(
                'Remove Birthday?',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          content: Text(
            'Remove ${contact.name} from your birthday list?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                app.deleteBirthdayContact(
                  contact.id,
                );

                Navigator.pop(ctx);

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(
                    behavior:
                        SnackBarBehavior.floating,
                    content: Text(
                      '${contact.name} removed',
                    ),
                  ),
                );
              },
              child: const Text(
                'Remove',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ========================================================================
  // SHARING
  // ========================================================================

  Future<void> _shareBirthdayMessage(
    BuildContext context,
    BirthdayContact contact,
  ) async {
    final messages = [
      'Happy Birthday, ${contact.name}! 🎂🎉 Wishing you an amazing day filled with happiness, laughter and beautiful memories! ❤️',

      'Happy Birthday ${contact.name}! 🥳🎂 Hope your special day is absolutely wonderful and the year ahead brings you lots of happiness! ✨',

      'Wishing you the happiest birthday, ${contact.name}! 🎉 May your day be full of love, smiles and everything that makes you happy! 💖',

      'Here’s to another amazing year, ${contact.name}! 🎂✨ Happy Birthday! May this year bring you new adventures and unforgettable memories! 🥳',
    ];

    final message =
        messages[
            DateTime.now().millisecond %
                messages.length];

    await SharePlus.instance.share(
      ShareParams(
        text: message,
      ),
    );
  }

  Future<void> _shareBirthdayList(
    BuildContext context,
    List<BirthdayContact> contacts,
  ) async {
    final lines = contacts.map(
      (contact) {
        final days =
            contact.daysUntil(DateTime.now());

        final when = days == 0
            ? 'today 🎉'
            : 'in $days days';

        return '🎂 ${contact.name} • '
            '${DateFormat.MMMd().format(contact.date)} '
            '($when)';
      },
    ).join('\n');

    await SharePlus.instance.share(
      ShareParams(
        text:
            '🎂 My upcoming birthdays\n\n$lines',
      ),
    );
  }

  void _showBirthdayTips(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context).colorScheme.surface,
      builder: (_) => const _TipsSheet(),
    );
  }

  void _showGiftIdeas(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context).colorScheme.surface,
      builder: (_) => const _GiftIdeasSheet(),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor:
          colors.surfaceContainerHighest
              .withValues(alpha: .45),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(18),
        borderSide: BorderSide(
          color: colors.outline
              .withValues(alpha: .08),
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(18),
        borderSide: BorderSide(
          color: colors.outline
              .withValues(alpha: .08),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(18),
        borderSide: BorderSide(
          color: colors.primary,
          width: 1.5,
        ),
      ),
    );
  }
}

// ============================================================================
// APP BAR BUTTON
// ============================================================================

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _AppBarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surfaceContainerHighest
            .withValues(alpha: .65),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 43,
            height: 43,
            child: Icon(
              icon,
              size: 19,
              color: colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ANIMATION
// ============================================================================

class _AnimatedSection extends StatelessWidget {
  final AnimationController controller;
  final int delay;
  final Widget child;

  const _AnimatedSection({
    required this.controller,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final progress =
            Curves.easeOutCubic.transform(
          ((controller.value * 1000 - delay) /
                  650)
              .clamp(0.0, 1.0),
        );

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(
              0,
              22 * (1 - progress),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

// ============================================================================
// HERO
// ============================================================================

class _HeroCard extends StatelessWidget {
  final int contactCount;
  final int todayCount;
  final BirthdayContact? nextBirthday;
  final DateTime now;

  const _HeroCard({
    required this.contactCount,
    required this.todayCount,
    required this.nextBirthday,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE85D75),
            Color(0xFF9B5DE5),
            Color(0xFFF59E0B),
          ],
        ),
        borderRadius:
            BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE85D75)
                .withValues(alpha: .30),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -35,
            child: Icon(
              Icons.cake_rounded,
              size: 155,
              color: Colors.white
                  .withValues(alpha: .08),
            ),
          ),
          Positioned(
            right: 35,
            bottom: -20,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 75,
              color: Colors.white
                  .withValues(alpha: .08),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -45,
            child: Icon(
              Icons.favorite_rounded,
              size: 105,
              color: Colors.white
                  .withValues(alpha: .05),
            ),
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: .16),
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: .15),
                      ),
                    ),
                    child: const Icon(
                      Icons.cake_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                  const Spacer(),
                  if (todayCount > 0)
                    _GlassPill(
                      text:
                          '$todayCount today 🎉',
                    ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'Celebrate the people\nwho matter most 🎂',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                contactCount == 0
                    ? 'Build your personal birthday list.'
                    : '$contactCount special '
                        '${contactCount == 1 ? 'person' : 'people'} saved.',
                style: TextStyle(
                  color: Colors.white
                      .withValues(alpha: .82),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),

              if (nextBirthday != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: .13),
                    borderRadius:
                        BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.white
                          .withValues(alpha: .10),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Next: ${nextBirthday!.name} • '
                          '${nextBirthday!.daysUntil(now) == 0 ? 'Today 🎉' : '${nextBirthday!.daysUntil(now)} days'}',
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final String text;

  const _GlassPill({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white
            .withValues(alpha: .15),
        borderRadius:
            BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white
              .withValues(alpha: .12),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ============================================================================
// TODAY
// ============================================================================

class _TodayBirthdayCard extends StatelessWidget {
  final List<BirthdayContact> contacts;
  final ValueChanged<BirthdayContact> onMessage;

  const _TodayBirthdayCard({
    required this.contacts,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.redAccent
            .withValues(alpha: .055),
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color: Colors.redAccent
              .withValues(alpha: .14),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Colors.redAccent,
                      Colors.pink,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Birthday Today! 🎉',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Make their day special ❤️',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors
                            .onSurface
                            .withValues(
                          alpha: .52,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...contacts.map(
            (contact) => Padding(
              padding:
                  const EdgeInsets.only(
                top: 7,
              ),
              child: Row(
                children: [
                  Container(
                    width: 37,
                    height: 37,
                    decoration: const BoxDecoration(
                      gradient:
                          LinearGradient(
                        colors: [
                          Color(0xFFE85D75),
                          Color(0xFF9B5DE5),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      contact.initials,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      contact.name,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip:
                        'Send birthday message',
                    onPressed: () =>
                        onMessage(contact),
                    icon: Icon(
                      Icons.send_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATISTICS
// ============================================================================

class _Statistics extends StatelessWidget {
  final int today;
  final int week;
  final int month;
  final int total;

  const _Statistics({
    required this.today,
    required this.week,
    required this.month,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.today_rounded,
            value: '$today',
            label: 'Today',
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.date_range_rounded,
            value: '$week',
            label: '7 Days',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_month_rounded,
            value: '$month',
            label: '30 Days',
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.people_alt_rounded,
            value: '$total',
            label: 'People',
            color: Colors.teal,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 13,
        horizontal: 4,
      ),
      decoration: BoxDecoration(
        color: colors
            .surfaceContainerHighest
            .withValues(alpha: .42),
        borderRadius:
            BorderRadius.circular(19),
        border: Border.all(
          color: colors.outline
              .withValues(alpha: .07),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color:
                  color.withValues(alpha: .11),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: colors.onSurface
                  .withValues(alpha: .50),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SEARCH
// ============================================================================

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String query;

  const _SearchBox({
    required this.controller,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      textCapitalization:
          TextCapitalization.words,
      decoration: InputDecoration(
        hintText:
            'Search people or relationships...',
        hintStyle: TextStyle(
          fontSize: 12,
          color: colors.onSurface
              .withValues(alpha: .42),
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 21,
        ),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                onPressed: controller.clear,
                icon: const Icon(
                  Icons.close_rounded,
                ),
              )
            : null,
        filled: true,
        fillColor: colors
            .surfaceContainerHighest
            .withValues(alpha: .55),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(19),
          borderSide: BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(19),
          borderSide: BorderSide(
            color: colors.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FILTERS
// ============================================================================

class _FilterBar extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({
    required this.filters,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 39,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final filter =
              filters[index];

          return ChoiceChip(
            selected: selected == filter,
            label: Text(
              filter,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            avatar: Icon(
              filter == 'All'
                  ? Icons.apps_rounded
                  : filter == 'Today'
                      ? Icons.today_rounded
                      : filter == 'This Week'
                          ? Icons.date_range_rounded
                          : Icons
                              .calendar_month_rounded,
              size: 15,
            ),
            onSelected: (_) =>
                onChanged(filter),
          );
        },
      ),
    );
  }
}

// ============================================================================
// QUICK ACTIONS
// ============================================================================

class _QuickActions extends StatelessWidget {
  final VoidCallback onMessage;
  final VoidCallback onGift;

  const _QuickActions({
    required this.onMessage,
    required this.onGift,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon:
                Icons.chat_bubble_outline_rounded,
            title: 'Birthday Message',
            subtitle: 'Share a wish',
            accent:
                const Color(0xFFE85D75),
            onTap: onMessage,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon:
                Icons.card_giftcard_rounded,
            title: 'Gift Ideas',
            subtitle: 'Find inspiration',
            accent:
                const Color(0xFFF59E0B),
            onTap: onGift,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Material(
      color: colors
          .surfaceContainerHighest
          .withValues(alpha: .40),
      borderRadius:
          BorderRadius.circular(19),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(19),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent
                      .withValues(alpha: .12),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9,
                        color: colors
                            .onSurface
                            .withValues(
                          alpha: .50,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TOOLBAR
// ============================================================================

class _ListToolbar
    extends StatelessWidget {
  final String sortMode;
  final int resultCount;
  final ValueChanged<String>
      onSortChanged;
  final VoidCallback? onShare;

  const _ListToolbar({
    required this.sortMode,
    required this.resultCount,
    required this.onSortChanged,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.primary
                .withValues(alpha: .09),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.people_alt_outlined,
            color: colors.primary,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Your People',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              Text(
                '$resultCount birthdays',
                style: TextStyle(
                  fontSize: 9,
                  color: colors.onSurface
                      .withValues(
                    alpha: .48,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 38,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: colors
                .surfaceContainerHighest
                .withValues(alpha: .55),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child:
              DropdownButtonHideUnderline(
            child:
                DropdownButton<String>(
              value: sortMode,
              isDense: true,
              borderRadius:
                  BorderRadius.circular(14),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 7,
              ),
              icon: const Icon(
                Icons.expand_more_rounded,
                size: 17,
              ),
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 10,
                fontWeight:
                    FontWeight.w800,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Soonest',
                  child: Text('Soonest'),
                ),
                DropdownMenuItem(
                  value: 'Name',
                  child: Text('Name'),
                ),
                DropdownMenuItem(
                  value: 'Age',
                  child: Text('Age'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onSortChanged(value);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip:
              'Share birthday list',
          onPressed: onShare,
          icon: Icon(
            Icons.ios_share_rounded,
            size: 18,
            color: onShare == null
                ? colors.onSurface
                    .withValues(
                    alpha: .25,
                  )
                : colors.primary,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BIRTHDAY CARD
// ============================================================================

class _BirthdayCard
    extends StatelessWidget {
  final BirthdayContact contact;
  final DateTime now;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMessage;

  const _BirthdayCard({
    required this.contact,
    required this.now,
    required this.onEdit,
    required this.onDelete,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    final days =
        contact.daysUntil(now);

    final next =
        contact.nextOccurrence(now);

    final age =
        contact.ageOn(next);

    final isToday = days == 0;
    final isTomorrow = days == 1;
    final isSoon = days <= 7;

    final accent = isToday
        ? Colors.redAccent
        : isSoon
            ? Colors.orange
            : colors.primary;

    final label = isToday
        ? 'TODAY 🎉'
        : isTomorrow
            ? 'TOMORROW'
            : days <= 30
                ? '$days DAYS'
                : DateFormat.MMMd()
                    .format(next);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius:
              BorderRadius.circular(23),
          border: Border.all(
            color: accent
                .withValues(alpha: .12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: .035),
              blurRadius: 18,
              offset:
                  const Offset(0, 7),
            ),
          ],
        ),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(23),
          onTap: onEdit,
          child: Padding(
            padding:
                const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  clipBehavior:
                      Clip.none,
                  children: [
                    Container(
                      width: 61,
                      height: 61,
                      decoration:
                          BoxDecoration(
                        gradient:
                            LinearGradient(
                          begin:
                              Alignment.topLeft,
                          end: Alignment
                              .bottomRight,
                          colors: [
                            accent.withValues(
                              alpha: .22,
                            ),
                            accent.withValues(
                              alpha: .06,
                            ),
                          ],
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          19,
                        ),
                      ),
                      alignment:
                          Alignment.center,
                      child: Text(
                        contact.initials,
                        style: TextStyle(
                          color: accent,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                    if (isToday)
                      Positioned(
                        right: -5,
                        top: -7,
                        child:
                            Container(
                          width: 25,
                          height: 25,
                          decoration:
                              BoxDecoration(
                            color:
                                colors
                                    .surface,
                            shape:
                                BoxShape
                                    .circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors
                                    .black
                                    .withValues(
                                  alpha: .10,
                                ),
                                blurRadius:
                                    8,
                              ),
                            ],
                          ),
                          alignment:
                              Alignment
                                  .center,
                          child:
                              const Text(
                            '🎂',
                            style:
                                TextStyle(
                              fontSize:
                                  13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        contact.name,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight
                                  .w900,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        contact.relation,
                        style:
                            TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight
                                  .w800,
                          color: accent,
                        ),
                      ),
                      const SizedBox(
                        height: 7,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons
                                .cake_outlined,
                            size: 13,
                            color: colors
                                .onSurface
                                .withValues(
                              alpha: .40,
                            ),
                          ),
                          const SizedBox(
                              width: 5),
                          Flexible(
                            child: Text(
                              DateFormat
                                  .yMMMd()
                                  .format(
                                contact.date,
                              ),
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  TextStyle(
                                fontSize:
                                    10,
                                color: colors
                                    .onSurface
                                    .withValues(
                                  alpha:
                                      .48,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                              width: 6),
                          Text(
                            '•',
                            style:
                                TextStyle(
                              color: colors
                                  .onSurface
                                  .withValues(
                                alpha:
                                    .25,
                              ),
                            ),
                          ),
                          const SizedBox(
                              width: 6),
                          Text(
                            'Turns $age',
                            style:
                                TextStyle(
                              fontSize:
                                  10,
                              fontWeight:
                                  FontWeight
                                      .w700,
                              color: colors
                                  .onSurface
                                  .withValues(
                                alpha:
                                    .55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 5),

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Container(
                      constraints:
                          const BoxConstraints(
                        maxWidth: 74,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: accent
                            .withValues(
                          alpha: .09,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            TextStyle(
                          color: accent,
                          fontSize: 7,
                          fontWeight:
                              FontWeight
                                  .w900,
                          letterSpacing:
                              .35,
                        ),
                      ),
                    ),
                    const SizedBox(
                        height: 2),
                    Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip:
                              'Birthday message',
                          visualDensity:
                              VisualDensity
                                  .compact,
                          onPressed:
                              onMessage,
                          icon: Icon(
                            Icons
                                .send_rounded,
                            size: 17,
                            color: colors
                                .primary,
                          ),
                        ),
                        PopupMenuButton<
                            String>(
                          padding:
                              EdgeInsets
                                  .zero,
                          icon: Icon(
                            Icons
                                .more_horiz_rounded,
                            size: 20,
                            color: colors
                                .onSurface
                                .withValues(
                              alpha:
                                  .45,
                            ),
                          ),
                          onSelected:
                              (value) {
                            switch (
                                value) {
                              case 'edit':
                                onEdit();
                                break;
                              case 'message':
                                onMessage();
                                break;
                              case 'delete':
                                onDelete();
                                break;
                            }
                          },
                          itemBuilder:
                              (_) =>
                                  const [
                            PopupMenuItem(
                              value:
                                  'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons
                                        .edit_outlined,
                                    size:
                                        18,
                                  ),
                                  SizedBox(
                                      width:
                                          10),
                                  Text(
                                      'Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value:
                                  'message',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons
                                        .message_outlined,
                                    size:
                                        18,
                                  ),
                                  SizedBox(
                                      width:
                                          10),
                                  Text(
                                    'Birthday Message',
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value:
                                  'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons
                                        .delete_outline,
                                    size:
                                        18,
                                    color: Colors
                                        .redAccent,
                                  ),
                                  SizedBox(
                                      width:
                                          10),
                                  Text(
                                      'Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY
// ============================================================================

class _EmptyBirthdayState
    extends StatelessWidget {
  const _EmptyBirthdayState();

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: colors.primary
            .withValues(alpha: .035),
        borderRadius:
            BorderRadius.circular(27),
        border: Border.all(
          color: colors.primary
              .withValues(alpha: .08),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              gradient:
                  LinearGradient(
                colors: [
                  Color(0xFFE85D75),
                  Color(0xFF9B5DE5),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cake_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No birthdays found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Add friends and family to your birthday list and never forget their special day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: colors.onSurface
                  .withValues(alpha: .52),
            ),
          ),
          const SizedBox(height: 22),
          const Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              _MiniFeature(
                icon: Icons
                    .notifications_active_outlined,
                text: 'Reminders',
              ),
              SizedBox(width: 16),
              _MiniFeature(
                icon: Icons.cake_outlined,
                text: 'Birthdays',
              ),
              SizedBox(width: 16),
              _MiniFeature(
                icon: Icons
                    .favorite_border_rounded,
                text: 'People',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniFeature
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniFeature({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: colors.primary,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            fontWeight:
                FontWeight.w700,
            color: colors.onSurface
                .withValues(alpha: .65),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// INPUT
// ============================================================================

class _BirthdayInput
    extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _BirthdayInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      textCapitalization:
          TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: colors
            .surfaceContainerHighest
            .withValues(alpha: .45),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colors.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DATE PICKER
// ============================================================================

class _DatePickerCard
    extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;

  const _DatePickerCard({
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors
                .surfaceContainerHighest
                .withValues(alpha: .45),
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: colors.outline
                  .withValues(alpha: .08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.pink
                      .withValues(alpha: .10),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons
                      .calendar_month_rounded,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Birthday',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMMd()
                          .format(
                        selectedDate,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons
                    .chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TIPS
// ============================================================================

class _TipsSheet
    extends StatelessWidget {
  const _TipsSheet();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Birthday Tips ✨',
              style: TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            SizedBox(height: 18),
            _TipRow(
              icon:
                  Icons.message_rounded,
              title:
                  'Send a personal message',
              text:
                  'A thoughtful message can make their day.',
            ),
            _TipRow(
              icon:
                  Icons.card_giftcard_rounded,
              title:
                  'Choose a meaningful gift',
              text:
                  'Think about their hobbies and interests.',
            ),
            _TipRow(
              icon: Icons.call_rounded,
              title: 'Give them a call',
              text:
                  'Sometimes a quick call means the most.',
            ),
            _TipRow(
              icon:
                  Icons.photo_camera_rounded,
              title:
                  'Share a memory',
              text:
                  'Send an old photo or special memory.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _TipRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary
                  .withValues(alpha: .09),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors
                        .onSurface
                        .withValues(
                      alpha: .52,
                    ),
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
// GIFT IDEAS
// ============================================================================

class _GiftIdeasSheet
    extends StatelessWidget {
  const _GiftIdeasSheet();

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    final ideas = [
      ('🎧', 'Tech & Gadgets'),
      ('📚', 'Books'),
      ('🌸', 'Flowers'),
      ('🍫', 'Chocolates'),
      ('👕', 'Fashion'),
      ('🎮', 'Gaming'),
      ('☕', 'Coffee & Food'),
      ('🎟️', 'Experiences'),
    ];

    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Gift Ideas 🎁',
              style: TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Quick inspiration for their special day.',
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurface
                    .withValues(alpha: .55),
              ),
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: ideas.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (_, index) {
                final item =
                    ideas[index];

                return Container(
                  padding:
                      const EdgeInsets.all(
                    11,
                  ),
                  decoration:
                      BoxDecoration(
                    color: colors
                        .surfaceContainerHighest
                        .withValues(
                      alpha: .45,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        item.$1,
                        style:
                            const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(
                          width: 9),
                      Expanded(
                        child: Text(
                          item.$2,
                          style:
                              const TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}