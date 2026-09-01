import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/birthday_contact.dart';
import '../services/app_scope.dart';

const _uuid = Uuid();

class BirthdayContactsScreen extends StatelessWidget {
  const BirthdayContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final now = DateTime.now();

    final contacts = app.birthdayContacts.toList()
      ..sort(
        (a, b) => a.nextOccurrence(now).compareTo(b.nextOccurrence(now)),
      );

    final todayCount = contacts.where((contact) {
      return contact.daysUntil(now) == 0;
    }).length;

    final weekCount = contacts.where((contact) {
      final days = contact.daysUntil(now);
      return days >= 0 && days <= 7;
    }).length;

    final monthCount = contacts.where((contact) {
      final days = contact.daysUntil(now);
      return days >= 0 && days <= 30;
    }).length;

    final bottomPadding = MediaQuery.of(context).padding.bottom + 100;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Birthday Contacts',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Never miss a special day',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cake_rounded,
                color: Colors.pink,
                size: 21,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editContact(context, app),
        elevation: 5,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add Birthday',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          bottomPadding,
        ),
        children: [
          // ============================================================
          // HERO HEADER
          // ============================================================

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.pink.shade400,
                  Colors.deepPurple.shade400,
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withValues(alpha: 0.20),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -12,
                  top: -18,
                  child: Icon(
                    Icons.cake_rounded,
                    size: 110,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Positioned(
                  right: 65,
                  bottom: -22,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 58,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.cake_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Celebrate the people\nwho matter most ÃƒÆ’Ã‚Â°Ãƒâ€¦Ã‚Â¸Ãƒâ€¦Ã‚Â½ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â°',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      contacts.isEmpty
                          ? 'Add your first birthday to get started.'
                          : '${contacts.length} special ${contacts.length == 1 ? 'person' : 'people'} in your birthday list.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ============================================================
          // STATISTICS
          // ============================================================

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.today_rounded,
                  value: '$todayCount',
                  label: 'Today',
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.date_range_rounded,
                  value: '$weekCount',
                  label: 'This week',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_month_rounded,
                  value: '$monthCount',
                  label: '30 days',
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ============================================================
          // DESCRIPTION
          // ============================================================

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add friends and family here. Your reminder center will automatically show birthdays that are coming up.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: colors.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ============================================================
          // SECTION HEADER
          // ============================================================

          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.10),
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
                      contacts.isEmpty ? 'Your Birthday List' : 'Your People',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contacts.isEmpty
                          ? 'No birthdays added yet'
                          : '${contacts.length} ${contacts.length == 1 ? 'contact' : 'contacts'} sorted by next birthday',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ============================================================
          // CONTACTS / EMPTY STATE
          // ============================================================

          if (contacts.isEmpty)
            const _EmptyBirthdayState()
          else
            ...contacts.map(
              (contact) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ADD / EDIT
  // ==========================================================================

  void _editContact(
    BuildContext context,
    dynamic app, {
    BirthdayContact? contact,
  }) {
    final nameCtrl = TextEditingController(text: contact?.name ?? '');

    final relationCtrl = TextEditingController(
      text: contact?.relation ?? 'Friend',
    );

    DateTime selectedDate = contact?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.pink,
                                  Colors.deepPurple,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.cake_rounded,
                              color: Colors.white,
                              size: 27,
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Keep their special day remembered',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _BirthdayInput(
                        controller: nameCtrl,
                        label: 'Name',
                        hint: 'e.g. Snehith',
                        icon: Icons.person_outline_rounded,
                      ),

                      const SizedBox(height: 12),

                      _BirthdayInput(
                        controller: relationCtrl,
                        label: 'Relation',
                        hint: 'e.g. Sister, Friend, Brother',
                        icon: Icons.people_outline_rounded,
                      ),

                      const SizedBox(height: 12),

                      // DATE PICKER
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(17),
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
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.surface.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: colors.outline.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.pink.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(13),
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
                                      const SizedBox(height: 3),
                                      Text(
                                        DateFormat.yMMMMd()
                                            .format(selectedDate),
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
                              ScaffoldMessenger.of(context).showSnackBar(
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
                              app.addBirthdayContact(edited);
                            } else {
                              app.updateBirthdayContact(edited);
                            }

                            Navigator.pop(sheetContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  contact == null
                                      ? 'ÃƒÆ’Ã‚Â°Ãƒâ€¦Ã‚Â¸Ãƒâ€¦Ã‚Â½ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â° Birthday added'
                                      : 'ÃƒÆ’Ã‚Â¢Ãƒâ€¦Ã¢â‚¬Å“Ãƒâ€šÃ‚Â¨ Birthday updated',
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

  // ==========================================================================
  // DELETE
  // ==========================================================================

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
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Remove Birthday?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 13,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
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
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
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

  const _BirthdayCard({
    required this.contact,
    required this.now,
    required this.onEdit,
    required this.onDelete,
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

    final Color accent = isToday
        ? Colors.redAccent
        : isSoon
            ? Colors.orange
            : Colors.pink;

    final String label = isToday
        ? 'TODAY ÃƒÆ’Ã‚Â°Ãƒâ€¦Ã‚Â¸Ãƒâ€¦Ã‚Â½ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â°'
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
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: accent.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // AVATAR
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.18),
                            accent.withValues(alpha: 0.07),
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
                        right: -4,
                        top: -6,
                        child: Container(
                          width: 23,
                          height: 23,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'ÃƒÆ’Ã‚Â°Ãƒâ€¦Ã‚Â¸Ãƒâ€¦Ã‚Â½ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 13),

                // DETAILS
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        contact.relation,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            size: 13,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              DateFormat.yMMMd().format(contact.date),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Turns $age',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // BADGE + MENU
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 72),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.09),
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
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        size: 21,
                        color: Colors.grey.shade500,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
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
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.withValues(alpha: 0.14),
                  Colors.deepPurple.withValues(alpha: 0.10),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cake_outlined,
              color: Colors.pink,
              size: 37,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No birthdays yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Add friends and family to your birthday list and weÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ll help you remember their special days.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniFeature(
                icon: Icons.notifications_active_outlined,
                text: 'Reminders',
              ),
              SizedBox(width: 14),
              _MiniFeature(
                icon: Icons.cake_outlined,
                text: 'Birthdays',
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
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
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
        fillColor: colors.surface.withValues(alpha: 0.42),
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
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
