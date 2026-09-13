import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: WizardDefenseScreen(),
  ));
}

enum GameState { menu, playing, gameOver }

class WizardDefenseScreen extends StatefulWidget {
  const WizardDefenseScreen({super.key});

  @override
  State<WizardDefenseScreen> createState() => _WizardDefenseScreenState();
}

class _WizardDefenseScreenState extends State<WizardDefenseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  GameState gameState = GameState.menu;

  double wizardX = 30;
  double wizardY = 200;
  final double wizardW = 55;
  final double wizardH = 75;

  int hp = 3;
  int score = 0;
  int coins = 0;
  int level = 1;
  int power = 1;

  bool shieldActive = false;
  double shieldTime = 0;

  double joyX = 0;
  double joyY = 0;

  List<Map<String, dynamic>> enemies = [];
  List<Map<String, dynamic>> spells = [];
  List<Map<String, dynamic>> particles = [];

  double spawnTimer = 0;
  DateTime lastTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameState = GameState.playing;
      hp = 3;
      score = 0;
      coins = 0;
      level = 1;
      power = 1;
      shieldActive = false;
      shieldTime = 0;
      enemies.clear();
      spells.clear();
      particles.clear();
      wizardX = 30;
      wizardY = 200;
      lastTime = DateTime.now();
    });
  }

  void _gameLoop() {
    if (gameState != GameState.playing) return;

    final now = DateTime.now();
    double dt = now.difference(lastTime).inMilliseconds / 1000.0;
    lastTime = now;
    if (dt > 0.1) dt = 0.1;

    final media = MediaQuery.of(context).size;
    double gameAreaHeight = media.height * 0.68;

    setState(() {
      // Gerak Wizard
      wizardX += joyX * 230 * dt;
      wizardY += joyY * 230 * dt;

      wizardX = wizardX.clamp(0.0, media.width - wizardW);
      wizardY = wizardY.clamp(0.0, gameAreaHeight - wizardH - 25);

      // Perisai
      if (shieldActive) {
        shieldTime -= dt;
        if (shieldTime <= 0) shieldActive = false;
      }

      // Spawn Musuh
      spawnTimer += dt;
      double delay = (1.4 - level * 0.05).clamp(0.5, 1.4);
      if (spawnTimer >= delay) {
        spawnTimer = 0;
        enemies.add({
          'x': media.width + 40,
          'y': Random().nextDouble() * (gameAreaHeight - 100) + 30,
          'w': 34.0,
          'h': 34.0,
          'speed': 60 + Random().nextDouble() * 45 + level * 7,
        });
      }

      // Gerak Sihir
      for (int i = spells.length - 1; i >= 0; i--) {
        spells[i]['x'] += spells[i]['speed'] * dt;
        if (spells[i]['x'] > media.width) {
          spells.removeAt(i);
        }
      }

      // Update Musuh & Tabrakan
      for (int i = enemies.length - 1; i >= 0; i--) {
        var e = enemies[i];
        e['x'] -= e['speed'] * dt;

        // Tabrakan Wizard
        if (e['x'] < wizardX + wizardW &&
            e['x'] + e['w'] > wizardX &&
            e['y'] < wizardY + wizardH &&
            e['y'] + e['h'] > wizardY) {
          enemies.removeAt(i);
          if (!shieldActive) {
            hp--;
            if (hp <= 0) gameState = GameState.gameOver;
          }
          continue;
        }

        // Kena Sihir
        for (int j = spells.length - 1; j >= 0; j--) {
          var s = spells[j];
          double r = s['radius'];
          if (s['x'] + r > e['x'] &&
              s['x'] - r < e['x'] + e['w'] &&
              s['y'] + r > e['y'] &&
              s['y'] - r < e['y'] + e['h']) {
            _createParticles(e['x'] + e['w'] / 2, e['y'] + e['h'] / 2, 10);
            enemies.removeAt(i);
            spells.removeAt(j);
            score += 10 * power;
            coins += 5;
            level = (score / 100).floor() + 1;
            break;
          }
        }
      }

      // Partikel
      for (int i = particles.length - 1; i >= 0; i--) {
        var p = particles[i];
        p['x'] += p['vx'] * dt;
        p['y'] += p['vy'] * dt;
        p['life'] -= dt;
        if (p['life'] <= 0) particles.removeAt(i);
      }
    });
  }

  void _createParticles(double x, double y, int count) {
    for (int i = 0; i < count; i++) {
      particles.add({
        'x': x,
        'y': y,
        'vx': (Random().nextDouble() - 0.5) * 180,
        'vy': (Random().nextDouble() - 0.5) * 180,
        'life': 0.5,
      });
    }
  }

  void _shoot() {
    if (gameState != GameState.playing) return;
    spells.add({
      'x': wizardX + wizardW,
      'y': wizardY + 35,
      'speed': 520.0,
      'radius': 7.0 + (power * 2),
    });
    _createParticles(wizardX + wizardW, wizardY + 35, 5);
  }

  void _useBomb() {
    if (gameState != GameState.playing || coins < 20) return;
    setState(() {
      coins -= 20;
      for (int i = enemies.length - 1; i >= 0; i--) {
        if ((enemies[i]['x'] - wizardX).abs() < 300) {
          _createParticles(enemies[i]['x'], enemies[i]['y'], 12);
          enemies.removeAt(i);
          score += 15;
        }
      }
    });
  }

  void _useLightning() {
    if (gameState != GameState.playing || coins < 30) return;
    setState(() {
      coins -= 30;
      int amount = min(4, enemies.length);
      for (int i = 0; i < amount; i++) {
        _createParticles(enemies[0]['x'], enemies[0]['y'], 15);
        enemies.removeAt(0);
        score += 20;
      }
    });
  }

  void _useShield() {
    if (gameState != GameState.playing || coins < 15) return;
    setState(() {
      coins -= 15;
      shieldActive = true;
      shieldTime = 5.0;
    });
  }

  void _useUpgrade() {
    if (gameState != GameState.playing || coins < 50) return;
    setState(() {
      coins -= 50;
      power++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090512),
      body: SafeArea(
        child: Column(
          children: [
            // GAME CANVAS AREA (68%)
            Expanded(
              flex: 68,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: GamePainter(
                      wizardX: wizardX,
                      wizardY: wizardY,
                      wizardW: wizardW,
                      wizardH: wizardH,
                      shieldActive: shieldActive,
                      enemies: enemies,
                      spells: spells,
                      particles: particles,
                    ),
                  ),

                  // UI HEADER
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("❤️ $hp", style: _uiStyle()),
                        Text("⭐ $score", style: _uiStyle()),
                        Text("💎 $coins", style: _uiStyle()),
                        Text("🏆 LV $level", style: _uiStyle()),
                      ],
                    ),
                  ),

                  // OVERLAY MENU
                  if (gameState == GameState.menu)
                    _buildOverlay(
                      title: "🧙 WIZARD DEFENSE",
                      desc: "Jadilah penyihir hebat!\nHancurkan monster dengan sihir.",
                      btnText: "✨ MULAI GAME",
                      btnColor: const Color(0xFF8E44AD),
                      onTap: _startGame,
                    ),

                  // OVERLAY GAME OVER
                  if (gameState == GameState.gameOver)
                    _buildOverlay(
                      title: "💀 GAME OVER",
                      desc: "Skor Akhir: $score\nPermata: $coins",
                      btnText: "🔄 MAIN LAGI",
                      btnColor: Colors.blueAccent,
                      onTap: _startGame,
                    ),
                ],
              ),
            ),

            // CONTROLS AREA (32%)
            Expanded(
              flex: 32,
              child: Container(
                color: const Color(0xFF15121C),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // JOYSTICK DUMMY/TOUCH CONTROL
                    GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          joyX = (details.localPosition.dx - 50) / 50;
                          joyY = (details.localPosition.dy - 50) / 50;
                          joyX = joyX.clamp(-1.0, 1.0);
                          joyY = joyY.clamp(-1.0, 1.0);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          joyX = 0;
                          joyY = 0;
                        });
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF30293A),
                          border: Border.all(color: const Color(0xFF695C78), width: 3),
                        ),
                        child: Center(
                          child: Transform.translate(
                            offset: Offset(joyX * 25, joyY * 25),
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFA98FC2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // SKILLS GRID
                    SizedBox(
                      width: 125,
                      height: 125,
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _skillBtn("💥\nBOM", _useBomb),
                          _skillBtn("⚡\nPETIR", _useLightning),
                          _skillBtn("🛡️\nPERISAI", _useShield),
                          _skillBtn("⬆️\nUPGRADE", _useUpgrade),
                        ],
                      ),
                    ),

                    // SHOOT BUTTON
                    GestureDetector(
                      onTap: _shoot,
                      child: Container(
                        width: 95,
                        height: 95,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF9B59B6),
                          border: Border.all(color: const Color(0xFFC39BD3), width: 4),
                        ),
                        child: const Center(
                          child: Text("🔮\nSIHIR",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _uiStyle() => const TextStyle(
      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13);

  Widget _skillBtn(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF49345A),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, color: Colors.white)),
    );
  }

  Widget _buildOverlay({
    required String title,
    required String desc,
    required String btnText,
    required Color btnColor,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD7A7FF))),
            const SizedBox(height: 12),
            Text(desc,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 12)),
              child: Text(btnText,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final double wizardX, wizardY, wizardW, wizardH;
  final bool shieldActive;
  final List<Map<String, dynamic>> enemies;
  final List<Map<String, dynamic>> spells;
  final List<Map<String, dynamic>> particles;

  GamePainter({
    required this.wizardX,
    required this.wizardY,
    required this.wizardW,
    required this.wizardH,
    required this.shieldActive,
    required this.enemies,
    required this.spells,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Latar Belakang
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF17102F), Color(0xFF302452), Color(0xFF17452E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Bintang
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 30; i++) {
      double x = (i * 97) % size.width;
      double y = (i * 43) % max(1.0, size.height - 70);
      canvas.drawRect(Rect.fromLTWH(x, y, 2, 2), starPaint);
    }

    // Tanah
    final groundPaint = Paint()..color = const Color(0xFF287A46);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height - 25, size.width, 25), groundPaint);

    // Wizard
    double x = wizardX;
    double y = wizardY;

    // Jubah
    final cloakPaint = Paint()..color = const Color(0xFF6C3483);
    Path cloak = Path()
      ..moveTo(x + 8, y + 70)
      ..lineTo(x + 47, y + 70)
      ..lineTo(x + 40, y + 28)
      ..lineTo(x + 15, y + 28)
      ..close();
    canvas.drawPath(cloak, cloakPaint);

    // Kepala
    final headPaint = Paint()..color = const Color(0xFFF5CBA7);
    canvas.drawCircle(Offset(x + 27, y + 25), 15, headPaint);

    // Topi
    final hatPaint = Paint()..color = const Color(0xFF4A235A);
    Path hat = Path()
      ..moveTo(x + 8, y + 18)
      ..lineTo(x + 46, y + 18)
      ..lineTo(x + 28, y - 18)
      ..close();
    canvas.drawPath(hat, hatPaint);

    // Perisai
    if (shieldActive) {
      final shieldPaint = Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(Offset(x + 27, y + 38), 55, shieldPaint);
    }

    // Sihir / Spells
    final spellPaint = Paint()..color = const Color(0xFFD98CFF);
    for (var s in spells) {
      canvas.drawCircle(Offset(s['x'], s['y']), s['radius'], spellPaint);
    }

    // Musuh
    final enemyPaint = Paint()..color = const Color(0xFFE74C3C);
    for (var e in enemies) {
      canvas.drawRect(
          Rect.fromLTWH(e['x'], e['y'], e['w'], e['h']), enemyPaint);
    }

    // Partikel
    final particlePaint = Paint()..color = const Color(0xFFD98CFF);
    for (var p in particles) {
      canvas.drawRect(Rect.fromLTWH(p['x'], p['y'], 4, 4), particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
