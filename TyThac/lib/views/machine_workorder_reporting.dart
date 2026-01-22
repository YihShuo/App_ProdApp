import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:production/services/remote_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/components/sizerun_table_machine_reporting.dart';

String apiAddress = '';
bool readOnly = true;

class MachineWorkOrderReporting extends StatefulWidget {
  const MachineWorkOrderReporting({super.key});

  @override
  State<StatefulWidget> createState() => MachineWorkOrderReportingState();
}

class MachineWorkOrderReportingState extends State<MachineWorkOrderReporting> with SingleTickerProviderStateMixin {
  late final TabController tabController;
  String previousPage = '', order = '', machine = '';
  List<DataColumn> partColumn = [];
  List<DataRow> cycleRow = [];
  List<List<String>> partList = [];
  List<Tab> partTab = [];
  late Future futureTabs;
  
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 1, vsync: this);
    loadInfo();
    futureTabs = fetchTabs();
  }

  void loadInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiAddress = prefs.getString('address') ?? '';
    });
  }

  Future<List<List<String>>> fetchTabs() async {
    partList = [];
    final prefs = await SharedPreferences.getInstance();
    String locale = prefs.getString('locale') ?? 'zh';
    final body = await RemoteService().getMachineDispatchedPart(
      apiAddress,
      machine,
      order
    );
    final jsonData = json.decode(body);
    for (int i = 0; i < jsonData.length; i++) {
      List<String> partInfo = [];
      partInfo.add(jsonData[i]['PartID'].toString());
      partInfo.add(jsonData[i]['MaterialID'].toString());
      partInfo.add(jsonData[i]['PartName'][0][locale.toUpperCase()].toString());
      partInfo.add(jsonData[i]['PartName'][0]['Type'].toString());
      partInfo.add(jsonData[i]['PartName'][0]['Status'].toString());
      partList.add(partInfo);
    }
    return partList;
  }

  void refreshPage() {
    futureTabs = fetchTabs();
  }

  double getTextWidth(String text, TextStyle style, BuildContext context) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }

  @override
  Widget build(BuildContext context) {
    List<String> arg = (ModalRoute.of(context)?.settings.arguments as String?)!.split(';');
    order = arg[0];
    machine = arg[1];
    previousPage = arg[2];
    readOnly = arg[3] == "ReadOnly" ? true : false;
    return FutureBuilder(
      future: futureTabs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.settings.name == previousPage);
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(machine.replaceAll('_', ' '), style: const TextStyle(fontSize: 16))
                ],
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: Colors.blue)
            )
          );
        }
        else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.settings.name == previousPage);
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(machine.replaceAll('_', ' '), style: const TextStyle(fontSize: 16))
                ],
              ),
            ),
            body: Center(
              child: Text('Error: ${snapshot.error}')
            )
          );
        }
        else if (snapshot.hasData) {
          List<List<String>> tabs = snapshot.data!;
          if (tabs.isNotEmpty) {
            return DefaultTabController(
              length: tabs.length,
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.settings.name == previousPage);
                    },
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(machine.replaceAll('_', ' '), style: const TextStyle(fontSize: 16))
                    ],
                  ),
                  bottom: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelPadding: EdgeInsets.zero,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white,
                    indicator: const BoxDecoration(
                      color: Colors.white,
                    ),
                    tabs: tabs.map((List<String> tab) =>
                      Tab(
                        icon: tab[3] == "Manual"
                        ? SizedBox(
                          width: getTextWidth(tab[2], const TextStyle(), context) > getTextWidth(tab[1], const TextStyle(), context)
                          ? getTextWidth(tab[2], const TextStyle(), context) + 20
                          : getTextWidth(tab[1], const TextStyle(), context) + 20,
                          height: 24,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.person_outline),
                                    Text(tab[0], style: const TextStyle(height: 1.4))
                                  ],
                                )
                              ),
                              int.parse(tab[4]) == 2
                              ? Positioned(
                                top: 0,
                                right: 3,
                                child: Container(
                                  height: 16,
                                  width: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(Radius.circular(10))
                                  ),
                                  child: const Icon(Icons.check_circle, color: Colors.green, size: 16)
                                )
                              )
                              : int.parse(tab[4]) == 1
                              ? Positioned(
                                top: 0,
                                right: 3,
                                child: Container(
                                  height: 16,
                                  width: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(Radius.circular(10))
                                  ),
                                  child: const Icon(Icons.watch_later, color: Colors.orangeAccent, size: 16)
                                )
                              )
                              : Container()
                            ],
                          ),
                        )
                        : SizedBox(
                          width: getTextWidth(tab[2], const TextStyle(), context) > getTextWidth(tab[1], const TextStyle(), context)
                          ? getTextWidth(tab[2], const TextStyle(), context) + 20
                          : getTextWidth(tab[1], const TextStyle(), context) + 20,
                          height: 24,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.precision_manufacturing),
                                    Text(tab[0], style: const TextStyle(height: 1.4))
                                  ],
                                )
                              ),
                              int.parse(tab[4]) == 2
                              ? Positioned(
                                right: 0,
                                child: Container(
                                  height: 16,
                                  width: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(Radius.circular(10))
                                  ),
                                  child: const Icon(Icons.check_circle, color: Colors.green, size: 16)
                                )
                              )
                              : int.parse(tab[4]) == 1
                              ? Positioned(
                                right: 0,
                                child: Container(
                                  height: 16,
                                  width: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(Radius.circular(10))
                                  ),
                                  child: const Icon(Icons.watch_later, color: Colors.orangeAccent, size: 16)
                                )
                              )
                              : Container()
                            ],
                          ),
                        ),
                        iconMargin: EdgeInsets.zero,
                        child: Column(
                          children: [
                            Text(tab[2], style: const TextStyle(height: 1.4)),
                            Text(tab[1], style: const TextStyle(height: 1.4))
                          ]
                        ))
                    ).toList(),
                  ),
                ),
                body: TabBarView(
                  children: tabs.map((List<String> tab) {
                    return SizeRunTableMachineReporting(
                      apiAddress: apiAddress,
                      machine: machine,
                      order: order,
                      partID: tab[0],
                      readOnly: readOnly,
                    );
                  }).toList(),
                ),
              ),
            );
          }
          else {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.settings.name == previousPage);
                  },
                ),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(machine.replaceAll('_', ' '), style: const TextStyle(fontSize: 16))
                  ],
                ),
              ),
              body: Center(
                child: Text(AppLocalizations.of(context)!.cuttingProgressReportingNoData)
              )
            );
          }
        } else {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.settings.name == previousPage);
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(machine.replaceAll('_', ' '), style: const TextStyle(fontSize: 16))
                ],
              ),
            ),
            body: Center(
              child: Text(AppLocalizations.of(context)!.cuttingProgressReportingNoData)
            )
          );
        }
      }
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
          Navigator.of(context).popUntil((route) => route.settings.name == '/cutting/dispatch');
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