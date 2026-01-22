import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:horizontal_data_table/refresh/pull_to_refresh/src/indicator/material_indicator.dart';
import 'package:horizontal_data_table/refresh/pull_to_refresh/src/smart_refresher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:production/services/remote_service.dart';

String lean = '', apiAddress = '', factory = '', userID = '';
double screenWidth = 0, screenHeight = 0;
List<bool> checkStatus = [], enabled = [];
List<String> selection = [];

class CycleTracking extends StatefulWidget {
  const CycleTracking({super.key});

  @override
  CycleTrackingState createState() => CycleTrackingState();
}

class CycleTrackingState extends State<CycleTracking> {
  RefreshController refreshController = RefreshController(initialRefresh: false);
  List<Widget> cycleList = [];
  List<GlobalKey> keys = [];
  String order = '', section = '';
  int cycleStart = 0, cycleEnd = 0;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString('userID') ?? '';
      factory = prefs.getString('factory') ?? '';
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    manualRefresh();
  }

  void getCycles() async {
    List<String> parameter = (ModalRoute.of(context)?.settings.arguments as String?)!.split(';');
    if (parameter.length == 4) {
      if (parameter[3].contains(' - ')) {
        cycleStart = int.parse(parameter[3].substring(1, parameter[3].indexOf(' - ')));
        cycleEnd = int.parse(parameter[3].substring(parameter[3].indexOf(' - ') + 4, parameter[3].length));
      }
      else {
        cycleStart = int.parse(parameter[3].substring(1, parameter[3].length));
        cycleEnd = cycleStart;
      }
      lean = parameter[2];
    }
    else {
      cycleStart = 0;
      cycleEnd = 0;
    }
    cycleList = [];
    checkStatus = [];
    enabled = [];
    selection = [];
    try {
      final body = await RemoteService().getOrderCycleDispatchData(
        apiAddress,
        order,
        section
      );
      final jsonData = json.decode(body);
      for (int i = 0; i < jsonData["Cycles"].length; i++) {
        int statusCode = int.parse(jsonData["Cycles"][i]["Dispatched"].toString());
        int prepare = int.parse(jsonData["Cycles"][i]["Prepare"].toString());
        Color textColor = Colors.black;
        checkStatus.add(true);
        enabled.add(true);
        if (statusCode == 1) {
          textColor = Colors.orange;
        }
        else if (statusCode == 2) {
          textColor = Colors.green;
        }

        String sCycle = jsonData["Cycles"][i]["Cycle"].toString();
        int cycle = sCycle == order ? 1 : int.parse(sCycle.substring(sCycle.length-2, sCycle.length));
        if ((cycle >= cycleStart && cycle <= cycleEnd) || cycleStart == 0) {
          if (cycleStart == 0) {
            cycleList.add(
              CycleSelection(
                index: i,
                cycle: sCycle,
                title: Text(sCycle, style: TextStyle(fontSize: 18, color: textColor)),
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
          else {
            cycleList.add(
              CyclePrepare(
                index: i,
                order: order,
                cycle: sCycle,
                title: Text(sCycle, style: TextStyle(fontSize: 18, color: textColor)),
                enabled: prepare == 0,
                icon: statusCode == 0
                ? Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.fiber_manual_record, size: 10, color: textColor),
                )
                : statusCode == 1
                ? Icon(Icons.downloading, color: textColor)
                : Icon(Icons.check_circle_outline, color: textColor),
                refresh: manualRefresh,
              )
            );
          }
        }
      }
      setState(() {
        cycleList = cycleList;
      });
    } on Exception {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context)!.stitchingWorkOrderLoadingError,
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
    List<String> parameter = (ModalRoute.of(context)?.settings.arguments as String?)!.split(';');
    order = parameter[0];
    section = parameter[1];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(order),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[300],
      body: SmartRefresher(
        header: const MaterialClassicHeader(color: Colors.blue),
        controller: refreshController,
        onRefresh: getCycles,
        child: SingleChildScrollView(
          child: Column(
            children: cycleList,
          ),
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
          onTap: null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: widget.icon,
                ),
                Expanded(child: widget.title),
                Checkbox(
                  checkColor: Colors.grey[300],
                  activeColor: Colors.grey[300],
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

class CyclePrepare extends StatefulWidget {
  const CyclePrepare({
    super.key,
    required this.index,
    required this.order,
    required this.cycle,
    required this.title,
    required this.enabled,
    required this.icon,
    required this.refresh,
  });
  final int index;
  final String order;
  final String cycle;
  final Widget title;
  final bool enabled;
  final Widget icon;
  final Function refresh;

  @override
  CyclePrepareState createState() => CyclePrepareState();
}

class CyclePrepareState extends State<CyclePrepare> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: widget.icon,
              ),
              Expanded(child: widget.title),
              Visibility(
                visible: !widget.enabled,
                child: const SizedBox(
                  height: 30,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Icon(Icons.check, color: Colors.blue),
                  )
                ),
              )
            ],
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