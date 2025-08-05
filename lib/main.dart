import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const EnhancedDinoSalaryApp());
}

class EnhancedDinoSalaryApp extends StatelessWidget {
  const EnhancedDinoSalaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Dino Salary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.light,
        ),
      ),
      home: const EnhancedDinoSalaryWidget(),
    );
  }
}

class Obstacle {
  double x;
  double y;
  double width;
  double height;
  
  Obstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class Character {
  double x;
  double y;
  bool isJumping;
  double jumpVelocity;
  
  Character({
    required this.x,
    required this.y,
    this.isJumping = false,
    this.jumpVelocity = 0,
  });
}

class Cloud {
  double x;
  double y;
  double width;
  double height;
  double speed;
  
  Cloud({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.speed,
  });
}

class BackgroundCactus {
  double x;
  double y;
  double height;
  double speed;
  int type; // 0: 小仙人掌, 1: 中仙人掌, 2: 大仙人掌
  
  BackgroundCactus({
    required this.x,
    required this.y,
    required this.height,
    required this.speed,
    required this.type,
  });
}

class Rock {
  double x;
  double y;
  double size;
  double speed;
  
  Rock({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

class Bush {
  double x;
  double y;
  double width;
  double speed;
  
  Bush({
    required this.x,
    required this.y,
    required this.width,
    required this.speed,
  });
}

class EnhancedDinoSalaryWidget extends StatefulWidget {
  const EnhancedDinoSalaryWidget({super.key});

  @override
  State<EnhancedDinoSalaryWidget> createState() => _EnhancedDinoSalaryWidgetState();
}

class _EnhancedDinoSalaryWidgetState extends State<EnhancedDinoSalaryWidget>
    with TickerProviderStateMixin {
  Timer? _timer;
  Timer? _gameTimer;
  Timer? _obstacleTimer;
  Timer? _autoJumpTimer;
  
  double _currentEarnings = 0.0;
  double _monthlySalary = 10000.0;
  double _dailyHours = 8.0;
  TimeOfDay _workStartTime = TimeOfDay(hour: 9, minute: 0); // 上班时间
  List<bool> _workDays = [true, true, true, true, true, false, false]; // 周一到周日的工作日设置
  late DateTime _startTime;
  
  String _displayedEarnings = '0.00';
  double _animatedEarnings = 0.0; // 用于动画的收入值
  String _currentTimeString = '';
  int _distance = 0;
  double _gameSpeed = 4.0;
  bool _gameRunning = true;
  bool _gamePaused = false; // 新增游戏暂停状态
  
  // 游戏元素
  Character _character = Character(x: 80, y: 0);
  List<Obstacle> _obstacles = [];
  List<Cloud> _clouds = [];
  List<BackgroundCactus> _backgroundCacti = [];
  List<Rock> _rocks = [];
  List<Bush> _bushes = [];
  
  double _groundLevel = 0;
  double _gravity = -1.2;
  double _jumpPower = 18;
  
  // 地面滚动偏移
  double _groundOffset = 0;
  
  // 动画控制器
  late AnimationController _runAnimationController;
  late AnimationController _numberController;
  late Animation<double> _earningsAnimation;
  
  // 平滑数字动画相关
  double _displayedAnimatedEarnings = 0.0; // 当前动画显示的数值
  double _targetEarnings = 0.0; // 目标数值

  
  @override
  void initState() {
    super.initState();
    _initializeSettings();
    _startTime = _getTodayWorkStartTime();
    
    _runAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);
    
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 500), // 0.5秒的平滑过渡，更快看到变化
      vsync: this,
    );
    
    // 初始化收入动画
    _earningsAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _numberController,
      curve: Curves.easeOutQuart, // 平滑的缓动曲线
    ));
    
    _earningsAnimation.addListener(() {
      setState(() {
        _displayedAnimatedEarnings = _earningsAnimation.value;
        _displayedEarnings = _displayedAnimatedEarnings.toStringAsFixed(2);
      });
    });


    
    _initializeBackground();
    _startEarningsTimer();
    _startGameLoop();
    _startObstacleSpawner();
    _startAutoJump();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameTimer?.cancel();
    _obstacleTimer?.cancel();
    _autoJumpTimer?.cancel();
    _runAnimationController.dispose();
    _numberController.dispose();

    super.dispose();
  }

  void _initializeBackground() {
    final random = Random();
    
    // 初始化云朵 - 分布到整个屏幕及右侧
    for (int i = 0; i < 12; i++) {
      _clouds.add(Cloud(
        x: random.nextDouble() * 1200, // 覆盖整个屏幕宽度
        y: 15 + random.nextDouble() * 35,
        width: 30 + random.nextDouble() * 25,
        height: 12 + random.nextDouble() * 8,
        speed: 0.3 + random.nextDouble() * 0.4,
      ));
    }
    
    // 初始化背景仙人掌 - 分布到整个屏幕及右侧
    for (int i = 0; i < 25; i++) {
      _backgroundCacti.add(BackgroundCactus(
        x: random.nextDouble() * 1500, // 覆盖整个屏幕宽度
        y: 45 + random.nextDouble() * 25,
        height: 12 + random.nextDouble() * 15,
        speed: 0.8 + random.nextDouble() * 0.7,
        type: random.nextInt(3),
      ));
    }
    
    // 初始化岩石 - 分布到整个屏幕及右侧
    for (int i = 0; i < 20; i++) {
      _rocks.add(Rock(
        x: random.nextDouble() * 1400, // 覆盖整个屏幕宽度
        y: 35 + random.nextDouble() * 30,
        size: 6 + random.nextDouble() * 8,
        speed: 1.2 + random.nextDouble() * 0.5,
      ));
    }
    
    // 初始化灌木丛 - 分布到整个屏幕及右侧
    for (int i = 0; i < 30; i++) {
      _bushes.add(Bush(
        x: random.nextDouble() * 1300, // 覆盖整个屏幕宽度
        y: 25 + random.nextDouble() * 15,
        width: 8 + random.nextDouble() * 6,
        speed: 0.6 + random.nextDouble() * 0.4,
      ));
    }
  }

  DateTime _getTodayWorkStartTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 9, 0, 0);
  }

  Future<void> _initializeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlySalary = prefs.getDouble('monthly_salary') ?? 10000.0;
      _dailyHours = prefs.getDouble('daily_hours') ?? 8.0;
      
      // 加载上班时间
      final startHour = prefs.getInt('work_start_hour') ?? 9;
      final startMinute = prefs.getInt('work_start_minute') ?? 0;
      _workStartTime = TimeOfDay(hour: startHour, minute: startMinute);
      
      // 加载工作日设置
      final workDaysString = prefs.getString('work_days') ?? '1,1,1,1,1,0,0';
      _workDays = workDaysString.split(',').map((e) => e == '1').toList();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_salary', _monthlySalary);
    await prefs.setDouble('daily_hours', _dailyHours);
    await prefs.setInt('work_start_hour', _workStartTime.hour);
    await prefs.setInt('work_start_minute', _workStartTime.minute);
    await prefs.setString('work_days', _workDays.map((e) => e ? '1' : '0').join(','));
  }

  void _startEarningsTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) { // 改为每500ms更新，让变化更明显
      if (!_gamePaused) { // 游戏暂停时不更新薪资
        _updateEarnings();
      }
      _updateCurrentTime(); // 时间始终更新
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    final timeString = '${now.year}年${now.month.toString().padLeft(2, '0')}月${now.day.toString().padLeft(2, '0')}日 '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    
    if (_currentTimeString != timeString) {
      setState(() {
        _currentTimeString = timeString;
      });
    }
  }

  void _startGameLoop() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_gameRunning && !_gamePaused) { // 检查游戏是否暂停
        _updateGame();
      }
    });
  }

  void _startObstacleSpawner() {
    _obstacleTimer = Timer.periodic(Duration(milliseconds: (2000 + Random().nextInt(1000))), (timer) {
      if (_gameRunning) {
        _spawnObstacle();
        // 重新设置随机间隔
        timer.cancel();
        _startObstacleSpawner();
      }
    });
  }

  void _startAutoJump() {
    _autoJumpTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_gameRunning && !_gamePaused) { // 检查游戏是否暂停
        _checkAndAutoJump();
      }
    });
  }

  void _updateEarnings() {
    // 如果游戏暂停，不更新收入
    if (_gamePaused) return;
    
    final now = DateTime.now();
    
    // 检查今天是否是工作日（1=周一，7=周日）
    final weekday = now.weekday;
    final isWorkDay = _workDays[weekday - 1]; // 转换为数组索引
    
    if (!isWorkDay) {
      _targetEarnings = 0.0;
      _animateToTarget();
      return;
    }
    
    // 计算今天的上班时间
    final today = DateTime(now.year, now.month, now.day);
    final workStart = today.add(Duration(
      hours: _workStartTime.hour,
      minutes: _workStartTime.minute,
    ));
    
    // 如果还没到上班时间，收入为0
    if (now.isBefore(workStart)) {
      _targetEarnings = 0.0;
      _animateToTarget();
      return;
    }
    
    // 计算每秒挣多少钱
    final dailySalary = _monthlySalary / 22; // 每天工资
    final secondlySalary = dailySalary / (_dailyHours * 3600); // 每秒工资
    
    // 计算从上班开始到现在经过了多少秒
    final workedSeconds = now.difference(workStart).inSeconds;
    
    // 不能超过当天工作时长的秒数
    final maxWorkSeconds = (_dailyHours * 3600).toInt(); // 最大工作秒数
    final effectiveSeconds = min(workedSeconds, maxWorkSeconds);
    
    // 计算今天挣的钱 = 每秒工资 × 工作秒数
    final newEarnings = secondlySalary * effectiveSeconds;
    
    // 始终更新目标值，让数字持续平滑增长
    if ((newEarnings - _targetEarnings).abs() > 0.001) {
      _targetEarnings = newEarnings;
      _animateToTarget();
    }
  }

  // 启动平滑动画到目标值
  void _animateToTarget() {
    if (_numberController.isAnimating) {
      _numberController.stop();
    }
    
    _earningsAnimation = Tween<double>(
      begin: _displayedAnimatedEarnings, // 从当前显示值开始
      end: _targetEarnings, // 到目标值结束
    ).animate(CurvedAnimation(
      parent: _numberController,
      curve: Curves.easeOutQuart,
    ));
    
    _numberController.reset();
    _numberController.forward();
  }

  void _spawnObstacle() {
    final random = Random();
    final obstacle = Obstacle(
      x: 300,
      y: 0,
      width: 15 + random.nextDouble() * 10,
      height: 30 + random.nextDouble() * 20,
    );
    
    setState(() {
      _obstacles.add(obstacle);
    });
  }

  void _checkAndAutoJump() {
    // 检查前方是否有障碍物，如果有就自动跳跃
    for (final obstacle in _obstacles) {
      // 如果障碍物在角色前方60像素范围内，且角色在地面上，就跳跃
      if (obstacle.x > _character.x && 
          obstacle.x < _character.x + 60 && 
          !_character.isJumping && 
          _character.y <= _groundLevel) {
        _jump();
        break;
      }
    }
  }

  void _updateGame() {
    setState(() {
      _updateCharacterPhysics();
      _updateObstacles();
      _updateBackground();
      _updateGroundOffset();
      _updateDistance();
      _checkCollisions();
    });
  }

  void _updateCharacterPhysics() {
    // 重力和跳跃物理
    if (_character.isJumping || _character.y > _groundLevel) {
      _character.jumpVelocity += _gravity;
      _character.y += _character.jumpVelocity;
      
      if (_character.y <= _groundLevel) {
        _character.y = _groundLevel;
        _character.isJumping = false;
        _character.jumpVelocity = 0;
      }
    }
  }

  void _updateObstacles() {
    for (int i = _obstacles.length - 1; i >= 0; i--) {
      _obstacles[i].x -= _gameSpeed;
      
      // 移除超出屏幕的障碍物
      if (_obstacles[i].x + _obstacles[i].width < 0) {
        _obstacles.removeAt(i);
      }
    }
  }

  void _updateBackground() {
    final random = Random();
    
    // 更新云朵
    for (final cloud in _clouds) {
      cloud.x -= cloud.speed;
      
      // 重置云朵位置
      if (cloud.x + cloud.width < 0) {
        cloud.x = 800 + random.nextDouble() * 400; // 更宽的重置范围
        cloud.y = 15 + random.nextDouble() * 35;
        cloud.width = 30 + random.nextDouble() * 25;
        cloud.height = 12 + random.nextDouble() * 8;
      }
    }
    
    // 更新背景仙人掌
    for (final cactus in _backgroundCacti) {
      cactus.x -= cactus.speed;
      
      // 重置仙人掌位置
      if (cactus.x < -20) {
        cactus.x = 800 + random.nextDouble() * 500; // 更宽的重置范围
        cactus.y = 45 + random.nextDouble() * 25;
        cactus.height = 12 + random.nextDouble() * 15;
        cactus.type = random.nextInt(3);
      }
    }
    
    // 更新岩石
    for (final rock in _rocks) {
      rock.x -= rock.speed;
      
      // 重置岩石位置
      if (rock.x < -15) {
        rock.x = 800 + random.nextDouble() * 400; // 更宽的重置范围
        rock.y = 35 + random.nextDouble() * 30;
        rock.size = 6 + random.nextDouble() * 8;
      }
    }
    
    // 更新灌木丛
    for (final bush in _bushes) {
      bush.x -= bush.speed;
      
      // 重置灌木丛位置
      if (bush.x < -15) {
        bush.x = 800 + random.nextDouble() * 300; // 更宽的重置范围
        bush.y = 25 + random.nextDouble() * 15;
        bush.width = 8 + random.nextDouble() * 6;
      }
    }
  }

  void _updateGroundOffset() {
    // 更新地面滚动偏移
    _groundOffset += _gameSpeed;
    if (_groundOffset >= 20) {
      _groundOffset = 0;
    }
  }

  void _updateDistance() {
    _distance += _gameSpeed.round();
    
    // 逐渐增加游戏速度
    if (_distance % 500 == 0 && _gameSpeed < 8.0) {
      _gameSpeed += 0.2;
    }
  }

  void _checkCollisions() {
    final characterRect = Rect.fromLTWH(
      _character.x + 2, 
      140 - _character.y - 30, 
      16, 
      28
    );
    
    for (final obstacle in _obstacles) {
      final obstacleRect = Rect.fromLTWH(
        obstacle.x + 2, 
        140 - obstacle.height, 
        obstacle.width - 4, 
        obstacle.height - 2
      );
      
      if (characterRect.overlaps(obstacleRect)) {
        _gameOver();
        break;
      }
    }
  }

  void _gameOver() {
    setState(() {
      _gameRunning = false;
    });
    
    // 3秒后重新开始
    Timer(const Duration(seconds: 3), () {
      _resetGame();
    });
  }

  void _resetGame() {
    setState(() {
      _gameRunning = true;
      _character = Character(x: 80, y: 0);
      _obstacles.clear();
      _distance = 0;
      _gameSpeed = 4.0;
      _groundOffset = 0;
    });
  }

  void _jump() {
    if (!_character.isJumping && _character.y <= _groundLevel) {
      setState(() {
        _character.isJumping = true;
        _character.jumpVelocity = _jumpPower;
      });
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double tempSalary = _monthlySalary;
        double tempHours = _dailyHours;
        
        return AlertDialog(
          title: const Text('🦖 智能恐龙工资设置'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '💰 月薪（元）',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: tempSalary.toStringAsFixed(0),
                    ),
                    onChanged: (value) {
                      tempSalary = double.tryParse(value) ?? _monthlySalary;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '⏰ 每日工作时长（小时）',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: tempHours.toStringAsFixed(1),
                    ),
                    onChanged: (value) {
                      tempHours = double.tryParse(value) ?? _dailyHours;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('🦖 恐龙沙漠奔跑统计', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('跑步距离: ${(_distance / 10).toStringAsFixed(1)}m'),
                        Text('游戏状态: ${_gameRunning ? "沙漠探险中" : "休息中"}'),
                        Text('当前速度: ${_gameSpeed.toStringAsFixed(1)}'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _monthlySalary = tempSalary;
                  _dailyHours = tempHours;
                });
                _saveSettings();
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCharacter() {
    return AnimatedBuilder(
      animation: _runAnimationController,
      builder: (context, child) {
        // 跑步动画 - 只有在地面时才有
        final runOffset = !_character.isJumping 
            ? _runAnimationController.value * 2 
            : 0.0;
        
        return Transform.translate(
          offset: Offset(0, -runOffset),
          child: Container(
            width: 20,
            height: 30,
            child: CustomPaint(
              painter: CharacterPainter(
                isJumping: _character.isJumping,
                animationValue: _runAnimationController.value,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildObstacle(Obstacle obstacle) {
    return Container(
      width: obstacle.width,
      height: obstacle.height,
      child: CustomPaint(
        painter: ObstaclePainter(),
      ),
    );
  }

  Widget _buildCloud(Cloud cloud) {
    return Container(
      width: cloud.width,
      height: cloud.height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(cloud.height / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCactus(BackgroundCactus cactus) {
    return Container(
      width: 8 + cactus.type * 2,
      height: cactus.height,
      child: CustomPaint(
        painter: BackgroundCactusPainter(type: cactus.type),
      ),
    );
  }

  Widget _buildRock(Rock rock) {
    return Container(
      width: rock.size,
      height: rock.size * 0.6,
      child: CustomPaint(
        painter: RockPainter(),
      ),
    );
  }

  Widget _buildBush(Bush bush) {
    return Container(
      width: bush.width,
      height: bush.width * 0.7,
      child: CustomPaint(
        painter: BushPainter(),
      ),
    );
  }

  Widget _buildGround() {
    return Container(
      width: double.infinity,
      height: 2,
      child: CustomPaint(
        painter: GroundPainter(offset: _groundOffset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.keyW) {
            _jump(); // 仍然支持手动跳跃
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: _jump, // 仍然支持点击跳跃
          onSecondaryTap: _showSettingsDialog,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF0F8FF), // 天空蓝
                  const Color(0xFFFFF8DC), // 沙漠黄
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 背景云朵
                ..._clouds.map((cloud) =>
                  Positioned(
                    left: cloud.x,
                    top: cloud.y,
                    child: _buildCloud(cloud),
                  ),
                ),
                
                // 远山剪影
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 80,
                  child: Container(
                    height: 40,
                    child: CustomPaint(
                      painter: MountainPainter(),
                    ),
                  ),
                ),
                
                // 背景岩石
                ..._rocks.map((rock) =>
                  Positioned(
                    left: rock.x,
                    bottom: rock.y,
                    child: _buildRock(rock),
                  ),
                ),
                
                // 背景灌木丛
                ..._bushes.map((bush) =>
                  Positioned(
                    left: bush.x,
                    bottom: bush.y,
                    child: _buildBush(bush),
                  ),
                ),
                
                // 背景仙人掌
                ..._backgroundCacti.map((cactus) =>
                  Positioned(
                    left: cactus.x,
                    bottom: cactus.y,
                    child: _buildBackgroundCactus(cactus),
                  ),
                ),
                
                // 地面线条（带滚动效果）
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: _buildGround(),
                ),
                
                // 障碍物
                ..._obstacles.map((obstacle) =>
                  Positioned(
                    left: obstacle.x,
                    bottom: 20,
                    child: _buildObstacle(obstacle),
                  ),
                ),
                
                // 恐龙角色
                Positioned(
                  left: _character.x,
                  bottom: 20 + _character.y,
                  child: _buildCharacter(),
                ),
                
                // 左上角 - 收入和时间显示
                Positioned(
                  top: 20,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 当前时间
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentTimeString,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      // 今日收入
                      const Text(
                        '💰 今日收入',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '¥$_displayedEarnings',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 右上角 - 距离和状态
                Positioned(
                  top: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '🏃 ${(_distance / 10).toStringAsFixed(0)}m',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '🌵 沙漠冲刺',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 游戏结束提示
                if (!_gameRunning)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '💥 沙漠遇险',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '3秒后重新开始沙漠探险...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // 游戏暂停提示
                if (_gamePaused)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pause_circle_filled,
                              color: Colors.white,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '⚙️ 游戏已暂停',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '薪资计算暂停，正在设置参数...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // 底部说明
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Text(
                    '🌵 恐龙在沙漠中自动奔跑赚钱！点击左上角设置按钮调整薪资 💰',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // 设置按钮 - 移到右上角，增大点击区域
                Positioned(
                  top: 15,
                  right: 15,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showSettings,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: EdgeInsets.all(15), // 增大点击区域
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '设置',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    // 暂停游戏
    setState(() {
      _gamePaused = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: true, // 允许点击外部关闭，但会触发取消回调
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            // 当用户尝试关闭对话框时，恢复游戏
            setState(() {
              _gamePaused = false;
            });
            return true;
          },
          child: _SettingsDialog(
            currentSalary: _monthlySalary,
            currentHours: _dailyHours,
            currentWorkStart: _workStartTime,
            currentWorkDays: _workDays,
            onSave: (double salary, double hours, TimeOfDay workStart, List<bool> workDays) {
              setState(() {
                _monthlySalary = salary;
                _dailyHours = hours;
                _workStartTime = workStart;
                _workDays = workDays;
                _gamePaused = false; // 恢复游戏
              });
              _saveSettings();
              
              // 强制重新计算收入
              _updateEarnings();
              
              Navigator.of(context).pop();
              
              final workDaysText = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
                  .asMap()
                  .entries
                  .where((entry) => workDays[entry.key])
                  .map((entry) => entry.value)
                  .join('、');
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ 设置已保存！月薪${salary.toStringAsFixed(0)}元，${workStart.format(context)}上班，工作日：$workDaysText'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            onCancel: () {
              setState(() {
                _gamePaused = false; // 恢复游戏
              });
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }


}

// 自定义设置对话框
class _SettingsDialog extends StatefulWidget {
  final double currentSalary;
  final double currentHours;
  final TimeOfDay currentWorkStart;
  final List<bool> currentWorkDays;
  final Function(double, double, TimeOfDay, List<bool>) onSave;
  final VoidCallback onCancel;

  const _SettingsDialog({
    required this.currentSalary,
    required this.currentHours,
    required this.currentWorkStart,
    required this.currentWorkDays,
    required this.onSave,
    required this.onCancel,
  });

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late TextEditingController _salaryController;
  late TextEditingController _hoursController;
  late FocusNode _salaryFocusNode;
  late FocusNode _hoursFocusNode;
  late TimeOfDay _selectedWorkStart;
  late List<bool> _selectedWorkDays;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _salaryController = TextEditingController(text: widget.currentSalary.toStringAsFixed(0));
    _hoursController = TextEditingController(text: widget.currentHours.toStringAsFixed(1));
    _salaryFocusNode = FocusNode();
    _hoursFocusNode = FocusNode();
    _selectedWorkStart = widget.currentWorkStart;
    _selectedWorkDays = List.from(widget.currentWorkDays);
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _hoursController.dispose();
    _salaryFocusNode.dispose();
    _hoursFocusNode.dispose();
    super.dispose();
  }

  void _handleSave() {
    final salaryText = _salaryController.text.trim();
    final hoursText = _hoursController.text.trim();
    
    final salary = double.tryParse(salaryText);
    final hours = double.tryParse(hoursText);
    
    if (salary == null || salary <= 0) {
      setState(() {
        _errorMessage = '请输入有效的月薪（大于0）';
      });
      return;
    }
    
    if (hours == null || hours <= 0 || hours > 24) {
      setState(() {
        _errorMessage = '请输入有效的工作时长（0-24小时）';
      });
      return;
    }
    
    widget.onSave(salary, hours, _selectedWorkStart, _selectedWorkDays);
  }

  Future<void> _selectWorkStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedWorkStart,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedWorkStart) {
      setState(() {
        _selectedWorkStart = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: Container(
        width: 400,
        constraints: BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    '薪资设置',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: Icon(Icons.close, color: Colors.white),
                    tooltip: '关闭',
                  ),
                ],
              ),
            ),
            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前设置',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                  SizedBox(height: 4),
                  Text('月薪: ${widget.currentSalary.toStringAsFixed(0)} 元'),
                  Text('工作时长: ${widget.currentHours.toStringAsFixed(1)} 小时/天'),
                  Text('上班时间: ${widget.currentWorkStart.format(context)}'),
                  Text('工作日: ${_getWorkDaysText()}'),
                ],
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                _salaryFocusNode.requestFocus();
              },
              child: TextField(
                controller: _salaryController,
                focusNode: _salaryFocusNode,
                decoration: InputDecoration(
                  labelText: '月薪 (元)',
                  hintText: '例如: 15000',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  errorText: _errorMessage.contains('月薪') ? _errorMessage : null,
                ),
                keyboardType: TextInputType.number,
                onTap: () {
                  // 确保点击时获取焦点
                  if (!_salaryFocusNode.hasFocus) {
                    _salaryFocusNode.requestFocus();
                  }
                },
                onChanged: (value) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                },
              ),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                _hoursFocusNode.requestFocus();
              },
              child: TextField(
                controller: _hoursController,
                focusNode: _hoursFocusNode,
                decoration: InputDecoration(
                  labelText: '每日工作时长 (小时)',
                  hintText: '例如: 8.0',
                  prefixIcon: Icon(Icons.schedule),
                  border: OutlineInputBorder(),
                  errorText: _errorMessage.contains('工作时长') ? _errorMessage : null,
                ),
                keyboardType: TextInputType.number,
                onTap: () {
                  // 确保点击时获取焦点
                  if (!_hoursFocusNode.hasFocus) {
                    _hoursFocusNode.requestFocus();
                  }
                },
                onChanged: (value) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                },
              ),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: _selectWorkStartTime,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '上班时间',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _selectedWorkStart.format(context),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '工作日设置',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (index) {
                      final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWorkDays[index] = !_selectedWorkDays[index];
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedWorkDays[index] ? Colors.blue : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedWorkDays[index] ? Colors.blue : Colors.grey.shade400,
                            ),
                          ),
                          child: Text(
                            dayNames[index],
                            style: TextStyle(
                              color: _selectedWorkDays[index] ? Colors.white : Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 底部按钮
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      '取消',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      elevation: 2,
                    ),
                    child: Text(
                      '保存设置',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWorkDaysText() {
    const dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final workDayNames = <String>[];
    for (int i = 0; i < widget.currentWorkDays.length; i++) {
      if (widget.currentWorkDays[i]) {
        workDayNames.add(dayNames[i]);
      }
    }
    return workDayNames.join('、');
  }

}

// 自定义绘制恐龙角色
class CharacterPainter extends CustomPainter {
  final bool isJumping;
  final double animationValue;
  
  CharacterPainter({required this.isJumping, required this.animationValue});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    // 恐龙身体 - 面向右边
    final path = Path();
    
    // 头部
    path.moveTo(15, 5);
    path.lineTo(18, 5);
    path.lineTo(20, 8);
    path.lineTo(18, 12);
    path.lineTo(15, 12);
    
    // 身体
    path.lineTo(15, 20);
    path.lineTo(5, 20);
    path.lineTo(5, 15);
    path.lineTo(8, 12);
    path.lineTo(12, 8);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // 眼睛
    canvas.drawCircle(const Offset(16, 8), 1, Paint()..color = Colors.white);
    
    // 腿部动画（只有在地面时）
    if (!isJumping) {
      final legOffset = animationValue * 3;
      // 左腿
      canvas.drawRect(
        Rect.fromLTWH(8, 20, 2, 8 + legOffset), 
        paint
      );
      // 右腿
      canvas.drawRect(
        Rect.fromLTWH(12, 20, 2, 8 - legOffset), 
        paint
      );
    } else {
      // 跳跃时腿部收起
      canvas.drawRect(Rect.fromLTWH(8, 20, 2, 5), paint);
      canvas.drawRect(Rect.fromLTWH(12, 20, 2, 5), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 自定义绘制障碍物（仙人掌）
class ObstaclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade800
      ..style = PaintingStyle.fill;
    
    // 仙人掌主干
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.4, 0, size.width * 0.2, size.height),
      paint,
    );
    
    // 仙人掌分支
    if (size.width > 20) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.3, size.width * 0.4, size.width * 0.15),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.6, size.height * 0.5, size.width * 0.4, size.width * 0.15),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 自定义绘制背景仙人掌
class BackgroundCactusPainter extends CustomPainter {
  final int type;
  
  BackgroundCactusPainter({required this.type});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade400.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    switch (type) {
      case 0: // 小仙人掌
        canvas.drawRect(Rect.fromLTWH(3, 0, 2, size.height), paint);
        canvas.drawRect(Rect.fromLTWH(1, size.height * 0.4, 2, 1), paint);
        break;
      case 1: // 中仙人掌
        canvas.drawRect(Rect.fromLTWH(2, 0, 4, size.height), paint);
        canvas.drawRect(Rect.fromLTWH(0, size.height * 0.3, 3, 2), paint);
        canvas.drawRect(Rect.fromLTWH(5, size.height * 0.6, 3, 2), paint);
        break;
      case 2: // 大仙人掌
        canvas.drawRect(Rect.fromLTWH(2, 0, 6, size.height), paint);
        canvas.drawRect(Rect.fromLTWH(0, size.height * 0.25, 4, 2), paint);
        canvas.drawRect(Rect.fromLTWH(6, size.height * 0.45, 4, 2), paint);
        canvas.drawRect(Rect.fromLTWH(1, size.height * 0.7, 3, 2), paint);
        break;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 自定义绘制岩石
class RockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade600.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    // 不规则岩石形状
    final path = Path();
    path.moveTo(size.width * 0.2, size.height);
    path.lineTo(size.width * 0.1, size.height * 0.6);
    path.lineTo(size.width * 0.3, size.height * 0.3);
    path.lineTo(size.width * 0.7, size.height * 0.2);
    path.lineTo(size.width * 0.9, size.height * 0.5);
    path.lineTo(size.width * 0.8, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 自定义绘制灌木丛
class BushPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade300.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    // 灌木丛由多个圆组成
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), size.width * 0.2, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.8), size.width * 0.25, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.15, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 自定义绘制远山
class MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // 远山剪影
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.15, size.height * 0.5);
    path.lineTo(size.width * 0.3, size.height * 0.3);
    path.lineTo(size.width * 0.45, size.height * 0.6);
    path.lineTo(size.width * 0.6, size.height * 0.2);
    path.lineTo(size.width * 0.75, size.height * 0.4);
    path.lineTo(size.width * 0.9, size.height * 0.1);
    path.lineTo(size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 自定义绘制滚动地面
class GroundPainter extends CustomPainter {
  final double offset;
  
  GroundPainter({required this.offset});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    // 主地面线
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 2),
      paint,
    );
    
    // 滚动的地面装饰点
    final dotPaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.fill;
    
    for (double x = -offset; x < size.width + 20; x += 20) {
      canvas.drawCircle(Offset(x, -3), 1, dotPaint);
      canvas.drawCircle(Offset(x + 10, -6), 0.5, dotPaint);
    }
  }
  
  @override
  bool shouldRepaint(GroundPainter oldDelegate) => oldDelegate.offset != offset;
}