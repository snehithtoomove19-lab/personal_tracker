import 'package:flutter/material.dart';
import '../services/app_scope.dart';

class LockScreen extends StatefulWidget {
  final Widget child;
  const LockScreen({super.key, required this.child});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _unlocked = false;
  final _controller = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    final app = AppScope.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56),
              const SizedBox(height: 16),
              const Text('Enter PIN',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                textAlign: TextAlign.center,
                decoration: InputDecoration(errorText: _error, counterText: ''),
                onSubmitted: (_) => _tryUnlock(app.pin),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => _tryUnlock(app.pin),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  child: Text('Unlock'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _tryUnlock(String? correctPin) {
    if (_controller.text == correctPin) {
      setState(() => _unlocked = true);
    } else {
      setState(() => _error = 'Incorrect PIN');
    }
  }
}
