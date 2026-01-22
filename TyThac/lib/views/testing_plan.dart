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
DateTime selectedDate = DateTime.now();
String selectedMonth = DateFormat('yyyy/MM').format(DateTime.now());

class TestingPlan extends StatefulWidget {
  const TestingPlan({super.key});

  @override
  TestingPlanState createState() => TestingPlanState();
}

class TestingPlanState extends State<TestingPlan> {
  String userName = '';
  String group = '';
  List<Widget> leanList = [];
  String loadingStatus = 'isLoading';
  final events = [];
  bool scrollable = true;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '';
    setState(() {
      userName = prefs.getString('userName') ?? '';
      group = prefs.getString('group') ?? '';
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    await loadPlan();
  }

  Future<void> loadPlan() async {
    setState(() {
      loadingStatus = 'isLoading';
    });

    final body = await RemoteService().getTestingPlan(
      apiAddress,
      DateFormat('yyyy/MM/dd').format(selectedDate)
    );
    final jsonData = json.decode(body);

    leanList = [];
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        List<Widget> ryList = [];
        for (int j = 0; j < jsonData[i]['Plan'].length; j++) {
          Color ryColor = Colors.blue;
          ryList.add(
            Padding(
              padding: EdgeInsets.only(top: j == 0 ? 16 : 4, bottom: j < jsonData[i]['Plan'].length - 1 ? 4 : 0),
              child: InkWell(
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
                        color: Colors.grey.withOpacity(0.2),
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
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))
                              ),
                              child: Text(' ${jsonData[i]['Plan'][j]['Seq']}.  ${jsonData[i]['Plan'][j]['AssemblyTime']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                            ),
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
                                  jsonData[i]['Plan'][j]['Country'] != ''
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
                                  : const SizedBox()
                                ],
                              ),
                            ),
                            title: Text(jsonData[i]['Plan'][j]['RY'] + ' [' + jsonData[i]['Plan'][j]['Cycle'] + ']'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(jsonData[i]['Plan'][j]['SKU'] + ' - ' + jsonData[i]['Plan'][j]['Type'] + ' [' + jsonData[i]['Plan'][j]['DieCut'] + '] [' + jsonData[i]['Plan'][j]['Last'] + ']', style: const TextStyle(fontSize: 10)),
                                jsonData[i]['Plan'][j]['Remark'] != '' ? Text(jsonData[i]['Plan'][j]['Remark'], style: const TextStyle(fontSize: 10, color: Colors.red)) : const SizedBox()
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(jsonData[i]['Plan'][j]['CyclePairs'].toString(), style: const TextStyle(fontSize: 14)),
                                      Text('/${jsonData[i]['Plan'][j]['Pairs']}', style: const TextStyle(fontSize: 8)),
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

        leanList.add(
          LeanCard(
            index: i,
            total: jsonData.length-1,
            lean: jsonData[i]['Lean'],
            ry: ryList,
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
            Text(AppLocalizations.of(context)!.sideMenuTestPlan),
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

class LeanCard extends StatefulWidget {
  const LeanCard({
    super.key,
    required this.index,
    required this.total,
    required this.lean,
    required this.ry
  });

  final int index;
  final int total;
  final String lean;
  final List<Widget> ry;

  @override
  State<StatefulWidget> createState() => LeanCardState();
}

class LeanCardState extends State<LeanCard> {
  bool expanded = true;

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