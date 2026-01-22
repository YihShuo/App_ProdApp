import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:production/services/remote_service.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  ChangePasswordState createState() => ChangePasswordState();
}

class ChangePasswordState extends State<ChangePassword> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String apiAddress = '', userID = '', password = '';
  Widget tipOldPassword = const Text(''), tipNewPassword = const Text(''), tipConfirmPassword = const Text('');
  bool suffixStateOld = true, suffixStateNew = true, suffixStateConfirm = true;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiAddress = prefs.getString('address') ?? '';
      userID = prefs.getString('userID') ?? '';
      password = prefs.getString('password') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  bool isValidPassword(String password) {
    RegExp regex = RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[!@#$%^&*()_+{}\[\]:;<>,.?~\\-]).{8,}$');
    return regex.hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.settingsPassword)
      ),
      backgroundColor: Colors.grey[300],
      body: Column(
        children: [
          const Text(''),
          ListTile(
            title: TextField(
              controller: oldPasswordController,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(suffixStateOld ? Icons.visibility : Icons.visibility_off),
                  color: Colors.black54,
                  onPressed: () {
                    setState(() {
                      suffixStateOld = !suffixStateOld;
                    });
                  },
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                hintText: AppLocalizations.of(context)!.settingsPasswordOldPassword,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  height: 1.4
                )
              ),
              obscureText: suffixStateOld,
            )
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: tipOldPassword,
            )
          ),
          ListTile(
            title: TextField(
              controller: newPasswordController,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(suffixStateNew ? Icons.visibility : Icons.visibility_off),
                  color: Colors.black54,
                  onPressed: () {
                    setState(() {
                      suffixStateNew = !suffixStateNew;
                    });
                  },
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                hintText: AppLocalizations.of(context)!.settingsPasswordNewPassword,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  height: 1.4
                )
              ),
              obscureText: suffixStateNew,
            )
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: tipNewPassword,
            )
          ),
          ListTile(
            title: TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(suffixStateConfirm ? Icons.visibility : Icons.visibility_off),
                  color: Colors.black54,
                  onPressed: () {
                    setState(() {
                      suffixStateConfirm = !suffixStateConfirm;
                    });
                  },
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                hintText: AppLocalizations.of(context)!.settingsPasswordConfirmPassword,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  height: 1.4
                )
              ),
              obscureText: suffixStateConfirm,
            )
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: tipConfirmPassword,
            )
          ),
          const Expanded(child: SizedBox()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton(
              onPressed: () async {
                if (oldPasswordController.text != password) {
                  setState(() {
                    tipOldPassword = Text(AppLocalizations.of(context)!.settingsPasswordCheckFailed, style: const TextStyle(color: Colors.red));
                    tipNewPassword = const Text('');
                    tipConfirmPassword = const Text('');
                  });
                }
                else if (isValidPassword(newPasswordController.text) == false) {
                  setState(() {
                    tipOldPassword = const Text('');
                    tipNewPassword = Text(AppLocalizations.of(context)!.settingsPasswordRuleCheckFailed, style: const TextStyle(color: Colors.red));
                    tipConfirmPassword = const Text('');
                  });
                }
                else if (newPasswordController.text != confirmPasswordController.text) {
                  setState(() {
                    tipOldPassword = const Text('');
                    tipNewPassword = const Text('');
                    tipConfirmPassword = Text(AppLocalizations.of(context)!.settingsPasswordConfirmFailed, style: const TextStyle(color: Colors.red));
                  });
                }
                else {
                  final body = await RemoteService().updateUserPassword(
                    apiAddress,
                    userID,
                    newPasswordController.text
                  );
                  final jsonData = json.decode(body);
                  if (jsonData['Status'] == 'Successful') {
                    if (!mounted) return;
                    Fluttertoast.showToast(
                      msg: AppLocalizations.of(context)!.successContent,
                      gravity: ToastGravity.BOTTOM,
                      toastLength: Toast.LENGTH_SHORT,
                    );
                    Navigator.of(context).pop();
                  }
                  else {
                    if (!mounted) return;
                    Fluttertoast.showToast(
                      msg: AppLocalizations.of(context)!.failedContent,
                      gravity: ToastGravity.BOTTOM,
                      toastLength: Toast.LENGTH_SHORT,
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4))
                ),
                side: const BorderSide(color: Colors.grey)
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(AppLocalizations.of(context)!.ok, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.4)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}