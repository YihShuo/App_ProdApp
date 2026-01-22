import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:production/components/side_menu.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

String department = '', apiAddress = '', ryTitle = '', userID = '', factory = '';
double screenWidth = 0, screenHeight = 0;
DateTime mySelectedDate = DateTime.now();
String selectedMonth = DateFormat('yyyy/MM').format(DateTime.now());
String sFactory = '', sLean = '';
List<String> factoryDropdownItems = [];
List<DropdownMenuItem<String>> lean = [];
List<List<String>> factoryLeans = [];
TextEditingController filterRYController = TextEditingController();
TextEditingController filterTitle = TextEditingController();
TextEditingController filterBUY = TextEditingController(text: '');
TextEditingController filterSKU = TextEditingController();
List<bool> orderVisible = [];
List<Color> orderColor = [];
List<String> orderFilterValue = [];
List<GlobalKey<OrderItemState>> keys = [];

class TyDatComponent extends StatefulWidget {
  const TyDatComponent({super.key});

  @override
  TyDatComponentState createState() => TyDatComponentState();
}

class TyDatComponentState extends State<TyDatComponent> {
  RefreshController refreshController = RefreshController(initialRefresh: false);
  List<Widget> cycleList = [];
  String userName = '', group = '';
  DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  void initState() {
    super.initState();
    sFactory = '';
    sLean = '';
    loadUserInfo();
    filterRYController.text = '';
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
    if (factoryDropdownItems.contains(sFactory) == false) {
      sFactory = factoryDropdownItems[0];
    }
    sLean = department.indexOf('_') > 0 ? department.split('_')[1] : '';

    lean = factoryLeans[factoryDropdownItems.indexOf(sFactory)].map((String factory) {
      return DropdownMenuItem(
        value: factory,
        child: Center(
          child: Text(factory.toString()),
        )
      );
    }).toList();

    if (sLean == '' || factoryLeans[factoryDropdownItems.indexOf(sFactory)].contains(sLean) == false) {
      sLean = factoryLeans[factoryDropdownItems.indexOf(sFactory)][0];
    }

    manualRefresh();
  }

  void getCycleList() async {
    cycleList = [];
    try {
      final body = await RemoteService().getDailyCycleList(
        apiAddress,
        DateFormat('yyyy/MM/dd').format(mySelectedDate),
        sFactory,
        sLean,
      );
      final jsonData = json.decode(body);
      if (!mounted) return;
      loadList(context, cycleList, jsonData);
      setState(() {
        cycleList = cycleList;
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

  void loadList(BuildContext context, List<Widget> orders, dynamic jsonData) {
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        bool listConfirmed = bool.parse(jsonData[i]["Confirmed"].toString());
        String listType = jsonData[i]["Type"].toString() == 'Others' ? AppLocalizations.of(context)!.others : AppLocalizations.of(context)!.allReady;
        orders.add(
          Padding(
            padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: i < jsonData.length-1 ? 0 : 20),
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  ),
                  showDragHandle: true,
                  isScrollControlled: true,
                  context: context, builder: (BuildContext context) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).copyWith().size.height * 0.9),
                      child: AddRYDialog(
                        mode: listConfirmed ? 'READONLY' : 'UPDATE',
                        listNo: jsonData[i]["ListNo"],
                        refresh: manualRefresh
                      )
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: listConfirmed ? Colors.green : Colors.red,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5))
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8, left: 15, right: 15, bottom: 8),
                              child: Text(jsonData[i]["RY"], style: const TextStyle(fontSize: 20, color: Colors.white)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white)
                              ),
                              child: Text(listConfirmed ? AppLocalizations.of(context)!.pmConfirmed : AppLocalizations.of(context)!.notConfirmed, style: const TextStyle(color: Colors.white),),
                            ),
                          )
                        ]
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 15, right: 15),
                      child: Text('${AppLocalizations.of(context)!.time}：${jsonData[i]["Time"].toString()}', style: const TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      child: Text('${AppLocalizations.of(context)!.type}：$listType', style: const TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      child: Text('${AppLocalizations.of(context)!.cycle}：${jsonData[i]["Cycle"].toString().replaceAll('[', '').replaceAll(']', '')}', style: const TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      child: Text('${AppLocalizations.of(context)!.pairs}：${jsonData[i]["Pairs"]}', style: const TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 8),
                      child: Text('${AppLocalizations.of(context)!.remark}：${jsonData[i]["Remark"].toString().replaceAll('\n', ' ')}', style: const TextStyle(fontSize: 16)),
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
          child: Text(AppLocalizations.of(context)!.noDataFound, style: const TextStyle(fontSize: 18))
        ),
      ));
    }
  }

  void manualRefresh() {
    setState(() {
      mySelectedDate = mySelectedDate;
    });
    refreshController.requestRefresh();
  }

  @override
  Widget build(BuildContext context) {
    ryTitle = AppLocalizations.of(context)!.ry;
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
            Text('$sFactory - $sLean ${AppLocalizations.of(context)!.componentReady}', style: const TextStyle(fontSize: 18)),
            Text(DateFormat('yyyy/MM/dd').format(mySelectedDate), style: const TextStyle(fontSize: 16))
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
      drawer: SideMenu(
        userName: userName,
        group: group,
      ),
      backgroundColor: Colors.grey[300],
      body: SmartRefresher(
        header: const MaterialClassicHeader(color: Colors.blue),
        controller: refreshController,
        onRefresh: getCycleList,
        child: SingleChildScrollView(
          child: Column(
            children: cycleList,
          ),
        ),
      ),
      floatingActionButton: Visibility(
        visible: DateTime.parse(DateFormat('yyyy-MM-dd').format(mySelectedDate)) == today || DateTime.parse(DateFormat('yyyy-MM-dd').format(mySelectedDate)).isAfter(today),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              showDragHandle: true,
              isScrollControlled: true,
              context: context, builder: (BuildContext context) {
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).copyWith().size.height * 0.9),
                  child: AddRYDialog(
                    mode: 'ADD',
                    listNo: '',
                    refresh: manualRefresh
                  )
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
  DateTime tempDate = mySelectedDate;
  String tempBuilding = sFactory, tempLean = sLean;
  final TextEditingController myDateController = TextEditingController(text: DateFormat('yyyy/MM/dd').format(mySelectedDate));

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
            child: Text('${AppLocalizations.of(context)!.date}：')
          ),
          SizedBox(
            height: 40,
            child: TextField(
              readOnly: true,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.bottom,
              controller: myDateController,
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
                          initialSelectedDate: mySelectedDate,
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
                            mySelectedDate = sfDateController.selectedDate!;
                            selectedMonth = DateFormat('yyyy/MM').format(mySelectedDate);
                            myDateController.text = DateFormat('yyyy/MM/dd').format(mySelectedDate);
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
                              initialSelectedDate: mySelectedDate,
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
                                mySelectedDate = sfDateController.selectedDate!;
                                selectedMonth = DateFormat('yyyy/MM').format(mySelectedDate);
                                myDateController.text = DateFormat('yyyy/MM/dd').format(mySelectedDate);
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
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.stitchingWorkOrderFilterFactory)
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
            child: Text(AppLocalizations.of(context)!.stitchingWorkOrderFilterLean)
          ),
          DropdownButton(
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
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            mySelectedDate = tempDate;
            sFactory = tempBuilding;
            sLean = tempLean;
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

class AddRYDialog extends StatefulWidget{
  const AddRYDialog({
    super.key,
    required this.mode,
    required this.listNo,
    required this.refresh
  });
  final String mode;
  final String listNo;
  final Function refresh;

  @override
  AddRYDialogState createState() => AddRYDialogState();
}

class AddRYDialogState extends State<AddRYDialog> {
  TextEditingController ryController = TextEditingController();
  TextEditingController pairsController = TextEditingController();
  TextEditingController remarkController = TextEditingController();
  dynamic futureParameter;
  String mode = 'ADD', type = 'Ready', timeSlot = '09:30', tipsTime = '${DateFormat('yyyy/MM/dd').format(mySelectedDate)} 08:30';
  bool loadSuccess = true, loadSuccess2 = true, ryGenerating = false;
  List<Widget> ryList = [], cycleItems = [];
  List<String> cycleList = [], selectedCycle = [];
  List<int> cyclePairsList = [];
  List<bool> cycleEnable = [];

  @override
  void initState() {
    super.initState();
    mode = widget.mode;
    loadRYList();
    if (widget.listNo.isNotEmpty) {
      loadListData();
    }
  }

  Future<void> loadRYList() async {
    setState(() {
      loadSuccess = false;
    });

    final body = await RemoteService().getLeanScheduleRY(
      apiAddress,
      DateFormat('yyyy/MM/dd').format(mySelectedDate),
      sFactory,
      sLean
    );

    final jsonBody = json.decode(body);
    ryList = [];
    ryList.add(const Divider(height: 1));
    for (int i = 0; i < jsonBody.length; i++) {
      orderFilterValue.add('${jsonBody[i]['BuyNo']} - ${jsonBody[i]['SKU']}');
      orderVisible.add(orderFilterValue[i].contains(filterTitle.text) ? true : false);
      orderColor.add(Colors.black);
      GlobalKey<OrderItemState> globalKey = GlobalKey();
      keys.add(globalKey);
      ryList.add(
        OrderItem(
          key: globalKey,
          index: i,
          date: jsonBody[i]['Date'],
          buy: jsonBody[i]['BuyNo'],
          sku: jsonBody[i]['SKU'],
          ry: jsonBody[i]['RY'],
          searchDate: DateFormat('yyyy/MM/dd').format(mySelectedDate),
          searchFactory: sFactory,
          searchLean: sLean,
          mode: 'Add',
          setRY: setRY,
        )
      );
    }

    setState(() {
      loadSuccess = true;
    });
  }

  Future<void> loadListData() async {
    setState(() {
      loadSuccess2 = false;
    });

    final body = await RemoteService().getCycleListData(
      apiAddress,
      widget.listNo
    );

    final jsonBody = json.decode(body);
    timeSlot = jsonBody[0]['Time'];
    List<String> initialCycleList = json.decode(jsonBody[0]['Cycle'].toString().replaceAll('[', '["').replaceAll(']', '"]').replaceAll(', ', '", "')).cast<String>().toList();
    setRY(jsonBody[0]['RY'], initialCycleList);
    loadSelectedCycle(initialCycleList, jsonBody[0]['Pairs']);
    remarkController.text = jsonBody[0]['Remark'];
    type = jsonBody[0]['Type'] != '' ? jsonBody[0]['Type'] : 'Ready';

    setState(() {
      loadSuccess2 = true;
    });
  }

  void loadSelectedCycle(List<String> items, int pairs) {
    cycleItems = [];
    for (int i = 0; i < items.length; i++) {
      cycleItems.add(
        Padding(
          padding: EdgeInsets.only(top: 8, left: 8, bottom: 8, right: i < items.length - 1 ? 0 : 8),
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
      pairsController.text = pairs.toString();
    });
  }

  Future<void> setRY(String ry, List<String> initialList) async {
    cycleList = [];
    cyclePairsList = [];
    cycleEnable = [];
    final cycleBody = await RemoteService().getOrderGroupDispatchCycle(
      apiAddress,
      ry,
      '',
      'C'
    );
    final jsonCycle = json.decode(cycleBody);
    for (int i = 0; i < jsonCycle.length; i++) {
      cycleList.add(jsonCycle[i]["Cycle"]);
      cyclePairsList.add(jsonCycle[i]["Pairs"]);
      if (initialList.contains(jsonCycle[i]["Cycle"])) {
        cycleEnable.add(true);
      }
      else {
        cycleEnable.add(!jsonCycle[i]["AllDispatched"]);
      }
    }

    setState(() {
      ryController.text = ry;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureParameter,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
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
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context)!.time, style: const TextStyle(fontSize: 20))
                  ),
                  SizedBox(
                    height: 45,
                    child: DropdownButton(
                      isExpanded: true,
                      underline: Container(
                        height: 1,
                        color: const Color.fromRGBO(182, 180, 184, 1)
                      ),
                      value: timeSlot,
                      items: const [
                        DropdownMenuItem(
                          value: '09:30',
                          child: Center(
                            child: Text('09:30', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        ),
                        DropdownMenuItem(
                          value: '13:30',
                          child: Center(
                            child: Text('13:30', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        ),
                        DropdownMenuItem(
                          value: '16:30',
                          child: Center(
                            child: Text('16:30', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        )
                      ],
                      onChanged: mode == 'ADD' ? (value) {
                        setState(() {
                          timeSlot = value.toString();
                          tipsTime = timeSlot == '09:30'
                          ? '${DateFormat('yyyy/MM/dd').format(mySelectedDate)} 08:30'
                          : timeSlot == '13:30'
                          ? '${DateFormat('yyyy/MM/dd').format(mySelectedDate)} 12:30'
                          : '${DateFormat('yyyy/MM/dd').format(mySelectedDate)} 15:30';
                        });
                      } : null,
                    ),
                  ),
                  Visibility(
                    visible: widget.mode == 'ADD',
                    child: Center(
                      child: Text('${AppLocalizations.of(context)!.materialRequisitionProhibitTips} : $tipsTime', style: const TextStyle(color: Colors.red, fontSize: 14)),
                    )
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context)!.ry, style: const TextStyle(fontSize: 20))
                  ),
                  InkWell(
                    onTap: () {},
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        onTap: mode == 'ADD' ? () async {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return OrderBox(
                                ryList: ryList
                              );
                            }
                          );
                        } : null,
                        readOnly: true,
                        style: TextStyle(fontSize: 20, color: mode == 'ADD' ? Colors.black : Colors.grey),
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.bottom,
                        controller: ryController,
                        decoration: InputDecoration(
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromRGBO(182, 180, 184, 1)
                            ),
                            borderRadius: BorderRadius.zero
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.blue
                            ),
                            borderRadius: BorderRadius.zero
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                          hintText: AppLocalizations.of(context)!.tapToSelect,
                          hintStyle: const TextStyle(color: Colors.grey),
                          suffix: const SizedBox(width: 20)
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context)!.type, style: const TextStyle(fontSize: 20))
                  ),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1), width: 1)
                    ),
                    child: DropdownButton(
                      isExpanded: true,
                      underline: const SizedBox(height: 0),
                      iconDisabledColor: Colors.grey,
                      iconEnabledColor: Colors.blue,
                      padding: const EdgeInsets.only(right: 12),
                      value: type,
                      items: [
                        DropdownMenuItem(
                          value: 'Ready',
                          child: Center(
                            child: Text(AppLocalizations.of(context)!.allReady, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Others',
                          child: Center(
                            child: Text(AppLocalizations.of(context)!.others, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        )
                      ],
                      onChanged: ryController.text != '' && mode == 'ADD' ? (value) {
                        setState(() {
                          type = value.toString();
                          selectedCycle = [];
                          cycleItems = [];
                          pairsController.text = '';
                        });
                      } : null
                    ),
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                    visible: type == 'Ready',
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(AppLocalizations.of(context)!.cycle, style: const TextStyle(fontSize: 20))
                    ),
                  ),
                  Visibility(
                    visible: type == 'Ready',
                    child: InkWell(
                      onTap: ryController.text != '' && mode == 'ADD' ? () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return MultiSelectItemDialog(
                              mode: 'Cycle',
                              type: type,
                              ry: ryController.text,
                              itemList: cycleList,
                              pairsList: cyclePairsList,
                              enableList: cycleEnable,
                              selectedList: selectedCycle,
                              loadItems: loadSelectedCycle,
                            );
                          },
                        );
                      } : null,
                      child: Ink(
                        width: screenWidth,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1))
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: cycleItems,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.add, color: ryController.text != '' && mode == 'ADD' ? Colors.blue : Colors.grey, size: 30),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context)!.pairs, style: const TextStyle(fontSize: 20))
                  ),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      enabled: ryController.text != '' && mode == 'ADD',
                      controller: pairsController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromRGBO(182, 180, 184, 1)
                          ),
                          borderRadius: BorderRadius.zero
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromRGBO(182, 180, 184, 1)
                          ),
                          borderRadius: BorderRadius.zero
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.blue
                          ),
                          borderRadius: BorderRadius.zero
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ], // Only numbers can be entered
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context)!.remark, style: const TextStyle(fontSize: 20))
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1))
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextField(
                          readOnly: ryController.text == '' || mode != 'ADD',
                          controller: remarkController,
                          maxLines: null,
                          maxLength: 150,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(fontSize: 18, color: mode == 'ADD' ? Colors.black : Colors.grey),
                          decoration: const InputDecoration.collapsed(hintText: '')
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: mode == 'ADD',
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
                              GlobalKey<MessageDialogState> globalKey = GlobalKey();
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  String checkResult = 'Pass';
                                  if (ryController.text.isNotEmpty) {
                                    if (type == 'Ready') {
                                      if (selectedCycle.isNotEmpty) {
                                        if (int.tryParse(pairsController.text) == null) {
                                          checkResult = 'NotIntValue';
                                        }
                                      }
                                      else {
                                        checkResult = 'NotSelect';
                                      }
                                    }
                                    else {
                                      if (int.tryParse(pairsController.text) == null) {
                                        checkResult = 'NotIntValue';
                                      }
                                    }
                                  }
                                  else {
                                    checkResult = 'NotSelect';
                                  }

                                  if (checkResult == 'Pass') {
                                    return MessageDialog(
                                      key: globalKey,
                                      titleText: AppLocalizations.of(context)!.confirmTitle,
                                      contentText: AppLocalizations.of(context)!.confirmToProceed,
                                      showOKButton: true,
                                      showCancelButton: true,
                                      onPressed: () async {
                                        if (ryGenerating == false) {
                                          ryGenerating = true;
                                          String body;
                                          if (widget.listNo.isEmpty) {
                                            body = await RemoteService().generateOrderCycleDispatchData(
                                              apiAddress,
                                              ryController.text,
                                              'C',
                                              userID,
                                              '${sFactory}_$sLean',
                                              factory,
                                              "'${selectedCycle.join("','")}'",
                                              type,
                                              DateFormat('yyyy/MM/dd $timeSlot').format(mySelectedDate),
                                              int.parse(pairsController.text),
                                              remarkController.text
                                            );
                                          }
                                          else {
                                            body = await RemoteService().updateCycleDispatchList(
                                              apiAddress,
                                              widget.listNo,
                                              ryController.text,
                                              'C',
                                              userID,
                                              '${sFactory}_$sLean',
                                              factory,
                                              "'${selectedCycle.join("','")}'",
                                              type,
                                              DateFormat('yyyy/MM/dd $timeSlot').format(mySelectedDate),
                                              int.parse(pairsController.text),
                                              remarkController.text
                                            );
                                          }
                                          final jsonData = json.decode(body);
                                          ryGenerating = false;
                                          if (!mounted) return;
                                          if (jsonData['statusCode'] == 200) {
                                            widget.refresh();
                                            globalKey.currentState?.changeContent(AppLocalizations.of(context)!.successTitle, Text(AppLocalizations.of(context)!.successContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/ty_dat_component')}, true);
                                          }
                                          else if (jsonData['statusCode'] == 401) {
                                            globalKey.currentState?.changeContent(AppLocalizations.of(context)!.information, Text(AppLocalizations.of(context)!.prohibited), true, false, () => {Navigator.of(context).pop()}, true);
                                          }
                                          else {
                                            globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).pop()}, true);
                                          }
                                        }
                                      }
                                    );
                                  }
                                  else if (checkResult == 'NotSelect') {
                                    return MessageDialog(
                                      titleText: AppLocalizations.of(context)!.failedTitle,
                                      contentText: AppLocalizations.of(context)!.noCycle,
                                      showOKButton: true,
                                      showCancelButton: false,
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  }
                                  else {
                                    return MessageDialog(
                                      titleText: AppLocalizations.of(context)!.failedTitle,
                                      contentText: AppLocalizations.of(context)!.noPairs,
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
                              child: Text(AppLocalizations.of(context)!.ok, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            )
                          ),
                        ],
                      ),
                    )
                  ),
                  Visibility(
                    visible: mode == 'UPDATE',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Expanded(child: SizedBox()),
                          OutlinedButton(
                            onPressed: () {
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
                                      final body = await RemoteService().deleteCycleDispatchList(
                                        apiAddress,
                                        widget.listNo,
                                        'C'
                                      );
                                      final jsonData = json.decode(body);
                                      if (!mounted) return;
                                      if (jsonData['statusCode'] == 200) {
                                        widget.refresh();
                                        globalKey.currentState?.changeContent(AppLocalizations.of(context)!.successTitle, Text(AppLocalizations.of(context)!.successContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/ty_dat_component')}, true);
                                      }
                                      else if (jsonData['statusCode'] == 402) {
                                        globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.sqConfirmed), true, false, () => {Navigator.of(context).pop()}, true);
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
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              setState(() {
                                mode = 'ADD';
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
                        ]
                      ),
                    )
                  )
                ],
              )
            )
          );
        }
      },
    );
  }
}

class OrderBox extends StatefulWidget {
  const OrderBox({
    super.key,
    required this.ryList
  });
  final List<Widget> ryList;

  @override
  OrderBoxState createState() => OrderBoxState();
}

class OrderBoxState extends State<OrderBox> {
  Widget title = filterTitle.text.isNotEmpty ? Text(filterTitle.text, style: const TextStyle(fontWeight: FontWeight.bold)) : Text(ryTitle, style: const TextStyle(fontWeight: FontWeight.bold));

  void updateTitle() {
    setState(() {
      title = filterTitle.text.isNotEmpty ? Text(filterTitle.text, style: const TextStyle(fontWeight: FontWeight.bold)) : Text(ryTitle, style: const TextStyle(fontWeight: FontWeight.bold));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      titlePadding: const EdgeInsets.all(4),
      contentPadding: const EdgeInsets.all(4),
      actionsPadding: const EdgeInsets.all(4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      title: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, left: 10),
              child: title,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return FilterBox(
                      updateTitle: updateTitle
                    );
                  }
                );
              },
              child: Text(AppLocalizations.of(context)!.filter),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          children: widget.ryList
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        )
      ],
    );
  }
}

class OrderItem extends StatefulWidget {
  const OrderItem({
    super.key,
    required this.index,
    required this.date,
    required this.buy,
    required this.sku,
    required this.ry,
    required this.searchDate,
    required this.searchFactory,
    required this.searchLean,
    required this.mode,
    required this.setRY
  });
  final int index;
  final String date;
  final String buy;
  final String sku;
  final String ry;
  final String searchDate;
  final String searchFactory;
  final String searchLean;
  final String mode;
  final Function setRY;

  @override
  OrderItemState createState() => OrderItemState();
}

class OrderItemState extends State<OrderItem> {
  void setVisible(bool value) {
    setState(() {
      orderVisible[widget.index] = value;
    });
  }

  @override
  void initState() {
    super.initState();
    loadFontColor();
  }

  void loadFontColor() {
    setState(() {
      orderColor[widget.index] = orderColor[widget.index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: orderVisible[widget.index],
      child: Column(
        children: [
          ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.date, style: TextStyle(color: orderColor[widget.index])),
                Text(widget.buy, style: TextStyle(color: orderColor[widget.index])),
              ],
            ),
            title: Row(
              children: [
                Text('[${widget.sku}]', style: TextStyle(color: orderColor[widget.index])),
                const SizedBox(width: 8),
                Text(widget.ry, style: TextStyle(fontSize: 16, color: orderColor[widget.index]))
              ],
            ),
            onTap: () async {
              List<String> blank = [];
              widget.setRY(widget.ry, blank);
              Navigator.of(context).pop();
            },
          ),
          const Divider(height: 1)
        ],
      ),
    );
  }
}

class FilterBox extends StatefulWidget {
  const FilterBox({
    super.key,
    required this.updateTitle
  });
  final Function updateTitle;

  @override
  FilterBoxState createState() => FilterBoxState();
}

class FilterBoxState extends State<FilterBox> {
  String buy = filterBUY.text;
  String sku = filterSKU.text;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      titlePadding: const EdgeInsets.all(4),
      contentPadding: const EdgeInsets.all(4),
      actionsPadding: const EdgeInsets.all(4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BUY', style: TextStyle(fontSize: 18)),
            SizedBox(
              height: 45,
              child: DropdownButton(
                isExpanded: true,
                underline: Container(
                  height: 1,
                  color: const Color.fromRGBO(182, 180, 184, 1)
                ),
                value: buy,
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Center(
                      child: Text(AppLocalizations.of(context)!.chooseNone, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '1 BUY',
                    child: Center(
                      child: Text('1 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '2 BUY',
                    child: Center(
                      child: Text('2 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '3 BUY',
                    child: Center(
                      child: Text('3 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '4 BUY',
                    child: Center(
                      child: Text('4 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '5 BUY',
                    child: Center(
                      child: Text('5 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '6 BUY',
                    child: Center(
                      child: Text('6 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '7 BUY',
                    child: Center(
                      child: Text('7 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '8 BUY',
                    child: Center(
                      child: Text('8 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '9 BUY',
                    child: Center(
                      child: Text('9 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '10 BUY',
                    child: Center(
                      child: Text('10 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '11 BUY',
                    child: Center(
                      child: Text('11 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '12 BUY',
                    child: Center(
                      child: Text('12 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  )
                ],
                onChanged: (value) {
                  setState(() {
                    buy = value.toString();
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            const Text('SKU', style: TextStyle(fontSize: 18)),
            SizedBox(
              height: 40,
              child: TextField(
                controller: filterSKU,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.bottom,
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromRGBO(182, 180, 184, 1)
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blue
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  suffix: SizedBox(width: 20)
                ),
              ),
            ),
          ]
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            buy = filterBUY.text;
            filterSKU.text = sku;
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () {
            filterBUY.text = buy;
            if (filterBUY.text.isNotEmpty && filterSKU.text.isEmpty) {
              filterTitle.text = filterBUY.text;
            }
            else if (filterBUY.text.isEmpty && filterSKU.text.isNotEmpty) {
              filterTitle.text = filterSKU.text;
            }
            else if (filterBUY.text.isNotEmpty && filterSKU.text.isNotEmpty) {
              filterTitle.text = '${filterBUY.text} - ${filterSKU.text}';
            }
            else {
              filterTitle.text = '';
            }
            widget.updateTitle();
            for (int i = 0; i < orderFilterValue.length; i++){
              keys[i].currentState?.setVisible(orderFilterValue[i].contains(filterTitle.text) ? true : false);
            }
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.ok),
        )
      ],
    );
  }
}

class MultiSelectItemDialog extends StatefulWidget {
  const MultiSelectItemDialog({
    super.key,
    required this.mode,
    required this.type,
    required this.ry,
    required this.itemList,
    required this.pairsList,
    required this.enableList,
    required this.selectedList,
    required this.loadItems
  });

  final String mode;
  final String type;
  final String ry;
  final List<String> itemList;
  final List<int> pairsList;
  final List<bool> enableList;
  final List<String> selectedList;
  final Function loadItems;

  @override
  State<StatefulWidget> createState() => MultiSelectItemDialogState();
}

class MultiSelectItemDialogState extends State<MultiSelectItemDialog> {
  List<Widget> options = [];
  List<String> selectedItems = [];
  List<GlobalKey<CheckboxListItemState>> keys = [];
  int pairs = 0;
  bool flag = false;

  @override
  void initState() {
    super.initState();
    loadOptions();
  }

  void loadOptions() {
    selectedItems = [];
    pairs = 0;
    for (int i = 0; i < widget.selectedList.length; i++) {
      selectedItems.add(widget.selectedList[i]);
      pairs += widget.pairsList[widget.itemList.indexOf(widget.selectedList[i])];
    }
    keys = [];
    flag = false;
    for (int i = 0; i < widget.itemList.length; i++) {
      GlobalKey<CheckboxListItemState> key = GlobalKey();
      keys.add(key);
      bool selected = selectedItems.contains(widget.itemList[i]);
      if (selected == false) {
        flag = true;
      }
      options.add(
        CheckboxListItem(
          key: key,
          type: widget.type,
          index: i,
          enabled: widget.enableList[i],
          selected: widget.enableList[i] ? selected : false,
          id: widget.itemList[i],
          title: Text(widget.itemList[i]),
          subTitle: '',
          setSelectedItem: setSelectedItem
        )
      );
    }
  }

  void setSelectedItem(String mode, String value) {
    if (mode == 'Add' && selectedItems.contains(value) == false) {
      selectedItems.add(value);
      pairs += widget.pairsList[widget.itemList.indexOf(value)];
    }
    else if (mode == 'Remove') {
      selectedItems.remove(value);
      pairs -= widget.pairsList[widget.itemList.indexOf(value)];
    }
  }

  void selectAllCycle(bool value) {
    for (int i = 0; i < keys.length; i++) {
      if (keys[i].currentState?.widget.enabled == true) {
        keys[i].currentState?.checked(value);
      }
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
                  TextButton(
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
            widget.loadItems(selectedItems, pairs);
            Navigator.of(context).pop();
          },
        )
      ]
    );
  }
}


class CheckboxListItem extends StatefulWidget {
  const CheckboxListItem({
    super.key,
    required this.type,
    required this.index,
    required this.enabled,
    required this.selected,
    required this.id,
    required this.title,
    required this.subTitle,
    required this.setSelectedItem
  });

  final String type;
  final int index;
  final bool enabled;
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
      enabled: widget.enabled || widget.type == 'Others',
      controlAffinity: widget.enabled || widget.type == 'Others' ? ListTileControlAffinity.leading : ListTileControlAffinity.trailing,
      activeColor: Colors.blue,
      side: widget.enabled || widget.type == 'Others' ? const BorderSide(width: 2) : const BorderSide(color: Colors.transparent),
      value: selected,
      title: widget.enabled || widget.type == 'Others' ? widget.title : Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, right: 24),
            child: Icon(Icons.check_box),
          ),
          widget.title
        ],
      ),
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