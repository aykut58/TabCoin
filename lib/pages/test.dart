import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class Test extends StatefulWidget {
  const Test({super.key});

  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  double _rotationSpeed = 1.0;
  DateTime? _lastTapTime;
  Timer? _decelerationTimer;
  bool _isRotating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..stop(); // Initialize in stopped state
  }

  @override
  void dispose() {
    _controller.dispose();
    _decelerationTimer?.cancel();
    super.dispose();
  }

  void _updateRotationSpeed() {
    if (_lastTapTime != null) {
      DateTime now = DateTime.now();
      int difference = now.difference(_lastTapTime!).inMilliseconds;
      double tapSpeed = max(1.0, 500.0 / difference);
      _rotationSpeed = tapSpeed;

      int durationMs = max(1, (1000 / _rotationSpeed).round());
      _controller.duration = Duration(milliseconds: durationMs);

      if (!_isRotating) {
        _controller.repeat(); // Start rotating
        _isRotating = true;
      }

      // Reset deceleration timer
      _decelerationTimer?.cancel();
    }
  }

  void _onTapDown(TapDownDetails details) {
    _lastTapTime = DateTime.now();
    _updateRotationSpeed();
  }

  void _onTapEnd() {
    _decelerationTimer?.cancel(); // Cancel any existing timer
    _decelerationTimer = Timer(Duration(milliseconds: 500), () {
      setState(() {
        _controller.stop();
       // _lastTapTime = null;
        _isRotating = false;
      });
      //_startDeceleration();
    });
  }

  void _startDeceleration() async {
    double targetSpeed = 0.1;
    while (_rotationSpeed > targetSpeed) {
      await Future.delayed(Duration(milliseconds: 50));
      setState(() {
        _rotationSpeed = max(targetSpeed, _rotationSpeed - 0.1);
        int durationMs = max(1, (1000 / _rotationSpeed).round());
        _controller.duration = Duration(milliseconds: durationMs);
      });
    }
    _controller.stop();
    _isRotating = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rotating Fan Blade'),
      ),
      body: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: (_) => _onTapEnd(),
        onTapCancel: _onTapEnd,
        child: Center(
          child: RotationTransition(
            turns: _controller,
            child: Image.asset('assets/images/tap-fan.png'), // Replace with your fan blade image
          ),
        ),
      ),
    );
  }
}
