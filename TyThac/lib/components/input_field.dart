import 'package:flutter/material.dart';

class InputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final bool readOnly;

  const InputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.readOnly,
  });

  @override
  State<InputField> createState() => InputFieldState();
}

class InputFieldState extends State<InputField> {
  late bool suffixVisible, obscureState;

  @override
  void initState() {
    super.initState();
    obscureState = widget.obscureText;
    suffixVisible = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: widget.controller,
        obscureText: obscureState,
        readOnly: widget.readOnly,
        decoration: InputDecoration(
          suffixIcon: suffixVisible
          ? IconButton(
            icon: Icon(obscureState ? Icons.visibility : Icons.visibility_off),
            color: Colors.black,
            onPressed: () {
              setState(() {
                obscureState = !obscureState;
              });
            },
          )
          : null,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black38),
          ),
          fillColor: Colors.white70,
          filled: true,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            height: 1.4
          )
        ),
      ),
    );
  }
}