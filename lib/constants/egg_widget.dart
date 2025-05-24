import 'package:flutter/material.dart';

class EggWidget extends StatefulWidget {
  final Function onCrack;
  final int level;
  final int coins;

  EggWidget(
      {super.key,
      required this.onCrack,
      required this.level,
      required this.coins});

  @override
  _EggWidgetState createState() => _EggWidgetState();
}

class _EggWidgetState extends State<EggWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _tapCount = 0;
  late int _requiredTaps;
  bool _isCracked = false;

  @override
  void initState() {
    super.initState();
    _requiredTaps = calculateRequiredTaps(widget.level);
    _controller = AnimationController(
      duration: const Duration(seconds: 5), // Duration of the animation
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: -0.2)
        .animate(_controller) // animate out of the screen
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
  }

  int calculateRequiredTaps(int level) {
    // Linear interpolation from 3 to 30 based on level (1 to 100)
    int minTaps = 3;
    int maxTaps = 30;
    return ((maxTaps - minTaps) / 99 * (level - 1) + minTaps).round();
  }

  void _onTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= _requiredTaps) {
        _isCracked = true;
        widget.onCrack();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_animation.value < -0.2) {
      // When the egg is out of the screen, hide it
      return Container();
    }

    return Positioned(
      right: _animation.value * MediaQuery.of(context).size.width,
      child: GestureDetector(
        onTap: _onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              _isCracked
                  ? 'assets/images/crack-egg.png'
                  : 'assets/images/easter-egg.png',
              width: 50,
              height: 70,
            ),
            if (_isCracked)
              Text(
                '${(widget.coins / 2).round()}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                ),
              ),
            if (!_isCracked)
              Text(
                '${_requiredTaps - _tapCount}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
