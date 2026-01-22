import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/components/side_menu.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:production/services/remote_service.dart';
import 'package:url_launcher/url_launcher.dart';

String apiAddress = '';
String userName = '';
String group = '';
String appVersion = '';
String appLatestVersion = '';
const apkDownloadUrl = 'https://github.com/danny0614/Tyxuan/releases/latest/download/Tythac.apk';

class Setting extends StatefulWidget {
  final Function changeLanguage;
  const Setting({
    super.key,
    required this.changeLanguage
  });

  @override
  SettingState createState() => SettingState();
}

class SettingState extends State<Setting> {
  final addressController = TextEditingController();
  String languages = 'zh';

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '';
    setState(() {
      userName = prefs.getString('userName') ?? '';
      group = prefs.getString('group') ?? '';
      languages = prefs.getString('locale') ?? 'zh';
      apiAddress = prefs.getString('address') ?? '';
      addressController.text = apiAddress;
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    appLatestVersion = appVersion;
  }

  Future<String> checkUpdate() async {
    String updateFrom = '';
    final body = await RemoteService().getAppLatestVersion();
    final latestApp = json.decode(body);
    updateFrom = latestApp['From'].toString();
    appLatestVersion = latestApp['Body']['tag_name'].toString().replaceAll('v', '');
    if (appVersion == appLatestVersion) {
      return 'isLatest';
    }
    else {
      return updateFrom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              }
            );
          },
        ),
        title: Text(AppLocalizations.of(context)!.settingsTitle),
      ),
      drawer: SideMenu(
        userName: userName,
        group: group,
      ),
      backgroundColor: Colors.grey[300],
      body: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.vpn_key,
              color: Colors.black,
            ),
            title: Text(AppLocalizations.of(context)!.settingsPassword),
            onTap: () {
              Navigator.pushNamed(context, '/setting/change_password');
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.language,
              color: Colors.black,
            ),
            title: Text(AppLocalizations.of(context)!.settingsLanguage),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(builder: (context, setState) {
                    return AlertDialog(
                      scrollable: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8))
                      ),
                      content: Column(
                        children: [
                          RadioListTile(
                            title: const Text('中文'),
                            activeColor: Colors.blue,
                            value: 'zh',
                            groupValue: languages,
                            onChanged: (value) {
                              setState(() {
                                languages = value!;
                              });
                            },
                          ),
                          RadioListTile(
                            title: const Text('English'),
                            activeColor: Colors.blue,
                            value: 'en',
                            groupValue: languages,
                            onChanged: (value) {
                              setState(() {
                                languages = value!;
                              });
                            },
                          ),
                          RadioListTile(
                            title: const Text('Tiếng Việt'),
                            activeColor: Colors.blue,
                            value: 'vi',
                            groupValue: languages,
                            onChanged: (value) {
                              setState(() {
                                languages = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            widget.changeLanguage(Locale(languages));
                          },
                          child: Text(AppLocalizations.of(context)!.ok),
                        ),
                      ]
                    );
                  });
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.dns_rounded,
              color: Colors.black,
            ),
            title: Text(AppLocalizations.of(context)!.settingsServerSetting),
            onTap: () {
              Navigator.pushNamed(context, '/setting/server_address');
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.system_update,
              color: Colors.black,
            ),
            title: Text(AppLocalizations.of(context)!.settingsUpgrade),
            trailing: Text(appVersion),
            onTap: () async {
              if (kIsWeb == false) {
                GlobalKey<MessageDialogState> globalKey = GlobalKey();
                checkUpdate().then((updateFrom) async {
                  if (updateFrom != 'isLatest') {
                    if (!mounted) return;
                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (BuildContext context) {
                        return MessageDialog(
                          key: globalKey,
                          titleText: Text(AppLocalizations.of(context)!.settingsVersionCheckTitle),
                          contentText: Column(
                            children: [
                              Text(AppLocalizations.of(context)!.settingsVersionCheckContent.replaceAll('%', appLatestVersion))
                            ],
                          ),
                          onPressed: () async {
                            if (Platform.isAndroid) {
                              if (updateFrom == 'GitHub' && await Permission.manageExternalStorage.request().isGranted) {
                                double? downloadProgress = 0;
                                globalKey.currentState?.changeContent(
                                  Text(AppLocalizations.of(context)!.settingsVersionUpgradeTitle),
                                  Column(
                                    children: [
                                      LinearProgressIndicator(
                                        value: downloadProgress / 100,
                                        color: Colors.blue,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(AppLocalizations.of(context)!.settingsVersionUpgradeConnecting),
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
                                  final savePath = '${(await getTemporaryDirectory()).path}/Tyxuan.apk';
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
                    if (!mounted) return;
                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (BuildContext context) {
                        return MessageDialog(
                          key: globalKey,
                          titleText: Text(AppLocalizations.of(context)!.settingsVersionCheckTitle),
                          contentText: Column(
                            children: [
                              Text(AppLocalizations.of(context)!.settingsVersionIsLatest)
                            ]
                          ),
                          onPressed: () async {
                            Navigator.of(context).pop();
                          },
                          showOKButton: true,
                          showCancelButton: false,
                        );
                      }
                    );
                  }
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.black,
            ),
            title: Text(AppLocalizations.of(context)!.settingsLogout),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    scrollable: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))
                    ),
                    content: Text(AppLocalizations.of(context)!.settingsLogoutConfirm),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
                        },
                        child: Text(AppLocalizations.of(context)!.ok),
                      ),
                    ]
                  );
                },
              );
            },
          ),
        ],
      ),
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