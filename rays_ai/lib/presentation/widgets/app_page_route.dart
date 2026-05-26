import 'package:flutter/material.dart';

/// Smooth slide + fade transition for all screen pushes.
/// Usage: Navigator.of(context).push(AppPageRoute(builder: (_) => MyScreen()));
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  final AxisDirection direction;

  AppPageRoute({
    required this.builder,
    this.direction = AxisDirection.left,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final begin = _beginOffset(direction);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: Curves.easeOutCubic),
            );
            final slideTween = animation.drive(tween);

            // Outgoing screen slides back slightly
            final secondaryTween = Tween(
              begin: Offset.zero,
              end: _secondaryOffset(direction),
            ).chain(CurveTween(curve: Curves.easeInCubic));

            return SlideTransition(
              position: secondaryAnimation.drive(secondaryTween),
              child: SlideTransition(
                position: slideTween,
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                  ),
                  child: child,
                ),
              ),
            );
          },
        );

  static Offset _beginOffset(AxisDirection direction) {
    switch (direction) {
      case AxisDirection.left:
        return const Offset(1.0, 0.0);
      case AxisDirection.right:
        return const Offset(-1.0, 0.0);
      case AxisDirection.up:
        return const Offset(0.0, 1.0);
      case AxisDirection.down:
        return const Offset(0.0, -1.0);
    }
  }

  static Offset _secondaryOffset(AxisDirection direction) {
    switch (direction) {
      case AxisDirection.left:
        return const Offset(-0.25, 0.0);
      case AxisDirection.right:
        return const Offset(0.25, 0.0);
      case AxisDirection.up:
        return const Offset(0.0, -0.25);
      case AxisDirection.down:
        return const Offset(0.0, 0.25);
    }
  }
}

/// Bottom-sheet style slide-up for modal screens (questionnaire, result).
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  SlideUpPageRoute({required this.builder, super.settings})
      : super(
          opaque: false,
          barrierColor: Colors.black54,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 340),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideTween = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            return FadeTransition(
              opacity: CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
              child: SlideTransition(
                position: animation.drive(slideTween),
                child: child,
              ),
            );
          },
        );
}

/// Fade-scale transition for dialogs and overlays.
class FadeScalePageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  FadeScalePageRoute({required this.builder, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleTween = Tween<double>(begin: 0.92, end: 1.0).chain(
              CurveTween(curve: Curves.easeOutCubic),
            );
            return FadeTransition(
              opacity: CurvedAnimation(
                  parent: animation, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: child,
              ),
            );
          },
        );
}

/// A widget that slides+fades its child in when first shown.
/// Wrap any card or section for staggered entry animations.
class SlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  const SlideInWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
    this.beginOffset = const Offset(0.0, 0.06),
  });

  @override
  State<SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<SlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _slide = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Staggered list animation helper.
/// Wraps each child with a progressive delay for a smooth cascade effect.
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration initialDelay;
  final Duration staggerDelay;

  const StaggeredList({
    super.key,
    required this.children,
    this.initialDelay = const Duration(milliseconds: 80),
    this.staggerDelay = const Duration(milliseconds: 70),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < children.length; i++)
          SlideInWidget(
            delay: initialDelay + staggerDelay * i,
            beginOffset: const Offset(0.0, 0.05),
            child: children[i],
          ),
      ],
    );
  }
}
