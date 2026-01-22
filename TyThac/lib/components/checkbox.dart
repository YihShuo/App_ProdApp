import 'package:flutter/material.dart';

class CheckBox extends StatefulWidget {
  final Widget titleWidget;
  final double topLeftRadius;
  final double topRightRadius;
  final double borderWidth;
  const CheckBox({
    super.key,
    required this.titleWidget,
    required this.topLeftRadius,
    required this.topRightRadius,
    required this.borderWidth
  });

  @override
  State<StatefulWidget> createState() => CheckBoxState();
}

class CheckBoxState extends State<CheckBox> {
  bool isChecked = false;

  MaterialColor white = const MaterialColor(
    0xFFFFFFFF,
    <int, Color>{
      50: Color(0xFFFFFFFF),
      100: Color(0xFFFFFFFF),
      200: Color(0xFFFFFFFF),
      300: Color(0xFFFFFFFF),
      400: Color(0xFFFFFFFF),
      500: Color(0xFFFFFFFF),
      600: Color(0xFFFFFFFF),
      700: Color(0xFFFFFFFF),
      800: Color(0xFFFFFFFF),
      900: Color(0xFFFFFFFF),
    },
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isChecked = !isChecked;
        });
      },
      child: Container(
        width: 80,
        height: 40,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(1, 152, 122, 1),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(widget.topLeftRadius), topRight: Radius.circular(widget.topRightRadius))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              child: Theme(
                data: ThemeData(
                  primarySwatch: white,
                  unselectedWidgetColor: Colors.white, // Your color
                ),
                child: Checkbox(
                  checkColor: const Color.fromRGBO(1, 152, 122, 1),
                  value: isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked = value!;
                    });
                  },
                ),
              ),
            ),

            Row(
              children: [
                const SizedBox(width: 5),
                widget.titleWidget
              ],
            )
          ],
        ),
      ),
    );
  }
}