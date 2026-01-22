import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:production/components/side_menu.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

String factory = '', department = '', apiAddress = '', userID = '', userName = '', group = '', locale = 'zh';
double screenWidth = 0, screenHeight = 0;
DateTime selectedDate = DateTime.now();
String sType = 'NotCompleted', sMachine = '';
List<String> machineDropdownItems = [], machineID = [];

class AutoCuttingWorkOrder extends StatefulWidget {
  const AutoCuttingWorkOrder({super.key});

  @override
  AutoCuttingWorkOrderState createState() => AutoCuttingWorkOrderState();
}

class AutoCuttingWorkOrderState extends State<AutoCuttingWorkOrder> {
  RefreshController refreshController = RefreshController(initialRefresh: false);
  List<Widget> orderList = [];

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
      department = prefs.getString('department') ?? 'A02_LEAN01';
      factory = prefs.getString('factory') ?? '';
      apiAddress = prefs.getString('address') ?? '';
      locale = prefs.getString('locale') ?? 'zh';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    loadFilter();
  }

  void loadFilter() async {
    machineID = ['EMMA', 'LECTRA', 'SemiAuto'];
    machineDropdownItems = ['EMMA', 'LECTRA', AppLocalizations.of(context)!.semiAutomaticCuttingMachine];
    sMachine = machineDropdownItems[0];
    manualRefresh();
  }

  void getOrders() async {
    orderList = [];
    try {
      final body = await RemoteService().getAutoCuttingWorkOrder(
        apiAddress,
        sMachine,
        DateFormat('yyyy/MM/dd').format(selectedDate),
        sType
      );
      final jsonData = json.decode(body);
      if (!mounted) return;
      loadWorkOrders(context, orderList, jsonData);
      setState(() {
        orderList = orderList;
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context)!.failedContent,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
    refreshController.refreshCompleted();
  }

  void loadWorkOrders(BuildContext context, List<Widget> orders, dynamic jsonData) {
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        List<Widget> ryList = [], partList = [];
        List<String> ryText = jsonData[i]['RY'].toString().split(',');
        for (int j = 0; j < ryText.length; j++) {
          ryList.add(
            Padding(
              padding: EdgeInsets.only(left: j == 0 ? 0 : 4, right: j < ryText.length - 1 ? 0 : 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: const BorderRadius.all(Radius.circular(8))
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(ryText[j]),
                ),
              ),
            ),
          );
        }

        List<String> partText = jsonData[i][locale.toUpperCase()].toString().split(',');
        for (int j = 0; j < partText.length; j++) {
          partList.add(
            Padding(
              padding: EdgeInsets.only(left: j == 0 ? 0 : 4, right: j < partText.length - 1 ? 0 : 4),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: const BorderRadius.all(Radius.circular(8))
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(partText[j]),
                ),
              ),
            ),
          );
        }

        orders.add(Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: i < jsonData.length-1 ? 0 : 20),
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                showDragHandle: true,
                isScrollControlled: true,
                context: context, builder: (BuildContext context) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).copyWith().size.height * 0.9),
                    child: AddWorkOrderDialog(
                      mode: 'Modify',
                      listNo: jsonData[i]["ListNo"].toString(),
                      refresh: manualRefresh
                    ),
                  );
                },
              );
            },
            child: Ink(
              width: screenWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(75),
                    spreadRadius: 2,
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 15, right: 15),
                    child: Row(
                      children: [
                        Text(jsonData[i]["ListNo"].toString(), style: const TextStyle(fontSize: 20)),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: jsonData[i]["Status"] == 'NotInProduction'
                            ? Text(AppLocalizations.of(context)!.notInProduction, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(204, 51, 0, 1)))
                            : jsonData[i]["Status"] == 'InProduction'
                            ? Text(AppLocalizations.of(context)!.inProduction, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(255, 153, 0, 1)))
                            : Text(AppLocalizations.of(context)!.completed, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(0, 153, 0, 1)))
                          )
                        )
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Divider(
                      height: 2,
                      color: Colors.grey,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 15, bottom: 2, right: 15),
                    child: Row(
                      children: [
                        Text('${AppLocalizations.of(context)!.machine}：${machineDropdownItems[machineID.indexOf(jsonData[i]["Machine"])]}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15, bottom: 2, right: 15),
                    child: Row(
                      children: [
                        Text('${AppLocalizations.of(context)!.date}：${jsonData[i]["PlanDate"]}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15, bottom: 2, right: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('${AppLocalizations.of(context)!.ry}：', style: const TextStyle(fontSize: 14)),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: ryList,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('${AppLocalizations.of(context)!.part}：', style: const TextStyle(fontSize: 14)),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: partList,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 15, right: 15, bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)!.dieCut, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                              AutoSizeText(jsonData[i]["DieCut"].toString().replaceAll('LY-', ''), style: const TextStyle(fontSize: 24), maxLines: 1),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(AppLocalizations.of(context)!.pairs, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                              Text(jsonData[i]["Pairs"].toString(), style: const TextStyle(fontSize: 24)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      }
    }
    else{
      orders.add(
        SizedBox(
          height: screenHeight - AppBar().preferredSize.height,
          child: Align(
            alignment: Alignment.center,
            child: Text(AppLocalizations.of(context)!.noWorkOrder, style: const TextStyle(fontSize: 18))
          ),
        )
      );
    }
  }

  void manualRefresh() {
    refreshController.requestRefresh();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top;
    return Scaffold(
      appBar: AppBar(
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
        title: Text(AppLocalizations.of(context)!.automaticCutting),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.filter_alt,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return FilterDialog(
                    refresh: manualRefresh
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: SideMenu(
        userName: userName,
        group: group,
      ),
      backgroundColor: Colors.grey[300],
      body: SmartRefresher(
        header: const MaterialClassicHeader(color: Colors.blue),
        controller: refreshController,
        onRefresh: getOrders,
        child: SingleChildScrollView(
          child: Column(
            children: orderList,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
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
                child: AddWorkOrderDialog(
                  mode: 'Add',
                  listNo: '',
                  refresh: manualRefresh
                ),
              );
            },
          );
        },
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        child: Text(
          String.fromCharCode(Icons.add.codePoint),
          style: TextStyle(
            inherit: false,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            fontFamily: Icons.add.fontFamily,
            color: Colors.white
          ),
        )
      ),
    );
  }
}

class FilterDialog extends StatefulWidget {
  final Function refresh;
  const FilterDialog({
    super.key,
    required this.refresh
  });

  @override
  FilterDialogState createState() => FilterDialogState();
}

class FilterDialogState extends State<FilterDialog> {
  final TextEditingController dateController = TextEditingController(text: DateFormat('yyyy/MM/dd').format(selectedDate));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      content: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.type)
          ),
          DropdownButton<String>(
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Colors.grey,
            ),
            value: sType,
            items: [
              DropdownMenuItem(
                value: 'NotCompleted',
                child: Center(
                  child: Text(AppLocalizations.of(context)!.notCompleted),
                )
              ),
              DropdownMenuItem(
                value: 'Completed',
                child: Center(
                  child: Text(AppLocalizations.of(context)!.completed),
                )
              )
            ],
            onChanged: (value) {
              setState(() {
                sType = value!;
              });
            },
          ),
          Visibility(
            visible: sType == 'Completed',
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${AppLocalizations.of(context)!.date}：')
            ),
          ),
          Visibility(
            visible: sType == 'Completed',
            child: SizedBox(
              height: 40,
              child: TextField(
                readOnly: true,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.bottom,
                controller: dateController,
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        DateRangePickerController sfDateController = DateRangePickerController();
                        return AlertDialog(
                          scrollable: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8))
                          ),
                          content: SizedBox(
                            width: screenWidth < screenHeight ? screenWidth * 0.7 : screenHeight * 0.7,
                            height: screenWidth < screenHeight ? screenWidth * 0.7 : screenHeight * 0.7,
                            child: SfDateRangePicker(
                              controller: sfDateController,
                              initialSelectedDate: selectedDate,
                              backgroundColor: Colors.transparent,
                              todayHighlightColor: Colors.blue,
                              selectionColor: Colors.blue,
                              headerStyle: const DateRangePickerHeaderStyle(
                                backgroundColor: Colors.transparent
                              ),
                              showActionButtons: true,
                              confirmText: AppLocalizations.of(context)!.ok,
                              cancelText: AppLocalizations.of(context)!.cancel,
                              onSubmit: (Object? value) {
                                selectedDate = sfDateController.selectedDate!;
                                dateController.text = DateFormat('yyyy/MM/dd').format(selectedDate);
                                Navigator.of(context).pop();
                              },
                              onCancel: () {
                                Navigator.of(context).pop();
                              },
                            )
                          )
                        );
                      }
                  );
                },
                decoration: InputDecoration(
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color.fromRGBO(182, 180, 184, 1)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color.fromRGBO(182, 180, 184, 1)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today, size: 20),
                    alignment: Alignment.centerRight,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          DateRangePickerController sfDateController = DateRangePickerController();
                          return AlertDialog(
                            scrollable: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8))
                            ),
                            content: SizedBox(
                              width: screenWidth < screenHeight ? screenWidth * 0.7 : screenHeight * 0.7,
                              height: screenWidth < screenHeight ? screenWidth * 0.7 : screenHeight * 0.7,
                              child: SfDateRangePicker(
                                controller: sfDateController,
                                initialSelectedDate: selectedDate,
                                backgroundColor: Colors.transparent,
                                todayHighlightColor: Colors.blue,
                                selectionColor: Colors.blue,
                                headerStyle: const DateRangePickerHeaderStyle(
                                  backgroundColor: Colors.transparent
                                ),
                                showActionButtons: true,
                                confirmText: AppLocalizations.of(context)!.ok,
                                cancelText: AppLocalizations.of(context)!.cancel,
                                onSubmit: (Object? value) {
                                  selectedDate = sfDateController.selectedDate!;
                                  dateController.text = DateFormat('yyyy/MM/dd').format(selectedDate);
                                  Navigator.of(context).pop();
                                },
                                onCancel: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            )
                          );
                        }
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${AppLocalizations.of(context)!.machine}：')
          ),
          DropdownButton<String>(
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Colors.grey,
            ),
            value: sMachine,
            items: machineDropdownItems.map((String machine) {
              return DropdownMenuItem(
                value: machineID[machineDropdownItems.indexOf(machine)],
                child: Center(
                  child: Text(machine.toString()),
                )
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                sMachine = value!;
              });
            },
          )
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
            widget.refresh();
          },
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    );
  }
}

class AddWorkOrderDialog extends StatefulWidget {
  const AddWorkOrderDialog({
    super.key,
    required this.mode,
    required this.listNo,
    required this.refresh
  });
  final String mode;
  final String listNo;
  final Function refresh;

  @override
  AddWorkOrderDialogState createState() => AddWorkOrderDialogState();
}

class AddWorkOrderDialogState extends State<AddWorkOrderDialog> {
  final TextEditingController dateController = TextEditingController(text: DateFormat('yyyy/MM/dd').format(DateTime.now()));
  DateTime mySelectedDate = DateTime.now();
  String machine = 'EMMA';
  List<Widget> ryWidgetList = [], readOnlyRYWidgetList = [];
  List<String> selectedRYList = [], selectedPartID = [], selectedCycle = [];
  bool loadSuccess2 = true, cardGenerating = false, readOnly = false;
  List<String> tempList = [];
  String mode = '';
  dynamic futureParameter;

  @override
  void initState() {
    super.initState();
    mode = widget.mode;
    if (mode == 'Add') {
      futureParameter = loadNothing();
    }
    else {
      futureParameter = loadWorkOrder();
    }
  }

  Future<bool> loadNothing() async {
    loadSuccess2 = true;
    return true;
  }

  Future<bool> loadWorkOrder() async {
    loadSuccess2 = false;
    final body = await RemoteService().getAutoCuttingWorkOrderInfo(
      apiAddress,
      widget.listNo
    );
    final jsonData = json.decode(body);

    dateController.text = jsonData[0]['PlanDate'];
    machine = jsonData[0]['Machine'];

    for (int i = 0; i < jsonData.length; i++) {
      List<dynamic> cycle = jsonData[i]['Cycle'].toString().split(',');
      List<dynamic> part = jsonData[i][locale.toUpperCase()].toString().split(',');
      if (int.parse(jsonData[i]['ScanQty'].toString()) > 0) {
        readOnly = true;
      }
      addRY(jsonData[i]['RY'], cycle, part);
    }

    setState(() {
      loadSuccess2 = true;
    });
    return true;
  }

  void addRY(String ry, List<dynamic> cycle, part) {
    List<Widget> cycleChips = [], partChips = [], readOnlyCycleChips = [], readOnlyPartChips = [];
    List<String> cycleTextList = [], partTextList = [];
    String cycleList = '', partIDList = '';

    for (int i = 0; i < cycle.length; i++) {
      cycleList += (i > 0 ? ',' : '') + cycle[i];
      cycleTextList.add(cycle[i].toString());
      cycleChips.add(
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8, right: i < cycle.length - 1 ? 0 : 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: const BorderRadius.all(Radius.circular(8))
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(cycle[i]),
            ),
          ),
        ),
      );
      readOnlyCycleChips.add(
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8, right: i < cycle.length - 1 ? 0 : 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(230, 230, 230, 1),
              border: Border.all(color: Colors.grey),
              borderRadius: const BorderRadius.all(Radius.circular(8))
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(cycle[i], style: const TextStyle(color: Color.fromRGBO(130, 130, 130, 1))),
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < part.length; i++) {
      partIDList += (i > 0 ? ',' : '') + part[i].substring(part[i].indexOf('[')+1, part[i].indexOf(']'));
      partTextList.add(part[i].toString());
      partChips.add(
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8, right: i < part.length - 1 ? 0 : 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: const BorderRadius.all(Radius.circular(8))
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(part[i]),
            ),
          ),
        ),
      );
      readOnlyPartChips.add(
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8, right: i < part.length - 1 ? 0 : 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(230, 230, 230, 1),
              border: Border.all(color: Colors.grey),
              borderRadius: const BorderRadius.all(Radius.circular(8))
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(part[i], style: const TextStyle(color: Color.fromRGBO(130, 130, 130, 1))),
            ),
          ),
        ),
      );
    }

    setState(() {
      if (selectedRYList.contains(ry) == false) {
        ryWidgetList.add(
          Slidable(
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_forever,
                  label: AppLocalizations.of(context)!.delete,
                  onPressed: (BuildContext context) {
                    GlobalKey<MessageDialogState> globalKey = GlobalKey();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return MessageDialog(
                          key: globalKey,
                          titleText: AppLocalizations.of(context)!.confirmTitle,
                          contentText: AppLocalizations.of(context)!.confirmToDelete,
                          showOKButton: true,
                          showCancelButton: true,
                          onPressed: () async {
                            removeRYChips(ry);
                            Navigator.of(context).pop();
                          },
                        );
                      }
                    );
                  },
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1)
              ),
              child: Column(
                children: [
                  TextButton(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)))
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(ry, style: const TextStyle(fontSize: 22, color: Colors.black))
                        ),
                        const Icon(Icons.add, color: Colors.blue)
                      ]
                    ),
                    onPressed: () {
                      showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext context) {
                          return MultiDispatchDialog(
                            order: ry,
                            ryDialogExist: false,
                            initialCycle: cycleTextList,
                            initialPart: partTextList,
                            refreshPage: widget.refresh,
                            setRYDialogVisibility: () {},
                            addRY: addRY,
                          );
                        },
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey), left: BorderSide(color: Colors.grey), right: BorderSide(color: Colors.grey))
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(AppLocalizations.of(context)!.part, style: const TextStyle(fontSize: 18)),
                              ),
                            ],
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: partChips,
                            ),
                          )
                        ],
                      ),
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(AppLocalizations.of(context)!.cycle, style: const TextStyle(fontSize: 18)),
                              ),
                            ],
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: cycleChips,
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  )
                ],
              ),
            ),
          )
        );

        readOnlyRYWidgetList.add(
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1)
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(ry, style: const TextStyle(fontSize: 22, color: Colors.grey))
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: Container(
                    decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey), left: BorderSide(color: Colors.grey), right: BorderSide(color: Colors.grey))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(AppLocalizations.of(context)!.part, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                            ),
                          ],
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: readOnlyPartChips,
                          ),
                        )
                      ],
                    ),
                  )
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(AppLocalizations.of(context)!.cycle, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                            ),
                          ],
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: readOnlyCycleChips,
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                )
              ],
            ),
          )
        );

        selectedRYList.add(ry);
        selectedPartID.add(partIDList);
        selectedCycle.add(cycleList);
      }
      else {
        int ryIndex = selectedRYList.indexOf(ry);
        ryWidgetList[ryIndex] = Slidable(
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete_forever,
                label: AppLocalizations.of(context)!.delete,
                onPressed: (BuildContext context) {
                  GlobalKey<MessageDialogState> globalKey = GlobalKey();
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return MessageDialog(
                          key: globalKey,
                          titleText: AppLocalizations.of(context)!.confirmTitle,
                          contentText: AppLocalizations.of(context)!.confirmToDelete,
                          showOKButton: true,
                          showCancelButton: true,
                          onPressed: () async {
                            removeRYChips(ry);
                            Navigator.of(context).pop();
                          },
                        );
                      }
                  );
                },
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1)
            ),
            child: Column(
              children: [
                TextButton(
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)))
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(ry, style: const TextStyle(fontSize: 22, color: Colors.black))
                      ),
                      const Icon(Icons.add, color: Colors.blue)
                    ]
                  ),
                  onPressed: () {
                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (BuildContext context) {
                        return MultiDispatchDialog(
                          order: ry,
                          ryDialogExist: false,
                          initialCycle: cycleTextList,
                          initialPart: partTextList,
                          refreshPage: widget.refresh,
                          setRYDialogVisibility: () {},
                          addRY: addRY,
                        );
                      },
                    );
                  },
                ),
                Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey), left: BorderSide(color: Colors.grey), right: BorderSide(color: Colors.grey))
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(AppLocalizations.of(context)!.part, style: const TextStyle(fontSize: 18)),
                              ),
                            ],
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: partChips,
                            ),
                          )
                        ],
                      ),
                    )
                ),
                Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(AppLocalizations.of(context)!.cycle, style: const TextStyle(fontSize: 18)),
                              ),
                            ],
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: cycleChips,
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                )
              ],
            ),
          )
        );

        selectedPartID[ryIndex] = partIDList;
        selectedCycle[ryIndex] = cycleList;
      }
    });
  }

  void removeRYChips(String ry) {
    int index = selectedRYList.indexOf(ry);
    if (index >= 0) {
      selectedRYList.removeAt(index);
      selectedPartID.removeAt(index);
      selectedCycle.removeAt(index);
      setState(() {
        ryWidgetList.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureParameter,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || loadSuccess2 == false) {
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
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context)!.date, style: const TextStyle(fontSize: 20))
                  ),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      readOnly: true,
                      style: mode == 'Add' ? const TextStyle(fontSize: 20) : const TextStyle(fontSize: 20, color: Colors.grey),
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.bottom,
                      controller: dateController,
                      onTap: mode == 'Add' ? () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            DateRangePickerController sfDateController = DateRangePickerController();
                            return AlertDialog(
                              scrollable: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8))
                              ),
                              content: SizedBox(
                                width: screenWidth * 0.7,
                                height: screenWidth * 0.7,
                                child: SfDateRangePicker(
                                  controller: sfDateController,
                                  initialSelectedDate: mySelectedDate,
                                  todayHighlightColor: Colors.blue,
                                  selectionColor: Colors.blue,
                                  showActionButtons: true,
                                  confirmText: AppLocalizations.of(context)!.ok,
                                  cancelText: AppLocalizations.of(context)!.cancel,
                                  onSubmit: (Object? value) {
                                    mySelectedDate = sfDateController.selectedDate!;
                                    dateController.text = DateFormat('yyyy/MM/dd').format(mySelectedDate);
                                    Navigator.of(context).pop();
                                  },
                                  onCancel: () {
                                    Navigator.of(context).pop();
                                  },
                                )
                              )
                            );
                          }
                        );
                      } : null,
                      decoration: InputDecoration(
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color.fromRGBO(182, 180, 184, 1)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color.fromRGBO(182, 180, 184, 1)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                        suffixIcon: IconButton(
                          icon: mode == 'Add' ? const Icon(Icons.calendar_today, size: 20) : const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                          alignment: Alignment.centerRight,
                          onPressed: mode == 'Add' ? () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                DateRangePickerController sfDateController = DateRangePickerController();
                                return AlertDialog(
                                  scrollable: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8))
                                  ),
                                  content: SizedBox(
                                    width: screenWidth * 0.7,
                                    height: screenWidth * 0.7,
                                    child: SfDateRangePicker(
                                      controller: sfDateController,
                                      initialSelectedDate: mySelectedDate,
                                      todayHighlightColor: Colors.blue,
                                      selectionColor: Colors.blue,
                                      showActionButtons: true,
                                      confirmText: AppLocalizations.of(context)!.ok,
                                      cancelText: AppLocalizations.of(context)!.cancel,
                                      onSubmit: (Object? value) {
                                        mySelectedDate = sfDateController.selectedDate!;
                                        dateController.text = DateFormat('yyyy/MM/dd').format(mySelectedDate);
                                        Navigator.of(context).pop();
                                      },
                                      onCancel: () {
                                        Navigator.of(context).pop();
                                      },
                                    )
                                  )
                                );
                              }
                            );
                          } : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context)!.machine, style: const TextStyle(fontSize: 20))
                  ),
                  SizedBox(
                    height: 45,
                    child: DropdownButton(
                      isExpanded: true,
                      underline: Container(
                        height: 1,
                        color: const Color.fromRGBO(182, 180, 184, 1)
                      ),
                      value: machine,
                      items: [
                        const DropdownMenuItem(
                          value: 'EMMA',
                          child: Center(
                            child: Text('EMMA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'LECTRA',
                          child: Center(
                            child: Text('LECTRA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'SemiAuto',
                          child: Center(
                            child: Text(AppLocalizations.of(context)!.semiAutomaticCuttingMachine, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        ),
                      ],
                      onChanged: mode == 'Add' ? (value) {
                        setState(() {
                          machine = value.toString();
                        });
                      } : null
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context)!.ry, style: const TextStyle(fontSize: 20))
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: mode == 'Add' ? ryWidgetList : readOnlyRYWidgetList,
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                    visible: mode == 'Add',
                    child: Center(
                      child: Ink(
                        height: 36,
                        width: 36,
                        decoration: const ShapeDecoration(
                          color: Colors.blue,
                          shape: CircleBorder(),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          color: Colors.white,
                          iconSize: 26,
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return RYDialog(
                                  selectedRY: selectedRYList,
                                  refresh: widget.refresh,
                                  addRY: addRY,
                                );
                              },
                            );
                          }
                        ),
                      ),
                    )
                  ),
                  Visibility(
                    visible: mode == 'Add',
                    child: const SizedBox(height: 20)
                  ),
                  Visibility(
                    visible: mode == 'Add',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
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
                            )
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              if (selectedRYList.isNotEmpty) {
                                GlobalKey<MessageDialogState> globalKey = GlobalKey();
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return MessageDialog(
                                      key: globalKey,
                                      titleText: AppLocalizations.of(context)!.confirmTitle,
                                      contentText: widget.listNo.isEmpty ? AppLocalizations.of(context)!.generateWorkOrderConfirm : AppLocalizations.of(context)!.confirmToUpdate,
                                      showOKButton: true,
                                      showCancelButton: true,
                                      onPressed: () async {
                                        if (cardGenerating == false) {
                                          cardGenerating == true;
                                          globalKey.currentState?.changeContent(AppLocalizations.of(context)!.executing, const SizedBox(height: 72, child: Column(children: [CircularProgressIndicator(color: Colors.blue,),],),), false, false, () => {Navigator.of(context).pop()}, true);

                                          final String body;
                                          if (widget.listNo.isEmpty) {
                                            body = await RemoteService().generateAutoCuttingWorkOrder(
                                              apiAddress,
                                              dateController.text,
                                              machine,
                                              selectedRYList.join(';'),
                                              selectedPartID.join(';'),
                                              selectedCycle.join(';'),
                                              userID,
                                              department,
                                              factory
                                            );
                                          }
                                          else {
                                            body = await RemoteService().updateAutoCuttingWorkOrder(
                                              apiAddress,
                                              widget.listNo,
                                              dateController.text,
                                              machine,
                                              selectedRYList.join(';'),
                                              selectedPartID.join(';'),
                                              selectedCycle.join(';'),
                                              userID,
                                              department,
                                              factory
                                            );
                                          }
                                          final jsonData = json.decode(body);
                                          cardGenerating = false;
                                          if (jsonData['statusCode'] == 200) {
                                            widget.refresh();
                                            globalKey.currentState?.changeContent(AppLocalizations.of(context)!.successTitle, Text(AppLocalizations.of(context)!.successContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/auto_cutting')}, true);
                                          }
                                          else if (jsonData['statusCode'] == 401) {
                                            widget.refresh();
                                            globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.modifyDenied), true, false, () => {Navigator.of(context).pop()}, true);
                                          }
                                          else {
                                            globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).pop()}, true);
                                          }
                                        }
                                      },
                                    );
                                  }
                                );
                              }
                              else {
                                Fluttertoast.showToast(
                                  msg: AppLocalizations.of(context)!.dispatchNoSelection,
                                  gravity: ToastGravity.BOTTOM,
                                  toastLength: Toast.LENGTH_SHORT,
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8))
                              ),
                            ),
                            child: Center(
                              child: Text(AppLocalizations.of(context)!.ok, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            )
                          ),
                        ],
                      ),
                    )
                  ),
                  Visibility(
                    visible: mode == 'Modify',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              GlobalKey<MessageDialogState> globalKey = GlobalKey();
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return MessageDialog(
                                    key: globalKey,
                                    titleText: AppLocalizations.of(context)!.confirmTitle,
                                    contentText: AppLocalizations.of(context)!.confirmToReport,
                                    showOKButton: true,
                                    showCancelButton: true,
                                    onPressed: () async {
                                      final body = await RemoteService().reportAutoCuttingWorkOrder(
                                        apiAddress,
                                        widget.listNo,
                                        userID
                                      );
                                      final jsonData = json.decode(body);
                                      if (jsonData['statusCode'] == 200) {
                                        widget.refresh();
                                        globalKey.currentState?.changeContent(AppLocalizations.of(context)!.successTitle, Text(AppLocalizations.of(context)!.successContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/auto_cutting')}, true);
                                      }
                                      else if (jsonData['statusCode'] == 401) {
                                        globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.dataNotExist), true, false, () => {Navigator.of(context).pop()}, true);
                                      }
                                      else if (jsonData['statusCode'] == 402) {
                                        globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.materialRequisitionWarehouseConfirmed), true, false, () => {Navigator.of(context).pop()}, true);
                                      }
                                      else {
                                        globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).pop()}, true);
                                      }
                                    }
                                  );
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
                              child: Text(AppLocalizations.of(context)!.completed, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            )
                          ),
                          const Expanded(child: SizedBox()),
                          Visibility(
                            visible: readOnly == false,
                            child: OutlinedButton(
                              onPressed: () async {
                                GlobalKey<MessageDialogState> globalKey = GlobalKey();
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return MessageDialog(
                                      key: globalKey,
                                      titleText: AppLocalizations.of(context)!.confirmTitle,
                                      contentText: AppLocalizations.of(context)!.confirmToDelete,
                                      showOKButton: true,
                                      showCancelButton: true,
                                      onPressed: () async {
                                        final body = await RemoteService().deleteAutoCuttingWorkOrder(
                                          apiAddress,
                                          widget.listNo
                                        );
                                        final jsonData = json.decode(body);
                                        if (jsonData['statusCode'] == 200) {
                                          widget.refresh();
                                          globalKey.currentState?.changeContent(AppLocalizations.of(context)!.successTitle, Text(AppLocalizations.of(context)!.successContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/auto_cutting')}, true);
                                        }
                                        else if (jsonData['statusCode'] == 401) {
                                          widget.refresh();
                                          globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.modifyDenied), true, false, () => {Navigator.of(context).pop()}, true);
                                        }
                                        else {
                                          globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).pop()}, true);
                                        }
                                      }
                                    );
                                  }
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8))
                                ),
                              ),
                              child: Center(
                                child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              )
                            ),
                          ),
                          const SizedBox(width: 8),
                          Visibility(
                            visible: readOnly == false,
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  mode = 'Add';
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8))
                                ),
                              ),
                              child: Center(
                                child: Text(AppLocalizations.of(context)!.modify, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              )
                            ),
                          )
                        ],
                      ),
                    )
                  ),
                ],
              ),
            )
          );
        }
      }
    );
  }
}

class RYDialog extends StatefulWidget {
  const RYDialog({
    super.key,
    required this.selectedRY,
    required this.refresh,
    required this.addRY
  });

  final List<String> selectedRY;
  final Function refresh;
  final Function addRY;

  @override
  RYDialogState createState() => RYDialogState();
}

class RYDialogState extends State<RYDialog> {
  final TextEditingController ryController = TextEditingController();
  List<Widget> ryList = [];
  bool loading = false, visible = true;

  @override
  void initState() {
    super.initState();
  }

  void setVisibility(bool value) {
    setState(() {
      visible = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: AlertDialog(
        scrollable: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8))
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          textAlignVertical: TextAlignVertical.bottom,
                          controller: ryController,
                          decoration: InputDecoration(
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromRGBO(182, 180, 184, 1)
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.blue
                              ),
                            ),
                            hintText: AppLocalizations.of(context)!.ry,
                            hintStyle: const TextStyle(color: Colors.grey)
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    color: Colors.blue,
                    onPressed: () async {
                      setState(() {
                        loading = true;
                      });
                      if (ryController.text.length >= 8) {
                        final body = await RemoteService().getRY(
                          apiAddress,
                          '',
                          '',
                          '',
                          ryController.text
                        );
                        final jsonData = json.decode(body);
                        ryList = [];
                        for (int i = 0; i < jsonData.length; i++) {
                          bool selected = widget.selectedRY.contains(jsonData[i]['Order'].toString());
                          ryList.add(
                            Column(
                              children: [
                                ListTile(
                                  title: Text(jsonData[i]['Order'].toString(), style: TextStyle(fontSize: 16, color: selected ? Colors.red : Colors.black)),
                                  subtitle: Text('[${jsonData[i]['DieCut']}]', style: TextStyle(fontSize: 12, color: selected ? Colors.red : Colors.black)),
                                  dense: true,
                                  visualDensity: const VisualDensity(vertical: -3),
                                  onTap: selected == false ? () {
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return MultiDispatchDialog(
                                          order: jsonData[i]['Order'].toString(),
                                          ryDialogExist: true,
                                          initialCycle: const [],
                                          initialPart: const [],
                                          refreshPage: widget.refresh,
                                          setRYDialogVisibility: setVisibility,
                                          addRY: widget.addRY,
                                        );
                                      },
                                    ).then((val) {
                                      setVisibility(true);
                                    });
                                    setState(() {
                                      visible = false;
                                    });
                                  } : () {
                                    Fluttertoast.showToast(
                                      msg: AppLocalizations.of(context)!.alreadyAdded,
                                      gravity: ToastGravity.BOTTOM,
                                      toastLength: Toast.LENGTH_SHORT,
                                    );
                                  },
                                ),
                                const Divider(height: 1)
                              ],
                            )
                          );
                        }
                        setState(() {
                          ryList = ryList;
                        });
                      }
                      else {
                        Fluttertoast.showToast(
                          msg: AppLocalizations.of(context)!.inputLengthNotEnough.replaceAll('%', '8'),
                          gravity: ToastGravity.BOTTOM,
                          toastLength: Toast.LENGTH_SHORT,
                        );
                      }
                      setState(() {
                        loading = false;
                      });
                    },
                  )
                ],
              ),
              const Divider(
                height: 1
              )
            ],
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        content: Column(
          children: ryList.isNotEmpty && loading == false
          ? ryList
          : loading
          ? [
            const ListTile(
              title: SizedBox(
                height: 42,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  )
                ),
              )
            )
          ]
          : [
            ListTile(
              title: Center(
                child: Text(AppLocalizations.of(context)!.noRYData, style: const TextStyle(fontSize: 16))
              )
            )
          ]
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.close),
          )
        ],
      ),
    );
  }
}

class MultiDispatchDialog extends StatefulWidget {
  const MultiDispatchDialog({
    super.key,
    required this.order,
    required this.ryDialogExist,
    required this.initialCycle,
    required this.initialPart,
    required this.refreshPage,
    required this.setRYDialogVisibility,
    required this.addRY,
  });
  final String order;
  final bool ryDialogExist;
  final List<String> initialCycle;
  final List<String> initialPart;
  final Function refreshPage;
  final Function setRYDialogVisibility;
  final Function addRY;

  @override
  MultiDispatchDialogState createState() => MultiDispatchDialogState();
}

class MultiDispatchDialogState extends State<MultiDispatchDialog> {
  bool loadSuccess = true;
  dynamic futureParameter;
  List<Widget> partItems = [], cycleItems = [];
  bool nonePart = true, noneCycle = true;
  List<String> partList = [], cycleList = [];
  List<String> selectedPart = [], selectedCycle = [];

  @override
  void initState() {
    super.initState();
    futureParameter = loadPartAndCycle();
    if (widget.initialPart.isNotEmpty) {
      loadSelectedPart(widget.initialPart);
    }
    if (widget.initialCycle.isNotEmpty) {
      loadSelectedCycle(widget.initialCycle);
    }
  }

  Future<bool> loadPartAndCycle() async {
    setState(() {
      loadSuccess = false;
    });

    partList = [];
    final partBody = await RemoteService().getOrderGroupDispatchPart(
      apiAddress,
      widget.order,
      'Automatic'
    );
    final jsonPart = json.decode(partBody);
    for (int i = 0; i < jsonPart.length; i++) {
      partList.add('${jsonPart[i]["PartID"]};${jsonPart[i]['PartName'][0][locale.toUpperCase()]};${jsonPart[i]['MaterialID']}');
    }

    cycleList = [];
    final cycleBody = await RemoteService().getOrderGroupDispatchCycle(
      apiAddress,
      widget.order,
      '',
      ''
    );
    final jsonCycle = json.decode(cycleBody);
    for (int i = 0; i < jsonCycle.length; i++) {
      cycleList.add(jsonCycle[i]["Cycle"]);
    }

    setState(() {
      loadSuccess = true;
    });
    return true;
  }

  void loadSelectedPart(List<String> items) {
    partItems = [];
    for (int i = 0; i < items.length; i++) {
      partItems.add(
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8, right: i < items.length - 1 ? 0 : 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: const BorderRadius.all(Radius.circular(8))
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(items[i]),
            ),
          ),
        ),
      );
    }

    setState(() {
      selectedPart = items;
      partItems = partItems;
    });
  }

  void loadSelectedCycle(List<String> items) {
    cycleItems = [];
    for (int i = 0; i < items.length; i++) {
      cycleItems.add(
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8, right: i < items.length - 1 ? 0 : 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: const BorderRadius.all(Radius.circular(8))
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(items[i]),
            ),
          ),
        ),
      );
    }

    setState(() {
      selectedCycle = items;
      cycleItems = cycleItems;
    });
  }

  Future<void> reloadAutoCuttingPart() async {
    partList = [];
    final partBody = await RemoteService().getOrderGroupDispatchPart(
      apiAddress,
      widget.order,
      'Automatic'
    );
    final jsonPart = json.decode(partBody);
    for (int i = 0; i < jsonPart.length; i++) {
      partList.add('${jsonPart[i]["PartID"]};${jsonPart[i]['PartName'][0][locale.toUpperCase()]};${jsonPart[i]['MaterialID']}');
    }

    setState(() {
      partList = partList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureParameter,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || loadSuccess == false) {
          return const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            ),
          );
        }
        else if (snapshot.hasError) {
          return const CircularProgressIndicator(
            color: Colors.blue,
          );
        }
        else {
          return AlertDialog(
            scrollable: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8))
            ),
            title: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Text(widget.order)
            ),
            content: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(AppLocalizations.of(context)!.part, style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.normal))
                              ),
                              const Icon(Icons.add, color: Colors.blue)
                            ],
                          ),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return MultiSelectItemDialog(
                                mode: 'Part',
                                ry: widget.order,
                                itemList: partList,
                                selectedList: selectedPart,
                                loadItems: loadSelectedPart,
                              );
                            },
                          );
                        },
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: partItems,
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey), left: BorderSide(color: Colors.grey), right: BorderSide(color: Colors.grey))
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(AppLocalizations.of(context)!.cycle, style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.normal))
                              ),
                              const Icon(Icons.add, color: Colors.blue)
                            ],
                          ),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return MultiSelectItemDialog(
                                mode: 'Cycle',
                                ry: widget.order,
                                itemList: cycleList,
                                selectedList: selectedCycle,
                                loadItems: loadSelectedCycle,
                              );
                            },
                          );
                        },
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: cycleItems,
                        ),
                      )
                    ],
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
                        if (selectedCycle.isNotEmpty && selectedPart.isNotEmpty) {
                          widget.addRY(widget.order, selectedCycle, selectedPart);
                          /*if (widget.initialPart.isEmpty) {
                            widget.setRYDialogVisibility(true);
                          }*/
                          if (widget.ryDialogExist) {
                            Navigator.of(context).pop();
                          }
                          Navigator.of(context).pop();
                        }
                        else {
                          Fluttertoast.showToast(
                            msg: AppLocalizations.of(context)!.dispatchNoSelection,
                            gravity: ToastGravity.BOTTOM,
                            toastLength: Toast.LENGTH_SHORT,
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))
                        ),
                      ),
                      child: Center(
                        child: Text(AppLocalizations.of(context)!.ok, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      )
                    )
                  ],
                )
              ]
            ),
          );
        }
      }
    );
  }
}

class MultiSelectItemDialog extends StatefulWidget {
  const MultiSelectItemDialog({
    super.key,
    required this.mode,
    required this.ry,
    required this.itemList,
    required this.selectedList,
    required this.loadItems
  });

  final String mode;
  final String ry;
  final List<String> itemList;
  final List<String> selectedList;
  final Function loadItems;
  
  @override
  State<StatefulWidget> createState() => MultiSelectItemDialogState();
}

class MultiSelectItemDialogState extends State<MultiSelectItemDialog> {
  List<Widget> options = [];
  List<String> selectedItems = [];
  List<GlobalKey<CheckboxListItemState>> keys = [];
  bool flag = false;

  @override
  void initState() {
    super.initState();
    loadOptions();
  }

  void loadOptions() {
    selectedItems = [];
    for (int i = 0; i < widget.selectedList.length; i++) {
      selectedItems.add(widget.selectedList[i]);
    }
    keys = [];
    flag = false;
    for (int i = 0; i < widget.itemList.length; i++) {
      if (widget.mode == 'Part') {
        List<String> itemInfo = widget.itemList[i].split(';');
        options.add(
          CheckboxListItem(
            index: i,
            selected: selectedItems.contains('[${itemInfo[0]}] ${itemInfo[1]}'),
            id: '[${itemInfo[0]}] ${itemInfo[1]}',
            title: Text('[${itemInfo[0]}] ${itemInfo[1]}'),
            subTitle: itemInfo[2],
            setSelectedItem: setSelectedItem
          )
        );
      }
      else {
        GlobalKey<CheckboxListItemState> key = GlobalKey();
        keys.add(key);
        bool selected = selectedItems.contains(widget.itemList[i]);
        if (selected == false) {
          flag = true;
        }
        options.add(
          CheckboxListItem(
            key: key,
            index: i,
            selected: selected,
            id: widget.itemList[i],
            title: Text(widget.itemList[i]),
            subTitle: '',
            setSelectedItem: setSelectedItem
          )
        );
      }
    }
  }

  void setSelectedItem(String mode, String value) {
    if (mode == 'Add' && selectedItems.contains(value) == false) {
      selectedItems.add(value);
    }
    else if (mode == 'Remove') {
      selectedItems.remove(value);
    }
  }

  Future<void> reloadAutoCuttingPart() async {
    options = [];
    keys = [];
    final partBody = await RemoteService().getOrderGroupDispatchPart(
      apiAddress,
      widget.ry,
      'Automatic'
    );
    final jsonPart = json.decode(partBody);
    for (int i = 0; i < jsonPart.length; i++) {
      GlobalKey<CheckboxListItemState> key = GlobalKey();
      keys.add(key);
      options.add(
        CheckboxListItem(
          key: key,
          index: i,
          selected: selectedItems.contains('[${jsonPart[i]["PartID"]}] ${jsonPart[i]['PartName'][0][locale.toUpperCase()]}'),
          id: '[${jsonPart[i]["PartID"]}] ${jsonPart[i]['PartName'][0][locale.toUpperCase()]}',
          title: Text('[${jsonPart[i]["PartID"]}] ${jsonPart[i]['PartName'][0][locale.toUpperCase()]}'),
          subTitle: jsonPart[i]['MaterialID'],
          setSelectedItem: setSelectedItem
        )
      );
    }

    setState(() {
      options = options;
    });
  }

  void selectAllCycle(bool value) {
    for (int i = 0; i < keys.length; i++) {
      keys[i].currentState?.checked(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      titlePadding: const EdgeInsets.only(left: 12, right: 12, top: 8),
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(AppLocalizations.of(context)!.part)
                  ),
                  widget.mode == 'Part' ? IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AutoCuttingPartSettingDialog(
                            ry: widget.ry,
                            reloadAutoCuttingPart: reloadAutoCuttingPart
                          );
                        },
                      );
                    }
                  ) : TextButton(
                    child: flag ? Text(AppLocalizations.of(context)!.selectAll, textAlign: TextAlign.center) : Text(AppLocalizations.of(context)!.unselectAll, textAlign: TextAlign.center),
                    onPressed: () {
                      selectAllCycle(flag);
                      setState(() {
                        flag = !flag;
                      });
                    }
                  )
                ],
              ),
            ),
            const Divider(height: 1)
          ],
        )
      ),
      contentPadding: const EdgeInsets.all(0),
      content: Column(
        children: options,
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
            widget.loadItems(selectedItems);
            Navigator.of(context).pop();
          },
        )
      ]
    );
  }
}

class AutoCuttingPartSettingDialog extends StatefulWidget {
  const AutoCuttingPartSettingDialog({
    super.key,
    required this.ry,
    required this.reloadAutoCuttingPart
  });

  final String ry;
  final Function reloadAutoCuttingPart;

  @override
  State<StatefulWidget> createState() => AutoCuttingPartSettingDialogState();
}

class AutoCuttingPartSettingDialogState extends State<AutoCuttingPartSettingDialog> {
  List<Widget> partItems = [];
  List<String> selectedPart = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPart();
  }

  void setSelectedItem(String mode, String value) {
    if (mode == 'Add' && selectedPart.contains(value) == false) {
      selectedPart.add(value);
    }
    else if (mode == 'Remove') {
      selectedPart.remove(value);
    }
  }

  Future<void> loadPart() async {
    partItems = [];
    final partBody = await RemoteService().getOrderGroupDispatchPart(
      apiAddress,
      widget.ry,
      'All'
    );
    final jsonPart = json.decode(partBody);
    for (int i = 0; i < jsonPart.length; i++) {
      if (jsonPart[i]['PartName'][0]['Type'] == 'AutoCutting') {
        selectedPart.add(jsonPart[i]["PartID"]);
      }
      partItems.add(
        CheckboxListItem(
          index: i,
          selected: jsonPart[i]['PartName'][0]['Type'] == 'AutoCutting',
          id: jsonPart[i]['PartID'],
          title: Text('[${jsonPart[i]["PartID"]}] ${jsonPart[i]['PartName'][0][locale.toUpperCase()]}'),
          subTitle: jsonPart[i]['MaterialID'],
          setSelectedItem: setSelectedItem,
        )
      );
    }

    setState(() {
      partItems = partItems;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      titlePadding: const EdgeInsets.only(left: 12, right: 12, top: 12),
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(AppLocalizations.of(context)!.partSettings),
            ),
            const Divider(height: 1)
          ],
        )
      ),
      contentPadding: const EdgeInsets.all(0),
      content: Column(
        children: loading == false ? partItems : [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 32,
              width: 32,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ),
              ),
            ),
          )
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
            final body = await RemoteService().setAutoCuttingPart(
              apiAddress,
              widget.ry,
              "'${selectedPart.join("','")}'",
            );
            final jsonData = json.decode(body);
            if (jsonData['statusCode'] == 200) {
              widget.reloadAutoCuttingPart();
              Navigator.of(context).pop();
            }
            else {
              Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.failedContent,
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

class CheckboxListItem extends StatefulWidget {
  const CheckboxListItem({
    super.key,
    required this.index,
    required this.selected,
    required this.id,
    required this.title,
    required this.subTitle,
    required this.setSelectedItem
  });

  final int index;
  final bool selected;
  final String id;
  final Widget title;
  final String subTitle;
  final Function setSelectedItem;

  @override
  State<StatefulWidget> createState() => CheckboxListItemState();
}

class CheckboxListItemState extends State<CheckboxListItem> {
  bool selected = false;

  @override
  void initState() {
    super.initState();
    selected = widget.selected;
  }

  void checked(bool value) {
    setState(() {
      selected = value;
    });
    widget.setSelectedItem(value ? 'Add' : 'Remove', widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.blue,
      value: selected,
      title: widget.title,
      subtitle: widget.subTitle == '' ? null : Text(widget.subTitle),
      onChanged: (bool? value) {
        widget.setSelectedItem(value! ? 'Add' : 'Remove', widget.id);
        setState(() {
          selected = value;
        });
      },
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