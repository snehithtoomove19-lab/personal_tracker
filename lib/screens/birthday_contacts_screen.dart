import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/birthday_contact.dart';
import '../services/app_scope.dart';

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
  State<BirthdayContactsScreen> createState() => _BirthdayContactsScreenState();
}

class _BirthdayContactsScreenState extends State<BirthdayContactsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;

  String _searchQuery = '';
  String _selectedFilter = 'All';

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
      duration: const Duration(milliseconds: 900),
    );

    _animationController.forward();

    _searchController.addListener(() {
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
      final matchesSearch = contact.name.toLowerCase().contains(_searchQuery) ||
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

    result.sort(
      (a, b) => a.nextOccurrence(now).compareTo(
            b.nextOccurrence(now),
          ),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final now = DateTime.now();

    final contacts = app.birthdayContacts.toList();

    final filtered = _filteredContacts(
      contacts,
      now,
    );

    final todayContacts = contacts
        .where(
          (contact) => contact.daysUntil(now) == 0,
        )
        .toList();

    final weekCount = contacts.where((contact) {
      final days = contact.daysUntil(now);
      return days >= 0 && days <= 7;
    }).length;

    final monthCount = contacts.where((contact) {
      final days = contact.daysUntil(now);
      return days >= 0 && days <= 30;
    }).length;

    final nextBirthday = contacts.isEmpty
        ? null
        : (contacts.toList()
              ..sort(
                (a, b) => a.nextOccurrence(now).compareTo(
                      b.nextOccurrence(now),
                    ),
              ))
            .first;

    final bottomPadding = MediaQuery.of(context).padding.bottom + 110;

    return Scaffold(
      backgroundColor: colors.surface,

      // ===============================================================
      // APP BAR
      // ===============================================================

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Birthdays',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Never miss a special day',
              style: TextStyle(
                fontSize: 10,
                color: colors.onSurface.withValues(alpha: .55),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Birthday tips',
            onPressed: () => _showBirthdayTips(context),
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.pink,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ===============================================================
      // FAB
      // ===============================================================

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editContact(context, app),
        elevation: 7,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Birthday',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          6,
          16,
          bottomPadding,
        ),
        children: [
          // =============================================================
          // HERO
          // =============================================================

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

          // =============================================================
          // TODAY BANNER
          // =============================================================

          if (todayContacts.isNotEmpty)
            _AnimatedSection(
              controller: _animationController,
              delay: 100,
              child: _TodayBirthdayCard(
                contacts: todayContacts,
                onMessage: (contact) {
                  _shareBirthdayMessage(context, contact);
                },
              ),
            ),

          if (todayContacts.isNotEmpty) const SizedBox(height: 16),

          // =============================================================
          // STATISTICS
          // =============================================================

          _AnimatedSection(
            controller: _animationController,
            delay: 150,
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.today_rounded,
                    value: '${todayContacts.length}',
                    label: 'Today',
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _StatCard(
                    icon: Icons.date_range_rounded,
                    value: '$weekCount',
                    label: '7 Days',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _StatCard(
                    icon: Icons.calendar_month_rounded,
                    value: '$monthCount',
                    label: '30 Days',
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // =============================================================
          // SEARCH
          // =============================================================

          _AnimatedSection(
            controller: _animationController,
            delay: 200,
            child: TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Search people or relationships...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      )
                    : null,
                filled: true,
                fillColor:
                    colors.surfaceContainerHighest.withValues(alpha: .55),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: colors.primary,
                    width: 1.3,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // =============================================================
          // FILTERS
          // =============================================================

          _AnimatedSection(
            controller: _animationController,
            delay: 250,
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final selected = _selectedFilter == filter;

                  return ChoiceChip(
                    selected: selected,
                    label: Text(filter),
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    avatar: Icon(
                      filter == 'All'
                          ? Icons.apps_rounded
                          : filter == 'Today'
                              ? Icons.today_rounded
                              : filter == 'This Week'
                                  ? Icons.date_range_rounded
                                  : Icons.calendar_month_rounded,
                      size: 15,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 22),

          // =============================================================
          // QUICK IDEAS
          // =============================================================

          _AnimatedSection(
            controller: _animationController,
            delay: 300,
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
              onTips: () => _showGiftIdeas(context),
            ),
          ),

          const SizedBox(height: 22),

          // =============================================================
          // SECTION HEADER
          // =============================================================

          _SectionHeader(
            count: filtered.length,
            searchActive: _searchQuery.isNotEmpty || _selectedFilter != 'All',
          ),

          const SizedBox(height: 12),

          // =============================================================
          // LIST
          // =============================================================

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
                    delay: 350 + (index * 60),
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
                      onMessage: () => _shareBirthdayMessage(
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
    );
  }

  // ========================================================================
  // ADD / EDIT
  // ========================================================================

  void _editContact(
    BuildContext context,
    dynamic app, {
    BirthdayContact? contact,
  }) {
    final nameCtrl = TextEditingController(
      text: contact?.name ?? '',
    );

    final relationCtrl = TextEditingController(
      text: contact?.relation ?? 'Friend',
    );
    var selectedRelation = _birthdayRelationOptions.contains(
      contact?.relation,
    )
        ? contact!.relation
        : 'Other';

    DateTime selectedDate = contact?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colors = Theme.of(context).colorScheme;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colors.onSurface.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.pink,
                                  Colors.deepPurple,
                                ],
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(17),
                              ),
                            ),
                            child: const Icon(
                              Icons.cake_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact == null
                                      ? 'Add Birthday'
                                      : 'Edit Birthday',
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Keep their special day remembered',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        colors.onSurface.withValues(alpha: .55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      _BirthdayInput(
                        controller: nameCtrl,
                        label: 'Name',
                        hint: 'e.g. Snehith',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRelation,
                        decoration: InputDecoration(
                          labelText: 'Relation',
                          prefixIcon: const Icon(
                            Icons.people_outline_rounded,
                          ),
                          filled: true,
                          fillColor: colors.surfaceContainerHighest
                              .withValues(alpha: .45),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: colors.outline.withValues(alpha: .10),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: colors.outline.withValues(alpha: .10),
                            ),
                          ),
                        ),
                        items: _birthdayRelationOptions
                            .map(
                              (relation) => DropdownMenuItem(
                                value: relation,
                                child: Text(relation),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() {
                            selectedRelation = value;
                            if (value != 'Other') {
                              relationCtrl.text = value;
                            }
                          });
                        },
                      ),
                      if (selectedRelation == 'Other') ...[
                        const SizedBox(height: 10),
                        _BirthdayInput(
                          controller: relationCtrl,
                          label: 'Custom relation',
                          hint: 'e.g. Mentor, Cousin',
                          icon: Icons.edit_note_rounded,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(1900),
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
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest
                                  .withValues(alpha: .45),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: colors.outline.withValues(alpha: .10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.pink.withValues(
                                      alpha: .10,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_rounded,
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
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat.yMMMMd().format(
                                          selectedDate,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: () {
                            if (nameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter a name',
                                  ),
                                ),
                              );
                              return;
                            }

                            final edited = BirthdayContact(
                              id: contact?.id ?? _uuid.v4(),
                              name: nameCtrl.text.trim(),
                              relation: relationCtrl.text.trim().isEmpty
                                  ? 'Friend'
                                  : relationCtrl.text.trim(),
                              date: DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                              ),
                            );

                            if (contact == null) {
                              app.addBirthdayContact(
                                edited,
                              );
                            } else {
                              app.updateBirthdayContact(
                                edited,
                              );
                            }

                            Navigator.pop(
                              sheetContext,
                            );

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  contact == null
                                      ? '🎂 Birthday added'
                                      : '✅ Birthday updated',
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
                            contact == null ? 'Add Birthday' : 'Save Changes',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
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
    dynamic app,
    BirthdayContact contact,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: const Text(
            'Remove Birthday?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Remove ${contact.name} from your birthday reminders?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                app.deleteBirthdayContact(
                  contact.id,
                );

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      '${contact.name} removed',
                    ),
                  ),
                );
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  // ========================================================================
  // SHARE MESSAGE
  // ========================================================================

  Future<void> _shareBirthdayMessage(
    BuildContext context,
    BirthdayContact contact,
  ) async {
    final messages = [
      'Happy Birthday, ${contact.name}! 🎂🎉 Wishing you an amazing day filled with happiness, laughter and beautiful memories! ❤️',
      'Happy Birthday ${contact.name}! 🥳🎂 Hope your special day is absolutely wonderful and the year ahead brings you lots of happiness! ✨',
      'Wishing you the happiest birthday, ${contact.name}! 🎉 May your day be full of love, smiles and everything that makes you happy! 💖',
    ];

    final message = messages[DateTime.now().millisecond % messages.length];

    await SharePlus.instance.share(
      ShareParams(text: message),
    );
  }

  // ========================================================================
  // TIPS
  // ========================================================================

  void _showBirthdayTips(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return const _TipsSheet();
      },
    );
  }

  void _showGiftIdeas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return const _GiftIdeasSheet();
      },
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
        final progress = Curves.easeOutCubic.transform(
          ((controller.value * 1000 - delay) / 650).clamp(0.0, 1.0),
        );

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(
              0,
              18 * (1 - progress),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

// ============================================================================
// HERO CARD
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF4F9A),
            Color(0xFF7C4DFF),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: .22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -25,
            child: Icon(
              Icons.cake_rounded,
              size: 135,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          Positioned(
            right: 45,
            bottom: -25,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 65,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.cake_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const Spacer(),
                  if (todayCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$todayCount today 🎉',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Celebrate the people\nwho matter most 🎂',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                contactCount == 0
                    ? 'Start your birthday list today.'
                    : '$contactCount special ${contactCount == 1 ? 'person' : 'people'} saved.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .82),
                  fontSize: 11,
                ),
              ),
              if (nextBirthday != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
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
                          'Next: ${nextBirthday!.name} • ${nextBirthday!.daysUntil(now) == 0 ? 'Today' : '${nextBirthday!.daysUntil(now)} days'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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

// ============================================================================
// TODAY CARD
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: .13),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Colors.redAccent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Birthday Today!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Make their day special ❤️',
                      style: TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...contacts.map(
            (contact) => Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    child: Text(
                      contact.initials,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      contact.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send birthday message',
                    onPressed: () => onMessage(contact),
                    icon: const Icon(
                      Icons.send_rounded,
                      size: 18,
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
// STAT CARD
// ============================================================================

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
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: colors.outline.withValues(alpha: .06),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(11),
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
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: colors.onSurface.withValues(alpha: .50),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// QUICK ACTIONS
// ============================================================================

class _QuickActions extends StatelessWidget {
  final VoidCallback onMessage;
  final VoidCallback onTips;

  const _QuickActions({
    required this.onMessage,
    required this.onTips,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Birthday Message',
            subtitle: 'Share a wish',
            onTap: onMessage,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.card_giftcard_rounded,
            title: 'Gift Ideas',
            subtitle: 'Find inspiration',
            onTap: onTips,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: .40),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9,
                        color: colors.onSurface.withValues(alpha: .50),
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
// SECTION HEADER
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final int count;
  final bool searchActive;

  const _SectionHeader({
    required this.count,
    required this.searchActive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: Colors.pink.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.people_alt_outlined,
            color: Colors.pink,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                searchActive ? 'Matching People' : 'Your People',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count ${count == 1 ? 'birthday' : 'birthdays'}',
                style: TextStyle(
                  fontSize: 10,
                  color: colors.onSurface.withValues(alpha: .48),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BIRTHDAY CARD
// ============================================================================

class _BirthdayCard extends StatelessWidget {
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
    final colors = Theme.of(context).colorScheme;

    final days = contact.daysUntil(now);
    final next = contact.nextOccurrence(now);
    final age = contact.ageOn(next);

    final isToday = days == 0;
    final isTomorrow = days == 1;
    final isSoon = days <= 7;

    final accent = isToday
        ? Colors.redAccent
        : isSoon
            ? Colors.orange
            : Colors.pink;

    final label = isToday
        ? 'TODAY 🎉'
        : isTomorrow
            ? 'TOMORROW'
            : days <= 30
                ? '$days DAYS'
                : DateFormat.MMMd().format(next);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: accent.withValues(alpha: .11),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .035),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 59,
                      height: 59,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: .20),
                            accent.withValues(alpha: .07),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        contact.initials,
                        style: TextStyle(
                          color: accent,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (isToday)
                      Positioned(
                        right: -5,
                        top: -7,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '🎂',
                              style: TextStyle(
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 13),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        contact.relation,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            size: 13,
                            color: colors.onSurface.withValues(alpha: .42),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              DateFormat.yMMMd().format(
                                contact.date,
                              ),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.onSurface.withValues(
                                  alpha: .50,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: TextStyle(
                              color: colors.onSurface.withValues(
                                alpha: .30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Turns $age',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface.withValues(
                                alpha: .55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Right side
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: 70,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Birthday message',
                          visualDensity: VisualDensity.compact,
                          onPressed: onMessage,
                          icon: Icon(
                            Icons.send_rounded,
                            size: 17,
                            color: colors.primary,
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: colors.onSurface.withValues(
                              alpha: .45,
                            ),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit();
                            } else if (value == 'message') {
                              onMessage();
                            } else if (value == 'delete') {
                              onDelete();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'message',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.message_outlined,
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Birthday Message',
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 10),
                                  Text('Delete'),
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
// EMPTY STATE
// ============================================================================

class _EmptyBirthdayState extends StatelessWidget {
  const _EmptyBirthdayState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 38,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: colors.primary.withValues(alpha: .08),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.withValues(alpha: .14),
                  Colors.deepPurple.withValues(alpha: .10),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cake_outlined,
              color: Colors.pink,
              size: 39,
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'No birthdays found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Add friends and family to your birthday list and never forget their special day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: colors.onSurface.withValues(alpha: .52),
            ),
          ),
          const SizedBox(height: 19),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniFeature(
                icon: Icons.notifications_active_outlined,
                text: 'Reminders',
              ),
              SizedBox(width: 18),
              _MiniFeature(
                icon: Icons.cake_outlined,
                text: 'Birthdays',
              ),
              SizedBox(width: 18),
              _MiniFeature(
                icon: Icons.favorite_border_rounded,
                text: 'People',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MINI FEATURE
// ============================================================================

class _MiniFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniFeature({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: Colors.pink,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: colors.onSurface.withValues(alpha: .65),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// INPUT
// ============================================================================

class _BirthdayInput extends StatelessWidget {
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
    final colors = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: .45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
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
// TIPS SHEET
// ============================================================================

class _TipsSheet extends StatelessWidget {
  const _TipsSheet();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Birthday Tips ✨',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 16),
            _TipRow(
              icon: Icons.message_rounded,
              title: 'Send a personal message',
              text: 'A thoughtful message can make their day.',
            ),
            _TipRow(
              icon: Icons.card_giftcard_rounded,
              title: 'Choose a meaningful gift',
              text: 'Think about their hobbies and interests.',
            ),
            _TipRow(
              icon: Icons.call_rounded,
              title: 'Give them a call',
              text: 'Sometimes a quick call means the most.',
            ),
            _TipRow(
              icon: Icons.photo_camera_rounded,
              title: 'Share a memory',
              text: 'Send an old photo or special memory.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
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
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 15,
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: .52),
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
// GIFT IDEAS SHEET
// ============================================================================

class _GiftIdeasSheet extends StatelessWidget {
  const _GiftIdeasSheet();

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gift Ideas 🎁',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Quick inspiration for their special day.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: .55),
              ),
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ideas.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (_, index) {
                final item = ideas[index];

                return Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
