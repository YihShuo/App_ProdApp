import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:production/services/remote_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/components/sizerun_table_reporting.dart';

String apiAddress = '';

class CuttingProgressReporting extends StatefulWidget {
  const CuttingProgressReporting({super.key});

  @override
  State<StatefulWidget> createState() => CuttingProgressReportingState();
}

class CuttingProgressReportingState extends State<CuttingProgressReporting> with SingleTickerProviderStateMixin {
  late final TabController tabController;
  String order = '';
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
    String userID = prefs.getString('userID') ?? '';
    setState(() {
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  Future<List<List<String>>> fetchTabs() async {
    partList = [];
    final prefs = await SharedPreferences.getInstance();
    String locale = prefs.getString('locale') ?? 'zh';
    final body = await RemoteService().getOrderDispatchedPart(
      apiAddress,
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
    order = (ModalRoute.of(context)?.settings.arguments as String?)!;
    return FutureBuilder(
      future: futureTabs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.settings.name == '/cutting_progress');
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Text(order),
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
                  Navigator.of(context).popUntil((route) => route.settings.name == '/cutting_progress');
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Text(order),
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
                      Navigator.of(context).popUntil((route) => route.settings.name == '/cutting_progress');
                    },
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  title: Text(order),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.library_add,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          showDragHandle: true,
                          isScrollControlled: true,
                          context: context, builder: (BuildContext context) {
                            return ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).copyWith().size.height * 0.9),
                              child: MultiDispatchDialog(
                                order: order,
                                refreshPage: refreshPage,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                  bottom: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelPadding: EdgeInsets.zero,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white,
                    indicator: const BoxDecoration(
                      color: Colors.white, // 设置指示器的背景色
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
                    return SizeRunTableReporting(
                      apiAddress: apiAddress,
                      order: order,
                      partID: tab[0]
                    );
                  }).toList(),
                ),
              ),
            );
          }
          else {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                title: Text(order),
              ),
              body: Center(
                child: Text(AppLocalizations.of(context)!.cuttingProgressReportingNoData)
              )
            );
          }
        } else {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Text(order),
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

class MultiDispatchDialog extends StatefulWidget {
  const MultiDispatchDialog({
    super.key,
    required this.order,
    required this.refreshPage
  });
  final String order;
  final Function refreshPage;

  @override
  MultiDispatchDialogState createState() => MultiDispatchDialogState();
}

class MultiDispatchDialogState extends State<MultiDispatchDialog> {
  bool loadSuccess = true;
  dynamic futureParameter;
  List<MultiSelectItem> partItems = [];
  List<MultiSelectItem> cycleItems = [];
  String part = '', cycle = '';
  bool nonePart = true, noneCycle = true;

  @override
  initState() {
    super.initState();
    loadPartAndCycle();
  }

  Future<bool> loadPartAndCycle() async {
    setState(() {
      loadSuccess = false;
    });

    partItems = [];
    final partBody = await RemoteService().getOrderGroupDispatchPart(
      apiAddress,
      widget.order,
      'Manual'
    );
    final jsonPart = json.decode(partBody);
    final prefs = await SharedPreferences.getInstance();
    String locale = prefs.getString('locale') ?? 'zh';
    for (int i = 0; i < jsonPart.length; i++) {
      partItems.add(
        MultiSelectItem(
          jsonPart[i]["PartID"],
          '[${jsonPart[i]["PartID"]}] ${jsonPart[i]['PartName'][0][locale.toUpperCase()]}\n${jsonPart[i]['MaterialID']}'
        )
      );
    }

    cycleItems = [];
    final cycleBody = await RemoteService().getOrderGroupDispatchCycle(
      apiAddress,
      widget.order,
      '',
      ''
    );
    final jsonCycle = json.decode(cycleBody);
    for (int i = 0; i < jsonCycle.length; i++) {
      cycleItems.add(
        MultiSelectItem(
          jsonCycle[i]["Cycle"],
          jsonCycle[i]["Cycle"]
        )
      );
    }

    setState(() {
      loadSuccess = true;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureParameter,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || loadSuccess == false) {
          return const CircularProgressIndicator(
            color: Colors.blue,
          );
        }
        else if (snapshot.hasError) {
          return const CircularProgressIndicator(
            color: Colors.blue,
          );
        }
        else {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    MultiSelectDialogField(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.part),
                          const Divider(color: Color.fromRGBO(120, 120, 120, 1))
                        ],
                      ),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey), left: BorderSide(color: Colors.grey), right: BorderSide(color: Colors.grey))
                      ),
                      buttonText: Text(AppLocalizations.of(context)!.part, style: const TextStyle(fontSize: 18)),
                      buttonIcon: const Icon(Icons.add, color: Colors.blue),
                      selectedColor: Colors.blue,
                      selectedItemsTextStyle: const TextStyle(color: Colors.blue),
                      checkColor: Colors.white,
                      confirmText: Text(AppLocalizations.of(context)!.ok),
                      cancelText: Text(AppLocalizations.of(context)!.cancel),
                      chipDisplay: MultiSelectChipDisplay(
                        chipColor: const Color.fromRGBO(0, 0, 0, 0.1),
                        textStyle: const TextStyle(color: Colors.blue),
                        decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: Colors.grey), right: BorderSide(color: Colors.grey))
                        ),
                      ),
                      items: partItems,
                      onConfirm: (value) {
                        part = value.isNotEmpty ? "'${value.join("','")}'" : "";
                      },
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey))
                      ),
                    ),
                    MultiSelectDialogField(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.cycle),
                          const Divider(color: Color.fromRGBO(120, 120, 120, 1))
                        ],
                      ),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey), left: BorderSide(color: Colors.grey), right: BorderSide(color: Colors.grey))
                      ),
                      buttonText: Text(AppLocalizations.of(context)!.cycle, style: const TextStyle(fontSize: 18)),
                      buttonIcon: const Icon(Icons.add, color: Colors.blue),
                      selectedColor: Colors.blue,
                      selectedItemsTextStyle: const TextStyle(color: Colors.blue),
                      checkColor: Colors.white,
                      confirmText: Text(AppLocalizations.of(context)!.ok),
                      cancelText: Text(AppLocalizations.of(context)!.cancel),
                      chipDisplay: MultiSelectChipDisplay(
                        chipColor: const Color.fromRGBO(0, 0, 0, 0.1),
                        textStyle: const TextStyle(color: Colors.blue),
                        decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: Colors.grey), right: BorderSide(color: Colors.grey))
                        )
                      ),
                      items: cycleItems,
                      onConfirm: (value) {
                        cycle = value.isNotEmpty ? "'${value.join("','")}'" : "";
                      },
                    ),
                    Container(
                      height: 12,
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey))
                      ),
                    ),
                    Row(
                      children: [
                        const Expanded(child: SizedBox()),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8))
                            ),
                          ),
                          child: Center(
                            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                GlobalKey<MessageDialogState> globalKey = GlobalKey();
                                if (part != '' && cycle != '') {
                                  return MessageDialog(
                                    key: globalKey,
                                    titleText: AppLocalizations.of(context)!.confirmTitle,
                                    contentText: AppLocalizations.of(context)!.cuttingProgressReportingSizeRunTableDialogConfirmContent,
                                    showOKButton: true,
                                    showCancelButton: true,
                                    onPressed: () async {
                                      globalKey.currentState?.changeContent(AppLocalizations.of(context)!.executing, const SizedBox(height: 72, child: Column(children: [CircularProgressIndicator(color: Colors.blue),],),), false, false, () => {Navigator.of(context).pop()}, true);
                                      final prefs = await SharedPreferences.getInstance();
                                      String userID = prefs.getString('userID') ?? '';
                                      String department = prefs.getString('department') ?? '';
                                      String factory = prefs.getString('factory') ?? '';

                                      final body = await RemoteService().submitCuttingGroupProgress(
                                        apiAddress,
                                        widget.order,
                                        part,
                                        cycle,
                                        userID,
                                        department,
                                        factory,
                                        ''
                                      );
                                      final jsonData = json.decode(body);
                                      if (!mounted) return;
                                      if (jsonData['statusCode'] == 200) {
                                        widget.refreshPage();
                                        globalKey.currentState?.changeContent(AppLocalizations.of(context)!.successTitle, Text(AppLocalizations.of(context)!.successContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/cutting_progress/reporting')}, true);
                                      }
                                      else if (jsonData['statusCode'] == 401) {
                                        globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.noneGenerated), true, false, () => {Navigator.of(context).pop()}, true);
                                      }
                                      else {
                                        globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).pop()}, true);
                                      }
                                    },
                                  );
                                }
                                else {
                                  return MessageDialog(
                                    key: globalKey,
                                    titleText: AppLocalizations.of(context)!.information,
                                    contentText: AppLocalizations.of(context)!.reportingNoSelection,
                                    showOKButton: true,
                                    showCancelButton: false,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  );
                                }
                              }
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8))
                            ),
                          ),
                          child: Center(
                            child: Text(AppLocalizations.of(context)!.reporting, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          )
                        )
                      ],
                    )
                  ]
                ),
              )
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