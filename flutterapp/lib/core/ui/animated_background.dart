import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedParticlesBackground extends StatefulWidget {
  const AnimatedParticlesBackground({this.color, super.key});

  final Color? color;

  @override
  State<AnimatedParticlesBackground> createState() => _AnimatedParticlesBackgroundState();
}

class _AnimatedParticlesBackgroundState extends State<AnimatedParticlesBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  final math.Random _rng = math.Random();
  late final List<_Particle> _particles = List.generate(80, (_) => _Particle(_rng));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ParticlesPainter(_particles, _controller.value, color),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle(math.Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        r = rng.nextDouble() * 2.5 + 0.8,
        vx = (rng.nextDouble() - 0.5) * 0.0025,
        vy = (rng.nextDouble() - 0.5) * 0.0025,
        hue = rng.nextDouble();

  double x, y, r, vx, vy, hue;

  void step(Size size) {
    x += vx;
    y += vy;
    if (x < -0.05) x = 1.05;
    if (x > 1.05) x = -0.05;
    if (y < -0.05) y = 1.05;
    if (y > 1.05) y = -0.05;
  }
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter(this.particles, this.t, this.primaryColor);

  final List<_Particle> particles;
  final double t;
  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      p.step(size);
      final dx = p.x * size.width;
      final dy = p.y * size.height;
      final color = HSVColor.fromAHSV(0.12, (p.hue * 360 + t * 360) % 360, 0.65, 1.0).toColor();
      paint.color = color.withOpacity(0.15).withRed(primaryColor.red);
      canvas.drawCircle(Offset(dx, dy), p.r * 3.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}

class TopWaves extends StatelessWidget {
  const TopWaves({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _WavesPainter(
            colors: [
              scheme.primary.withOpacity(.12),
              scheme.secondary.withOpacity(.10),
              scheme.tertiary.withOpacity(.08),
            ],
          ),
        ),
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  _WavesPainter({required this.colors});
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paths = <Path>[
      _wave(size, 0.75, 18),
      _wave(size, 0.6, 24),
      _wave(size, 0.45, 30),
    ];
    for (var i = 0; i < paths.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawPath(paths[i], paint);
    }
  }

  Path _wave(Size size, double heightFactor, double amplitude) {
    final path = Path();
    final h = size.height * heightFactor;
    path.moveTo(0, 0);
    path.lineTo(0, h);
    path.quadraticBezierTo(size.width * .25, h + amplitude, size.width * .5, h);
    path.quadraticBezierTo(size.width * .75, h - amplitude, size.width, h);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
