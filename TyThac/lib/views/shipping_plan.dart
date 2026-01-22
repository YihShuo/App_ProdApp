import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:production/components/side_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

String apiAddress = '';
double screenWidth = 0, screenHeight = 0;
DateTime selectedDate = DateTime.now();
String selectedMonth = DateFormat('yyyy/MM').format(DateTime.now());

class ShippingPlan extends StatefulWidget {
  const ShippingPlan({super.key});

  @override
  ShippingPlanState createState() => ShippingPlanState();
}

class ShippingPlanState extends State<ShippingPlan> with TickerProviderStateMixin {
  String userName = '';
  String factory = '', group = '';
  late TabController tabController;
  List<Widget> estimatedList = [], actualList = [];
  String loadingStatus = 'isLoading';
  final events = [];
  bool scrollable = true;

  @override
  void initState() {
    super.initState();
    tabController = TabController(initialIndex: 0, length: 2, vsync: this);
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '';
    setState(() {
      userName = prefs.getString('userName') ?? '';
      factory = prefs.getString('factory') ?? '';
      group = prefs.getString('group') ?? '';
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    await loadShippingPlan();
  }

  Future<void> loadShippingPlan() async {
    setState(() {
      loadingStatus = 'isLoading';
    });

    final body = await RemoteService().getShippingPlan(
      apiAddress,
      DateFormat('yyyy/MM/dd').format(selectedDate),
      factory
    );
    final jsonData = json.decode(body);

    estimatedList = [];
    if (jsonData['Estimate'].length > 0) {
      for (int i = 0; i < jsonData['Estimate'].length; i++) {
        List<Widget> ryList = [];
        for (int j = 0; j < jsonData['Estimate'][i]['Content'].length; j++) {
          Color ryColor = jsonData['Estimate'][i]['Content'][j]['Status'] == "Finished"
          ? Colors.green.shade200
          : Colors.red.shade200;
          ryList.add(
            Padding(
              padding: EdgeInsets.only(top: ryList.isEmpty ? 16 : 4, bottom: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(50),
                      spreadRadius: 2,
                      blurRadius: 1,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 26,
                            decoration: BoxDecoration(
                              color: ryColor,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4))
                            ),
                            child: Text(' ${jsonData['Estimate'][i]['Content'][j]['Seq']}.  ${jsonData['Estimate'][i]['Content'][j]['RY']}', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold))
                          ),
                        ),
                        Container(
                          height: 26,
                          width: 28,
                          decoration: BoxDecoration(
                            color: ryColor,
                            borderRadius: const BorderRadius.only(topRight: Radius.circular(4))
                          ),
                          child: jsonData['Estimate'][i]['Content'][j]['Status'] == "Finished"
                          ? Icon(Icons.check_circle_outline, color: darken(ryColor, 0.5), size: 20)
                          : null,
                        )
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 26),
                        ListTile(
                          leading: SizedBox(
                            width: 40,
                            child: Center(
                              child: Text(jsonData['Estimate'][i]['Content'][j]['Building'], style: const TextStyle(fontSize: 18))
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("SKU: ${jsonData['Estimate'][i]['Content'][j]['SKU']}", style: const TextStyle(fontSize: 10)),
                              Text("PO: ${jsonData['Estimate'][i]['Content'][j]['PO']} [${jsonData['Estimate'][i]['Content'][j]['Country']}]", style: const TextStyle(fontSize: 10)),
                              Text("Cartons: ${NumberFormat('###,###,##0').format(jsonData['Estimate'][i]['Content'][j]['Cartons'])}", style: const TextStyle(fontSize: 10)),
                              Text("CBM: ${jsonData['Estimate'][i]['Content'][j]['CBM'].toStringAsFixed(3)}", style: const TextStyle(fontSize: 10))
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.all(Radius.circular(8))
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text("Pairs", style: TextStyle(color: Colors.white, fontSize: 14)),
                                )
                              ),
                              Text(NumberFormat('###,###,##0').format(jsonData['Estimate'][i]['Content'][j]['Pairs']), style: const TextStyle(fontSize: 20)),
                            ],
                          ),
                          contentPadding: const EdgeInsets.only(left: 4, right: 8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          );
        }

        estimatedList.add(
          ContainerCard(
            index: jsonData['Estimate'][i]['ID'],
            total: jsonData.length-1,
            container: jsonData['Estimate'][i]['Container'],
            pairs: jsonData['Estimate'][i]['Pairs'],
            cartons: jsonData['Estimate'][i]['Cartons'],
            cbm: jsonData['Estimate'][i]['CBM'],
            ry: ryList
          )
        );
      }
    }
    else {
      estimatedList.add(
        SizedBox(
          height: screenHeight,
          child: Center(
            child: Text(AppLocalizations.of(context)!.noDataFound),
          ),
        )
      );
    }

    actualList = [];
    if (jsonData['Actual'].length > 0) {
      for (int i = 0; i < jsonData['Actual'].length; i++) {
        List<Widget> ryList = [];
        for (int j = 0; j < jsonData['Actual'][i]['Content'].length; j++) {
          Color ryColor = jsonData['Actual'][i]['Content'][j]['Status'] == "Finished"
          ? Colors.green.shade200
          : Colors.red.shade200;
          ryList.add(
            Padding(
              padding: EdgeInsets.only(top: ryList.isEmpty ? 16 : 4, bottom: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(50),
                      spreadRadius: 2,
                      blurRadius: 1,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 26,
                            decoration: BoxDecoration(
                              color: ryColor,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4))
                            ),
                            child: Text(' ${jsonData['Actual'][i]['Content'][j]['Seq']}.  ${jsonData['Actual'][i]['Content'][j]['RY']}', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold))
                          ),
                        ),
                        Container(
                          height: 26,
                          width: 28,
                          decoration: BoxDecoration(
                            color: ryColor,
                            borderRadius: const BorderRadius.only(topRight: Radius.circular(4))
                          ),
                          child: jsonData['Actual'][i]['Content'][j]['Status'] == "Finished"
                          ? Icon(Icons.check_circle_outline, color: darken(ryColor, 0.5), size: 20)
                          : null,
                        )
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 26),
                        ListTile(
                          leading: SizedBox(
                            width: 40,
                            child: Center(
                              child: Text(jsonData['Actual'][i]['Content'][j]['Building'], style: const TextStyle(fontSize: 18))
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("SKU: ${jsonData['Actual'][i]['Content'][j]['SKU']}", style: const TextStyle(fontSize: 10)),
                              Text("PO: ${jsonData['Actual'][i]['Content'][j]['PO']} [${jsonData['Actual'][i]['Content'][j]['Country']}]", style: const TextStyle(fontSize: 10)),
                              Text("Cartons: ${NumberFormat('###,###,##0').format(jsonData['Actual'][i]['Content'][j]['Cartons'])}", style: const TextStyle(fontSize: 10)),
                              Text("CBM: ${jsonData['Actual'][i]['Content'][j]['CBM'].toStringAsFixed(3)}", style: const TextStyle(fontSize: 10))
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.all(Radius.circular(8))
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text("Pairs", style: TextStyle(color: Colors.white, fontSize: 14)),
                                  )
                              ),
                              Text(NumberFormat('###,###,##0').format(jsonData['Actual'][i]['Content'][j]['Pairs']), style: const TextStyle(fontSize: 20)),
                            ],
                          ),
                          contentPadding: const EdgeInsets.only(left: 4, right: 8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          );
        }

        actualList.add(
          ContainerCard(
            index: jsonData['Actual'][i]['ID'],
            total: jsonData.length-1,
            container: "Invoice [${jsonData['Actual'][i]['Container']}]",
            pairs: jsonData['Actual'][i]['Pairs'],
            cartons: jsonData['Actual'][i]['Cartons'],
            cbm: jsonData['Actual'][i]['CBM'],
            ry: ryList
          )
        );
      }
    }
    else {
      actualList.add(
        SizedBox(
          height: screenHeight,
          child: Center(
            child: Text(AppLocalizations.of(context)!.noDataFound),
          ),
        )
      );
    }

    setState(() {
      estimatedList = estimatedList;
      actualList = actualList;
      loadingStatus = 'Completed';
    });
  }

  Color darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - kBottomNavigationBarHeight;

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
            Text(AppLocalizations.of(context)!.shippingPlan),
            Text(DateFormat('yyyy/MM/dd').format(selectedDate), style: const TextStyle(fontSize: 14),)
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return LeanFilter(
                    refresh: loadShippingPlan,
                  );
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Text(AppLocalizations.of(context)!.estimatedShipping, style: const TextStyle(fontSize: 16))
            ),
            Tab(
              child: Text(AppLocalizations.of(context)!.actualShipping, style: const TextStyle(fontSize: 16))
            )
          ]
        ),
      ),
      drawer: SideMenu(userName: userName, group: group),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: TabBarView(
          controller: tabController,
          children: [
            SingleChildScrollView(
              physics: scrollable ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
              child: Listener(
                onPointerDown: (event) {
                  events.add(event.pointer);
                },
                onPointerUp: (event) {
                  events.clear();
                  setState(() {
                    scrollable = true;
                  });
                },
                onPointerMove: (event) {
                  if (events.length == 2) {
                    setState(() {
                      scrollable = false;
                    });
                  }
                },
                child: InteractiveViewer(
                  clipBehavior: Clip.none,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: loadingStatus == 'Completed'
                    ? estimatedList
                    : loadingStatus == 'isLoading'
                    ? [
                      SizedBox(
                        height: screenHeight,
                        child: const Center(
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: CircularProgressIndicator(color: Colors.blue),
                          ),
                        ),
                      )
                    ]
                    : []
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              physics: scrollable ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
              child: Listener(
                onPointerDown: (event) {
                  events.add(event.pointer);
                },
                onPointerUp: (event) {
                  events.clear();
                  setState(() {
                    scrollable = true;
                  });
                },
                onPointerMove: (event) {
                  if (events.length == 2) {
                    setState(() {
                      scrollable = false;
                    });
                  }
                },
                child: InteractiveViewer(
                  clipBehavior: Clip.none,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: loadingStatus == 'Completed'
                    ? actualList
                    : loadingStatus == 'isLoading'
                    ? [
                      SizedBox(
                        height: screenHeight,
                        child: const Center(
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: CircularProgressIndicator(color: Colors.blue),
                          ),
                        ),
                      )
                    ]
                    : []
                  ),
                ),
              ),
            )
          ]
        ),
      )
      /*SafeArea(
        child: SingleChildScrollView(
          physics: scrollable ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
          child: Listener(
            onPointerDown: (event) {
              events.add(event.pointer);
            },
            onPointerUp: (event) {
              events.clear();
              setState(() {
                scrollable = true;
              });
            },
            onPointerMove: (event) {
              if (events.length == 2) {
                setState(() {
                  scrollable = false;
                });
              }
            },
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: loadingStatus == 'Completed'
                  ? containerList
                  : loadingStatus == 'isLoading'
                  ? [
                      SizedBox(
                        height: screenHeight,
                        child: const Center(
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: CircularProgressIndicator(color: Colors.blue),
                          ),
                        ),
                      )
                    ]
                  : [
                      SizedBox(
                        height: screenHeight,
                        child: Center(
                          child: Text(AppLocalizations.of(context)!.noDataFound, style: const TextStyle(fontSize: 16))
                        )
                      )
                    ]
              ),
            ),
          ),
        )
      )*/
    );
  }
}

class LeanFilter extends StatefulWidget {
  const LeanFilter({
    super.key,
    required this.refresh
  });
  final Function refresh;

  @override
  State<StatefulWidget> createState() => LeanFilterState();
}

class LeanFilterState extends State<LeanFilter> {
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
            child: Text('${AppLocalizations.of(context)!.date}：')
          ),
          SizedBox(
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
                          onSubmit: (Object? value) async {
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
                              onSubmit: (Object? value) async {
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

class ContainerCard extends StatefulWidget {
  const ContainerCard({
    super.key,
    required this.index,
    required this.total,
    required this.container,
    required this.pairs,
    required this.cartons,
    required this.cbm,
    required this.ry
  });

  final int index;
  final int total;
  final String container;
  final int pairs;
  final int cartons;
  final double cbm;
  final List<Widget> ry;

  @override
  State<StatefulWidget> createState() => ContainerCardState();
}

class ContainerCardState extends State<ContainerCard> {
  bool expanded = true;
  double cardHeight = 0;

  @override
  Widget build(BuildContext context) {
    cardHeight = widget.ry.length * 75 + 20 + (widget.ry.length - 1) * 8;

    return Padding(
      padding: EdgeInsets.only(top: widget.index > 1 ? 4 : 8, left: 8, right: 8, bottom: widget.index < widget.total ? 4 : 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            expanded = !expanded;
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
                  height: 52,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.container, style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.normal)),
                            Row(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.all(Radius.circular(6))
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text("${NumberFormat('###,###,##0').format(widget.pairs)} Pairs", style: const TextStyle(color: Colors.white)),
                                  )
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.all(Radius.circular(6))
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text("${NumberFormat('###,###,##0').format(widget.cartons)} Cartons", style: const TextStyle(color: Colors.white)),
                                  )
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.all(Radius.circular(6))
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text("${NumberFormat('###,###,##0.000').format(widget.cbm)} CBM", style: const TextStyle(color: Colors.white)),
                                  )
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      expanded ? const Icon(Icons.keyboard_arrow_up, color: Colors.black54) : const Icon(Icons.keyboard_arrow_down, color: Colors.black54)
                    ],
                  ),
                ),
                Visibility(
                  visible: expanded,
                  child: Column(
                    children: widget.ry,
                  ),
                )
              ],
            ),
          ),
        ),
      )
    );
  }
}