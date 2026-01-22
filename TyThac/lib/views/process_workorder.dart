import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:production/components/side_menu.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

String department = '', apiAddress = '';
double screenWidth = 0, screenHeight = 0;
DateTime selectedDate = DateTime.now();
String selectedMonth = DateFormat('yyyy/MM').format(DateTime.now());
String sType = 'Incomplete', sFactory = '', sLean = '', multiSelectedSKU = '';
List<String> factoryDropdownItems = [];
List<DropdownMenuItem<String>> lean = [];
List<List<String>> factoryLeans = [];
List<String> workOrders = [];
List<bool> selectedStatus = [];
List<double> workOrderOpacity = [];
List<String> workOrderSKU = [];
int workOrderQty = 0;
bool multiSelectMode = false;
ScrollController scrollController = ScrollController();
bool scrollFlag = false;
TextEditingController filterRYController = TextEditingController();

class ProcessWorkOrder extends StatefulWidget {
  const ProcessWorkOrder({super.key});

  @override
  ProcessWorkOrderState createState() => ProcessWorkOrderState();
}

class ProcessWorkOrderState extends State<ProcessWorkOrder> {
  RefreshController refreshController = RefreshController(initialRefresh: false);
  List<Widget> orderList = [];
  List<GlobalKey<WorkOrderState>> keyList = [];
  String userID = '', userName = '', group = '';

  @override
  void initState() {
    multiSelectMode = false;
    multiSelectedSKU = '';
    super.initState();
    loadUserInfo();
    filterRYController.text = '';
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '';
    setState(() {
      userName = prefs.getString('userName') ?? '';
      group = prefs.getString('group') ?? '';
      department = prefs.getString('department') ?? 'A02_LEAN01';
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    loadFilter();
  }

  void loadFilter() async {
    factoryDropdownItems = [];
    final body = await RemoteService().getFactoryLean(
      apiAddress,
      selectedMonth,
      'CurrentMonth'
    );
    final jsonData = json.decode(body);
    for (int i = 0; i < jsonData.length; i++) {
      factoryDropdownItems.add(jsonData[i]['Factory']);
      List<String> leans = [];
      for (int j = 0; j < jsonData[i]['Lean'].length; j++) {
        leans.add(jsonData[i]['Lean'][j]);
      }
      factoryLeans.add(leans);
    }
    sFactory = department.split('_')[0];
    lean = factoryLeans[factoryDropdownItems.indexOf(sFactory)].map((String myLean) {
      return DropdownMenuItem(
        value: myLean,
        child: Center(
          child: Text(myLean.toString()),
        )
      );
    }).toList();
    sLean = department.indexOf('_') > 0 ? department.split('_')[1] : factoryLeans[factoryDropdownItems.indexOf(sFactory)][0];
    manualRefresh();
  }

  void getOrders() async {
    orderList = [];
    try {
      final body = await RemoteService().getMonthProcessingOrder(
        apiAddress,
        '${sFactory}_$sLean',
        selectedMonth,
        sType,
        filterRYController.text
      );
      final jsonData = json.decode(body);
      if (!mounted) return;
      loadOrders(context, orderList, jsonData);
      setState(() {
        orderList = orderList;
      });
    } on Exception {
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context)!.processWorkOrderLoadingError,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
    refreshController.refreshCompleted();
  }

  void loadOrders(BuildContext context, List<Widget> orders, dynamic jsonData) {
    workOrders = [];
    selectedStatus = [];
    workOrderOpacity = [];
    workOrderSKU = [];
    keyList = [];
    workOrderQty = jsonData.length;
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        workOrders.add(jsonData[i]["Order"].toString());
        selectedStatus.add(false);
        workOrderOpacity.add(1);
        workOrderSKU.add(jsonData[i]["SKU"].toString());
        GlobalKey<WorkOrderState> key = GlobalKey();
        keyList.add(key);
        orders.add(
          WorkOrder(
            key: key,
            index: i,
            order: jsonData[i]["Order"].toString(),
            status: jsonData[i]["Status"].toString(),
            assemblyDate: jsonData[i]["AssemblyDate"].toString(),
            shipDate: jsonData[i]["ShipDate"].toString(),
            sku: jsonData[i]["SKU"].toString(),
            buy: jsonData[i]["BuyNo"].toString(),
            diecut: jsonData[i]["DieCut"].toString(),
            pairs: jsonData[i]["Pairs"].toString(),
            changeMode: setMultiSelectMode,
            setScrollOffset: setScrollOffset,
            changeOpacity: changeOpacity,
          )
        );
      }
    }
    else{
      orders.add(SizedBox(
        height: screenHeight - AppBar().preferredSize.height,
        child: Align(
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.processWorkOrderNoScheduleOrder, style: const TextStyle(fontSize: 18))
        ),
      ));
    }
  }

  void setScrollOffset(double offset) {
    scrollController.jumpTo(offset);
  }

  void setMultiSelectMode(bool enable) {
    setState(() {
      multiSelectMode = enable;
    });
  }

  void changeOpacity() {
    setState(() {
      for (int i = 0; i < keyList.length; i++) {
        keyList[i].currentState?.setState(() {
          workOrderOpacity[i] = workOrderOpacity[i];
        });
      }
    });
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
        title: Text(AppLocalizations.of(context)!.processWorkOrderTitle),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: orderList,
                ),
              ),
            ),
            Visibility(
              visible: multiSelectMode,
              child: Container(
                color: Colors.blue,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: OutlinedButton(
                        onPressed: () {
                          multiSelectedSKU = '';
                          for (int i = 0; i < keyList.length; i++) {
                            keyList[i].currentState?.setState(() {
                              selectedStatus[i] = false;
                              workOrderOpacity[i] = 1;
                            });
                          }
                          setState(() {
                            multiSelectMode = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4))
                          ),
                        ),
                        child: Center(
                          child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                        )
                      )
                    ),
                    const Expanded(child: SizedBox()),
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: OutlinedButton(
                        onPressed: () {
                          List<String> orders = [];
                          for (int i = 0; i < selectedStatus.length; i++) {
                            if (selectedStatus[i]) {
                              orders.add(workOrders[i]);
                            }
                          }
                          if (orders.isNotEmpty) {
                            Navigator.pushNamed(context, '/process/merge_chart', arguments: {'orders': orders, 'lean': '${sFactory}_$sLean'});
                          }
                          else {
                            GlobalKey<MessageDialogState> globalKey = GlobalKey();
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return MessageDialog(
                                  key: globalKey,
                                  titleText: AppLocalizations.of(context)!.processWorkOrderNotSelectTitle,
                                  contentText: AppLocalizations.of(context)!.processWorkOrderNotSelectContent,
                                  showOKButton: true,
                                  showCancelButton: false,
                                  onPressed: () {
                                    Navigator.of(context).popUntil((route) => route.settings.name == '/process');
                                  },
                                );
                              }
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4))
                          ),
                        ),
                        child: Center(
                          child: Text(AppLocalizations.of(context)!.processWorkOrderMergeDispatching, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                        )
                      )
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class WorkOrder extends StatefulWidget {
  const WorkOrder({
    super.key,
    required this.index,
    required this.order,
    required this.status,
    required this.assemblyDate,
    required this.shipDate,
    required this.sku,
    required this.buy,
    required this.diecut,
    required this.pairs,
    required this.changeMode,
    required this.setScrollOffset,
    required this.changeOpacity
  });
  final int index;
  final String order;
  final String status;
  final String assemblyDate;
  final String shipDate;
  final String sku;
  final String buy;
  final String diecut;
  final String pairs;
  final Function changeMode;
  final Function setScrollOffset;
  final Function changeOpacity;

  @override
  WorkOrderState createState() => WorkOrderState();
}

class WorkOrderState extends State<WorkOrder> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: selectedStatus[widget.index] == false
      ? EdgeInsets.only(top: 20, left: 20, right: 20, bottom: widget.index < workOrderQty-1 ? 3 : 20)
      : EdgeInsets.only(top: 17, left: 17, right: 17, bottom: widget.index < workOrderQty-1 ? 0 : 17),
      child: InkWell(
        onTap: () {
          if (multiSelectMode == false) {
            Navigator.pushNamed(context, '/process/chart', arguments: '${widget.order};${sFactory}_$sLean');
          }
          else {
            if (multiSelectedSKU == '' || multiSelectedSKU == workOrderSKU[widget.index]) {
              double offset = scrollController.offset;
              selectedStatus[widget.index] = !selectedStatus[widget.index];
              if (selectedStatus.contains(true) == false) {
                multiSelectedSKU = '';
              }
              else {
                multiSelectedSKU = workOrderSKU[widget.index];
              }
              for (int i = 0; i < workOrderOpacity.length; i++) {
                if (workOrderSKU[i] != multiSelectedSKU && multiSelectedSKU != '') {
                  workOrderOpacity[i] = 0.3;
                }
                else {
                  workOrderOpacity[i] = 1;
                }
              }
              setState(() {
                selectedStatus[widget.index] = selectedStatus[widget.index];
                multiSelectedSKU = multiSelectedSKU;
              });
              widget.changeOpacity();
              widget.setScrollOffset(offset + (scrollFlag ? 0.01 : -0.01));
            }
          }
        },
        onLongPress: () {
          if (multiSelectedSKU == '' || multiSelectedSKU == workOrderSKU[widget.index]) {
            double offset = scrollController.offset;
            widget.changeMode(true);
            multiSelectedSKU = workOrderSKU[widget.index];
            for (int i = 0; i < workOrderOpacity.length; i++) {
              if (workOrderSKU[i] != multiSelectedSKU && multiSelectedSKU != '') {
                workOrderOpacity[i] = 0.3;
              }
              else {
                workOrderOpacity[i] = 1;
              }
            }
            setState(() {
              selectedStatus[widget.index] = true;
              multiSelectedSKU = multiSelectedSKU;
            });
            widget.changeOpacity();
            widget.setScrollOffset(offset + (scrollFlag ? 0.01 : -0.01));
          }
        },
        child: AnimatedOpacity(
          opacity: workOrderOpacity[widget.index],
          duration: const Duration(milliseconds: 100),
          child: Ink(
            width: screenWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: selectedStatus[widget.index] == false ? Colors.grey.shade400 : const Color.fromRGBO(255, 153, 0, 1),
                width: selectedStatus[widget.index] == false ? 1 : 4,
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
                      Text(widget.order, style: const TextStyle(fontSize: 20)),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: widget.status == 'NoProcessData'
                          ? Text(AppLocalizations.of(context)!.processWorkOrderNoCuttingData, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(204, 51, 0, 1)))
                          : widget.status == 'NotDispatch'
                          ? Text(AppLocalizations.of(context)!.processWorkOrderNotDispatch, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(204, 51, 0, 1)))
                          : widget.status == 'InProduction'
                          ? Text(AppLocalizations.of(context)!.processWorkOrderInProduction, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(255, 153, 0, 1)))
                          : Text(AppLocalizations.of(context)!.processWorkOrderCompleted, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(0, 153, 0, 1)))
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 15, right: 15),
                            child: Row(
                              children: [
                                Text('${AppLocalizations.of(context)!.cuttingWorkOrderAssemblyDate}${widget.assemblyDate}', style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15, right: 15),
                            child: Row(
                              children: [
                                Text('${AppLocalizations.of(context)!.processWorkOrderShipDate}${widget.shipDate}', style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 4),
                            child: Row(
                              children: [
                                Text('${AppLocalizations.of(context)!.processWorkOrderSKU}${widget.sku}', style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: selectedStatus[widget.index],
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Icon(
                          Icons.check_box,
                          color: Color.fromRGBO(255, 153, 0, 1),
                          size: 50,
                        ),
                      ),
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 15, right: 15, bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.processWorkOrderBuyNo, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            Text(widget.buy, style: const TextStyle(fontSize: 24)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.dieCut, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            AutoSizeText(widget.diecut.replaceAll('LY-', ''), style: const TextStyle(fontSize: 24), maxLines: 1),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(AppLocalizations.of(context)!.pairs, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            Text(widget.pairs, style: const TextStyle(fontSize: 24)),
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
  final TextEditingController dateController = TextEditingController(text: DateFormat('yyyy/MM').format(selectedDate));

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
                value: 'Incomplete',
                child: Center(
                  child: Text(AppLocalizations.of(context)!.processWorkOrderFilterIncomplete),
                )
              ),
              DropdownMenuItem(
                value: 'All',
                child: Center(
                  child: Text(AppLocalizations.of(context)!.processWorkOrderFilterAll),
                )
              )
            ],
            onChanged: (value) {
              setState(() {
                sType = value!;
              });
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.processWorkOrderFilterDate)
          ),
          SizedBox(
            height: 40,
            child: TextField(
              readOnly: true,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.bottom,
              controller: dateController,
              onTap: () {
                showMonthPicker(
                  context: context,
                  initialDate: selectedDate,
                  monthPickerDialogSettings: MonthPickerDialogSettings(
                    headerSettings: const PickerHeaderSettings(
                      headerBackgroundColor: Colors.blue
                    ),
                    dialogSettings: const PickerDialogSettings(
                      dialogRoundedCornersRadius: 10,
                    ),
                    dateButtonsSettings: const PickerDateButtonsSettings(
                      selectedMonthBackgroundColor: Colors.blue
                    ),
                    actionBarSettings: PickerActionBarSettings(
                      confirmWidget: Text(AppLocalizations.of(context)!.ok),
                      cancelWidget: Text(AppLocalizations.of(context)!.cancel)
                    ),
                  ),
                ).then((date) async {
                  if (date != null) {
                    final body = await RemoteService().getFactoryLean(
                      apiAddress,
                      DateFormat('yyyy/MM').format(date),
                      'CurrentMonth'
                    );
                    final jsonData = json.decode(body);
                    if (jsonData.length > 0) {
                      factoryDropdownItems = [];
                      factoryLeans = [];
                      for (int i = 0; i < jsonData.length; i++) {
                        factoryDropdownItems.add(jsonData[i]['Factory']);
                        List<String> leans = [];
                        for (int j = 0; j < jsonData[i]['Lean'].length; j++) {
                          leans.add(jsonData[i]['Lean'][j]);
                        }
                        factoryLeans.add(leans);
                      }
                    }

                    setState(() {
                      selectedDate = date;
                      dateController.text = DateFormat('yyyy/MM').format(selectedDate);
                      selectedMonth = dateController.text;
                      lean = factoryLeans[factoryDropdownItems.indexOf(sFactory)].map((String myLean) {
                        return DropdownMenuItem(
                          value: myLean,
                          child: Center(
                            child: Text(myLean.toString()),
                          )
                        );
                      }).toList();
                      sLean = factoryLeans[factoryDropdownItems.indexOf(sFactory)][0];
                    });
                  }
                });
              },
              decoration: InputDecoration(
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today, size: 20),
                  alignment: Alignment.centerRight,
                  onPressed: () {
                    showMonthPicker(
                      context: context,
                      initialDate: selectedDate,
                      monthPickerDialogSettings: MonthPickerDialogSettings(
                        headerSettings: const PickerHeaderSettings(
                          headerBackgroundColor: Colors.blue
                        ),
                        dialogSettings: const PickerDialogSettings(
                          dialogRoundedCornersRadius: 10,
                        ),
                        dateButtonsSettings: const PickerDateButtonsSettings(
                          selectedMonthBackgroundColor: Colors.blue
                        ),
                        actionBarSettings: PickerActionBarSettings(
                          confirmWidget: Text(AppLocalizations.of(context)!.ok),
                          cancelWidget: Text(AppLocalizations.of(context)!.cancel)
                        ),
                      ),
                    ).then((date) async {
                      if (date != null) {
                        final body = await RemoteService().getFactoryLean(
                          apiAddress,
                          DateFormat('yyyy/MM').format(date),
                          'CurrentMonth'
                        );
                        final jsonData = json.decode(body);
                        if (jsonData.length > 0) {
                          factoryDropdownItems = [];
                          factoryLeans = [];
                          for (int i = 0; i < jsonData.length; i++) {
                            factoryDropdownItems.add(jsonData[i]['Factory']);
                            List<String> leans = [];
                            for (int j = 0; j < jsonData[i]['Lean'].length; j++) {
                              leans.add(jsonData[i]['Lean'][j]);
                            }
                            factoryLeans.add(leans);
                          }
                        }

                        setState(() {
                          selectedDate = date;
                          dateController.text = DateFormat('yyyy/MM').format(selectedDate);
                          selectedMonth = dateController.text;
                          lean = factoryLeans[factoryDropdownItems.indexOf(sFactory)].map((String myLean) {
                            return DropdownMenuItem(
                              value: myLean,
                              child: Center(
                                child: Text(myLean.toString()),
                              )
                            );
                          }).toList();
                          sLean = factoryLeans[factoryDropdownItems.indexOf(sFactory)][0];
                        });
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.processWorkOrderFilterFactory)
          ),
          DropdownButton<String>(
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Colors.grey,
            ),
            value: sFactory,
            items: factoryDropdownItems.map((String factory) {
              return DropdownMenuItem(
                value: factory,
                child: Center(
                  child: Text(factory.toString()),
                )
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                sFactory = value!;
                lean = factoryLeans[factoryDropdownItems.indexOf(sFactory)].map((String factory) {
                  return DropdownMenuItem(
                    value: factory,
                    child: Center(
                      child: Text(factory.toString()),
                    )
                  );
                }).toList();
                sLean = factoryLeans[factoryDropdownItems.indexOf(sFactory)][0];
              });
            },
          ),
          const SizedBox(height: 2),
          Align(
              alignment: Alignment.centerLeft,
              child: Text(AppLocalizations.of(context)!.processWorkOrderFilterLean)
          ),
          DropdownButton<String>(
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Colors.grey,
            ),
            value: sLean,
            items: lean,
            onChanged: (value) {
              setState(() {
                sLean = value!;
              });
            },
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${AppLocalizations.of(context)!.ry}：')
          ),
          SizedBox(
            height: 40,
            child: TextField(
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.bottom,
              controller: filterRYController,
              decoration: const InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
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
            widget.refresh();
          },
          child: Text(AppLocalizations.of(context)!.ok),
        ),
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
          Navigator.of(context).popUntil((route) => route.settings.name == '/process');
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