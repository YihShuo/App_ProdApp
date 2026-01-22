import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:production/components/side_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';

String apiAddress = '';
double screenWidth = 0, screenHeight = 0;
String sFactory = '', sLean = '', department = '';
List<String> factoryDropdownItems = [];
List<DropdownMenuItem<String>> lean = [];
List<List<String>> factoryLeans = [];

List<Color> buyBGColor = [
  const Color.fromARGB(205, 208, 240, 0),
  const Color.fromARGB(94, 137, 202, 0),
  const Color.fromARGB(2, 125, 89, 0),
  const Color.fromARGB(186, 204, 71, 0),
  const Color.fromARGB(110, 88, 47, 0),
  const Color.fromARGB(147, 142, 126, 0),
  const Color.fromARGB(232, 144, 158, 0),
  const Color.fromARGB(196, 87, 98, 0),
  const Color.fromARGB(211, 58, 2, 0),
  const Color.fromARGB(254, 158, 136, 0),
  const Color.fromARGB(231, 192, 57, 0),
  const Color.fromARGB(10, 54, 77, 0)
];

List<Color> buyTextColor = [
  Colors.black,
  Colors.black,
  Colors.black,
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.black
];

class HomePageWIP extends StatefulWidget {
  const HomePageWIP({super.key});

  @override
  HomePageWIPState createState() => HomePageWIPState();
}

class HomePageWIPState extends State<HomePageWIP> {
  String userName = '';
  String group = '';
  List<Widget> cuttingOrderList = [], processingOrderList = [], stitchingOrderList = [], assemblyOrderList = [];
  int cuttingWorkOrderCount = 0, processingWorkOrderCount = 0, stitchingWorkOrderCount = 0, assemblyWorkOrderCount = 0;
  bool cuttingLoadSuccess = false, processingLoadSuccess = false, stitchingLoadSuccess = false, assemblyLoadSuccess = false;
  bool cuttingExpanded = true, processingExpanded = true, stitchingExpanded = true, assemblyExpanded = true;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    String userID = '';

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString('userID') ?? '';
      userName = prefs.getString('userName') ?? '';
      group = prefs.getString('group') ?? '';
      department = prefs.getString('department') ?? 'A02_LEAN01';
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    await loadFilter();
    loadProcessingWorkOrders();
    loadCuttingWorkOrders();
    loadStitchingWorkOrders();
    loadAssemblyWorkOrders();
  }

  Future<void> loadFilter() async {
    factoryDropdownItems = [];
    factoryLeans = [];
    lean = [];
    sLean = '';
    final body = await RemoteService().getFactoryLean(
      apiAddress,
      '',
      'MasterLean'
    );
    final jsonData = json.decode(body);
    if (!mounted) return;
    for (int i = 0; i < jsonData.length; i++) {
      factoryDropdownItems.add(jsonData[i]['Factory']);
      List<String> leans = [];
      leans.add(AppLocalizations.of(context)!.homePageLeanFilterAll);
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
    sLean = department.indexOf('_') > 0 ? department.split('_')[1] : lean[0].value.toString();
    if (sFactory != '') {
      department = (sLean != lean[0].value.toString() ? '${sFactory}_$sLean' : sFactory);
    }
  }

  Future<void> loadCuttingWorkOrders() async {
    setState(() {
      cuttingLoadSuccess = false;
    });

    try {
      cuttingOrderList = [];
      final body = await RemoteService().getCuttingDispatchedOrderProgress(
        apiAddress,
        department,
      );
      final jsonData = json.decode(body);
      cuttingWorkOrderCount = jsonData.length;
      if (!mounted) return;
      loadCuttingOrders(context, cuttingOrderList, jsonData);
      setState(() {
        cuttingOrderList = cuttingOrderList;
        cuttingLoadSuccess = true;
      });
    } on Exception {
      setState(() {
        cuttingOrderList = [];
        cuttingLoadSuccess = true;
      });
    }
  }

  void loadCuttingOrders(BuildContext context, List<Widget> orders, dynamic jsonData) {
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        int colorIndex = int.parse(jsonData[i]["BuyNo"].split(' ')[0]);
        orders.add(
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 16 : 4, left: 8, right: 8, bottom: i < jsonData.length-1 ? 0 : 4),
            child: InkWell(
              onTap: () {
                //Navigator.pushNamed(context, '/home/cutting_tracking', arguments: jsonData[i]["Order"]);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: buyBGColor[colorIndex-1],
                            border: Border.all(color: buyTextColor[colorIndex-1]),
                            borderRadius: const BorderRadius.all(Radius.circular(8))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('${jsonData[i]["BuyNo"]} - ${jsonData[i]["Date"]}', style: TextStyle(fontSize: 12, color: buyTextColor[colorIndex-1])),
                          )
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: buyBGColor[colorIndex-1],
                            border: Border.all(color: buyTextColor[colorIndex-1]),
                            borderRadius: const BorderRadius.all(Radius.circular(8))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('${NumberFormat('###,###,##0').format(jsonData[i]["Pairs"])} Pairs', style: TextStyle(fontSize: 12, color: buyTextColor[colorIndex-1])),
                          )
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('[${jsonData[i]["SKU"]}]', style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(jsonData[i]["Order"], style: const TextStyle(fontSize: 18))
                        ),
                        SizedBox(
                          width: 60,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: Icon(Icons.check_circle_outline, size: 14, color: Colors.green)
                              ),
                              const Expanded(
                                child: SizedBox()
                              ),
                              Text('${jsonData[i]["Progress"].toString().replaceAll('.0', '')}%', style: const TextStyle(fontSize: 14, color: Colors.green)),
                            ],
                          )
                        )
                      ],
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
      orders.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.cuttingProgressNoDispatchedOrder, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ));
    }
  }

  void loadProcessingWorkOrders() async {
    setState(() {
      processingLoadSuccess = false;
    });

    try {
      processingOrderList = [];
      final body = await RemoteService().getProcessingDispatchedOrderProgress(
        apiAddress,
        department,
      );
      final jsonData = json.decode(body);
      processingWorkOrderCount = jsonData.length;
      if (!mounted) return;
      loadProcessingOrders(context, processingOrderList, jsonData);
      setState(() {
        processingOrderList = processingOrderList;
        processingLoadSuccess = true;
      });
    } on Exception {
      setState(() {
        processingOrderList = [];
        processingLoadSuccess = true;
      });
    }
  }

  void loadProcessingOrders(BuildContext context, List<Widget> orders, dynamic jsonData) {
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        int colorIndex = int.parse(jsonData[i]["BuyNo"].split(' ')[0]);
        orders.add(
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 16 : 4, left: 8, right: 8, bottom: i < jsonData.length-1 ? 0 : 4),
            child: InkWell(
              onTap: () {
                //Navigator.pushNamed(context, '/home/process_tracking', arguments: jsonData[i]["Order"]);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: buyBGColor[colorIndex-1],
                            border: Border.all(color: buyTextColor[colorIndex-1]),
                            borderRadius: const BorderRadius.all(Radius.circular(8))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('${jsonData[i]["BuyNo"]} - ${jsonData[i]["Date"]}', style: TextStyle(fontSize: 12, color: buyTextColor[colorIndex-1])),
                          )
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: buyBGColor[colorIndex-1],
                            border: Border.all(color: buyTextColor[colorIndex-1]),
                            borderRadius: const BorderRadius.all(Radius.circular(8))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('${NumberFormat('###,###,##0').format(jsonData[i]["Pairs"])} Pairs', style: TextStyle(fontSize: 12, color: buyTextColor[colorIndex-1])),
                          )
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text('[${jsonData[i]["SKU"]}]  ${jsonData[i]["Order"]}', style: const TextStyle(fontSize: 18))
                        ),
                        SizedBox(
                          width: 60,
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: Icon(Icons.check_circle_outline, size: 14, color: Colors.green)
                              ),
                              const Expanded(
                                child: SizedBox()
                              ),
                              Text('${jsonData[i]["Progress"].toString().replaceAll('.0', '')}%', style: const TextStyle(fontSize: 14, color: Colors.green)),
                            ],
                          )
                        )
                      ],
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
      orders.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.cuttingProgressNoDispatchedOrder, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ));
    }
  }

  Future<void> loadStitchingWorkOrders() async {
    setState(() {
      stitchingLoadSuccess = false;
    });

    try {
      stitchingOrderList = [];
      final body = await RemoteService().getStitchingDispatchedOrderProgress(
        apiAddress,
        department
      );
      final jsonData = json.decode(body);
      stitchingWorkOrderCount = jsonData.length;
      if (!mounted) return;
      loadStitchingOrders(context, stitchingOrderList, jsonData);
      setState(() {
        stitchingOrderList = stitchingOrderList;
        stitchingLoadSuccess = true;
      });
    } on Exception {
      setState(() {
        stitchingOrderList = [];
        stitchingLoadSuccess = true;
      });
    }
  }

  void loadStitchingOrders(BuildContext context, List<Widget> orders, dynamic jsonData) {
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        int colorIndex = int.parse(jsonData[i]["BuyNo"].split(' ')[0]);
        orders.add(
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 16 : 4, left: 8, right: 8, bottom: i < jsonData.length-1 ? 0 : 4),
            child: InkWell(
              onTap: () {
                //Navigator.pushNamed(context, '/home/cycle_tracking', arguments: jsonData[i]["Order"] + ';S');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: buyBGColor[colorIndex-1],
                            border: Border.all(color: buyTextColor[colorIndex-1]),
                            borderRadius: const BorderRadius.all(Radius.circular(8))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('${jsonData[i]["BuyNo"]} - ${jsonData[i]["Date"]}', style: TextStyle(fontSize: 12, color: buyTextColor[colorIndex-1])),
                          )
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: buyBGColor[colorIndex-1],
                            border: Border.all(color: buyTextColor[colorIndex-1]),
                            borderRadius: const BorderRadius.all(Radius.circular(8))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('${NumberFormat('###,###,##0').format(jsonData[i]["Pairs"])} Pairs', style: TextStyle(fontSize: 12, color: buyTextColor[colorIndex-1])),
                          )
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text('[${jsonData[i]["SKU"]}]  ${jsonData[i]["Order"]}', style: const TextStyle(fontSize: 18))
                        ),
                        SizedBox(
                          width: 60,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: Icon(Icons.check_circle_outline, size: 14, color: Colors.green)
                                  ),
                                  const Expanded(
                                    child: SizedBox()
                                  ),
                                  Text('${jsonData[i]["Progress"].toString().replaceAll('.0', '')}%', style: const TextStyle(fontSize: 14, color: Colors.green)),
                                ],
                              ),
                            ],
                          )
                        )
                      ],
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
      orders.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.noDispatchedOrder, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ));
    }
  }

  Future<void> loadAssemblyWorkOrders() async {
    setState(() {
      assemblyLoadSuccess = false;
    });

    try {
      assemblyOrderList = [];
      final body = await RemoteService().getAssemblyDispatchedOrderProgress(
        apiAddress,
        department
      );
      final jsonData = json.decode(body);
      assemblyWorkOrderCount = jsonData.length;
      if (!mounted) return;
      loadAssemblyOrders(context, assemblyOrderList, jsonData);
      setState(() {
        assemblyOrderList = assemblyOrderList;
        assemblyLoadSuccess = true;
      });
    } on Exception {
      setState(() {
        assemblyOrderList = [];
        assemblyLoadSuccess = true;
      });
    }
  }

  void loadAssemblyOrders(BuildContext context, List<Widget> orders, dynamic jsonData) {
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        int colorIndex = int.parse(jsonData[i]["BuyNo"].split(' ')[0]);
        orders.add(
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 16 : 4, left: 8, right: 8, bottom: i < jsonData.length-1 ? 0 : 4),
            child: InkWell(
              onTap: () {
                //Navigator.pushNamed(context, '/home/cycle_tracking', arguments: jsonData[i]["Order"] + ';A');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: buyBGColor[colorIndex-1],
                            border: Border.all(color: buyTextColor[colorIndex-1]),
                            borderRadius: const BorderRadius.all(Radius.circular(8))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('${jsonData[i]["BuyNo"]} - ${jsonData[i]["Date"]}', style: TextStyle(fontSize: 12, color: buyTextColor[colorIndex-1])),
                          )
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: buyBGColor[colorIndex-1],
                            border: Border.all(color: buyTextColor[colorIndex-1]),
                            borderRadius: const BorderRadius.all(Radius.circular(8))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('${NumberFormat('###,###,##0').format(jsonData[i]["Pairs"])} Pairs', style: TextStyle(fontSize: 12, color: buyTextColor[colorIndex-1])),
                          )
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text('[${jsonData[i]["SKU"]}]  ${jsonData[i]["Order"]}', style: const TextStyle(fontSize: 18))
                        ),
                        SizedBox(
                          width: 60,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: Icon(Icons.check_circle_outline, size: 14, color: Colors.green)
                                  ),
                                  const Expanded(
                                    child: SizedBox()
                                  ),
                                  Text('${jsonData[i]["Progress"].toString().replaceAll('.0', '')}%', style: const TextStyle(fontSize: 14, color: Colors.green)),
                                ],
                              ),
                            ],
                          )
                        )
                      ],
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
      orders.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.noDispatchedOrder, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ));
    }
  }

  Future<void> reloadInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiAddress = prefs.getString('address') ?? '';
    });

    if (sFactory != '') {
      setState(() {
        department = sLean != lean[0].value.toString() ? '${sFactory}_$sLean' : sFactory;
      });
    }
    loadCuttingWorkOrders();
    loadProcessingWorkOrders();
    loadStitchingWorkOrders();
    loadAssemblyWorkOrders();
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
        title: Text(AppLocalizations.of(context)!.homePageTitle),
        actions: [
          IconButton(
            onPressed: () {
              reloadInfo();
            },
            icon: const Icon(Icons.refresh)
          )
        ],
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      drawer: SideMenu(userName: userName, group: group),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return LeanFilter(
                                reloadHomePage: reloadInfo,
                              );
                            },
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8))
                          ),
                          side: const BorderSide(color: Colors.white)
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_pin, size: 30, color: Colors.blue,),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Text(department.replaceAll('_', ' '), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 30)),
                            ),
                          ],
                        )
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 4.0, right: 16.0),
                  child: Text(AppLocalizations.of(context)!.homePageInProgress, style: const TextStyle(fontSize: 20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      processingExpanded = !processingExpanded;
                    });
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(254, 247, 255, 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.grey,
                          offset: Offset(0, 1),
                          blurRadius: 2
                        )
                      ],
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 40,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: processingLoadSuccess
                                  ? SizedBox(
                                    width: 40,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      child: Text(processingWorkOrderCount.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                                    )
                                  )
                                  : const Center(
                                    child: SizedBox(height: 28, width: 28, child: CircularProgressIndicator(color: Colors.blue))
                                  )
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(AppLocalizations.of(context)!.homePageProcessing, style: const TextStyle(fontSize: 18)),
                                ),
                                const Expanded(child: SizedBox()),
                                processingExpanded ? const Icon(Icons.keyboard_arrow_up, color: Colors.black54) : const Icon(Icons.keyboard_arrow_down, color: Colors.black54)
                              ],
                            ),
                          ),
                          Visibility(
                            visible: processingExpanded,
                            child: Column(
                              children: processingOrderList,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      cuttingExpanded = !cuttingExpanded;
                    });
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(254, 247, 255, 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.grey,
                          offset: Offset(0, 1),
                          blurRadius: 2
                        )
                      ],
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 40,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: cuttingLoadSuccess
                                  ? SizedBox(
                                    width: 40,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      child: Text(cuttingWorkOrderCount.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                                    )
                                  )
                                  : const Center(
                                    child: SizedBox(height: 28, width: 28, child: CircularProgressIndicator(color: Colors.blue))
                                  )
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(AppLocalizations.of(context)!.homePageCutting, style: const TextStyle(fontSize: 18)),
                                ),
                                const Expanded(child: SizedBox()),
                                cuttingExpanded ? const Icon(Icons.keyboard_arrow_up, color: Colors.black54) : const Icon(Icons.keyboard_arrow_down, color: Colors.black54)
                              ],
                            ),
                          ),
                          Visibility(
                            visible: cuttingExpanded,
                            child: Column(
                              children: cuttingOrderList,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      stitchingExpanded = !stitchingExpanded;
                    });
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(254, 247, 255, 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.grey,
                          offset: Offset(0, 1),
                          blurRadius: 2
                        )
                      ],
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 40,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: stitchingLoadSuccess
                                  ? SizedBox(
                                    width: 40,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      child: Text(stitchingWorkOrderCount.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                                    )
                                  )
                                  : const Center(
                                    child: SizedBox(height: 28, width: 28, child: CircularProgressIndicator(color: Colors.blue))
                                  )
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(AppLocalizations.of(context)!.stitching, style: const TextStyle(fontSize: 18)),
                                ),
                                const Expanded(child: SizedBox()),
                                stitchingExpanded ? const Icon(Icons.keyboard_arrow_up, color: Colors.black54) : const Icon(Icons.keyboard_arrow_down, color: Colors.black54)
                              ],
                            ),
                          ),
                          Visibility(
                            visible: stitchingExpanded,
                            child: Column(
                              children: stitchingOrderList,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      assemblyExpanded = !assemblyExpanded;
                    });
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(254, 247, 255, 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.grey,
                          offset: Offset(0, 1),
                          blurRadius: 2
                        )
                      ],
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 40,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: assemblyLoadSuccess
                                  ? SizedBox(
                                    width: 40,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      child: Text(assemblyWorkOrderCount.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                                    )
                                  )
                                  : const Center(
                                    child: SizedBox(height: 28, width: 28, child: CircularProgressIndicator(color: Colors.blue))
                                  )
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(AppLocalizations.of(context)!.assembly, style: const TextStyle(fontSize: 18)),
                                ),
                                const Expanded(child: SizedBox()),
                                assemblyExpanded ? const Icon(Icons.keyboard_arrow_up, color: Colors.black54) : const Icon(Icons.keyboard_arrow_down, color: Colors.black54)
                              ],
                            ),
                          ),
                          Visibility(
                            visible: assemblyExpanded,
                            child: Column(
                              children: assemblyOrderList,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              )
            ],
          ),
        )
      )
    );
  }
}

class LeanFilter extends StatefulWidget {
  const LeanFilter({
    super.key,
    required this.reloadHomePage
  });
  final Function reloadHomePage;

  @override
  State<StatefulWidget> createState() => LeanFilterState();
}

class LeanFilterState extends State<LeanFilter> {
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
          const SizedBox(height: 10),
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
            final userInfo = await SharedPreferences.getInstance();
            userInfo.setString('department', sFactory + (sLean.contains('LEAN') ? '_$sLean' : '_LEAN01'));
            Navigator.of(context).pop();
            widget.reloadHomePage();
          },
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    );
  }
}