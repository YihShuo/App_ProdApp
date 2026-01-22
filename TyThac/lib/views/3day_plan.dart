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

class ThreeDayPlan extends StatefulWidget {
  const ThreeDayPlan({super.key});

  @override
  ThreeDayPlanState createState() => ThreeDayPlanState();
}

class ThreeDayPlanState extends State<ThreeDayPlan> {
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

    loadModelStandard();
  }

  Future<void> loadModelStandard() async {
    setState(() {
      loadingStatus = 'isLoading';
    });

    final body = await RemoteService().get3DayPlan(
      apiAddress,
      DateFormat('yyyy/MM/dd').format(selectedDate),
      sFactory
    );
    final jsonData = json.decode(body);

    leanList = [];
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        List<Widget> ryList = [], ryList2 = [];
        for (int j = 0; j < jsonData[i]['Plan'].length; j++) {
          if (jsonData[i]['Plan'][j]['Version'] == "Normal") {
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
                  child: ListTile(
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
                    title: Text('${jsonData[i]['Plan'][j]['RY']} [${jsonData[i]['Plan'][j]['Cycle']}]'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(jsonData[i]['Plan'][j]['SKU'], style: const TextStyle(fontSize: 10)),
                        Text(jsonData[i]['Plan'][j]['DieCut'], style: const TextStyle(fontSize: 10)),
                        jsonData[i]['Plan'][j]['Remark'] != '' ? SizedBox(height: 18, child: Text(jsonData[i]['Plan'][j]['Remark'], style: const TextStyle(fontSize: 10, color: Colors.red))) : const SizedBox()
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(NumberFormat('###,###,##0').format(jsonData[i]['Plan'][j]['Pairs']), style: const TextStyle(fontSize: 14)),
                        Text(jsonData[i]['Plan'][j]['TotalCycle'])
                      ],
                    ),
                    contentPadding: const EdgeInsets.only(left: 4, right: 8),
                  ),
                ),
              )
            );
          }
          else {
            ryList2.add(
              Padding(
                padding: EdgeInsets.only(top: ryList2.isEmpty ? 16 : 4, bottom: 4),
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
                  child: ListTile(
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
                    title: Text('${jsonData[i]['Plan'][j]['RY']} [${jsonData[i]['Plan'][j]['Cycle']}]'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${jsonData[i]['Plan'][j]['SKU']} - ${jsonData[i]['Plan'][j]['Type']} [${jsonData[i]['Plan'][j]['DieCut']}]', style: const TextStyle(fontSize: 10)),
                        jsonData[i]['Plan'][j]['Remark'] != '' ? SizedBox(height: 18, child: Text(jsonData[i]['Plan'][j]['Remark'], style: const TextStyle(fontSize: 10, color: Colors.red))) : const SizedBox()
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(NumberFormat('###,###,##0').format(jsonData[i]['Plan'][j]['Pairs']), style: const TextStyle(fontSize: 14)),
                        Text(jsonData[i]['Plan'][j]['TotalCycle'])
                      ],
                    ),
                    contentPadding: const EdgeInsets.only(left: 4, right: 8),
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
            ry: ryList,
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
            Text('$sFactory ${AppLocalizations.of(context)!.sideMenu3DayPlan}'),
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
                    refresh: loadModelStandard,
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
                              'CurrentMonthWithoutPM'
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
                                  'CurrentMonthWithoutPM'
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
    required this.ry,
    required this.ry2
  });

  final int index;
  final int total;
  final String lean;
  final List<Widget> ry;
  final List<Widget> ry2;

  @override
  State<StatefulWidget> createState() => LeanCardState();
}

class LeanCardState extends State<LeanCard> {
  bool expanded = true;
  double cardHeight = 0;

  @override
  Widget build(BuildContext context) {
    cardHeight = widget.ry.length > widget.ry2.length
    ? widget.ry.length * 75 + 20 + (widget.ry.length - 1) * 8
    : widget.ry2.length * 75 + 20 + (widget.ry2.length - 1) * 8;

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
                      expanded ? const Icon(Icons.keyboard_arrow_up, color: Colors.black54) : const Icon(Icons.keyboard_arrow_down, color: Colors.black54)
                    ],
                  ),
                ),
                Visibility(
                  visible: expanded,
                  child: widget.ry2.isNotEmpty
                  ? DefaultTabController(
                    animationDuration: Duration.zero,
                    length: 2,
                    child: Column(
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
                          height: cardHeight,
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
                    ),
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