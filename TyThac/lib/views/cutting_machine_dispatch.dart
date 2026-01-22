import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:horizontal_data_table/refresh/pull_to_refresh/src/indicator/material_indicator.dart';
import 'package:horizontal_data_table/refresh/pull_to_refresh/src/smart_refresher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';

String building = '', machine = '', userID = '', factory = '', lean = 'Lean01', apiAddress = '', locale = 'zh';
double screenHeight = 0, screenWidth = 0;
List<String> leanDropdownItems = [];

class CuttingMachineDispatch extends StatefulWidget {
  const CuttingMachineDispatch({super.key});

  @override
  CuttingMachineDispatchState createState() => CuttingMachineDispatchState();
}

class CuttingMachineDispatchState extends State<CuttingMachineDispatch> {
  RefreshController refreshController = RefreshController(initialRefresh: false);
  List<Widget> wOrderList = [];

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString('userID') ?? '';
      factory = prefs.getString('factory') ?? '';
      apiAddress = prefs.getString('address') ?? '';
      locale = prefs.getString('locale') ?? 'zh';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    leanDropdownItems = [];
    final body = await RemoteService().getFactoryLean(
      apiAddress,
      building,
      'MachineLean'
    );
    final jsonData = json.decode(body);
    if (!mounted) return;
    for (int i = 0; i < jsonData[0]['Lean'].length; i++) {
      leanDropdownItems.add(jsonData[0]['Lean'][i]);
    }
    lean = leanDropdownItems[0];

    manualRefresh();
  }

  void getWorkOrders() async {
    wOrderList = [];
    try {
      final body = await RemoteService().getMachineDispatchedWorkOrder(
        apiAddress,
        '${building}_$machine'
      );
      final jsonData = json.decode(body);
      loadWorkOrders(context, wOrderList, jsonData);
      setState(() {
        wOrderList = wOrderList;
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

  void loadWorkOrders(BuildContext context, List<Widget> wOrders, dynamic jsonData) {
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
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: const BorderRadius.all(Radius.circular(8))
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(partText[j], style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ),
          );
        }

        wOrders.add(
          Padding(
            padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: i < jsonData.length-1 ? 0 : 20),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/machineWorkOrder/reporting', arguments: jsonData[i]["RY"] + ';${building}_$machine;/cutting_machine/dispatch;ReadOnly');
              },
              onLongPress: () {
                GlobalKey<MessageDialogState> globalKey = GlobalKey();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return MessageDialog(
                      key: globalKey,
                      titleText: AppLocalizations.of(context)!.confirmTitle,
                      contentText: AppLocalizations.of(context)!.confirmToCancelAssignment,
                      showOKButton: true,
                      showCancelButton: true,
                      onPressed: () async {
                        globalKey.currentState?.changeContent(AppLocalizations.of(context)!.executing, const SizedBox(height: 72, child: Column(children: [CircularProgressIndicator(color: Colors.blue,),],),), false, false, () => {Navigator.of(context).pop()}, true);
                        final body = await RemoteService().cancelMachineCuttingWorkOrder(
                          apiAddress,
                          '${building}_$machine',
                          jsonData[i]["RY"].toString()
                        );
                        final jData = json.decode(body);
                        if (jData['statusCode'] == 200) {
                          manualRefresh();
                          globalKey.currentState?.changeContent(AppLocalizations.of(context)!.successTitle, Text(AppLocalizations.of(context)!.successContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/cutting_machine/dispatch')}, true);
                        }
                        else {
                          globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).pop()}, true);
                        }
                      }
                    );
                  }
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
                          Text(jsonData[i]["RY"].toString(), style: const TextStyle(fontSize: 20)),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(AppLocalizations.of(context)!.inProduction, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(255, 153, 0, 1)))
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
                          Text('${AppLocalizations.of(context)!.cuttingWorkOrderAssemblyDate}：${jsonData[i]["PlanDate"]}', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, bottom: 2, right: 15),
                      child: Row(
                        children: [
                          Text('${AppLocalizations.of(context)!.cuttingWorkOrderShipDate}：${jsonData[i]["GAC"]}', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, bottom: 2, right: 15),
                      child: Row(
                        children: [
                          Text('${AppLocalizations.of(context)!.cuttingWorkOrderSKU}：${jsonData[i]["SKU"]}', style: const TextStyle(fontSize: 14)),
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
                      padding: const EdgeInsets.only(left: 15, bottom: 2, right: 15),
                      child: Row(
                        children: [
                          Text('${AppLocalizations.of(context)!.cycle}：${jsonData[i]["Cycles"]}', style: const TextStyle(fontSize: 14)),
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
                                Text(jsonData[i]["Buy"], style: const TextStyle(fontSize: 24)),
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
          )
        );
      }
    }
    else{
      wOrders.add(
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
    screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top;
    screenWidth = MediaQuery.of(context).size.width;
    building = (ModalRoute.of(context)?.settings.arguments as String?)!.split(';')[0];
    machine = (ModalRoute.of(context)?.settings.arguments as String?)!.split(';')[1];
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.settings.name == '/cutting_machine');
              }
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(building, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(machine, style: const TextStyle(fontSize: 16))
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white
      ),
      backgroundColor: Colors.grey[300],
      body: SmartRefresher(
        header: const MaterialClassicHeader(color: Colors.blue),
        controller: refreshController,
        onRefresh: getWorkOrders,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: wOrderList,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return RYDialog(
                selectedRY: const [],
                refresh: manualRefresh
              );
            }
          );
        },
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        child: Text(String.fromCharCode(Icons.add.codePoint), style: TextStyle(inherit: false, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: Icons.add.fontFamily, color: Colors.white))
      ),
    );
  }
}

class RYDialog extends StatefulWidget {
  const RYDialog({
    super.key,
    required this.selectedRY,
    required this.refresh
  });

  final List<String> selectedRY;
  final Function refresh;

  @override
  RYDialogState createState() => RYDialogState();
}

class RYDialogState extends State<RYDialog> {
  final TextEditingController skuController = TextEditingController();
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
        title: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1)),
                                    borderRadius: BorderRadius.circular(5)
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton(
                                      value: lean,
                                      padding: const EdgeInsets.only(left: 12, right: 4),
                                      items: leanDropdownItems.map((String leanValue) {
                                        return DropdownMenuItem(
                                          value: leanValue,
                                          child: Center(
                                            child: Text(leanValue.toString(), style: const TextStyle(fontWeight: FontWeight.normal)),
                                          )
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          lean = value!;
                                        });
                                      },
                                    ),
                                  ),
                                )
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: TextField(
                                    textAlignVertical: TextAlignVertical.bottom,
                                    controller: skuController,
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
                                      hintText: AppLocalizations.of(context)!.sku,
                                      hintStyle: const TextStyle(color: Colors.grey)
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 36,
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.blue
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        color: Colors.blue,
                        onPressed: () async {
                          setState(() {
                            loading = true;
                          });
                          if (skuController.text.length >= 5 || ryController.text.length >= 8) {
                            final body = await RemoteService().getRY(
                              apiAddress,
                              building,
                              lean,
                              skuController.text,
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
                                      subtitle: Text('[${jsonData[i]['DieCut']}] - [${jsonData[i]['SKU']}]', style: TextStyle(fontSize: 12, color: selected ? Colors.red : Colors.black)),
                                      dense: true,
                                      visualDensity: const VisualDensity(vertical: -3),
                                      onTap: selected == false ? () {
                                        showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (BuildContext context) {
                                            return MultiDispatchDialog(
                                              mode: 'Add',
                                              order: jsonData[i]['Order'].toString(),
                                              ryDialogExist: true,
                                              initialCycle: const [],
                                              initialPart: const [],
                                              refreshPage: widget.refresh,
                                              setRYDialogVisibility: setVisibility
                                            );
                                          }
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
                              msg: AppLocalizations.of(context)!.inputLengthNotEnough.replaceAll('%1', '5').replaceAll('%2', '8'),
                              gravity: ToastGravity.BOTTOM,
                              toastLength: Toast.LENGTH_SHORT,
                            );
                          }
                          setState(() {
                            loading = false;
                          });
                        },
                      ),
                    )
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Divider(height: 1),
                )
              ],
            ),
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
    required this.mode,
    required this.order,
    required this.ryDialogExist,
    required this.initialCycle,
    required this.initialPart,
    required this.refreshPage,
    required this.setRYDialogVisibility
  });

  final String mode;
  final String order;
  final bool ryDialogExist;
  final List<String> initialCycle;
  final List<String> initialPart;
  final Function refreshPage;
  final Function setRYDialogVisibility;

  @override
  MultiDispatchDialogState createState() => MultiDispatchDialogState();
}

class MultiDispatchDialogState extends State<MultiDispatchDialog> {
  bool partLoadSuccess = true, cycleLoadSuccess = true, partReady = false, workOrderGenerating = false;
  dynamic futureParameter;
  List<Widget> partItems = [], cycleItems = [];
  bool nonePart = true, noneCycle = true;
  List<String> partID = [], partList = [], cycleList = [];
  List<String> selectedPart = [], selectedCycle = [];

  @override
  void initState() {
    super.initState();
    futureParameter = loadPart();
    if (widget.initialPart.isNotEmpty) {
      loadSelectedPart(widget.initialPart);
    }
    if (widget.initialCycle.isNotEmpty) {
      loadSelectedCycle(widget.initialCycle);
    }
  }

  Future<bool> loadPart() async {
    setState(() {
      partLoadSuccess = false;
    });

    partList = [];
    final partBody = await RemoteService().getOrderGroupDispatchPart(
      apiAddress,
      widget.order,
      'Material Requested'
    );
    final jsonPart = json.decode(partBody);
    for (int i = 0; i < jsonPart.length; i++) {
      partList.add('${jsonPart[i]["PartID"]};${jsonPart[i]['PartName'][0][locale.toUpperCase()]};${jsonPart[i]['MaterialID']}');
    }

    setState(() {
      partLoadSuccess = true;
    });
    return true;
  }

  Future<void> loadSelectedPart(List<String> items) async {
    setState(() {
      cycleLoadSuccess = false;
    });
    partID = [];
    partItems = [];
    for (int i = 0; i < items.length; i++) {
      partID.add(items[i].substring(items[i].indexOf('[') + 1, items[i].indexOf('] ')));
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

    cycleList = [];
    if (partID.isNotEmpty) {
      final cycleBody = await RemoteService().getOrderGroupDispatchCycle(
        apiAddress,
        widget.order,
        "'${partID.join("','")}'",
        'MachineDispatched'
      );
      final jsonCycle = json.decode(cycleBody);
      for (int i = 0; i < jsonCycle.length; i++) {
        cycleList.add(jsonCycle[i]["Cycle"] + ';' + jsonCycle[i]["DispatchMachine"]);
      }
    }

    setState(() {
      selectedPart = items;
      partItems = partItems;
      cycleLoadSuccess = true;
      partReady = partID.isNotEmpty;
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureParameter,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || partLoadSuccess == false) {
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
                        onTap: partReady && cycleLoadSuccess ? () {
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
                        } : null,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(AppLocalizations.of(context)!.cycle, style: TextStyle(fontSize: 18, color: partReady && cycleLoadSuccess ? Colors.black : Colors.grey, fontWeight: FontWeight.normal))
                              ),
                              cycleLoadSuccess == false
                              ? const Padding(
                                padding: EdgeInsets.only(right: 3),
                                child: SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2)
                                ),
                              )
                              : partReady ? const Icon(Icons.add, color: Colors.blue) : const SizedBox()
                            ],
                          ),
                        ),
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
                      onPressed: () async {
                        if (selectedCycle.isNotEmpty && selectedPart.isNotEmpty) {
                          GlobalKey<MessageDialogState> globalKey = GlobalKey();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return MessageDialog(
                                key: globalKey,
                                titleText: AppLocalizations.of(context)!.confirmTitle,
                                contentText: widget.mode == 'Add' ? AppLocalizations.of(context)!.generateWorkOrderConfirm : AppLocalizations.of(context)!.confirmToUpdate,
                                showOKButton: true,
                                showCancelButton: true,
                                onPressed: () async {
                                  if (workOrderGenerating == false) {
                                    workOrderGenerating = true;
                                    globalKey.currentState?.changeContent(AppLocalizations.of(context)!.executing, const SizedBox(height: 72, child: Column(children: [CircularProgressIndicator(color: Colors.blue,),],),), false, false, () => {Navigator.of(context).pop()}, true);

                                    final body = await RemoteService().generateMachineCuttingWorkOrder(
                                      apiAddress,
                                      '${building}_$machine',
                                      widget.order,
                                      "'${selectedPart.map((str) {return str.substring(str.indexOf('[') + 1, str.indexOf('] '));}).join("','")}'",
                                      "'${selectedCycle.join("','")}'",
                                      userID
                                    );
                                    final jsonData = json.decode(body);
                                    workOrderGenerating = false;
                                    if (jsonData['statusCode'] == 200) {
                                      widget.refreshPage();
                                      globalKey.currentState?.changeContent(AppLocalizations.of(context)!.successTitle, Text(AppLocalizations.of(context)!.successContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/cutting_machine/dispatch')}, true);
                                    }
                                    else {
                                      globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).pop()}, true);
                                    }
                                  }
                                }
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
        List<String> itemInfo = widget.itemList[i].split(';');
        bool selected = selectedItems.contains(itemInfo[0]);
        if (selected == false) {
          flag = true;
        }
        options.add(
          CheckboxListItem(
            key: key,
            index: i,
            selected: selected,
            id: itemInfo[0],
            title: Text(itemInfo[0]),
            subTitle: itemInfo[1] == '' ? '' : '[${itemInfo[1].replaceAll('_', ' ')}]',
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
                    child: Text(widget.mode == 'Part' ? AppLocalizations.of(context)!.part : AppLocalizations.of(context)!.cycle)
                  ),
                  widget.mode == 'Cycle'
                  ? TextButton(
                    child: flag ? Text(AppLocalizations.of(context)!.selectAll, textAlign: TextAlign.center) : Text(AppLocalizations.of(context)!.unselectAll, textAlign: TextAlign.center),
                    onPressed: () {
                      selectAllCycle(flag);
                      setState(() {
                        flag = !flag;
                      });
                    }
                  ) : const SizedBox()
                ],
              )
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
