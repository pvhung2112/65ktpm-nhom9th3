import 'dart:math';
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final double amplitude;
  final bool isRecording;
  final Color waveColor;

  WaveformPainter({
    required this.amplitude,
    required this.isRecording,
    this.waveColor = const Color(0xFF4F46E5),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isRecording) {
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    const barCount = 30;
    final spacing = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * spacing + spacing / 2;
      // Sinh độ cao sóng ngẫu nhiên theo biên độ amplitude
      final normalizedAmp = (amplitude.abs().clamp(0.0, 50.0)) / 50.0;
      final h = sin((i / barCount) * pi) * (normalizedAmp * (size.height / 2) + 6);

      canvas.drawLine(
        Offset(x, centerY - h),
        Offset(x, centerY + h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.amplitude != amplitude || oldDelegate.isRecording != isRecording;
  }
}

