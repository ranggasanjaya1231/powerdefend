import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';

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

class _WizardDefenseScreenState extends State<WizardDefenseScreen> {
  late WizardDefenseGame game;

  @override
  void initState() {
    super.initState();
    game = WizardDefenseGame(onStateChanged: () => setState(() {}));
  }

  void _restartGame() {
    setState(() {
      game.startGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090512),
      body: Stack(
        children: [
          // Game Canvas
          GameWidget(game: game),

          // OVERLAY 1: MENU UTAMA
          if (game.gameState == GameState.menu)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "🧙 WIZARD DEFENSE",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD7A7FF)),
                    ),
                    const SizedBox(height: 15),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        "Jadilah penyihir hebat!\nGerakkan penyihir dengan joystick dan hancurkan monster menggunakan sihir.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: _restartGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E44AD),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                      ),
                      child: const Text("✨ MULAI GAME",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),

          // OVERLAY 2: GAME OVER
          if (game.gameState == GameState.gameOver)
            Container(
              color: Colors.black.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "💀 GAME OVER",
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Skor: ${game.score}\nPermata: ${game.coins}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18, height: 1.6),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: _restartGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                      ),
                      child: const Text("🔄 MAIN LAGI",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),

          // OVERLAY 3: KONTROL IN-GAME (Hanya tampil saat playing)
          if (game.gameState == GameState.playing)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildSkillBtn("💥\nBOM", () => game.useMagicBomb()),
                        _buildSkillBtn("⚡\nPETIR", () => game.useLightning()),
                        _buildSkillBtn("🛡️\nPERISAI", () => game.useShield()),
                        _buildSkillBtn("⬆️\nUPGRADE", () => game.useUpgrade()),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => game.shootSpell(),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(32),
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text("🔮\nSIHIR",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkillBtn(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF49345A),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Colors.white)),
    );
  }
}

class WizardDefenseGame extends FlameGame with HasCollisionDetection {
  final VoidCallback onStateChanged;
  WizardDefenseGame({required this.onStateChanged});

  GameState gameState = GameState.menu;

  late WizardPlayer wizard;
  late JoystickComponent joystick;
  late TextComponent uiText;

  int hp = 3;
  int score = 0;
  int coins = 0;
  int level = 1;
  int power = 1;

  bool shieldActive = false;
  double shieldTime = 0;
  double spawnTimer = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    wizard = WizardPlayer(gameRef: this)
      ..position = Vector2(50, size.y / 2)
      ..size = Vector2(55, 75);
    add(wizard);

    final knobPaint = BasicPalette.purple.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.gray.withAlpha(100).paint();
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 40, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 20, bottom: 160),
    );
    add(joystick);

    uiText = TextComponent(
      text: '',
      position: Vector2(15, 15),
      textRenderer: TextPaint(
        style: const TextStyle(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
    add(uiText);
  }

  void startGame() {
    hp = 3;
    score = 0;
    coins = 0;
    level = 1;
    power = 1;
    shieldActive = false;
    shieldTime = 0;

    children.whereType<EnemyComponent>().toList().forEach((e) => e.removeFromParent());
    children.whereType<SpellComponent>().toList().forEach((s) => s.removeFromParent());

    wizard.position = Vector2(50, size.y / 2);
    gameState = GameState.playing;
    onStateChanged();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState != GameState.playing) return;

    uiText.text = '❤️ HP: $hp  |  ⭐ Score: $score  |  💎 Coins: $coins  |  🏆 LV: $level';

    if (!joystick.delta.isZero()) {
      wizard.position.add(joystick.relativeDelta * 230 * dt);
      wizard.position.x = wizard.position.x.clamp(0, size.x - wizard.size.x);
      wizard.position.y = wizard.position.y.clamp(0, size.y - wizard.size.y - 150);
    }

    if (shieldActive) {
      shieldTime -= dt;
      if (shieldTime <= 0) shieldActive = false;
    }

    spawnTimer += dt;
    double delay = (1.4 - level * 0.05).clamp(0.5, 1.4);
    if (spawnTimer >= delay) {
      spawnTimer = 0;
      add(EnemyComponent(level: level));
    }
  }

  void shootSpell() {
    if (gameState != GameState.playing) return;
    add(SpellComponent(
      startPosition: wizard.position + Vector2(wizard.size.x, 35),
      power: power,
    ));
  }

  void useMagicBomb() {
    if (gameState != GameState.playing || coins < 20) return;
    coins -= 20;
    children.whereType<EnemyComponent>().toList().forEach((enemy) {
      if ((enemy.position.x - wizard.position.x).abs() < 300) {
        enemy.removeFromParent();
        score += 15;
      }
    });
  }

  void useLightning() {
    if (gameState != GameState.playing || coins < 30) return;
    coins -= 30;
    var enemies = children.whereType<EnemyComponent>().toList();
    int count = min(4, enemies.length);
    for (int i = 0; i < count; i++) {
      enemies[i].removeFromParent();
      score += 20;
    }
  }

  void useShield() {
    if (gameState != GameState.playing || coins < 15) return;
    coins -= 15;
    shieldActive = true;
    shieldTime = 5.0;
  }

  void useUpgrade() {
    if (gameState != GameState.playing || coins < 50) return;
    coins -= 50;
    power++;
  }

  void triggerGameOver() {
    gameState = GameState.gameOver;
    onStateChanged();
  }
}

class WizardPlayer extends PositionComponent {
  final WizardDefenseGame gameRef;
  WizardPlayer({required this.gameRef});

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paintBody = Paint()..color = const Color(0xFF6C3483);
    final paintHead = Paint()..color = const Color(0xFFF5CBA7);
    final paintHat = Paint()..color = const Color(0xFF4A235A);

    canvas.drawRect(Rect.fromLTWH(10, 25, 35, 45), paintBody);
    canvas.drawCircle(const Offset(27, 20), 12, paintHead);

    Path hatPath = Path()
      ..moveTo(8, 15)
      ..lineTo(46, 15)
      ..lineTo(28, -10)
      ..close();
    canvas.drawPath(hatPath, paintHat);

    // Visual Efek Perisai Aktif
    if (gameRef.shieldActive) {
      final shieldPaint = Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(const Offset(27, 35), 45, shieldPaint);
    }
  }
}

class SpellComponent extends PositionComponent {
  final int power;
  SpellComponent({required Vector2 startPosition, required this.power}) {
    position = startPosition;
    size = Vector2.all(7.0 + (power * 2));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += 520 * dt;

    final game = findGame();
    if (game != null) {
      if (position.x > game.size.x) removeFromParent();

      for (var enemy in game.children.whereType<EnemyComponent>()) {
        if (toRect().overlaps(enemy.toRect())) {
          enemy.removeFromParent();
          removeFromParent();
          (game as WizardDefenseGame).score += 10 * power;
          game.coins += 5;
          game.level = (game.score / 100).floor() + 1;
          break;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = const Color(0xFFD98CFF);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
  }
}

class EnemyComponent extends PositionComponent {
  final int level;
  EnemyComponent({required this.level});

  @override
  Future<void> onLoad() async {
    size = Vector2(34, 34);
    final game = findGame();
    position = Vector2(
        game?.size.x ?? 800, Random().nextDouble() * ((game?.size.y ?? 400) - 200) + 50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= (60 + Random().nextDouble() * 45 + level * 7) * dt;

    final game = findGame() as WizardDefenseGame?;
    if (game != null) {
      if (position.x < -50) removeFromParent();

      if (toRect().overlaps(game.wizard.toRect())) {
        removeFromParent();
        if (!game.shieldActive) {
          game.hp--;
          if (game.hp <= 0) {
            game.triggerGameOver();
          }
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = const Color(0xFFE74C3C);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}
