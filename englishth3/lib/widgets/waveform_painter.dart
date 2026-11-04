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
    final centerY = size.height / 2;
    const barCount = 32;
    final spacing = size.width / barCount;

    if (!isRecording) {
      final paint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.25)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width, centerY),
        paint,
      );
      return;
    }

    final normalizedAmp = (amplitude.abs().clamp(0.0, 50.0)) / 50.0;
    final isSilent = normalizedAmp < 0.05;

    final barPaint = Paint()
      ..color = isSilent ? Colors.indigo.withValues(alpha: 0.25) : waveColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barCount; i++) {
      final x = i * spacing + spacing / 2;
      if (isSilent) {
        // Khi người dùng KHÔNG nói gì: Sóng đứng yên dạng chấm nhỏ phẳng, tuyệt đối không rung nhảy
        canvas.drawCircle(Offset(x, centerY), 1.5, barPaint);
      } else {
        // Khi người dùng nói: Độ cao thanh nảy lên tương ứng với âm lượng giọng nói thực tế
        final waveProfile = sin((i / barCount) * pi);
        final dynamicH = normalizedAmp * (size.height * 0.42) * (0.3 + 0.7 * waveProfile);
        final h = max(2.5, dynamicH);
        canvas.drawLine(
          Offset(x, centerY - h),
          Offset(x, centerY + h),
          barPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.amplitude != amplitude || oldDelegate.isRecording != isRecording;
  }
}

