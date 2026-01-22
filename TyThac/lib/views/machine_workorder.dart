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

String department = '', apiAddress = '', factory = '', machine = '';
double screenWidth = 0, screenHeight = 0;
DateTime selectedDate = DateTime.now();
String selectedMonth = DateFormat('yyyy/MM').format(DateTime.now());
TextEditingController filterRYController = TextEditingController();

class MachineWorkOrder extends StatefulWidget {
  const MachineWorkOrder({super.key});

  @override
  MachineWorkOrderState createState() => MachineWorkOrderState();
}

class MachineWorkOrderState extends State<MachineWorkOrder> {
  RefreshController refreshController = RefreshController(initialRefresh: false);
  List<Widget> orderList = [];

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    filterRYController.text = '';
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      factory = prefs.getString('building') ?? 'A16';
      machine = prefs.getString('machine') ?? 'Cutting - 01';
      apiAddress = prefs.getString('address') ?? '';
    });

    manualRefresh();
  }

  void getOrders() async {
    orderList = [];
    try {
      final body = await RemoteService().getMachineWorkOrder(
        apiAddress,
        '${factory}_$machine',
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
        orders.add(Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: i < jsonData.length-1 ? 0 : 20),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/machineWorkOrder/reporting', arguments: jsonData[i]["Order"] + ';${factory}_$machine;/machineWorkOrder;Update');
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
                        Text(jsonData[i]["Order"], style: const TextStyle(fontSize: 20)),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: jsonData[i]["Status"] == 'NoCuttingData'
                            ? Text(AppLocalizations.of(context)!.cuttingWorkOrderNoCuttingData, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(204, 51, 0, 1)))
                            : jsonData[i]["Status"] == 'NotDispatch'
                            ? Text(AppLocalizations.of(context)!.cuttingWorkOrderNotDispatch, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(204, 51, 0, 1)))
                            : jsonData[i]["Status"] == 'InProduction'
                            ? Text(AppLocalizations.of(context)!.cuttingWorkOrderInProduction, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(255, 153, 0, 1)))
                            : Text(AppLocalizations.of(context)!.cuttingWorkOrderCompleted, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(0, 153, 0, 1)))
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
                    padding: const EdgeInsets.only(top: 8, left: 15, right: 15),
                    child: Row(
                      children: [
                        Text('${AppLocalizations.of(context)!.cuttingWorkOrderAssemblyDate}${jsonData[i]["AssemblyDate"]}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: Row(
                      children: [
                        Text('${AppLocalizations.of(context)!.cuttingWorkOrderShipDate}${jsonData[i]["ShipDate"]}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15, bottom: 4),
                    child: Row(
                      children: [
                        Text('${AppLocalizations.of(context)!.cuttingWorkOrderSKU}${jsonData[i]["SKU"]}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
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
                              Text(AppLocalizations.of(context)!.cuttingWorkOrderBuyNo, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                              Text(jsonData[i]["BuyNo"], style: const TextStyle(fontSize: 24)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(AppLocalizations.of(context)!.dieCut, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                              AutoSizeText(jsonData[i]["DieCut"].toString().replaceAll('LY-', ''), style: const TextStyle(fontSize: 24), maxLines: 1),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
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
            Text(factory, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(machine, style: const TextStyle(fontSize: 16))
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
                          Text(machine, style: const TextStyle(fontSize: 16, color: Colors.white)),
                          Text(factory, style: const TextStyle(fontSize: 12, color: Colors.white)),
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