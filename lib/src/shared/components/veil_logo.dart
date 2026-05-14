import 'package:flutter/material.dart';

class VeilLogo extends StatelessWidget {
  const VeilLogo({super.key, this.size = 28, this.center = false});

  final double size;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/app_icon/veil_app_icon.png',
          width: size,
          height: size,
          filterQuality: FilterQuality.high,
        ),
        SizedBox(width: size * 0.28),
        Text(
          'VEIL',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.78,
            fontWeight: FontWeight.w900,
            letterSpacing: size * 0.11,
          ),
        ),
      ],
    );

    return center ? Center(child: logo) : logo;
  }
}
