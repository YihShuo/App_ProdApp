import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:production/components/selectable_machine_item.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';

class SizeRunTableMachineReporting extends StatefulWidget {
  const SizeRunTableMachineReporting({
    super.key,
    required this.apiAddress,
    required this.machine,
    required this.order,
    required this.partID,
    required this.readOnly
  });

  final String apiAddress;
  final String machine;
  final String order;
  final String partID;
  final bool readOnly;

  @override
  State<StatefulWidget> createState() => SizeRunTableMachineReportingState();
}

class SizeRunTableMachineReportingState extends State<SizeRunTableMachineReporting> {
  List<String> sizeList = [];
  List<Widget> tableColumnTitles = [];
  List<bool> sizeSelectAll = [];
  List<List<GlobalKey<SelectableMachineItemState>>> itemKeys = [];
  List<GlobalKey<TableTitleState>> columnTitleKeys = [];
  List<GlobalKey<TableTitleState>> rowTitleKeys = [];
  bool loadSuccess = false;
  List<Widget> sizeRunTable = [];
  dynamic tableFirstRow;
  dynamic tableContentRows;
  dynamic futureTable;

  @override
  void initState() {
    super.initState();
    loadSuccess = true;
    reloadTable();
  }

  Future<bool> loadTableData() async {
    setState(() {
      loadSuccess = false;
    });
    sizeRunTable = [];
    sizeList = [];
    tableColumnTitles = [];
    sizeSelectAll = [];
    columnTitleKeys = [];
    rowTitleKeys = [];
    itemKeys = [];

    final sizeBody = await RemoteService().getReportingOrderSize(
      widget.apiAddress,
      widget.order,
      '',
      '',
      widget.partID,
      widget.machine
    );
    final jsonSize = json.decode(sizeBody);
    if (!mounted) return false;
    tableColumnTitles.add(
      Container(
        width: 80,
        height: 50,
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        alignment: Alignment.centerLeft,
        child: Center(
          child: Text(AppLocalizations.of(context)!.cycle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
        ),
      )
    );

    for (int i = 0; i < jsonSize.length; i++) {
      sizeList.add(jsonSize[i]['Size'].toString());
      sizeSelectAll.add(jsonSize[i]['AllDispatched']);
      GlobalKey<TableTitleState> titleKey = GlobalKey();
      columnTitleKeys.add(titleKey);
      tableColumnTitles.add(
        GestureDetector(
          onTap: widget.readOnly == false ? () async {
            GlobalKey<MessageDialogState> globalKey = GlobalKey();
            if (sizeSelectAll[i] == false) {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (BuildContext context) {
                  return MessageDialog(
                    key: globalKey,
                    titleText: AppLocalizations.of(context)!.information,
                    contentText: AppLocalizations.of(context)!.executing,
                    showOKButton: false,
                    showCancelButton: false,
                    onPressed: null,
                  );
                }
              );
              final body = await RemoteService().submitMachineCuttingProgress(
                widget.apiAddress,
                widget.order,
                widget.machine,
                widget.partID,
                '',
                jsonSize[i]['Size'].toString(),
                'Completed'
              );

              final jsonData = json.decode(body);
              if (jsonData['statusCode'] == 200) {
                sizeSelectAll[i] = !sizeSelectAll[i];
                for (int j = 0; j < itemKeys.length; j++) {
                  itemKeys[j][sizeList.indexOf(jsonSize[i]['Size'].toString())].currentState?.setStatus(sizeSelectAll[i]);
                }
                columnTitleKeys[i].currentState?.changeStatus(sizeSelectAll[i]);
                Navigator.of(context).popUntil((route) => route.settings.name == '/machineWorkOrder/reporting');
              }
              else {
                globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/machineWorkOrder/reporting')}, true);
              }
            }
            else {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (BuildContext context) {
                  return MessageDialog(
                    key: globalKey,
                    titleText: AppLocalizations.of(context)!.confirmTitle,
                    contentText: AppLocalizations.of(context)!.confirmToCancel,
                    showOKButton: true,
                    showCancelButton: true,
                    onPressed: () async {
                      globalKey.currentState?.changeContent(AppLocalizations.of(context)!.executing, const SizedBox(height: 72, child: Column(children: [CircularProgressIndicator(color: Colors.blue,),],),), false, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/machineWorkOrder/reporting')}, true);
                      final body = await RemoteService().submitMachineCuttingProgress(
                        widget.apiAddress,
                        widget.order,
                        widget.machine,
                        widget.partID,
                        '',
                        jsonSize[i]['Size'].toString(),
                        'Cancelled'
                      );
                      final jsonData = json.decode(body);
                      if (jsonData['statusCode'] == 200) {
                        sizeSelectAll[i] = !sizeSelectAll[i];
                        for (int j = 0; j < itemKeys.length; j++) {
                          itemKeys[j][sizeList.indexOf(jsonSize[i]['Size'].toString())].currentState?.setStatus(sizeSelectAll[i]);
                        }
                        columnTitleKeys[i].currentState?.changeStatus(sizeSelectAll[i]);
                        Navigator.of(context).popUntil((route) => route.settings.name == '/machineWorkOrder/reporting');
                      }
                      else {
                        globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/machineWorkOrder/reporting')}, true);
                      }
                    },
                  );
                }
              );
            }
          } : null,
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
          ),
        )
      );
    }

    final cycleBody = await RemoteService().getReportingCycle(
      widget.apiAddress,
      widget.order,
      '',
      ''
    );
    tableFirstRow = json.decode(cycleBody);
    for (int i = 0; i < tableFirstRow.length; i++) {
      GlobalKey<TableTitleState> titleKey = GlobalKey();
      rowTitleKeys.add(titleKey);
      List<GlobalKey<SelectableMachineItemState>> keyList = [];
      for (int j = 0; j < sizeList.length; j++) {
        GlobalKey<SelectableMachineItemState> key = GlobalKey();
        keyList.add(key);
      }
      itemKeys.add(keyList);
    }

    final sizeRunBody = await RemoteService().getReportingDispatchedSizeRun(
      widget.apiAddress,
      widget.order,
      widget.machine,
      widget.partID,
      '',
      ''
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
              return Container(
                width: 80,
                height: 80,
                padding: index < tableFirstRow.length - 1 ? const EdgeInsets.fromLTRB(4, 4, 4, 0) : const EdgeInsets.fromLTRB(4, 4, 4, 4),
                child: Center(
                  child: Text('T$cycleInt', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                ),
              );
            }
            else {
              return const SizedBox(height: 4);
            }
          },
          rightSideItemBuilder: (BuildContext context, int index) {
            if (index < tableFirstRow.length) {
              List<Widget> cells = [];
              for (int i = 0; i < sizeList.length; i++){
                bool isExist = false;
                for (int j = 0; j < tableContentRows[index]['Parts'][0]['SizeQty'].length; j++) {
                  if (tableContentRows[index]['Parts'][0]['SizeQty'][j]['Size'].toString() == sizeList[i]) {
                    if (int.parse(tableContentRows[index]['Parts'][0]['SizeQty'][j]['Qty'].toString()) > 0) {
                      GlobalKey<SelectableMachineItemState> globalKey = GlobalKey();
                      itemKeys[index][i] = globalKey;
                      cells.add(
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                          alignment: Alignment.centerLeft,
                          child: SelectableMachineItem(
                            key: globalKey,
                            apiAddress: widget.apiAddress,
                            order: widget.order,
                            machine: widget.machine,
                            partID: widget.partID,
                            cycle: tableContentRows[index]['Cycle'],
                            size: sizeList[i],
                            textWidget: Text(tableContentRows[index]['Parts'][0]['SizeQty'][j]['Qty'].toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            selectable: !widget.readOnly,
                            selected: tableContentRows[index]['Parts'][0]['SizeQty'][j]['Dispatched'],
                            checkSizeStatus: checkSizeStatus,
                          ),
                        )
                      );
                    }
                    else {
                      cells.add(
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: const Color.fromRGBO(240, 240, 240, 1),
                            ),
                            child: const Center(
                              child: Icon(Icons.close, size: 70, color: Color.fromRGBO(220, 220, 220, 1),)
                            )
                          )
                        )
                      );
                    }
                    isExist = true;
                    break;
                  }
                }
                if (isExist == false) {
                  cells.add(
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                      alignment: Alignment.centerLeft,
                      child: const Center(child: Text(''))
                    )
                  );
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
          //itemExtent: 82,
        ),
      ),
    );

    setState(() {
      loadSuccess = true;
    });
    return true;
  }

  void checkSizeStatus(String size) {
    bool allCompleted = true;
    int index = sizeList.indexOf(size);
    for (int i = 0; i < tableFirstRow.length; i++) {
      if (itemKeys[i][index].currentContext != null && itemKeys[i][index].currentState!.state == false) {
        allCompleted = false;
        break;
      }
    }
    sizeSelectAll[index] = allCompleted;
    columnTitleKeys[index].currentState?.changeStatus(sizeSelectAll[index]);
  }

  void reloadTable() {
    if (loadSuccess) {
      futureTable = loadTableData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureTable,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || loadSuccess == false) {
          return const Center(child: CircularProgressIndicator(color: Colors.blue,));
        }
        else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        else {
          return Column(
            children: sizeRunTable
          );
        }
      },
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
          color: state ? Colors.white : Colors.blue.shade50,
          border: Border.all(width: 1, color: state ? Colors.white : Colors.blue.shade200),
          borderRadius: BorderRadius.circular(5)
        ),
        child: Padding(
          padding: EdgeInsets.all(state ? 4 : 8),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(widget.titleText, style: TextStyle(fontSize: 20, fontWeight: state ? FontWeight.bold : FontWeight.normal))
          )
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
          Navigator.of(context).popUntil((route) => route.settings.name == '/machineWorkOrder/reporting');
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
