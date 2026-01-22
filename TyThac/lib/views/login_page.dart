import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:production/components/input_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

String loginMode = '', apiAddress = '';
List<String> factoryDropdownItems = [];
List<List<String>> factoryLeans = [];
List<DropdownMenuItem<String>> lean = [], orderLean = [];
const apkDownloadUrl = 'https://github.com/danny0614/Tythac/releases/latest/download/Tythac.apk';

class LoginPage extends StatefulWidget {
  final Function changeLanguage;

  const LoginPage({
    super.key,
    required this.changeLanguage
  });

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final useridController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();
  final buildingController = TextEditingController();
  final leanController = TextEditingController();
  final orderBuildingController = TextEditingController();
  final orderLeanController = TextEditingController();
  final sectionController = TextEditingController();
  final machineController = TextEditingController();

  String selectedLocal = 'zh';
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  String appVersion = '', appLatestVersion = '', sMode = 'User';
  bool rememberPwd = false, isReady = false;

  @override
  void initState() {
    super.initState();
    Future(() async {
      await loadData();
      setState(() {
        isReady = true;
      });
    });
  }

  Future<String> checkUpdate() async {
    String updateFrom = '';
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final body = await RemoteService().getAppLatestVersion();
    final latestApp = json.decode(body);
    updateFrom = latestApp['From'].toString();
    appLatestVersion = latestApp['Body']['tag_name'].toString().replaceAll('v', '');
    if (packageInfo.version == appLatestVersion) {
      return 'isLatest';
    }
    else {
      return updateFrom;
    }
  }

  Future<void> loadData() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    appLatestVersion = appVersion;

    final prefs = await SharedPreferences.getInstance();
    useridController.text = prefs.getString('userID') ?? '';
    addressController.text = prefs.getString('address') ?? '';
    passwordController.text = prefs.getString('password') ?? '';
    buildingController.text = prefs.getString('building') ?? 'A16';
    leanController.text = prefs.getString('lean') ?? 'LEAN01';
    orderBuildingController.text = prefs.getString('orderBuilding') ?? 'A16';
    orderLeanController.text = prefs.getString('orderLean') ?? 'LEAN01';
    sectionController.text = prefs.getString('section') ?? 'S';
    machineController.text = prefs.getString('machine') ?? 'Cutting - 01';
    loginMode = prefs.getString('loginMode') ?? 'User';
    apiAddress = prefs.getString('address') ?? '';

    if (loginMode == 'ProductionLine') {
      DateTime today = DateTime.now();
      final body = await RemoteService().getFactoryLean(
        apiAddress,
        DateFormat('yyyy/MM').format(DateTime(today.year, today.month - 1, 1)),
        'CurrentMonthWithoutPM'
      );
      final jsonData = json.decode(body);

      factoryDropdownItems = [];
      factoryLeans = [];
      if (jsonData.length > 0) {
        for (int i = 0; i < jsonData.length; i++) {
          factoryDropdownItems.add(jsonData[i]['Factory']);
          List<String> leans = [];
          for (int j = 0; j < jsonData[i]['Lean'].length; j++) {
            leans.add(jsonData[i]['Lean'][j]);
          }
          factoryLeans.add(leans);
        }

        lean = factoryLeans[factoryDropdownItems.indexOf(buildingController.text)].map((String myLean) {
          return DropdownMenuItem(
            value: myLean,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(myLean.toString()),
              ),
            )
          );
        }).toList();

        orderLean = factoryLeans[factoryDropdownItems.indexOf(orderBuildingController.text)].map((String myLean) {
          return DropdownMenuItem(
            value: myLean,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(myLean.toString()),
              ),
            )
          );
        }).toList();
      }
    }

    setState(() {
      loginMode = loginMode;
      selectedLocal = prefs.getString('locale') ?? 'zh';
      rememberPwd = passwordController.text != '' ? true : false;
    });
  }

  void modeSwitch(String building, String machine) {
    setState(() {
      if (loginMode == 'Machine') {
        buildingController.text = building;
        machineController.text = machine;
      }
      lean = lean;
      orderLean = orderLean;
      loginMode = loginMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return Scaffold(
        backgroundColor: Colors.grey[200],
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 150,
                  width: 150
                ),
                const Text('LAI YIH · YIH SHUO', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        )
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 150,
                      width: 150
                    ),
                    const Text('LAI YIH · YIH SHUO', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Visibility(
                          visible: loginMode == 'User',
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.grey.shade400, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(AppLocalizations.of(context)!.userAccount, style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: loginMode == 'ProductionLine',
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.grey.shade400, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(AppLocalizations.of(context)!.productionLine, style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: loginMode == 'Machine',
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.grey.shade400, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(AppLocalizations.of(context)!.machineAccount, style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Visibility(
                      visible: loginMode == 'User',
                      child: Column(
                        children: [
                          InputField(
                            controller: useridController,
                            hintText: AppLocalizations.of(context)!.loginPageID,
                            obscureText: false,
                            readOnly: false,
                          ),
                          const SizedBox(height: 10),
                          InputField(
                            controller: passwordController,
                            hintText: AppLocalizations.of(context)!.loginPagePassword,
                            obscureText: true,
                            readOnly: false,
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: loginMode == 'ProductionLine',
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white70,
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(4)
                                    ),
                                    child: DropdownButton(
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      value: buildingController.text,
                                      itemHeight: 56,
                                      items: factoryDropdownItems.map((String factory) {
                                        return DropdownMenuItem(
                                          value: factory,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: Text(factory.toString()),
                                            ),
                                          )
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          buildingController.text = value!;
                                          lean = factoryLeans[factoryDropdownItems.indexOf(buildingController.text)].map((String myLean) {
                                            return DropdownMenuItem(
                                              value: myLean,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  child: Text(myLean.toString()),
                                                ),
                                              )
                                            );
                                          }).toList();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white70,
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(4)
                                    ),
                                    child: DropdownButton(
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      value: leanController.text,
                                      itemHeight: 56,
                                      items: lean,
                                      onChanged: (value) {
                                        setState(() {
                                          leanController.text = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white70,
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: DropdownButton(
                                isExpanded: true,
                                underline: const SizedBox(),
                                value: sectionController.text,
                                itemHeight: 56,
                                items: [
                                  DropdownMenuItem(
                                    value: 'S',
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(AppLocalizations.of(context)!.stitching),
                                      ),
                                    )
                                  ),
                                  DropdownMenuItem(
                                    value: 'C',
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(AppLocalizations.of(context)!.cutting),
                                      ),
                                    )
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    sectionController.text = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: Colors.grey,)
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(AppLocalizations.of(context)!.orderProductionLine),
                                ),
                                const Expanded(
                                  child: Divider(color: Colors.grey,)
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: SizedBox(
                              height: 36,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white70,
                                        border: Border.all(color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(4)
                                      ),
                                      child: DropdownButton(
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                        value: orderBuildingController.text,
                                        itemHeight: 56,
                                        items: factoryDropdownItems.map((String factory) {
                                          return DropdownMenuItem(
                                            value: factory,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Text(factory.toString()),
                                              ),
                                            )
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            orderBuildingController.text = value!;
                                            orderLean = factoryLeans[factoryDropdownItems.indexOf(orderBuildingController.text)].map((String myLean) {
                                              return DropdownMenuItem(
                                                value: myLean,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    child: Text(myLean.toString()),
                                                  ),
                                                )
                                              );
                                            }).toList();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white70,
                                        border: Border.all(color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(4)
                                      ),
                                      child: DropdownButton(
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                        value: orderLeanController.text,
                                        itemHeight: 56,
                                        items: lean,
                                        onChanged: (value) {
                                          setState(() {
                                            orderLeanController.text = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Visibility(
                      visible: loginMode == 'Machine',
                      child: Column(
                        children: [
                          InputField(
                            controller: buildingController,
                            hintText: AppLocalizations.of(context)!.building,
                            obscureText: false,
                            readOnly: true,
                          ),
                          const SizedBox(height: 10),
                          InputField(
                            controller: machineController,
                            hintText: AppLocalizations.of(context)!.machineAccount,
                            obscureText: false,
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: loginMode == 'User',
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Checkbox(
                              checkColor: Colors.white,
                              activeColor: Colors.blue,
                              value: rememberPwd,
                              onChanged: (value) {
                                setState(() {
                                  rememberPwd = value!;
                                });
                              }
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                rememberPwd = !rememberPwd;
                              });
                            },
                            child: Text(AppLocalizations.of(context)!.rememberPWD, style: const TextStyle(color: Colors.blue))
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 25),
                      child: OutlinedButton(
                        onPressed: () async {
                          GlobalKey<MessageDialogState> globalKey = GlobalKey();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.blue,
                                ),
                              );
                            }
                          );

                          try {
                            final param = await SharedPreferences.getInstance();
                            addressController.text = param.getString('address') ?? '';
                            String firebaseToken = kIsWeb ? 'Web' : param.getString('firebaseToken') ?? '';
                            String body = '';
                            if (loginMode == 'User') {
                              try {
                                body = await RemoteService().login(
                                  addressController.text,
                                  useridController.text,
                                  passwordController.text,
                                  firebaseToken,
                                  appVersion
                                );
                              } catch (ex) {
                                Fluttertoast.showToast(
                                  msg: AppLocalizations.of(context)!.loginPageConnectFailed,
                                  gravity: ToastGravity.BOTTOM,
                                  toastLength: Toast.LENGTH_SHORT,
                                );
                              }
                            }
                            else if (loginMode == 'ProductionLine' || loginMode == 'Machine') {
                              body = '{"Result":true,"Status":"Successful"}';
                            }
                            else {
                              body = '{"Result":false,"Status":"Failed"}';
                            }
                            final loginResult = json.decode(body);

                            if (loginResult['Result']) {
                              if (kIsWeb == false) {
                                checkUpdate().then((updateFrom) async {
                                  if (updateFrom != 'isLatest') {
                                    if (!mounted) return;
                                    Navigator.popUntil(context, ModalRoute.withName('/login'));
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return MessageDialog(
                                          key: globalKey,
                                          titleText: Text(AppLocalizations.of(context)!.loginPageVersionCheckTitle),
                                          contentText: Column(
                                            children: [
                                              Text(AppLocalizations.of(context)!.loginPageVersionCheckContent.replaceAll('%', appLatestVersion))
                                            ],
                                          ),
                                          onPressed: () async {
                                            if (Platform.isAndroid) {
                                              if (updateFrom == 'GitHub' && await Permission.manageExternalStorage.request().isGranted) {
                                                double? downloadProgress = 0;
                                                globalKey.currentState?.changeContent(
                                                  Text(AppLocalizations.of(context)!.loginPageVersionUpgradeTitle),
                                                  Column(
                                                    children: [
                                                      LinearProgressIndicator(
                                                        value: downloadProgress / 100,
                                                        color: Colors.blue,
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 4.0),
                                                        child: Text(AppLocalizations.of(context)!.loginPageVersionUpgradeConnecting),
                                                      ),
                                                    ],
                                                  ),
                                                  false,
                                                  false,
                                                  () => {Navigator.of(context).pop()},
                                                  true
                                                );

                                                try {
                                                  final dio = Dio();
                                                  final savePath = '${(await getTemporaryDirectory()).path}/Tythac.apk';
                                                  var sTime = DateTime.now();
                                                  await dio.download(
                                                    apkDownloadUrl,
                                                    savePath,
                                                    onReceiveProgress: (downloaded, total) async {
                                                      downloadProgress = downloaded * 100 / total;
                                                      if (downloadProgress! < 100 && DateTime.now().difference(sTime).inSeconds >= 1) {
                                                        globalKey.currentState?.changeContent(
                                                          Text(AppLocalizations.of(context)!.loginPageVersionUpgradeTitle),
                                                          Column(
                                                            children: [
                                                              LinearProgressIndicator(
                                                                value: downloadProgress! / 100,
                                                                color: Colors.blue,
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets.only(top: 4.0),
                                                                child: Text('${(downloaded/1024/1024).toStringAsFixed(2)} MB / ${(total/1024/1024).toStringAsFixed(2)} MB (${downloadProgress?.toStringAsFixed(0)}%)'),
                                                              ),
                                                            ],
                                                          ),
                                                          false,
                                                          false,
                                                          () => {Navigator.of(context).pop()},
                                                          true
                                                        );
                                                        sTime = DateTime.now();
                                                      }
                                                      else if (downloadProgress! >= 100) {
                                                        Navigator.of(context).pop();
                                                        try {
                                                          if (await Permission.requestInstallPackages.request().isGranted) {
                                                            await OpenFile.open(savePath);
                                                          }
                                                        } catch (ex) {
                                                          Fluttertoast.showToast(
                                                            msg: ex.toString(),
                                                            gravity: ToastGravity.BOTTOM,
                                                            toastLength: Toast.LENGTH_SHORT,
                                                          );
                                                        }
                                                      }
                                                    }
                                                  );
                                                } on DioException {
                                                  globalKey.currentState?.changeContent(
                                                    Text(AppLocalizations.of(context)!.failedTitle),
                                                    Text(AppLocalizations.of(context)!.downloadError),
                                                    true,
                                                    false,
                                                    () => {Navigator.of(context).pop()},
                                                    true
                                                  );
                                                }
                                              }
                                              else {
                                                globalKey.currentState?.changeContent(
                                                  Text(AppLocalizations.of(context)!.failedTitle),
                                                  Text('${AppLocalizations.of(context)!.downloadError}, ${AppLocalizations.of(context)!.manualUpdate}'),
                                                  true,
                                                  true,
                                                  () async => {
                                                    if (await canLaunchUrl(Uri.parse(apkDownloadUrl))) {
                                                      await launchUrl(
                                                        Uri.parse(apkDownloadUrl),
                                                        mode: LaunchMode.externalApplication,
                                                      )
                                                    }
                                                    else {
                                                      Fluttertoast.showToast(
                                                        msg: AppLocalizations.of(context)!.downloadError,
                                                        gravity: ToastGravity.BOTTOM,
                                                        toastLength: Toast.LENGTH_SHORT,
                                                      )
                                                    }
                                                  },
                                                  true
                                                );
                                              }
                                            }
                                          },
                                          showOKButton: true,
                                          showCancelButton: true
                                        );
                                      }
                                    );
                                  }
                                  else {
                                    final userInfo = await SharedPreferences.getInstance();
                                    if (loginMode == 'User') {
                                      userInfo.setString('userID', loginResult['UserID']);
                                      userInfo.setString('userName', loginResult['UserName']);
                                      userInfo.setString('password', rememberPwd ? passwordController.text : '');
                                      userInfo.setString('group', loginResult['Group']);
                                      userInfo.setString('department', loginResult['Department']);
                                      userInfo.setString('factory', loginResult['Factory']);
                                      userInfo.setString('loginMode', 'User');
                                      Navigator.popUntil(context, ModalRoute.withName('/login'));
                                      Navigator.pushReplacementNamed(context, '/home');
                                    }
                                    else if (loginMode == 'ProductionLine') {
                                      userInfo.setString('building', buildingController.text);
                                      userInfo.setString('lean', leanController.text);
                                      userInfo.setString('orderBuilding', orderBuildingController.text);
                                      userInfo.setString('orderLean', orderLeanController.text);
                                      userInfo.setString('section', sectionController.text);
                                      userInfo.setString('loginMode', 'ProductionLine');
                                      Navigator.popUntil(context, ModalRoute.withName('/login'));
                                      Navigator.pushReplacementNamed(context, '/lean_schedule');
                                    }
                                    else if (loginMode == 'Machine') {
                                      userInfo.setString('building', buildingController.text);
                                      userInfo.setString('machine', machineController.text);
                                      userInfo.setString('loginMode', 'Machine');
                                      Navigator.popUntil(context, ModalRoute.withName('/login'));
                                      Navigator.pushReplacementNamed(context, '/machineWorkOrder');
                                    }

                                    Fluttertoast.showToast(
                                      msg: AppLocalizations.of(context)!.loginPageSuccess,
                                      gravity: ToastGravity.BOTTOM,
                                      toastLength: Toast.LENGTH_SHORT,
                                    );
                                  }
                                });
                              }
                              else {
                                final userInfo = await SharedPreferences.getInstance();
                                if (loginMode == 'User') {
                                  userInfo.setString('userID', loginResult['UserID']);
                                  userInfo.setString('userName', loginResult['UserName']);
                                  userInfo.setString('password', rememberPwd ? passwordController.text : '');
                                  userInfo.setString('group', loginResult['Group']);
                                  userInfo.setString('department', loginResult['Department']);
                                  userInfo.setString('factory', loginResult['Factory']);
                                  userInfo.setString('loginMode', 'User');
                                  Navigator.popUntil(context, ModalRoute.withName('/login'));
                                  Navigator.pushReplacementNamed(context, '/home');
                                }
                                else if (loginMode == 'ProductionLine') {
                                  userInfo.setString('building', buildingController.text);
                                  userInfo.setString('lean', leanController.text);
                                  userInfo.setString('orderBuilding', orderBuildingController.text);
                                  userInfo.setString('orderLean', orderLeanController.text);
                                  userInfo.setString('section', sectionController.text);
                                  userInfo.setString('loginMode', 'ProductionLine');
                                  Navigator.popUntil(context, ModalRoute.withName('/login'));
                                  Navigator.pushReplacementNamed(context, '/lean_schedule');
                                }
                                else if (loginMode == 'Machine') {
                                  userInfo.setString('building', buildingController.text);
                                  userInfo.setString('machine', machineController.text);
                                  userInfo.setString('loginMode', 'Machine');
                                  Navigator.popUntil(context, ModalRoute.withName('/login'));
                                  Navigator.pushReplacementNamed(context, '/machineWorkOrder');
                                }

                                Fluttertoast.showToast(
                                  msg: AppLocalizations.of(context)!.loginPageSuccess,
                                  gravity: ToastGravity.BOTTOM,
                                  toastLength: Toast.LENGTH_SHORT,
                                );
                              }
                            }
                            else {
                              Navigator.popUntil(context, ModalRoute.withName('/login'));
                              Fluttertoast.showToast(
                                msg: AppLocalizations.of(context)!.loginPageWrongPassword,
                                gravity: ToastGravity.BOTTOM,
                                toastLength: Toast.LENGTH_SHORT,
                              );
                            }
                          } catch (error) {
                            Navigator.popUntil(context, ModalRoute.withName('/login'));
                            Fluttertoast.showToast(
                              msg: AppLocalizations.of(context)!.loginPageConnectFailed,
                              gravity: ToastGravity.BOTTOM,
                              toastLength: Toast.LENGTH_SHORT,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4))
                          ),
                          side: const BorderSide(color: Colors.grey)
                        ),
                        child: Center(
                          child: Text(AppLocalizations.of(context)!.loginPageLogin, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.4)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLocalizations.of(context)!.loginPageLanguage, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          isExpanded: false,
                          underline: Container(
                            height: 1,
                            color: Colors.black,
                          ),
                          value: selectedLocal,
                          items: const [
                            DropdownMenuItem(
                              value: 'zh',
                              child: Text('中文')
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English')
                            ),
                            DropdownMenuItem(
                              value: 'vi',
                              child: Text('Tiếng Việt')
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedLocal = value!;
                              widget.changeLanguage(Locale(selectedLocal));
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/setting/server_address');
                          },
                          child: Text(AppLocalizations.of(context)!.loginPageServerSetting, style: const TextStyle(fontSize: 16, color: Colors.blue))
                        ),
                        const Text('/', style: TextStyle(fontSize: 20)),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return ModeSwitchDialog(
                                  building: buildingController.text,
                                  orderBuilding: orderBuildingController.text,
                                  machine: machineController.text,
                                  modeSwitch: modeSwitch,
                                );
                              }
                            );
                          },
                          child: Text(AppLocalizations.of(context)!.loginModeSwitch, style: const TextStyle(fontSize: 16, color: Colors.blue))
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: MediaQuery.of(context).viewInsets.bottom == 0,
              child: Positioned(
                right: 8,
                bottom: 8,
                child: Text('Ver. $appVersion', style: const TextStyle(color: Colors.black))
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ModeSwitchDialog extends StatefulWidget {
  const ModeSwitchDialog({
    super.key,
    required this.building,
    required this.orderBuilding,
    required this.machine,
    required this.modeSwitch
  });

  final String building;
  final String orderBuilding;
  final String machine;
  final Function modeSwitch;

  @override
  State<StatefulWidget> createState() => ModeSwitchDialogState();
}

class ModeSwitchDialogState extends State<ModeSwitchDialog> {
  String sMode = loginMode;
  final fController = TextEditingController();
  final mController = TextEditingController();
  final pwdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fController.text = widget.building;
    mController.text = widget.machine;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      titlePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      title: Text(AppLocalizations.of(context)!.loginModeSwitch, style: const TextStyle(fontSize: 18)),
      contentPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
              color: Colors.white38
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton(
                padding: const EdgeInsets.only(left: 12, right: 4),
                isExpanded: true,
                value: sMode,
                style: const TextStyle(fontSize: 14, color: Colors.black),
                items: [
                  DropdownMenuItem(
                    value: 'User',
                    child: Text(AppLocalizations.of(context)!.userAccount)
                  ),
                  DropdownMenuItem(
                    value: 'ProductionLine',
                    child: Text(AppLocalizations.of(context)!.productionLine)
                  ),
                  DropdownMenuItem(
                    value: 'Machine',
                    child: Text(AppLocalizations.of(context)!.machineAccount)
                  )
                ],
                onChanged: (value) {
                  setState(() {
                    sMode = value!;
                  });
                },
              ),
            ),
          ),
          Visibility(
            visible: sMode == 'Machine',
            child: const SizedBox(height: 4)
          ),
          Visibility(
            visible: sMode == 'Machine',
            child: TextField(
              controller: fController,
              obscureText: false,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black38),
                ),
                fillColor: Colors.white38,
                filled: true,
                hintText: AppLocalizations.of(context)!.building,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  height: 1.4
                )
              )
            ),
          ),
          Visibility(
            visible: sMode == 'Machine',
            child: const SizedBox(height: 4)
          ),
          Visibility(
            visible: sMode == 'Machine',
            child: TextField(
              controller: mController,
              obscureText: false,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black38),
                ),
                fillColor: Colors.white38,
                filled: true,
                hintText: AppLocalizations.of(context)!.machineAccount,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  height: 1.4
                )
              )
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 48,
            child: TextField(
              controller: pwdController,
              obscureText: true,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black38),
                ),
                fillColor: Colors.white38,
                filled: true,
                hintText: AppLocalizations.of(context)!.loginPagePassword,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  height: 1.4
                )
              )
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.ok),
          onPressed: () async {
            if (pwdController.text == 'Admin@modeswitch') {
              if (sMode == 'User') {
                loginMode = 'User';
              }
              else if (sMode == 'ProductionLine') {
                DateTime today = DateTime.now();
                final body = await RemoteService().getFactoryLean(
                  apiAddress,
                  DateFormat('yyyy/MM').format(DateTime(today.year, today.month - 1, 1)),
                  'CurrentMonthWithoutPM'
                );
                final jsonData = json.decode(body);

                factoryDropdownItems = [];
                factoryLeans = [];
                if (jsonData.length > 0) {
                  for (int i = 0; i < jsonData.length; i++) {
                    factoryDropdownItems.add(jsonData[i]['Factory']);
                    List<String> leans = [];
                    for (int j = 0; j < jsonData[i]['Lean'].length; j++) {
                      leans.add(jsonData[i]['Lean'][j]);
                    }
                    factoryLeans.add(leans);
                  }

                  lean = factoryLeans[factoryDropdownItems.indexOf(widget.building)].map((String myLean) {
                    return DropdownMenuItem(
                      value: myLean,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(myLean.toString()),
                        ),
                      )
                    );
                  }).toList();

                  orderLean = factoryLeans[factoryDropdownItems.indexOf(widget.orderBuilding)].map((String myLean) {
                    return DropdownMenuItem(
                      value: myLean,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(myLean.toString()),
                        ),
                      )
                    );
                  }).toList();
                }

                loginMode = 'ProductionLine';
              }
              else {
                loginMode = 'Machine';
              }
              widget.modeSwitch(fController.text, mController.text);
              Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.successTitle,
                gravity: ToastGravity.BOTTOM,
                toastLength: Toast.LENGTH_SHORT,
              );
              Navigator.of(context).pop();
            }
            else {
              Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.loginPageWrongPassword,
                gravity: ToastGravity.BOTTOM,
                toastLength: Toast.LENGTH_SHORT,
              );
            }
          },
        )
      ]
    );
  }
}

class MessageDialog extends StatefulWidget {
  const MessageDialog({
    super.key,
    required this.titleText,
    required this.contentText,
    required this.onPressed,
    required this.showOKButton,
    required this.showCancelButton
  });

  final Widget titleText;
  final Widget contentText;
  final void Function()? onPressed;
  final bool showOKButton;
  final bool showCancelButton;

  @override
  State<StatefulWidget> createState() => MessageDialogState();
}

class MessageDialogState extends State<MessageDialog> {
  bool applyChange = false;
  Widget setTitle = const Text('');
  Widget setContent = const Text('');
  bool setOkButton = true;
  bool setCancelButton = true;
  void Function()? setPressed;

  @override
  void initState() {
    super.initState();
  }

  void changeContent(Widget title, Widget content, bool oKButton, bool cancelButton, Function()? onPressed, bool change) {
    setState(() {
      applyChange = change;
      setTitle = title;
      setContent = content;
      setOkButton = oKButton;
      setCancelButton = cancelButton;
      setPressed = onPressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actionButtons = [];
    if (applyChange == false ? widget.showCancelButton : setCancelButton) {
      actionButtons.add(TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text(AppLocalizations.of(context)!.cancel),
      ));
    }
    if (applyChange == false ? widget.showOKButton : setOkButton) {
      actionButtons.add(TextButton(
        onPressed: applyChange == false ? widget.onPressed : setPressed,
        child: Text(AppLocalizations.of(context)!.ok),
      ));
    }

    return AlertDialog(
      scrollable: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      title: applyChange == false ? widget.titleText : setTitle,
      content: applyChange == false ? widget.contentText : setContent,
      actions: actionButtons
    );
  }
}