import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const Salyut7Game());
}

class Salyut7Game extends StatelessWidget {
  const Salyut7Game({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salyut-7 Incident',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StationExplorationScreen(),
      },
    );
  }
}

class StationExplorationScreen extends StatefulWidget {
  const StationExplorationScreen({super.key});

  @override
  State<StationExplorationScreen> createState() => _StationExplorationScreenState();
}

class _StationExplorationScreenState extends State<StationExplorationScreen> with TickerProviderStateMixin {
  Offset _pointerPosition = const Offset(200, 300);
  bool _isTerminalOpen = false;
  late AnimationController _flickerController;
  late AnimationController _creatureController;
  late AnimationController _terminalBlinkController;
  
  Offset _creaturePosition = const Offset(-100, -100);
  bool _showCreature = false;
  
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _creatureController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    _terminalBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _startCreatureSpawnTimer();
  }
  
  void _startCreatureSpawnTimer() {
    Future.delayed(Duration(seconds: 5 + _random.nextInt(15)), () {
      if (mounted && !_isTerminalOpen) {
        _spawnCreature();
      }
      _startCreatureSpawnTimer();
    });
  }
  
  void _spawnCreature() {
    setState(() {
      _showCreature = true;
      // Spawn near the edges or in random dark spots
      final double x = _random.nextDouble() * 500;
      final double y = _random.nextDouble() * 800;
      _creaturePosition = Offset(x, y);
    });
    
    _creatureController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _showCreature = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _flickerController.dispose();
    _creatureController.dispose();
    _terminalBlinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MouseRegion(
        onHover: (event) {
          setState(() {
            _pointerPosition = event.position;
          });
        },
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _pointerPosition = details.globalPosition;
            });
          },
          onTapDown: (details) {
            setState(() {
              _pointerPosition = details.globalPosition;
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The frozen station background
              Container(
                color: const Color(0xFF0F1116),
                child: CustomPaint(
                  painter: StationCorridorPainter(),
                ),
              ),
              
              // Terminal Interactable object
              Positioned(
                left: 100,
                top: 250,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isTerminalOpen = true;
                    });
                  },
                  child: Container(
                    width: 80,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22252A),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 40,
                        color: Colors.black,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _terminalBlinkController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _terminalBlinkController.value,
                                child: Container(
                                  width: 8,
                                  height: 12,
                                  color: Colors.green.withOpacity(0.5),
                                ),
                              );
                            }
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Creature
              if (_showCreature)
                Positioned(
                  left: _creaturePosition.dx,
                  top: _creaturePosition.dy,
                  child: AnimatedBuilder(
                    animation: _creatureController,
                    builder: (context, child) {
                      // Fade in and out
                      final opacity = sin(_creatureController.value * pi);
                      return Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: const GlowingEyes(),
                      );
                    }
                  ),
                ),
                
              // Flashlight effect mask
              AnimatedBuilder(
                animation: _flickerController,
                builder: (context, child) {
                  // Simulate failing battery or unstable connection
                  final flicker = 1.0 - (_random.nextDouble() > 0.95 ? 0.3 : 0.0);
                  return IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: FractionalOffset(
                            _pointerPosition.dx / MediaQuery.of(context).size.width,
                            _pointerPosition.dy / MediaQuery.of(context).size.height,
                          ),
                          radius: 0.4 * flicker,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.9),
                            Colors.black,
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Film grain / Noise overlay
              IgnorePointer(
                child: Opacity(
                  opacity: 0.05,
                  child: Container(
                    color: Colors.white,
                    // Typically a noise shader or static asset goes here, simulating with color for now
                  ),
                ),
              ),
              
              // Terminal UI Overlay
              if (_isTerminalOpen)
                Positioned.fill(
                  child: SovietTerminalOverlay(
                    onClose: () {
                      setState(() {
                        _isTerminalOpen = false;
                      });
                    },
                  ),
                ),
                
              // Hint text if not interacting
              if (!_isTerminalOpen)
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "Drag to move flashlight. Find the terminal.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        letterSpacing: 2.0,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlowingEyes extends StatelessWidget {
  const GlowingEyes({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildEye(),
          _buildEye(),
        ],
      ),
    );
  }
  
  Widget _buildEye() {
    return Container(
      width: 12,
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.6),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class StationCorridorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF15181D)
      ..style = PaintingStyle.fill;
      
    // Draw walls
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.2, size.height * 0.2)
      ..lineTo(size.width * 0.2, size.height * 0.8)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
    
    final path2 = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.8, size.height * 0.2)
      ..lineTo(size.width * 0.8, size.height * 0.8)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path2, paint);
    
    // Draw floor
    final floorPaint = Paint()..color = const Color(0xFF111317);
    final floorPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.2, size.height * 0.8)
      ..lineTo(size.width * 0.8, size.height * 0.8)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(floorPath, floorPaint);
    
    // Draw pipes / details
    final pipePaint = Paint()
      ..color = const Color(0xFF0A0C0E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;
      
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.1, size.height * 0.9),
      pipePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.9, size.height * 0.1),
      Offset(size.width * 0.9, size.height * 0.9),
      pipePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SovietTerminalOverlay extends StatefulWidget {
  final VoidCallback onClose;
  
  const SovietTerminalOverlay({super.key, required this.onClose});

  @override
  State<SovietTerminalOverlay> createState() => _SovietTerminalOverlayState();
}

class _SovietTerminalOverlayState extends State<SovietTerminalOverlay> {
  final String _logContent = '''
> СИСТЕМА ИНИЦИАЛИЗИРОВАНА...
> ОС РАФОС 2.0 (САЛЮТ-7)
> ДАТА: 11.02.1985
> 
> [ОШИБКА] СВЯЗЬ С ЦУП ПОТЕРЯНА.
> [ОШИБКА] СИСТЕМА ОЖИВЛЕНИЯ... НЕИЗВЕСТНЫЙ СБОЙ.
> [ПРЕДУПРЕЖДЕНИЕ] ТЕМПЕРАТУРА В ОТСЕКЕ 4 ПАДАЕТ: -15°C
>
> ВОССТАНОВЛЕН ИЗ КЕША: ЖУРНАЛ 85-02
> ...Мы слышим скрежет снаружи станции. 
> В.В. говорит, что это термическое расширение металла. 
> Но панели солнечных батарей заблокированы.
> ...
> Что-то проникло в шлюз.
> Я запер отсек. Свет мигает.
> Они не должны это найти.
>
> > ВВОД КОМАНДЫ_
''';

  String _displayedText = '';
  int _charIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _typeText();
  }
  
  void _typeText() async {
    while (_charIndex < _logContent.length && mounted) {
      setState(() {
        _displayedText += _logContent[_charIndex];
        _charIndex++;
      });
      // Vary typing speed to simulate processing
      int delay = 20 + Random().nextInt(40);
      if (_logContent[_charIndex - 1] == '\\n') delay += 300;
      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      padding: const EdgeInsets.all(40),
      child: Stack(
        children: [
          // Screen border
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1E3320), width: 20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF051105),
              child: SingleChildScrollView(
                child: Text(
                  _displayedText,
                  style: const TextStyle(
                    color: Color(0xFF4AF626),
                    fontFamily: 'Courier',
                    fontSize: 16,
                    height: 1.5,
                    shadows: [
                      Shadow(
                        color: Color(0xFF4AF626),
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // CRT scanline effect
          IgnorePointer(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.darken,
              child: Container(
                color: Colors.white,
              ),
            ),
          ),
          
          // Close button
          Positioned(
            top: 30,
            right: 30,
            child: IconButton(
              icon: const Icon(Icons.power_settings_new, color: Color(0xFF4AF626)),
              onPressed: widget.onClose,
              tooltip: 'Выключить (Turn off)',
            ),
          ),
        ],
      ),
    );
  }
}
