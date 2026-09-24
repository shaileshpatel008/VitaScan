import 'package:flutter/material.dart';

/// Scales its child like a heartbeat at [bpm] (a quick double-thump per beat).
class Heartbeat extends StatefulWidget {
  const Heartbeat({super.key, required this.child, this.bpm = 64, this.enabled = true, this.amount = 0.12});

  final Widget child;
  final double bpm;
  final bool enabled;
  final double amount;

  @override
  State<Heartbeat> createState() => _HeartbeatState();
}

class _HeartbeatState extends State<Heartbeat> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: _period)..repeat();

  Duration get _period => Duration(milliseconds: (60000 / widget.bpm.clamp(40, 180)).round());

  @override
  void didUpdateWidget(covariant Heartbeat old) {
    super.didUpdateWidget(old);
    if ((old.bpm - widget.bpm).abs() > 2) {
      _c.duration = _period;
      if (widget.enabled) _c.repeat();
    }
    if (!widget.enabled) _c.stop();
    if (widget.enabled && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _curve(double t) {
    // Two bumps: systolic thump then a smaller echo.
    double bump(double center, double width) {
      final d = (t - center) / width;
      return d.abs() > 1 ? 0 : 1 - d * d;
    }

    return bump(0.12, 0.1) + 0.45 * bump(0.32, 0.09);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(scale: 1 + widget.amount * _curve(_c.value), child: child),
      child: widget.child,
    );
  }
}

/// Soft expanding rings behind a widget, used to draw attention calmly.
class PulseHalo extends StatefulWidget {
  const PulseHalo({super.key, required this.child, required this.color, this.size = 120, this.rings = 2});

  final Widget child;
  final Color color;
  final double size;
  final int rings;

  @override
  State<PulseHalo> createState() => _PulseHaloState();
}

class _PulseHaloState extends State<PulseHalo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < widget.rings; i++)
              Builder(
                builder: (_) {
                  final t = (_c.value + i / widget.rings) % 1.0;
                  return Container(
                    width: widget.size * (0.45 + 0.55 * t),
                    height: widget.size * (0.45 + 0.55 * t),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: 0.28 * (1 - t)),
                    ),
                  );
                },
              ),
            child!,
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
