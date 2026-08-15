import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../utils/formatters.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final results = app.globalSearch(_query);
    final txs = results['transactions'] ?? [];
    final tasks = results['tasks'] ?? [];
    final notes = results['notes'] ?? [];
    final goals = results['goals'] ?? [];
    final hasResults = txs.isNotEmpty || tasks.isNotEmpty || notes.isNotEmpty || goals.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search everything...', border: InputBorder.none),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      body: _query.isEmpty
          ? Center(child: Text('Search transactions, tasks, notes & goals', style: TextStyle(color: Colors.grey.shade600)))
          : !hasResults
              ? Center(child: Text('No results for "$_query"', style: TextStyle(color: Colors.grey.shade600)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (txs.isNotEmpty) ...[
                      const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...txs.map((t) => ListTile(
                            title: Text(t.category),
                            subtitle: Text(t.note.isEmpty ? formatDate(t.date) : t.note),
                            trailing: Text(formatMoney(t.amount, app.currency)),
                          )),
                      const Divider(),
                    ],
                    if (tasks.isNotEmpty) ...[
                      const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...tasks.map((t) => ListTile(title: Text(t.title))),
                      const Divider(),
                    ],
                    if (notes.isNotEmpty) ...[
                      const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...notes.map((n) => ListTile(title: Text(n.title), subtitle: Text(n.content, maxLines: 1, overflow: TextOverflow.ellipsis))),
                      const Divider(),
                    ],
                    if (goals.isNotEmpty) ...[
                      const Text('Goals', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...goals.map((g) => ListTile(title: Text(g.title), trailing: Text('${g.progress}%'))),
                    ],
                  ],
                ),
    );
  }
}
