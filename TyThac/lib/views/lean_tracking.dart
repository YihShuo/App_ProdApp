import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:production/components/side_menu.dart';

String department = '', apiAddress = '', factory = '', lean = '', section = '', showMode = 'None';
DateTime selectedDate = DateTime.now();
String selectedMonth = DateFormat('yyyy/MM').format(DateTime.now());
List<String> factoryDropdownItems = [];
List<DropdownMenuItem<String>> leanList = [];
List<List<String>> factoryLeans = [];
double screenWidth = 0, screenHeight = 0, minScale = 1, fitHeightScale = 1, maxScale = 1;
bool loadSuccess = false;

class LeanTracking extends StatefulWidget {
  const LeanTracking({super.key});

  @override
  LeanTrackingState createState() => LeanTrackingState();
}

class LeanTrackingState extends State<LeanTracking> with TickerProviderStateMixin {
  late final TransformationController transformationController;
  late final AnimationController animationController;
  late AnimationController floatAnimationController;
  late Animation<Offset> floatAnimationExtra, floatAnimationSP, floatAnimationC, floatAnimationS, floatAnimationA, floatAnimationW;
  bool isOpen = false;
  Animation<Matrix4>? animation;
  List<Widget> tableColumnTitles = [];
  List<String> tableFirstCol = [];
  List<List<Widget>> tableContentRows = [];
  List<GlobalKey<OrderCardState>> keyList = [];
  Widget schedules = const SizedBox();
  double cardHeight = 208.0, cardWidth = 130.0;
  String userName = '', group = '';
  bool firstLoad = true;

  @override
  void initState() {
    super.initState();
    factory = '';
    lean = '';
    firstLoad = true;
    showMode = 'None';
    transformationController = TransformationController();
    transformationController.addListener(() {
      final matrix = transformationController.value.clone();
      final scale = matrix.getMaxScaleOnAxis();
      final y = matrix.getTranslation().y;

      final contentHeight = tableFirstCol.length * cardHeight + 60;
      final scaledHeight = contentHeight * scale;
      final minY = screenHeight - scaledHeight;

      double clampedY = y.clamp(minY < 0 ? minY : 0, 0);
      matrix.setEntry(1, 3, clampedY);
      transformationController.value = matrix;
    });
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      transformationController.value = animation!.value;
    });
    floatAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    floatAnimationExtra = Tween<Offset>(begin: const Offset(-0.1, -1.4), end: const Offset(-0.1, -5.8/*-6.9*/)).animate(floatAnimationController);
    floatAnimationSP = Tween<Offset>(begin: const Offset(-0.1, -0.2), end: const Offset(-0.1, -5.8)).animate(floatAnimationController);
    floatAnimationC = Tween<Offset>(begin: const Offset(-0.1, -0.2), end: const Offset(-0.1, -4.7)).animate(floatAnimationController);
    floatAnimationS = Tween<Offset>(begin: const Offset(-0.1, -0.2), end: const Offset(-0.1, -3.6)).animate(floatAnimationController);
    floatAnimationA = Tween<Offset>(begin: const Offset(-0.1, -0.2), end: const Offset(-0.1, -2.5)).animate(floatAnimationController);
    floatAnimationW = Tween<Offset>(begin: const Offset(-0.1, -0.2), end: const Offset(-0.1, -1.4)).animate(floatAnimationController);
    loadUserInfo();
  }

  @override
  void dispose() {
    transformationController.dispose();
    animationController.dispose();
    floatAnimationController.dispose();
    super.dispose();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '';
    department = prefs.getString('department') ?? 'DT_LINE 01';

    setState(() {
      userName = prefs.getString('userName') ?? '';
      group = prefs.getString('group') ?? '';
      section = 'A';
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    await loadFilter();
    loadSchedule();
  }

  Future loadFilter() async {
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
    factory = department.split('_')[0];
    lean = department.indexOf('_') > 0 ? department.split('_')[1] : 'LINE 01';
    if (factoryDropdownItems.contains(factory) == false) {
      factory = factoryDropdownItems[0];
      lean = factoryLeans[factoryDropdownItems.indexOf(factory)][0];
    }
    leanList = factoryLeans[factoryDropdownItems.indexOf(factory)].map((String myLean) {
      return DropdownMenuItem(
        value: myLean,
        child: Center(
          child: Text(myLean.toString()),
        )
      );
    }).toList();
  }

  void loadSchedule() async {
    setState(() {
      loadSuccess = false;
    });
    schedules = const SizedBox();

    try {
      final body = await RemoteService().getLeanScheduleData(
        apiAddress,
        selectedMonth,
        factory,
        lean,
        section
      );
      final jsonBody = json.decode(body);

      tableColumnTitles = [];
      tableFirstCol = [];
      tableContentRows = [];
      keyList = [];
      if (jsonBody.length > 0) {
        DateTime firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
        DateTime lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

        tableColumnTitles.add(
          SizedBox(
            height: 50,
            child: Center(child: Text(AppLocalizations.of(context)!.scheduleSequence)),
          )
        );

        for (int j = firstDayOfMonth.day; j <= lastDayOfMonth.day; j++) {
          DateTime sDate = firstDayOfMonth.add(Duration(days: j - 1));
          tableColumnTitles.add(
            SizedBox(
              width: cardWidth,
              height: 50,
              child: Center(
                child: DateFormat('yyyy/MM/dd').format(sDate) != DateFormat('yyyy/MM/dd').format(DateTime.now())
                ? Text(DateFormat('MM/dd').format(sDate))
                : Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(DateFormat('MM/dd').format(sDate), style: const TextStyle(color: Colors.white),),
                  ),
                )
              ),
            )
          );
        }

        List<int> holidays = jsonBody['Holiday'].cast<int>();

        for (int j = 0; j < jsonBody['Sequence'].length; j++) {
          tableFirstCol.add((j + 1).toString());
          List<Widget> orders = [];
          DateTime tempDate = firstDayOfMonth;
          for (int k = 0; k < jsonBody['Sequence'][j]['Schedule'].length; k++) {
            DateTime orderDate = DateFormat('yyyy/MM/dd').parse(jsonBody['Sequence'][j]['Schedule'][k]['Date'].toString());
            int days = orderDate.difference(tempDate).inDays;
            for (int l = 0; l < days; l++) {
              if (holidays.contains(orders.length + 1) == false) {
                orders.add(
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight
                  )
                );
              }
              else {
                orders.add(
                  Container(
                    color: Colors.yellow[200],
                    width: cardWidth,
                    height: cardHeight
                  )
                );
              }
            }

            GlobalKey<OrderCardState> key = GlobalKey();
            keyList.add(key);
            orders.add(
              OrderCard(
                key: keyList[keyList.length - 1],
                height: cardHeight,
                width: cardWidth,
                dieCut: jsonBody['Sequence'][j]['Schedule'][k]['DieCutMold'].toString(),
                order: jsonBody['Sequence'][j]['Schedule'][k]['Order'],
                subOrder: jsonBody['Sequence'][j]['Schedule'][k]['SubOrder'],
                buy: jsonBody['Sequence'][j]['Schedule'][k]['BuyNo'],
                sku: jsonBody['Sequence'][j]['Schedule'][k]['SKU'],
                pairs: NumberFormat('###,###,##0').format(jsonBody['Sequence'][j]['Schedule'][k]['Pairs']),
                gac: jsonBody['Sequence'][j]['Schedule'][k]['ShipDate'],
                country: jsonBody['Sequence'][j]['Schedule'][k]['Country'],
                progress: jsonBody['Sequence'][j]['Schedule'][k]['Progress'],
                location: jsonBody['Sequence'][j]['Schedule'][k]['Location'],
                labor: NumberFormat('###,###,##0').format(jsonBody['Sequence'][j]['Schedule'][k]['Labor']),
                matStatus: jsonBody['Sequence'][j]['Schedule'][k]['MatStatus'],
                ftt: jsonBody['Sequence'][j]['Schedule'][k]['FTT'],
                highLight: jsonBody['Sequence'][j]['Schedule'][k]['IsToday'],
                loadSchedule: loadSchedule,
              )
            );
            tempDate = orderDate.add(const Duration(days: 1));
          }
          int days = lastDayOfMonth.difference(tempDate).inDays;
          for (int l = 0; l < days; l++) {
            if (holidays.contains(orders.length + 1) == false) {
              orders.add(
                SizedBox(
                  width: cardWidth,
                  height: cardHeight
                )
              );
            }
            else {
              orders.add(
                Container(
                  color: Colors.yellow[200],
                  width: cardWidth,
                  height: cardHeight
                )
              );
            }
          }
          tableContentRows.add(orders);
        }
      }
    }
    finally {
      setState(() {
        minScale = screenWidth / ((tableColumnTitles.length - 1) * cardWidth + 60);
        fitHeightScale = screenHeight / (tableFirstCol.length * cardHeight + 60);
        maxScale = fitHeightScale < 1 ? 1 : fitHeightScale;
        if (firstLoad) {
          transformationController.value = Matrix4.identity()..scale(fitHeightScale);
        }
        loadSuccess = true;
      });
      firstLoad = false;
    }
  }

  void toggleMenu() {
    setState(() {
      isOpen = !isOpen;
      if (isOpen) {
        floatAnimationController.forward();
      } else {
        floatAnimationController.reverse();
      }
    });
  }

  Widget buildFab(Widget widget, Animation<Offset> animation, VoidCallback onTap) {
    return SlideTransition(
      position: animation,
      child: FloatingActionButton(
        heroTag: null,
        mini: true,
        backgroundColor: Colors.white,
        onPressed: onTap,
        child: widget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - AppBar().preferredSize.height - MediaQuery.of(context).viewPadding.bottom;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.sideMenuProductionTracking, style: const TextStyle(fontSize: 18),),
            Text('$factory $lean - ${(section == 'W' ? AppLocalizations.of(context)!.warehouse : section == 'A' ? AppLocalizations.of(context)!.assembly : section == 'S' ? AppLocalizations.of(context)!.stitching : section == 'C' ? AppLocalizations.of(context)!.cutting : AppLocalizations.of(context)!.secondProcess)}', style: const TextStyle(fontSize: 16))
          ],
        ),
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
                    refresh: loadSchedule,
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
      body: loadSuccess && tableColumnTitles.isNotEmpty ? LayoutBuilder(
        builder: (context, constraints) {
          double tableWidth = (tableColumnTitles.length - 1) * cardWidth + 60;
          double tableHeight = tableWidth * screenHeight / screenWidth;

          return GestureDetector(
            onDoubleTapDown: (details) {
              final position = details.localPosition;
              final currentMatrix = transformationController.value;
              final currentScale = currentMatrix.getMaxScaleOnAxis();
              double dx = position.dx / screenWidth * tableWidth * fitHeightScale;
              if (dx > tableWidth * fitHeightScale - screenWidth) {
                dx = tableWidth * fitHeightScale - screenWidth;
              }
              final targetMatrix = currentScale > minScale ? (Matrix4.identity()..scale(minScale)) : (Matrix4.identity()..translate(-dx, 0)..scale(fitHeightScale));

              animation = Matrix4Tween(
                begin: transformationController.value,
                end: targetMatrix,
              ).animate(CurveTween(curve: Curves.easeInOut).animate(animationController));

              animationController.forward(from: 0);
            },
            child: InteractiveViewer(
              transformationController: transformationController,
              minScale: minScale,
              maxScale: maxScale,
              panEnabled: true,
              constrained: false,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: tableWidth,
                height: tableHeight,
                child: HorizontalDataTable(
                  scrollPhysics: const NeverScrollableScrollPhysics(),
                  horizontalScrollPhysics: const NeverScrollableScrollPhysics(),
                  leftHandSideColumnWidth: 60,
                  rightHandSideColumnWidth: cardWidth * (tableColumnTitles.length - 1),
                  isFixedHeader: true,
                  headerWidgets: tableColumnTitles,
                  leftSideItemBuilder: (BuildContext context, int index) {
                    return SizedBox(
                      height: cardHeight,
                      child: Center(
                        child: Text(tableFirstCol[index], style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  },
                  rightSideItemBuilder: (BuildContext context, int index) {
                    return Row(children: tableContentRows[index]);
                  },
                  itemCount: tableFirstCol.length,
                  rowSeparatorWidget: Divider(
                    color: Colors.grey.shade300,
                    height: 1.0,
                    thickness: 0.0,
                  ),
                  leftHandSideColBackgroundColor: const Color(0xFFFFFFFF),
                  rightHandSideColBackgroundColor: const Color(0xFFFFFFFF),
                ),
              ),
            ),
          );
        },
      ) : loadSuccess && tableFirstCol.isEmpty ? Center(
        child: Text(AppLocalizations.of(context)!.noDataFound),
      ) : const Center(
        child: CircularProgressIndicator(
          color: Colors.blue,
        ),
      ),
      floatingActionButton: SizedBox.expand(
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            if (isOpen)...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (isOpen) toggleMenu();
                  },
                  behavior: HitTestBehavior.opaque,
                ),
              ),
            ],
            buildFab(showMode == 'None' ? const Icon(Icons.hide_source, color: Colors.grey,) : showMode == 'Labor' ? const Icon(Icons.person, color: Colors.blue,) : showMode == 'Material' ? const Icon(Icons.view_in_ar, color: Colors.blue,) : const Icon(Icons.flaky, color: Colors.blue,),
            floatAnimationExtra, () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    scrollable: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))
                    ),
                    content: Column(
                      children: [
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.hide_source, color: Colors.grey, size: 28,),
                          title: Text(AppLocalizations.of(context)!.chooseNone, style: const TextStyle(fontSize: 16),),
                          onTap: () {
                            setState(() {
                              isOpen = false;
                              showMode = 'None';
                              for (int i = 0; i < keyList.length; i++) {
                                keyList[i].currentState?.setModeVisible();
                              }
                            });
                            Navigator.of(context).pop();
                            floatAnimationController.reverse();
                          },
                        ),
                        const Divider(height: 1, color: Colors.black,),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.person, color: Colors.blue, size: 32,),
                          title: Text(AppLocalizations.of(context)!.directLabor, style: const TextStyle(fontSize: 16)),
                          onTap: () {
                            setState(() {
                              isOpen = false;
                              showMode = 'Labor';
                              for (int i = 0; i < keyList.length; i++) {
                                keyList[i].currentState?.setModeVisible();
                              }
                            });
                            Navigator.of(context).pop();
                            floatAnimationController.reverse();
                          },
                        ),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.view_in_ar, color: Colors.blue, size: 32,),
                          title: Text(AppLocalizations.of(context)!.material, style: const TextStyle(fontSize: 16)),
                          onTap: () {
                            setState(() {
                              isOpen = false;
                              showMode = 'Material';
                              for (int i = 0; i < keyList.length; i++) {
                                keyList[i].currentState?.setModeVisible();
                              }
                            });
                            Navigator.of(context).pop();
                            floatAnimationController.reverse();
                          },
                        ),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.flaky, color: Colors.blue, size: 32,),
                          title: const Text('FTT', style: const TextStyle(fontSize: 16)),
                          onTap: () {
                            setState(() {
                              isOpen = false;
                              showMode = 'FTT';
                              for (int i = 0; i < keyList.length; i++) {
                                keyList[i].currentState?.setModeVisible();
                              }
                            });
                            Navigator.of(context).pop();
                            floatAnimationController.reverse();
                          },
                        )
                      ],
                    )
                  );
                },
              );
            }),
            /*buildFab(const Text('SP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)), floatAnimationSP, () {
              setState(() {
                isOpen = false;
                section = 'SP';
              });
              floatAnimationController.reverse();
              loadSchedule();
            }),*/
            buildFab(const Text('C', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)), floatAnimationC, () {
              setState(() {
                isOpen = false;
                section = 'C';
              });
              floatAnimationController.reverse();
              loadSchedule();
            }),
            buildFab(const Text('S', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)), floatAnimationS, () {
              setState(() {
                isOpen = false;
                section = 'S';
              });
              floatAnimationController.reverse();
              loadSchedule();
            }),
            buildFab(const Text('A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)), floatAnimationA, () {
              setState(() {
                isOpen = false;
                section = 'A';
              });
              floatAnimationController.reverse();
              loadSchedule();
            }),
            buildFab(const Text('W', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)), floatAnimationW, () {
              setState(() {
                isOpen = false;
                section = 'W';
              });
              floatAnimationController.reverse();
              loadSchedule();
            }),
            FloatingActionButton(
              heroTag: null,
              onPressed: toggleMenu,
              backgroundColor: Colors.blue,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 250),
                turns: isOpen ? 0.25 : 0.0,
                child: Text(section, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white))
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderCard extends StatefulWidget {
  const OrderCard({
    super.key,
    required this.height,
    required this.width,
    required this.dieCut,
    required this.order,
    required this.subOrder,
    required this.buy,
    required this.sku,
    required this.pairs,
    required this.gac,
    required this.country,
    required this.progress,
    required this.location,
    required this.labor,
    required this.matStatus,
    required this.ftt,
    required this.highLight,
    required this.loadSchedule,
  });

  final double height;
  final double width;
  final String dieCut;
  final String order;
  final String subOrder;
  final String buy;
  final String sku;
  final String pairs;
  final String gac;
  final String country;
  final String progress;
  final String location;
  final String labor;
  final String matStatus;
  final String ftt;
  final bool highLight;
  final Function loadSchedule;

  @override
  OrderCardState createState() => OrderCardState();
}

class OrderCardState extends State<OrderCard> {

  void setModeVisible() {
    setState(() {
      showMode = showMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color fontColor = widget.location == 'None' ? const Color.fromRGBO(150, 150, 150, 1) : Colors.black;

    return Stack(
      children: [
        SizedBox(
          height: widget.height,
          width: widget.width,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              height: widget.height - 4,
              width: widget.width - 4,
              decoration: BoxDecoration(
                color: widget.location == 'None' ? const Color.fromRGBO(240, 240, 240, 1) : double.parse(widget.progress) == 100 ? Colors.green.shade100 : double.parse(widget.progress) > 0 ? Colors.orange.shade100 : Colors.white,
                border: Border.all(width: widget.highLight ? 3 : 1, color: widget.highLight ? Colors.blue : double.parse(widget.progress) == 100 ? Colors.green : double.parse(widget.progress) > 0 ? Colors.orange : Colors.black38),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: section == 'SP' && widget.location != 'None'
                  ? () {
                    Navigator.pushNamed(
                      context, '/lean_tracking/second_process',
                      arguments: {
                        "ry": widget.order,
                        "previousPage": "/lean_tracking",
                      },
                    ).then((_) => widget.loadSchedule());
                  }
                  : section != 'W' && widget.location != 'None' ? () {
                    Navigator.pushNamed(
                      context, '/leanWorkOrder/reporting',
                      arguments: {
                        "ry": widget.order,
                        "building": factory,
                        "lean": lean,
                        "section": section,
                        "type": "OUTPUT",
                        "previousPage": "/lean_tracking",
                        "mode": "ReadOnly"
                      },
                    ).then((_) => widget.loadSchedule());
                  } : () {},
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(widget.dieCut, style: TextStyle(color: fontColor), strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                        Text(widget.order + (widget.subOrder == '' ? '' : '-${widget.subOrder}'), style: TextStyle(color: fontColor), strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                        Text(widget.buy, style: TextStyle(color: fontColor), strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                        Text(widget.sku, style: TextStyle(color: fontColor), strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                        Text(widget.pairs, style: TextStyle(color: fontColor), strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                        Text(widget.gac, style: TextStyle(color: fontColor), strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                        Text(widget.country, style: TextStyle(color: fontColor), strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                        Text(widget.location != 'None' ? '[${widget.progress}%]' : '[Not Required]', style: TextStyle(color: fontColor), strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis)
                      ]
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: widget.location == 'Ty Dat' && showMode == 'None',
          child: Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4)
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                child: Text('TĐ', style: TextStyle(color: Colors.white, height: 1),),
              ),
            ),
          )
        ),
        Visibility(
          visible: showMode == 'Labor' && (section == 'C' || section == 'S' || section == 'A'),
          child: Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4)
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                child: Text(widget.labor, style: const TextStyle(color: Colors.white, height: 1),),
              ),
            ),
          ),
        ),
        Visibility(
          visible: showMode == 'Material' && (section == 'C' || section == 'S' || section == 'A'),
          child: Positioned(
            right: 6,
            bottom: 6,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context, '/lean_tracking/material',
                  arguments: {
                    "ry": widget.order,
                    "section": section,
                    "previousPage": "/lean_tracking"
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: widget.matStatus == '100.0' ? Colors.blue : Colors.deepOrange,
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                  child: Text('${widget.matStatus}%', style: const TextStyle(color: Colors.white, height: 1),),
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: showMode == 'FTT' && widget.ftt != '',
          child: Positioned(
            right: 6,
            bottom: 6,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context, '/lean_tracking/ftt',
                  arguments: {
                    "ry": widget.order,
                    "pairs": widget.pairs,
                    "building": factory,
                    "lean": lean,
                    "section": section,
                    "ftt": widget.ftt,
                    "previousPage": "/lean_tracking"
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: widget.ftt != '' && double.parse(widget.ftt) >= 91.0 ? Colors.blue : Colors.deepOrange,
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                  child: Text('${widget.ftt}%', style: const TextStyle(color: Colors.white, height: 1),),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class FilterDialog extends StatefulWidget {
  const FilterDialog({
    super.key,
    required this.refresh
  });
  final Function refresh;

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
            child: Text('${AppLocalizations.of(context)!.month}：')
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
                      leanList = factoryLeans[factoryDropdownItems.indexOf(factory)].map((String myLean) {
                        return DropdownMenuItem(
                          value: myLean,
                          child: Center(
                            child: Text(myLean.toString()),
                          )
                        );
                      }).toList();
                      lean = factoryLeans[factoryDropdownItems.indexOf(factory)][0];
                    });
                  }
                });
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
                          leanList = factoryLeans[factoryDropdownItems.indexOf(factory)].map((String myLean) {
                            return DropdownMenuItem(
                              value: myLean,
                              child: Center(
                                child: Text(myLean.toString()),
                              )
                            );
                          }).toList();
                          lean = factoryLeans[factoryDropdownItems.indexOf(factory)][0];
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
            child: Text(AppLocalizations.of(context)!.floor)
          ),
          DropdownButton<String>(
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Colors.grey,
            ),
            value: factory,
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
                factory = value!;
                leanList = factoryLeans[factoryDropdownItems.indexOf(factory)].map((String factory) {
                  return DropdownMenuItem(
                    value: factory,
                    child: Center(
                      child: Text(factory.toString()),
                    )
                  );
                }).toList();
                lean = factoryLeans[factoryDropdownItems.indexOf(factory)][0];
              });
            },
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.cuttingWorkOrderFilterLean)
          ),
          DropdownButton<String>(
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Colors.grey,
            ),
            value: lean,
            items: leanList,
            onChanged: (value) {
              setState(() {
                lean = value!;
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
          onPressed: () {
            Navigator.of(context).pop();
            widget.refresh();
          },
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    );
  }
}