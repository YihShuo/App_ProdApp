import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:horizontal_data_table/refresh/pull_to_refresh/src/indicator/material_indicator.dart';
import 'package:horizontal_data_table/refresh/pull_to_refresh/src/smart_refresher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:production/services/remote_service.dart';

String department = '', apiAddress = '', factory = '';
double screenWidth = 0, screenHeight = 0;
List<bool> checkStatus = [], enabled = [];
List<String> selection = [];

class AssemblyWorkOrderDispatch extends StatefulWidget {
  const AssemblyWorkOrderDispatch({super.key});

  @override
  AssemblyWorkOrderDispatchState createState() => AssemblyWorkOrderDispatchState();
}

class AssemblyWorkOrderDispatchState extends State<AssemblyWorkOrderDispatch> {
  RefreshController refreshController = RefreshController(initialRefresh: false);
  List<Widget> cycleList = [];
  List<GlobalKey> keys = [];
  String userID = '', userName = '', group = '', order = '', lean = '';

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString('userID') ?? '';
      userName = prefs.getString('userName') ?? '';
      group = prefs.getString('group') ?? '';
      factory = prefs.getString('factory') ?? '';
      department = prefs.getString('department') ?? 'A02_LEAN01';
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    manualRefresh();
  }

  void getCycles() async {
    cycleList = [];
    checkStatus = [];
    enabled = [];
    selection = [];
    try {
      final body = await RemoteService().getOrderCycleDispatchData(
        apiAddress,
        order,
        'A'
      );
      final jsonData = json.decode(body);
      for (int i = 0; i < jsonData["Cycles"].length; i++) {
        int statusCode = int.parse(jsonData["Cycles"][i]["Dispatched"].toString());
        Color textColor = Colors.black;
        if (statusCode == 0) {
          checkStatus.add(false);
          enabled.add(true);
        }
        else {
          checkStatus.add(true);
          enabled.add(false);
          if (statusCode == 1) {
            textColor = Colors.orange;
          }
          else {
            textColor = Colors.green;
          }
        }
        cycleList.add(
          CycleSelection(
            index: i,
            cycle: jsonData["Cycles"][i]["Cycle"],
            title: Text(jsonData["Cycles"][i]["Cycle"], style: TextStyle(fontSize: 18, color: textColor)),
            enabled: enabled[i],
            icon: statusCode == 0
            ? Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(Icons.fiber_manual_record, size: 10, color: textColor),
            )
            : statusCode == 1
            ? Icon(Icons.downloading, color: textColor)
            : Icon(Icons.check_circle_outline, color: textColor),
          )
        );
      }
      setState(() {
        cycleList = cycleList;
      });
    } on Exception {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context)!.assemblyWorkOrderLoadingError,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
    refreshController.refreshCompleted();
  }

  void manualRefresh() {
    refreshController.requestRefresh();
  }

  @override
  Widget build(BuildContext context) {
    order = (ModalRoute.of(context)?.settings.arguments as String?)!.split(';')[0];
    lean = (ModalRoute.of(context)?.settings.arguments as String?)!.split(';')[1];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.settings.name == '/assembly');
          },
        ),
        title: Text(order),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: SmartRefresher(
        header: const MaterialClassicHeader(color: Colors.blue),
        controller: refreshController,
        onRefresh: getCycles,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: cycleList,
                ),
              ),
            ),
            Container(
              color: Colors.blue,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: OutlinedButton(
                  onPressed: () {
                    GlobalKey<MessageDialogState> globalKey = GlobalKey();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        if (selection.isNotEmpty) {
                          return MessageDialog(
                            key: globalKey,
                            titleText: AppLocalizations.of(context)!.confirmTitle,
                            contentText: AppLocalizations.of(context)!.assemblyWorkOrderDispatchDispatchingConfirmContent,
                            showOKButton: true,
                            showCancelButton: true,
                            onPressed: () async {
                              final body = await RemoteService().generateOrderCycleDispatchData(
                                apiAddress,
                                order,
                                'A',
                                userID,
                                lean,
                                factory,
                                "'${selection.join("','")}'",
                                '',
                                '',
                                0,
                                ''
                              );
                              final jsonData = json.decode(body);
                              if (!mounted) return;
                              if (jsonData['statusCode'] == 200) {
                                manualRefresh();
                                globalKey.currentState?.changeContent(AppLocalizations.of(context)!.successTitle, Text(AppLocalizations.of(context)!.successContent), true, false, () => {Navigator.of(context).pop()}, true);
                              }
                              else {
                                globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).pop()}, true);
                              }
                            }
                          );
                        }
                        else {
                          return MessageDialog(
                            key: globalKey,
                            titleText: AppLocalizations.of(context)!.assemblyWorkOrderDispatchNotSelectTitle,
                            contentText: AppLocalizations.of(context)!.assemblyWorkOrderDispatchDispatchingNotSelectContent,
                            showOKButton: true,
                            showCancelButton: false,
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.settings.name == '/assembly/dispatch');
                            },
                          );
                        }
                      }
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))
                    ),
                  ),
                  child: Center(
                    child: Text(AppLocalizations.of(context)!.assemblyWorkOrderDispatchDispatching, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                  )
                )
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CycleSelection extends StatefulWidget {
  const CycleSelection({
    super.key,
    required this.index,
    required this.cycle,
    required this.title,
    required this.enabled,
    required this.icon
  });
  final int index;
  final String cycle;
  final Widget title;
  final bool enabled;
  final Widget icon;

  @override
  CycleSelectionState createState() => CycleSelectionState();
}

class CycleSelectionState extends State<CycleSelection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: widget.enabled
          ? () {
            if (widget.enabled) {
              setState(() {
                checkStatus[widget.index] = !checkStatus[widget.index];
              });
              if (checkStatus[widget.index]) {
                selection.add(widget.cycle);
              }
              else {
                selection.remove(widget.cycle);
              }
            }
          }
          : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: widget.icon,
                ),
                Expanded(child: widget.title),
                Checkbox(
                  checkColor: widget.enabled ? Colors.white : Colors.grey[100],
                  activeColor: widget.enabled ? Colors.blue : Colors.grey[100],
                  value: checkStatus[widget.index],
                  onChanged: (bool? newValue) {
                    if (widget.enabled) {
                      setState(() {
                        checkStatus[widget.index] = !checkStatus[widget.index];
                      });
                      if (checkStatus[widget.index]) {
                        selection.add(widget.cycle);
                      }
                      else {
                        selection.remove(widget.cycle);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1)
      ],
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

  final String titleText;
  final String contentText;
  final void Function()? onPressed;
  final bool showOKButton;
  final bool showCancelButton;

  @override
  State<StatefulWidget> createState() => MessageDialogState();
}

class MessageDialogState extends State<MessageDialog> {
  bool applyChange = false;
  String setTitle = '';
  Widget setContent = const Text('');
  bool setOkButton = true;
  bool setCancelButton = true;
  void Function()? setPressed;

  @override
  void initState() {
    super.initState();
  }

  void changeContent(String title, Widget content, bool oKButton, bool cancelButton, Function()? onPressed, bool change) {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      title: Text(applyChange == false ? widget.titleText : setTitle),
      content: applyChange == false ? Text(widget.contentText) : setContent,
      actions: actionButtons
    );
  }
}