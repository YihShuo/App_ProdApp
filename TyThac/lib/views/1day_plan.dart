import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:production/components/side_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

String apiAddress = '';
double screenWidth = 0, screenHeight = 0;
String sFactory = '', department = '';
DateTime selectedDate = DateTime.now();
String selectedMonth = DateFormat('yyyy/MM').format(DateTime.now());
List<String> factoryDropdownItems = [];
List<DropdownMenuItem<String>> lean = [];
List<List<String>> factoryLeans = [];

class OneDayPlan extends StatefulWidget {
  const OneDayPlan({super.key});

  @override
  OneDayPlanState createState() => OneDayPlanState();
}

class OneDayPlanState extends State<OneDayPlan> {
  String userName = '';
  String group = '';
  List<Widget> leanList = [];
  String loadingStatus = 'isLoading';
  final events = [];
  bool scrollable = true;

  @override
  void initState() {
    super.initState();
    sFactory = '';
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '';
    setState(() {
      userName = prefs.getString('userName') ?? '';
      group = prefs.getString('group') ?? '';
      department = prefs.getString('department') ?? '3F_LINE 01';
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    await loadFilter();
  }

  Future<void> loadFilter() async {
    factoryDropdownItems = [];
    final body = await RemoteService().getFactoryLean(
      apiAddress,
      selectedMonth,
      'CurrentMonth'
    );
    final jsonData = json.decode(body);
    if (!mounted) return;
    for (int i = 0; i < jsonData.length; i++) {
      factoryDropdownItems.add(jsonData[i]['Factory']);
    }
    sFactory = department.split('_')[0];
    if (factoryDropdownItems.contains(sFactory) == false) {
      sFactory = factoryDropdownItems[0];
    }

    loadPlan();
  }

  Future<void> loadPlan() async {
    setState(() {
      loadingStatus = 'isLoading';
    });

    final body = await RemoteService().get1DayPlan(
      apiAddress,
      DateFormat('yyyy/MM/dd').format(selectedDate),
      sFactory
    );
    final jsonData = json.decode(body);

    leanList = [];
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        List<Widget> ryList = [], ryList2 = [];
        int pairs = 0, pairs2 = 0;
        for (int j = 0; j < jsonData[i]['Plan'].length; j++) {
          Color ryColor = jsonData[i]['Plan'][j]['Status'] == "NotDispatched"
          ? Colors.red.shade200
          : Colors.green.shade200;

          if (jsonData[i]['Plan'][j]['Version'] == "Normal") {
            pairs += int.parse(jsonData[i]['Plan'][j]['CyclePairs'].toString());
            ryList.add(
              Padding(
                padding: EdgeInsets.only(top: ryList.isEmpty ? 16 : 4, bottom: 4),
                child: InkWell(
                  onTap: () {
                    if (isNumeric(jsonData[i]['Plan'][j]['BuyNo'].toString().substring(0, 1))) {
                      Navigator.pushNamed(context, '/home/cycle_tracking', arguments: jsonData[i]['Plan'][j]['RY'] + ';A;' + sFactory + '_' + jsonData[i]['Lean'] + ';' + jsonData[i]['Plan'][j]['Cycle']);
                    }
                  },
                  child: Ink(
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
                                height: 20,
                                decoration: BoxDecoration(
                                  color: ryColor,
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4))
                                ),
                                child: Text(' ${jsonData[i]['Plan'][j]['Seq']}.  ${jsonData[i]['Plan'][j]['DeliveryTime']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                              ),
                            ),
                            Container(
                              height: 20,
                              width: 22,
                              decoration: BoxDecoration(
                                color: ryColor,
                                borderRadius: const BorderRadius.only(topRight: Radius.circular(4))
                              ),
                              child: jsonData[i]['Plan'][j]['Status'] == "NotDispatched"
                              ? null
                              : Icon(Icons.check_circle_outline, color: darken(ryColor, 0.5), size: 18),
                            )
                          ],
                        ),
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            ListTile(
                              leading: SizedBox(
                                width: 40,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AutoSizeText(jsonData[i]['Plan'][j]['BuyNo'], minFontSize: 1, maxFontSize: 10, maxLines: 1),
                                    Text(jsonData[i]['Plan'][j]['ShipDate']),
                                    /*jsonData[i]['Plan'][j]['Country'] != ''
                                    ? Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.all(Radius.circular(4))
                                        ),
                                        child: AutoSizeText(
                                          ' ${jsonData[i]['Plan'][j]['Country']} ',
                                          minFontSize: 1,
                                          maxFontSize: 10,
                                          maxLines: 1,
                                          style: const TextStyle(color: Colors.white)
                                        ),
                                    )
                                    : const SizedBox()*/
                                  ],
                                ),
                              ),
                              title: Text(jsonData[i]['Plan'][j]['RY'] + (jsonData[i]['Plan'][j]['Cycle'] != '' ? ' [${jsonData[i]['Plan'][j]['Cycle']}]' : '')),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(jsonData[i]['Plan'][j]['SKU'], style: const TextStyle(fontSize: 10)),
                                  Text(jsonData[i]['Plan'][j]['DieCut'], style: const TextStyle(fontSize: 10)),
                                  Text(jsonData[i]['Plan'][j]['Last'], style: const TextStyle(fontSize: 10)),
                                  jsonData[i]['Plan'][j]['Remark'] != '' ? SizedBox(height: 18, child: Text(jsonData[i]['Plan'][j]['Remark'], style: const TextStyle(fontSize: 10, color: Colors.red))) : const SizedBox()
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 64,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        jsonData[i]['Plan'][j]['CyclePairs'] > 0 ? Text(NumberFormat('###,###,##0').format(jsonData[i]['Plan'][j]['CyclePairs']), style: const TextStyle(fontSize: 14)) : const SizedBox(),
                                        jsonData[i]['Plan'][j]['Pairs'] > 0 ? Text('/${NumberFormat('###,###,##0').format(jsonData[i]['Plan'][j]['Pairs'])}', style: const TextStyle(fontSize: 8)) : const SizedBox(),
                                      ],
                                    ),
                                  ),
                                  Text(jsonData[i]['Plan'][j]['TotalCycle'])
                                ],
                              ),
                              contentPadding: const EdgeInsets.only(left: 4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            );
          }
          else {
            pairs2 += int.parse(jsonData[i]['Plan'][j]['CyclePairs'].toString());
            ryList2.add(
              Padding(
                padding: EdgeInsets.only(top: ryList2.isEmpty ? 16 : 4, bottom: 4),
                child: InkWell(
                  onTap: () {
                    if (isNumeric(jsonData[i]['Plan'][j]['BuyNo'].toString().substring(0, 1))) {
                      Navigator.pushNamed(context, '/home/cycle_tracking', arguments: jsonData[i]['Plan'][j]['RY'] + ';A;' + sFactory + '_' + jsonData[i]['Lean'] + ';' + jsonData[i]['Plan'][j]['Cycle']);
                    }
                  },
                  child: Ink(
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
                                height: 20,
                                decoration: BoxDecoration(
                                  color: ryColor,
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4))
                                ),
                                child: Text(' ${jsonData[i]['Plan'][j]['Seq']}.  ${jsonData[i]['Plan'][j]['AssemblyTime']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                              ),
                            ),
                            Container(
                              height: 20,
                              width: 22,
                              decoration: BoxDecoration(
                                color: ryColor,
                                borderRadius: const BorderRadius.only(topRight: Radius.circular(4))
                              ),
                              child: jsonData[i]['Plan'][j]['Status'] == "NotDispatched"
                              ? null
                              : Icon(Icons.check_circle_outline, color: darken(ryColor, 0.5), size: 18),
                            )
                          ],
                        ),
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            ListTile(
                              leading: SizedBox(
                                width: 40,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AutoSizeText(jsonData[i]['Plan'][j]['BuyNo'], minFontSize: 1, maxFontSize: 10, maxLines: 1),
                                    Text(jsonData[i]['Plan'][j]['ShipDate']),
                                    /*jsonData[i]['Plan'][j]['Country'] != ''
                                    ? Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.all(Radius.circular(4))
                                      ),
                                      child: AutoSizeText(
                                        ' ${jsonData[i]['Plan'][j]['Country']} ',
                                        minFontSize: 1,
                                        maxFontSize: 10,
                                        maxLines: 1,
                                        style: const TextStyle(color: Colors.white)
                                      ),
                                    )
                                    : const SizedBox()*/
                                  ],
                                ),
                              ),
                              title: Text(jsonData[i]['Plan'][j]['RY'] + (jsonData[i]['Plan'][j]['Cycle'] != '' ? ' [${jsonData[i]['Plan'][j]['Cycle']}]' : '')),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(jsonData[i]['Plan'][j]['SKU'], style: const TextStyle(fontSize: 10)),
                                  Text(jsonData[i]['Plan'][j]['DieCut'], style: const TextStyle(fontSize: 10)),
                                  Text(jsonData[i]['Plan'][j]['Last'], style: const TextStyle(fontSize: 10)),
                                  jsonData[i]['Plan'][j]['Remark'] != '' ? SizedBox(height: 18, child: Text(jsonData[i]['Plan'][j]['Remark'], style: const TextStyle(fontSize: 10, color: Colors.red))) : const SizedBox(height: 18)
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 64,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        jsonData[i]['Plan'][j]['CyclePairs'] > 0 ? Text(NumberFormat('###,###,##0').format(jsonData[i]['Plan'][j]['CyclePairs']), style: const TextStyle(fontSize: 14)) : const SizedBox(),
                                        jsonData[i]['Plan'][j]['Pairs'] > 0 ? Text('/${NumberFormat('###,###,##0').format(jsonData[i]['Plan'][j]['Pairs'])}', style: const TextStyle(fontSize: 8)) : const SizedBox(),
                                      ],
                                    ),
                                  ),
                                  Text(jsonData[i]['Plan'][j]['TotalCycle'])
                                ],
                              ),
                              contentPadding: const EdgeInsets.only(left: 4),
                            ),
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

        leanList.add(
          LeanCard(
            index: i,
            total: jsonData.length-1,
            lean: jsonData[i]['Lean'],
            pairs: NumberFormat('###,###,##0').format(pairs),
            ry: ryList,
            pairs2: NumberFormat('###,###,##0').format(pairs2),
            ry2: ryList2
          )
        );
      }

      setState(() {
        leanList = leanList;
        loadingStatus = 'Completed';
      });
    }
    else {
      setState(() {
        loadingStatus = 'No Data';
      });
    }
  }

  bool isNumeric(String s) {
    return int.tryParse(s) != null;
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
            Text('$sFactory ${AppLocalizations.of(context)!.sideMenu1DayPlan}'),
            Text(DateFormat('yyyy/MM/dd').format(selectedDate), style: const TextStyle(fontSize: 14))
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
                    refresh: loadPlan,
                  );
                },
              );
            },
          ),
        ]
      ),
      drawer: SideMenu(userName: userName, group: group),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
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
                  ? leanList
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
      )
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
                            final body = await RemoteService().getFactoryLean(
                              apiAddress,
                              DateFormat('yyyy/MM').format(selectedDate),
                              'CurrentMonth'
                            );
                            final jsonData = json.decode(body);
                            if (jsonData.length > 0) {
                              factoryDropdownItems = [];
                              for (int i = 0; i < jsonData.length; i++) {
                                factoryDropdownItems.add(jsonData[i]['Factory']);
                              }
                            }

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
                                final body = await RemoteService().getFactoryLean(
                                  apiAddress,
                                  DateFormat('yyyy/MM').format(selectedDate),
                                  'CurrentMonth'
                                );
                                final jsonData = json.decode(body);
                                if (jsonData.length > 0) {
                                  factoryDropdownItems = [];
                                  for (int i = 0; i < jsonData.length; i++) {
                                    factoryDropdownItems.add(jsonData[i]['Factory']);
                                  }
                                }

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
            value: sFactory,
            items: factoryDropdownItems.map((String factory) {
              if (factory != 'ALL') {
                return DropdownMenuItem(
                  value: factory,
                  child: Center(
                    child: Text(factory.toString()),
                  )
                );
              }
              else {
                return DropdownMenuItem(
                  value: 'ALL',
                  child: Center(
                    child: Text(AppLocalizations.of(context)!.all),
                  )
                );
              }
            }).toList(),
            onChanged: (value) {
              setState(() {
                sFactory = value!;
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

class LeanCard extends StatefulWidget {
  const LeanCard({
    super.key,
    required this.index,
    required this.total,
    required this.lean,
    required this.pairs,
    required this.ry,
    required this.pairs2,
    required this.ry2
  });

  final int index;
  final int total;
  final String lean;
  final String pairs;
  final List<Widget> ry;
  final String pairs2;
  final List<Widget> ry2;

  @override
  State<StatefulWidget> createState() => LeanCardState();
}

class LeanCardState extends State<LeanCard> {
  bool expanded = true;
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: widget.index > 0 ? 4 : 8, left: 8, right: 8, bottom: widget.index < widget.total ? 4 : 8),
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
                  height: 40,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(widget.lean, style: const TextStyle(fontSize: 26, color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      const Expanded(child: SizedBox()),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.all(Radius.circular(8))
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: index == 0
                          ? Text(widget.pairs, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold))
                          : Text(widget.pairs2, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ),
                      const SizedBox(width: 16),
                      expanded ? const Icon(Icons.keyboard_arrow_up, color: Colors.black54) : const Icon(Icons.keyboard_arrow_down, color: Colors.black54)
                    ],
                  ),
                ),
                Visibility(
                  visible: expanded,
                  child: widget.ry2.isNotEmpty
                  ? DefaultTabController(
                    initialIndex: index,
                    animationDuration: Duration.zero,
                    length: 2,
                    child: Builder(builder: (BuildContext context) {
                      final TabController tabController = DefaultTabController.of(context);
                      tabController.addListener(() {
                        if (!tabController.indexIsChanging) {
                          setState(() {
                            index = tabController.index;
                          });
                        }
                      });

                      return Column(
                        children: [
                          TabBar(
                            labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            indicatorColor: Colors.blue,
                            tabs: [
                              SizedBox(
                                height: 22,
                                child: Tab(text: AppLocalizations.of(context)!.originalPlan)
                              ),
                              SizedBox(
                                height: 22,
                                child: Tab(text: AppLocalizations.of(context)!.extraPlan)
                              ),
                            ]
                          ),
                          SizedBox(
                            height: index == 0
                            ? widget.ry.length * 91 + 20 + (widget.ry.length - 1) * 8
                            : widget.ry2.length * 91 + 20 + (widget.ry2.length - 1) * 8,
                            child: TabBarView(
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                Column(
                                  children: widget.ry,
                                ),
                                Column(
                                  children: widget.ry2,
                                )
                              ]
                            ),
                          ),
                        ],
                      );
                    })
                  )
                  : Column(
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