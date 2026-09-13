import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';

void main() {
  runApp(GameWidget(game: WizardDefenseGame()));
}

class WizardDefenseGame extends FlameGame with HasCollisionDetection {
  late WizardPlayer wizard;
  late JoystickComponent joystick;
  
  int hp = 3;
  int score = 0;
  int coins = 0;
  int level = 1;
  int power = 1;
  
  bool shieldActive = false;
  double shieldTime = 0;
  double spawnTimer = 0;
  
  final TextComponent scoreText = TextComponent();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Inisialisasi Player
    wizard = WizardPlayer()
      ..position = Vector2(50, size.y / 2)
      ..size = Vector2(55, 75);
    add(wizard);

    // Inisialisasi Joystick
    final knobPaint = BasicPalette.purple.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.gray.withAlpha(100).paint();
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 25, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(joystick);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Pergerakan Wizard via Joystick
    if (!joystick.delta.isZero()) {
      wizard.position.add(joystick.relativeDelta * 230 * dt);
      wizard.position.x = wizard.position.x.clamp(0, size.x - wizard.size.x);
      wizard.position.y = wizard.position.y.clamp(0, size.y - wizard.size.y - 25);
    }

    // Timer Perisai
    if (shieldActive) {
      shieldTime -= dt;
      if (shieldTime <= 0) shieldActive = false;
    }

    // Spawn Musuh
    spawnTimer += dt;
    double delay = (1.4 - level * 0.05).clamp(0.5, 1.4);
    if (spawnTimer >= delay) {
      spawnTimer = 0;
      add(EnemyComponent(level: level));
    }
  }

  void shootSpell() {
    add(SpellComponent(
      startPosition: wizard.position + Vector2(wizard.size.x, 35),
      power: power,
    ));
  }
}

class WizardPlayer extends PositionComponent {
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Visual Jubah & Karakter
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
    if (position.x > 1000) removeFromParent();
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
    position = Vector2(1000, Random().nextDouble() * 300 + 30);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= (60 + Random().nextDouble() * 45 + level * 7) * dt;
    if (position.x < -50) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = const Color(0xFFE74C3C);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}
