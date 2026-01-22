import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

String department = '', apiAddress = '', factory = '', lean = '', section = '', sType = 'Incomplete';
double screenWidth = 0, screenHeight = 0;
DateTime selectedDate = DateTime.now();
TextEditingController filterRYController = TextEditingController();

class LeanWorkOrder extends StatefulWidget {
  const LeanWorkOrder({super.key});

  @override
  LeanWorkOrderState createState() => LeanWorkOrderState();
}

class LeanWorkOrderState extends State<LeanWorkOrder> {
  RefreshController refreshController = RefreshController(initialRefresh: false);
  List<Widget> orderList = [];

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    sType = 'Incomplete';
    filterRYController.text = '';
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      factory = prefs.getString('building') ?? 'A16';
      lean = prefs.getString('lean') ?? 'LEAN01';
      section = prefs.getString('section') ?? 'S';
      apiAddress = prefs.getString('address') ?? '';
    });

    manualRefresh();
  }

  void getOrders() async {
    orderList = [];
    try {
      final body = await RemoteService().getLeanWorkOrder(
        apiAddress,
        factory,
        lean,
        filterRYController.text,
        section,
        sType,
        DateFormat('yyyy/MM/dd').format(selectedDate)
      );
      final jsonData = json.decode(body);

      loadOrders(context, orderList, jsonData);
      setState(() {
        orderList = orderList;
      });
    } on Exception {
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context)!.cuttingWorkOrderLoadingError,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
    refreshController.refreshCompleted();
  }

  void loadOrders(BuildContext context, List<Widget> orders, dynamic jsonData) {
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        orders.add(
          Padding(
            padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: i < jsonData.length-1 ? 0 : 20),
            child: InkWell(
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
                      padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
                      child: Row(
                        children: [
                          Text(jsonData[i]["RY"], style: const TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
                      child: Divider(
                        height: 2,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
                      child: Row(
                        children: [
                          Text('${AppLocalizations.of(context)!.assignmentDate}：${jsonData[i]["PlanDate"]}')
                        ],
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 15, right: 15, bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context)!.cuttingWorkOrderBuyNo, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                Text(jsonData[i]["BUY"], style: const TextStyle(fontSize: 20)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(AppLocalizations.of(context)!.dieCut, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                AutoSizeText(jsonData[i]["SKU"].toString(), style: const TextStyle(fontSize: 20), maxLines: 1),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(AppLocalizations.of(context)!.pairs, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                Text(jsonData[i]["Pairs"].toString(), style: const TextStyle(fontSize: 20)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        /*Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context, '/leanWorkOrder/reporting',
                                arguments: {
                                  "ry": jsonData[i]["RY"],
                                  "building": factory,
                                  "lean": lean,
                                  "section": section,
                                  "type": "INPUT",
                                  "previousPage": "/leanWorkOrder",
                                  "mode": "Update"
                                },
                              );
                            },
                            child: Ink(
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border(right: BorderSide(width: 1, color: Colors.grey.shade300), top: BorderSide(width: 2, color: Colors.grey.shade300))
                              ),
                              child: Center(
                                child: Text('${AppLocalizations.of(context)!.input} [${NumberFormat('##0').format(jsonData[i]["Input"] * 100.0 / jsonData[i]["Pairs"])}%]', style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold))
                              )
                            ),
                          ),
                        ),*/
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context, '/leanWorkOrder/reporting',
                                arguments: {
                                  "ry": jsonData[i]["RY"],
                                  "building": factory,
                                  "lean": lean,
                                  "section": section,
                                  "type": "OUTPUT",
                                  "previousPage": "/leanWorkOrder",
                                  "mode": "Update"
                                },
                              );
                            },
                            child: Ink(
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(width: 1, color: Colors.grey.shade300), top: BorderSide(width: 2, color: Colors.grey.shade300))
                              ),
                              child: Center(
                                child: Text('${AppLocalizations.of(context)!.output} [${NumberFormat('##0').format(jsonData[i]["Output"] * 100.0 / jsonData[i]["Pairs"])}%]', style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold))
                              )
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        );
      }
    }
    else{
      orders.add(SizedBox(
        height: screenHeight - AppBar().preferredSize.height,
        child: Align(
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.cuttingWorkOrderNoScheduleOrder, style: const TextStyle(fontSize: 18))
        ),
      ));
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$factory $lean', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            section == 'S' ? Text(AppLocalizations.of(context)!.stitching, style: const TextStyle(fontSize: 16, color: Colors.white))
            : section == 'C' ? Text(AppLocalizations.of(context)!.cutting, style: const TextStyle(fontSize: 16, color: Colors.white))
            : const SizedBox(),
          ],
        ),
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
      drawer: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white,
        ),
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 120,
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.layerGroup,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$factory $lean', style: const TextStyle(fontSize: 16, color: Colors.white)),
                          section == 'S' ? Text(AppLocalizations.of(context)!.stitching, style: const TextStyle(fontSize: 12, color: Colors.white))
                          : section == 'C' ? Text(AppLocalizations.of(context)!.cutting, style: const TextStyle(fontSize: 12, color: Colors.white))
                          : const SizedBox(),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  size: 22,
                  color: Colors.black,
                ),
                title: Text(AppLocalizations.of(context)!.settingsLogout, style: const TextStyle(fontSize: 18)),
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
            ]
          )
        )
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
            child: Text('${AppLocalizations.of(context)!.type}：')
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
                  child: Text(AppLocalizations.of(context)!.incomplete),
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
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
          ),
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