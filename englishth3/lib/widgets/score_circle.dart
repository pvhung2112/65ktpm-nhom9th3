import 'package:flutter/material.dart';

class ScoreCircle extends StatelessWidget {
  final double score;
  final double size;
  final String label;

  const ScoreCircle({
    super.key,
    required this.score,
    this.size = 90,
    this.label = 'Tổng điểm',
  });

  Color _getScoreColor(double s) {
    if (s >= 80) return const Color(0xFF10B981); // Xanh lá: Xuất sắc
    if (s >= 50) return const Color(0xFFF59E0B); // Vàng cam: Khá/Trung bình
    return const Color(0xFFEF4444); // Đỏ: Cần cải thiện
  }

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    final clampedScore = score.clamp(0.0, 100.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: clampedScore),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, child) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vòng tiến độ xoay tròn mềm mại
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: animatedValue / 100.0,
                      strokeWidth: size * 0.09,
                      strokeCap: StrokeCap.round,
                      backgroundColor: color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  // Điểm số trung tâm
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${animatedValue.toInt()}',
                        style: TextStyle(
                          fontSize: size * 0.30,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'pts',
                        style: TextStyle(
                          fontSize: size * 0.12,
                          fontWeight: FontWeight.w600,
                          color: color.withOpacity(0.75),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ]
      ],
    );
  }
}

class StreakBadge extends StatelessWidget {
  final int streakDays;

  const StreakBadge({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$streakDays ngày',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
