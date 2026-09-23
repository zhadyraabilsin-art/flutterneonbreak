import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const NeonBrickBreakerApp());
}

class NeonBrickBreakerApp extends StatelessWidget {
  const NeonBrickBreakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Neon Brick Breaker',
      theme: ThemeData.dark(useMaterial3: true),
      home: const BrickBreakerScreen(),
    );
  }
}

class Brick {
  Rect rect;
  Color color;
  bool isBroken;

  Brick({required this.rect, required this.color, this.isBroken = false});
}

class BrickBreakerScreen extends StatefulWidget {
  const BrickBreakerScreen({super.key});

  @override
  State<BrickBreakerScreen> createState() => _BrickBreakerScreenState();
}

class _BrickBreakerScreenState extends State<BrickBreakerScreen> {
  double _ballX = 0.0; // -1.0 to 1.0
  double _ballY = 0.4;
  double _ballVx = 0.014;
  double _ballVy = -0.018;

  double _paddleX = 0.0; // center -1.0 to 1.0
  final double _paddleWidth = 0.42;

  List<Brick> _bricks = [];
  Timer? _gameTimer;
  bool _isPlaying = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _initBricks();
  }

  void _initBricks() {
    final colors = [
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.cyanAccent,
      Colors.greenAccent,
    ];
    final list = <Brick>[];
    const rows = 4;
    const cols = 5;
    const width = 0.34;
    const height = 0.065;
    const gapX = 0.04;
    const gapY = 0.03;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final left = -0.92 + c * (width + gapX);
        final top = -0.82 + r * (height + gapY);
        list.add(
          Brick(
            rect: Rect.fromLTWH(left, top, width, height),
            color: colors[r % colors.length],
          ),
        );
      }
    }
    _bricks = list;
  }

  void _startGame() {
    _gameTimer?.cancel();
    setState(() {
      _ballX = 0.0;
      _ballY = 0.4;
      _ballVx = 0.014;
      _ballVy = -0.018;
      _paddleX = 0.0;
      _score = 0;
      _isPlaying = true;
      _initBricks();
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _updatePhysics();
    });
  }

  void _updatePhysics() {
    if (!mounted) return;
    setState(() {
      _ballX += _ballVx;
      _ballY += _ballVy;

      // Қабырғалардан серпілу
      if (_ballX <= -0.96 || _ballX >= 0.96) {
        _ballVx = -_ballVx;
      }
      if (_ballY <= -0.96) {
        _ballVy = -_ballVy;
      }

      // Платформадан серпілу
      if (_ballY >= 0.78 &&
          _ballY <= 0.84 &&
          _ballX >= _paddleX - _paddleWidth / 2 - 0.04 &&
          _ballX <= _paddleX + _paddleWidth / 2 + 0.04 &&
          _ballVy > 0) {
        _ballVy = -_ballVy;
        final hitOffset = (_ballX - _paddleX) / (_paddleWidth / 2);
        _ballVx = hitOffset * 0.022;
      }

      // Кірпіштерді тексеру
      for (final brick in _bricks) {
        if (!brick.isBroken && brick.rect.contains(Offset(_ballX, _ballY))) {
          brick.isBroken = true;
          _ballVy = -_ballVy;
          _score += 20;
          break;
        }
      }

      // Барлық кірпіш сынса немесе шар түсіп кетсе
      if (_bricks.every((b) => b.isBroken) || _ballY > 1.02) {
        _gameTimer?.cancel();
        _isPlaying = false;
      }
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allCleared = _bricks.every((b) => b.isBroken);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'NEON BREAKER',
          style: TextStyle(letterSpacing: 1.8, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'SCORE: $_score',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        final delta =
                            (details.delta.dx / constraints.maxWidth) * 2;
                        _paddleX = (_paddleX + delta).clamp(
                          -1.0 + _paddleWidth / 2,
                          1.0 - _paddleWidth / 2,
                        );
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121626),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          ..._bricks.where((b) => !b.isBroken).map((brick) {
                            return Align(
                              alignment: Alignment(
                                brick.rect.center.dx,
                                brick.rect.center.dy,
                              ),
                              child: FractionallySizedBox(
                                widthFactor: brick.rect.width / 2,
                                heightFactor: brick.rect.height / 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: brick.color,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: brick.color.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          // Шар
                          Align(
                            alignment: Alignment(_ballX, _ballY),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent,
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Платформа
                          Align(
                            alignment: Alignment(_paddleX, 0.82),
                            child: FractionallySizedBox(
                              widthFactor: _paddleWidth / 2,
                              child: Container(
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (!_isPlaying)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.78),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      allCleared
                                          ? 'STAGE CLEARED! 🎉'
                                          : (_score > 0
                                                ? 'GAME OVER'
                                                : 'READY?'),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    FilledButton.icon(
                                      onPressed: _startGame,
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('PLAY'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            Colors.pinkAccent.shade700,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                          vertical: 12,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
