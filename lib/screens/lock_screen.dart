
import 'package:flutter/material.dart';

import '../services/app_scope.dart';

class LockScreen extends StatefulWidget {
  final Widget child;

  const LockScreen({
    super.key,
    required this.child,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  bool _unlocked = false;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _error;
  bool _isChecking = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();

    _controller.addListener(_onPinChanged);
  }

  void _onPinChanged() {
    if (_error != null) {
      setState(() {
        _error = null;
      });
    }

    if (_controller.text.length == 6) {
      _tryUnlock();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPinChanged);
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final app = AppScope.of(context);

    return Scaffold(
      backgroundColor: colors.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
          },
          child: Stack(
            children: [
              _buildBackground(context),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    32,
                    24,
                    32,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildLockContent(
                        context,
                        app.pin,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BACKGROUND
  // ===========================================================================

  Widget _buildBackground(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.secondary.withValues(alpha: 0.055),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MAIN CONTENT
  // ===========================================================================

  Widget _buildLockContent(
    BuildContext context,
    String? correctPin,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 430,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLockIcon(context),

          const SizedBox(height: 24),

          Text(
            'Welcome back',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Enter your PIN to continue',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 28),

          _buildLockCard(
            context,
            correctPin,
          ),

          const SizedBox(height: 18),

          Text(
            'Your personal tracker is protected',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOCK ICON
  // ===========================================================================

  Widget _buildLockIcon(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.18),
            colors.secondary.withValues(alpha: 0.08),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Icon(
          Icons.lock_rounded,
          size: 30,
          color: colors.primary,
        ),
      ),
    );
  }

  // ===========================================================================
  // LOCK CARD
  // ===========================================================================

  Widget _buildLockCard(
    BuildContext context,
    String? correctPin,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        24,
        22,
        22,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'SECURITY PIN',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          _buildPinDisplay(context),

          const SizedBox(height: 12),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _error != null
                ? Row(
                    key: const ValueKey('error'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 17,
                        color: colors.error,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Your PIN is private and secure',
                    key: const ValueKey('hint'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
          ),

          const SizedBox(height: 22),

          _buildHiddenTextField(context),

          _buildUnlockButton(
            context,
            correctPin,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PIN DISPLAY
  // ===========================================================================

  Widget _buildPinDisplay(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final length = _controller.text.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        6,
        (index) {
          final filled = index < length;
          final active = index == length;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 43,
            height: 54,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 5,
              right: index == 5 ? 0 : 5,
            ),
            decoration: BoxDecoration(
              color: filled
                  ? colors.primary.withValues(alpha: 0.10)
                  : colors.surface.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: filled || active
                    ? colors.primary.withValues(alpha: 0.45)
                    : colors.outlineVariant.withValues(alpha: 0.42),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: filled ? 12 : 8,
                height: filled ? 12 : 8,
                decoration: BoxDecoration(
                  color: filled
                      ? colors.primary
                      : colors.onSurfaceVariant.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  boxShadow: filled
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.20),
                            blurRadius: 7,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // HIDDEN INPUT
  // ===========================================================================

  Widget _buildHiddenTextField(BuildContext context) {
    return SizedBox(
      height: 1,
      width: 1,
      child: Opacity(
        opacity: 0,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          obscureText: true,
          maxLength: 6,
          onSubmitted: (_) => _tryUnlock(),
        ),
      ),
    );
  }

  // ===========================================================================
  // UNLOCK BUTTON
  // ===========================================================================

  Widget _buildUnlockButton(
    BuildContext context,
    String? correctPin,
  ) {
    final colors = Theme.of(context).colorScheme;

    final canUnlock = _controller.text.isNotEmpty && !_isChecking;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: canUnlock ? _tryUnlock : null,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor:
              colors.surfaceContainerHighest.withValues(alpha: 0.55),
          disabledForegroundColor:
              colors.onSurfaceVariant.withValues(alpha: 0.50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isChecking
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: colors.onPrimary,
                  ),
                )
              : Row(
                  key: const ValueKey('unlock'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_open_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'Unlock',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PIN VALIDATION
  // ===========================================================================

  Future<void> _tryUnlock() async {
    if (_isChecking) return;

    final app = AppScope.of(context);
    final correctPin = app.pin;

    if (_controller.text.isEmpty) {
      setState(() {
        _error = 'Please enter your PIN';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _error = null;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 180),
    );

    if (!mounted) return;

    if (_controller.text == correctPin) {
      setState(() {
        _unlocked = true;
        _isChecking = false;
      });

      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      setState(() {
        _isChecking = false;
        _error = 'Incorrect PIN. Please try again.';
      });

      _controller.clear();

      _focusNode.requestFocus();
    }
  }
}

