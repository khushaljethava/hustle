import 'package:flutter/material.dart';
import '../../../blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return OutlinedButton(
          onPressed: isLoading
              ? null
              : () => context.read<AuthBloc>().add(SignInWithGoogleRequested()),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1.5,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _GoogleIcon(),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: _GoogleLetterIcon(),
    );
  }
}

class _GoogleLetterIcon extends StatelessWidget {
  const _GoogleLetterIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GooglePainter(),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const sweepAngle = 2 * 3.14159265 * 0.75;

    // Blue arc (top-right to bottom)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    // Red arc
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    // Yellow arc
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    // Green arc
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - size.width * 0.18) / 2;
    final ovalRect = Rect.fromCircle(center: center, radius: radius);

    // Draw four colored arcs
    // Red: top (315° to 45°)
    canvas.drawArc(ovalRect, -1.9635, 1.5708, false, redPaint);
    // Blue: right + partial bottom (45° to 195°)
    canvas.drawArc(ovalRect, -0.3927, sweepAngle * 0.5, false, bluePaint);
    // Yellow: bottom-left (195° to 270°)
    canvas.drawArc(ovalRect, 2.7489, 0.7854, false, yellowPaint);
    // Green: left (270° to 315°)
    canvas.drawArc(ovalRect, 3.5343, 0.7854, false, greenPaint);

    // Horizontal bar for the "G" cut-in (blue fill)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        center.dx - size.width * 0.09,
        center.dy - size.height * 0.09,
        size.width * 0.5,
        size.height * 0.18,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
