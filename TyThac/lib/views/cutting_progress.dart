import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:production/components/side_menu.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

String department = '', apiAddress = '';
double screenWidth = 0, screenHeight = 0;
DateTime selectedDate = DateTime.now();
String selectedMonth = DateFormat('yyyy/MM').format(DateTime.now());
String sFactory = '', sLean = '';
List<String> factoryDropdownItems = [];
List<DropdownMenuItem<String>> lean = [];
List<List<String>> factoryLeans = [];
TextEditingController filterRYController = TextEditingController();

class CuttingProgress extends StatefulWidget {
  const CuttingProgress({super.key});

  @override
  CuttingProgressState createState() => CuttingProgressState();
}

class CuttingProgressState extends State<CuttingProgress> {
  RefreshController refreshController = RefreshController(initialRefresh: false);
  List<Widget> orderList = [];
  String userID = '', userName = '', group = '';

  @override
  void initState() {
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
      final body = await RemoteService().getDispatchedOrder(
        apiAddress,
        '${sFactory}_$sLean',
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
        msg: AppLocalizations.of(context)!.cuttingProgressLoadingError,
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
              Navigator.pushNamed(context, '/cutting_progress/reporting', arguments: jsonData[i]["Order"]);
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
                    color: Colors.grey.withOpacity(0.3),
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
                            child: Text(AppLocalizations.of(context)!.cuttingProgressInProduction, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(255, 153, 0, 1)))
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
                        Text('${AppLocalizations.of(context)!.cuttingProgressAssemblyDate}${jsonData[i]["AssemblyDate"]}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: Row(
                      children: [
                        Text('${AppLocalizations.of(context)!.cuttingProgressShipDate}${jsonData[i]["ShipDate"]}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15, bottom: 4),
                    child: Row(
                      children: [
                        Text('${AppLocalizations.of(context)!.cuttingProgressSKU}${jsonData[i]["SKU"]}', style: const TextStyle(fontSize: 14)),
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
                              Text(AppLocalizations.of(context)!.cuttingProgressBuyNo, style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
            child: Text(AppLocalizations.of(context)!.cuttingProgressNoDispatchedOrder, style: const TextStyle(fontSize: 18))
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
        title: Text(AppLocalizations.of(context)!.cuttingProgressTitle),
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
            child: Text(AppLocalizations.of(context)!.cuttingProgressFilterFactory)
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
            child: Text(AppLocalizations.of(context)!.cuttingProgressFilterLean)
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