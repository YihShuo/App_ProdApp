import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:production/services/remote_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/components/selectable_item.dart';

String apiAddress = '';
String order = '';
String lean = '';
String section = '';
bool loadSuccess = false;

class ProcessWorkOrderDispatch extends StatefulWidget {
  const ProcessWorkOrderDispatch({super.key});

  @override
  State<StatefulWidget> createState() => ProcessWorkOrderDispatchState();
}

class ProcessWorkOrderDispatchState extends State<ProcessWorkOrderDispatch> {
  List<String> sizeList = [];
  List<Widget> tableColumnTitles = [];
  List<bool> sizeSelectAll = [], cycleSelectAll = [];
  List<List<String>> selection = [];
  List<List<GlobalKey<SelectableItemState>>> itemKeys = [];
  List<GlobalKey<TableTitleState>> columnTitleKeys = [];
  List<GlobalKey<TableTitleState>> rowTitleKeys = [];
  List<Widget> sizeRunTable = [];
  dynamic tableFirstRow;
  dynamic tableContentRows;
  dynamic myFuture;
  
  @override
  void initState() {
    super.initState();
    loadInfo();
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

    myFuture = loadTableData();
  }

  void changeSelection(String operation, int cycleIndex, String size){
    if (operation == 'Add') {
      if (selection[cycleIndex].contains(size) == false) {
        selection[cycleIndex].add(size);
      }
    }
    else if (operation == 'Remove') {
      if (selection[cycleIndex].contains(size)) {
        selection[cycleIndex].remove(size);
      }
    }
  }

  Future<bool> loadTableData() async {
    setState(() {
      loadSuccess = false;
    });

    try {
      sizeRunTable = [];
      sizeList = [];
      tableColumnTitles = [];
      columnTitleKeys = [];
      sizeSelectAll = [];
      rowTitleKeys = [];
      cycleSelectAll = [];
      selection = [];
      itemKeys = [];

      final sizeBody = await RemoteService().getOrderProcessingSize(
        apiAddress,
        order,
        section
      );
      final jsonSize = json.decode(sizeBody);
      if (!mounted) return false;
      tableColumnTitles.add(Container(
        width: 80,
        height: 50,
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        alignment: Alignment.centerLeft,
        child: Center(child: Text(AppLocalizations.of(context)!.processWorkOrderDispatchCycle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      ));
      for (int i = 0; i < jsonSize.length; i++) {
        sizeList.add(jsonSize[i]['Size'].toString());
        sizeSelectAll.add(false);
        GlobalKey<TableTitleState> titleKey = GlobalKey();
        columnTitleKeys.add(titleKey);
        tableColumnTitles.add(GestureDetector(
          onTap: () {
            sizeSelectAll[i] = !sizeSelectAll[i];
            for (int j = 0; j < itemKeys.length; j++) {
              itemKeys[j][sizeList.indexOf(jsonSize[i]['Size'].toString())].currentState?.setStatus(sizeSelectAll[i]);
            }
            columnTitleKeys[i].currentState?.changeStatus(sizeSelectAll[i]);
          },
          child: Container(
            width: 80,
            height: 50,
            padding: const EdgeInsets.all(4),
            child: TableTitle(
              key: titleKey,
              height: 40,
              width: 80,
              titleText: jsonSize[i]['Size'].toString(),
              selected: sizeSelectAll[i],
            ),
          )
        ));
      }

      final cycleBody = await RemoteService().getOrderProcessingCycle(
        apiAddress,
        order,
        section
      );
      tableFirstRow = json.decode(cycleBody);
      for (int i = 0; i < tableFirstRow.length; i++) {
        selection.add([]);
        cycleSelectAll.add(false);
        GlobalKey<TableTitleState> titleKey = GlobalKey();
        rowTitleKeys.add(titleKey);
        List<GlobalKey<SelectableItemState>> keyList = [];
        for (int j = 0; j < sizeList.length; j++) {
          GlobalKey<SelectableItemState> key = GlobalKey();
          keyList.add(key);
        }
        itemKeys.add(keyList);
      }

      final sizeRunBody = await RemoteService().getOrderProcessingSizeRun(
        apiAddress,
        order,
        section
      );
      tableContentRows = json.decode(sizeRunBody);

      sizeRunTable.add(
        Expanded(
          child: HorizontalDataTable(
            leftHandSideColumnWidth: 60,
            rightHandSideColumnWidth: sizeList.length * 80,
            isFixedHeader: true,
            headerWidgets: tableColumnTitles,
            leftSideItemBuilder: (BuildContext context, int index) {
              if (index < tableFirstRow.length) {
                String cycle = tableFirstRow[index]['Cycle'].toString();
                int cycleInt = int.parse(cycle.substring(cycle.lastIndexOf('-')+1));
                GlobalKey<TableTitleState> globalKey = GlobalKey();
                rowTitleKeys[index] = globalKey;
                return GestureDetector(
                  onTap: () {
                    cycleSelectAll[index] = !cycleSelectAll[index];
                    for (int i = 0; i < itemKeys[index].length; i++) {
                      itemKeys[index][i].currentState?.setStatus(cycleSelectAll[index]);
                    }
                    rowTitleKeys[index].currentState?.changeStatus(cycleSelectAll[index]);
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    padding: index < tableFirstRow.length - 1 ? const EdgeInsets.fromLTRB(4, 4, 4, 0) : const EdgeInsets.fromLTRB(4, 4, 4, 4),
                    child: TableTitle(
                      key: globalKey,
                      height: 40,
                      width: 40,
                      titleText: 'T$cycleInt',
                      selected: cycleSelectAll[index]
                    ),
                  ),
                );
              }
              else {
                return const SizedBox(
                  height: 4
                );
              }
            },
            rightSideItemBuilder: (BuildContext context, int index) {
              if (index < tableFirstRow.length) {
                List<Widget> cells = [];
                for (int i = 0; i < sizeList.length; i++){
                  bool isExist = false;
                  for (int j = 0; j < tableContentRows[index]['Parts'][0]['SizeQty'].length; j++) {
                    if (tableContentRows[index]['Parts'][0]['SizeQty'][j]['Size'] == sizeList[i]) {
                      GlobalKey<SelectableItemState> globalKey = GlobalKey();
                      itemKeys[index][i] = globalKey;
                      cells.add(Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                        alignment: Alignment.centerLeft,
                        child: SelectableItem(
                          key: globalKey,
                          cycleIndex: index,
                          size: sizeList[i],
                          textWidget: Text(tableContentRows[index]['Parts'][0]['SizeQty'][j]['Qty'].toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          selectable: !tableContentRows[index]['Parts'][0]['SizeQty'][j]['Dispatched'],
                          selected: false,
                          changeSelection: changeSelection,
                        ),
                      ));
                      isExist = true;
                      break;
                    }
                  }
                  if (isExist == false) {
                    cells.add(Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                      alignment: Alignment.centerLeft,
                      child: const Center(child: Text(''))
                    ));
                  }
                }
                return Row(
                  children: cells
                );
              }
              else {
                return const SizedBox(
                  height: 4,
                  child: Row(
                    children: []
                  ),
                );
              }
            },
            itemCount: tableFirstRow.length + 1,
            rowSeparatorWidget: const Divider(
              color: Colors.transparent,
              height: 1.0,
              thickness: 0.0,
            ),
            leftHandSideColBackgroundColor: const Color(0xFFFFFFFF),
            rightHandSideColBackgroundColor: const Color(0xFFFFFFFF),
          ),
        )
      );

      if (mounted) {
        sizeRunTable.add(
          Container(
            color: Colors.blue,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: OutlinedButton(
                    onPressed: () {
                      for (int i = 0; i < itemKeys.length; i++) {
                        for (int j = 0; j < itemKeys[i].length; j++) {
                          itemKeys[i][j].currentState?.setStatus(true);
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4))
                      ),
                    ),
                    child: Center(
                      child: Text(AppLocalizations.of(context)!.processWorkOrderDispatchSelectAll, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                    )
                  )
                ),
                const Expanded(child: SizedBox()),
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: OutlinedButton(
                    onPressed: () {
                      GlobalKey<MessageDialogState> globalKey = GlobalKey();
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          bool isEmpty = true;
                          for (int i = 0; i < selection.length; i++) {
                            if (selection[i].isNotEmpty) {
                              isEmpty = false;
                              break;
                            }
                          }

                          if (isEmpty) {
                            return MessageDialog(
                              key: globalKey,
                              titleText: AppLocalizations.of(context)!.processWorkOrderDispatchDialogNotSelectTitle,
                              contentText: AppLocalizations.of(context)!.processWorkOrderDispatchDialogNotSelectContent,
                              showOKButton: true,
                              showCancelButton: false,
                              onPressed: () {
                                Navigator.of(context).popUntil((route) => route.settings.name == '/process/chart/dispatch');
                              },
                            );
                          }
                          else {
                            return MessageDialog(
                              key: globalKey,
                              titleText: AppLocalizations.of(context)!.processWorkOrderDispatchDialogConfirmTitle,
                              contentText: AppLocalizations.of(context)!.processWorkOrderDispatchDialogConfirmContent,
                              showOKButton: true,
                              showCancelButton: true,
                              onPressed: () async {
                                globalKey.currentState?.changeContent(AppLocalizations.of(context)!.processWorkOrderDispatchDialogGeneratingTitle, const SizedBox(height: 72, child: Column(children: [CircularProgressIndicator(color: Colors.blue),],),), false, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/process/chart/dispatch')}, true);
                                final prefs = await SharedPreferences.getInstance();
                                String userID = prefs.getString('userID') ?? '';
                                String factory = prefs.getString('factory') ?? '';

                                final body = await RemoteService().generateProcessingWorkOrder(
                                  apiAddress,
                                  order,
                                  userID,
                                  lean,
                                  factory,
                                  section,
                                  selection
                                );
                                final jsonData = json.decode(body);
                                if (!mounted) return;
                                if (jsonData['statusCode'] == 200) {
                                  myFuture = loadTableData();
                                  globalKey.currentState?.changeContent(AppLocalizations.of(context)!.processWorkOrderDispatchDialogSuccessTitle, Text(AppLocalizations.of(context)!.processWorkOrderDispatchDialogSuccessContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/process/chart/dispatch')}, true);
                                }
                                else {
                                  globalKey.currentState?.changeContent(AppLocalizations.of(context)!.processWorkOrderDispatchDialogFailedTitle, Text(AppLocalizations.of(context)!.processWorkOrderDispatchDialogFailedContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/process/chart/dispatch')}, true);
                                }
                              },
                            );
                          }
                        },
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4))
                      ),
                    ),
                    child: Center(
                      child: Text(AppLocalizations.of(context)!.processWorkOrderDispatchDispatch, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                    )
                  )
                )
              ],
            ),
          )
        );
      }

      setState(() {
        loadSuccess = true;
      });
      return true;
    } catch (ex) {
      setState(() {
        loadSuccess = true;
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    order = (ModalRoute.of(context)?.settings.arguments as String?)!.split(';')[0];
    section = (ModalRoute.of(context)?.settings.arguments as String?)!.split(';')[1];
    String name = (ModalRoute.of(context)?.settings.arguments as String?)!.split(';')[2];
    lean = (ModalRoute.of(context)?.settings.arguments as String?)!.split(';')[3];
    return FutureBuilder(
      future: myFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || loadSuccess == false || tableFirstRow == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.settings.name == '/process/chart');
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order),
                  Text(name.replaceAll('@', ' - ').replaceAll('/n', ' '), style: const TextStyle(fontSize: 14))
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
                  Navigator.of(context).popUntil((route) => route.settings.name == '/process/chart');
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order),
                  Text(name.replaceAll('@', ' - ').replaceAll('/n', ' '), style: const TextStyle(fontSize: 14))
                ],
              ),
            ),
            body: Center(
              child: Text('Error: ${snapshot.error}')
            )
          );
        }
        else {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.settings.name == '/process/chart');
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order),
                  Text(name.replaceAll('@', ' - ').replaceAll('/n', ' '), style: const TextStyle(fontSize: 14))
                ],
              ),
            ),
            body: Column(
              children: sizeRunTable
            ),
          );
        }
      }
    );
  }
}

class TableTitle extends StatefulWidget {
  const TableTitle({
    super.key,
    required this.height,
    required this.width,
    required this.titleText,
    required this.selected
  });

  final double height;
  final double width;
  final String titleText;
  final bool selected;

  @override
  State<StatefulWidget> createState() => TableTitleState();
}

class TableTitleState extends State<TableTitle> {
  late bool state;

  @override
  void initState() {
    super.initState();
    state = widget.selected;
  }

  void changeStatus(bool result) {
    setState(() {
      state = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
          decoration: BoxDecoration(
              color: state ? Colors.red.shade50 : Colors.blue.shade50,
              border: Border.all(width: 1, color: state ? Colors.red.shade200 : Colors.blue.shade200),
              borderRadius: BorderRadius.circular(5)
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: FittedBox(
                fit: BoxFit.contain,
                child: Text(widget.titleText, style: const TextStyle(fontSize: 20))
            ),
          )
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
          Navigator.of(context).popUntil((route) => route.settings.name == '/process/chart/dispatch');
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