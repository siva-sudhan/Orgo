import 'package:flutter/material.dart';

class LevelProgressCard extends StatelessWidget {
  final int xp;
  final int level;
  final int xpToNextLevel;

  const LevelProgressCard({
    required this.xp,
    required this.level,
    required this.xpToNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = xpToNextLevel / 100;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Level $level", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              minHeight: 10,
            ),
            SizedBox(height: 6),
            Text("$xpToNextLevel XP to next level"),
          ],
        ),
      ),
    );
  }
}
