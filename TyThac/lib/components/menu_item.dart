import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MenuItem extends StatelessWidget {
  final String title;
  final FaIcon icon;
  final Color bColor;
  final Function()? onTap;

  const MenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.bColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Column(
              children: [
                Row(
                  children: [
                    icon,
                    const SizedBox(width: 20),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ]
            ),
          ),
        )
      ),
    );
  }
}