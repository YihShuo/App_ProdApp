import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:production/components/side_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

String apiAddress = '';
double screenWidth = 0, screenHeight = 0;
String sFactory = '', sStatus = 'All', department = '';
DateTime selectedDate = DateTime.now().add(Duration(days: DateTime.saturday - DateTime.now().weekday + 7));
List<String> factoryDropdownItems = [];
List<DropdownMenuItem<String>> lean = [];
List<List<String>> factoryLeans = [];

class ShipmentTracking extends StatefulWidget {
  const ShipmentTracking({super.key});

  @override
  ShipmentTrackingState createState() => ShipmentTrackingState();
}

class ShipmentTrackingState extends State<ShipmentTracking> {
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
      department = prefs.getString('department') ?? 'A02_LEAN01';
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
      DateFormat('yyyy/MM').format(selectedDate),
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

    final body = await RemoteService().getShipmentTrackingData(
      apiAddress,
      DateFormat('yyyy/MM/dd').format(selectedDate),
      sFactory,
      sStatus
    );
    final jsonData = json.decode(body);

    leanList = [];
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        List<Widget> ryList = [];
        int pairs = 0, totalShortage = 0;
        for (int j = 0; j < jsonData[i]['Data'].length; j++) {
          int shortage = jsonData[i]['Data'][j]['CompletedPairs'] - jsonData[i]['Data'][j]['Pairs'];
          Color ryColor = shortage < 0
          ? Colors.red.shade200
          : Colors.green.shade200;

          pairs += int.parse(jsonData[i]['Data'][j]['Pairs'].toString());
          totalShortage += shortage;
          ryList.add(
            Padding(
              padding: EdgeInsets.only(top: ryList.isEmpty ? 16 : 8),
              child: InkWell(
                onTap: () {},
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
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: ryColor,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      const Text('[', style: TextStyle(fontSize: 18, color: Colors.black)),
                                      jsonData[i]['Data'][j]['Type'] == 'Estimate'
                                      ? const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 2),
                                        child: FaIcon(FontAwesomeIcons.star, size: 10),
                                      )
                                      : const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 2),
                                        child: FaIcon(FontAwesomeIcons.solidStar, size: 10,),
                                      ),
                                      Text(jsonData[i]['Data'][j]['ExFactoryDate'], style: const TextStyle(fontSize: 18, color: Colors.black)),
                                      const Text('] ', style: TextStyle(fontSize: 18, color: Colors.black)),
                                      Text(jsonData[i]['Data'][j]['RY'], style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                ),
                              ),
                            ),
                            shortage < 0
                            ? Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(NumberFormat('###,###,##0').format(shortage), style: const TextStyle(color: Color.fromRGBO(130, 0, 0, 1), fontWeight: FontWeight.bold, fontSize: 18),),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4, top: 3),
                                    child: Text('Pairs', style: TextStyle(color: Color.fromRGBO(130, 0, 0, 1), fontSize: 12),),
                                  )
                                ],
                              ),
                            )
                            : Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(Icons.check_circle_outline, color: darken(ryColor, 0.5), size: 18),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${AppLocalizations.of(context)!.scheduleBUY}${jsonData[i]['Data'][j]['BUY']}', style: const TextStyle(fontSize: 12),),
                                  Text('${AppLocalizations.of(context)!.cuttingDie}：${jsonData[i]['Data'][j]['CuttingDie']}', style: const TextStyle(fontSize: 12)),
                                  Text('${AppLocalizations.of(context)!.sku}：${jsonData[i]['Data'][j]['SKU']}', style: const TextStyle(fontSize: 12)),
                                  Text('${AppLocalizations.of(context)!.assembly}：${jsonData[i]['Data'][j]['PlanDate']}', style: const TextStyle(fontSize: 12)),
                                  Text('${AppLocalizations.of(context)!.shippingDate}：${jsonData[i]['Data'][j]['ShipDate']}', style: const TextStyle(fontSize: 12)),
                                  Text('${AppLocalizations.of(context)!.country}：${jsonData[i]['Data'][j]['Country']}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(NumberFormat('###,###,##0').format(jsonData[i]['Data'][j]['CompletedPairs']), style: const TextStyle(fontSize: 22)),
                                      Text('/${NumberFormat('###,###,##0').format(jsonData[i]['Data'][j]['Pairs'])}', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
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

        leanList.add(
          LeanCard(
            index: i,
            total: jsonData.length-1,
            lean: jsonData[i]['Lean'],
            pairs: NumberFormat('###,###,##0').format(pairs),
            shortage: totalShortage < 0 ? NumberFormat('###,###,##0').format(totalShortage) : '',
            completionRate: '${NumberFormat('##0').format((pairs + totalShortage) * 100.0 / pairs)}%',
            ry: ryList
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
            Text('$sFactory ${AppLocalizations.of(context)!.shipmentTracking}'),
            Text('${AppLocalizations.of(context)!.asOf} ${DateFormat('yyyy/MM/dd').format(selectedDate)}', style: const TextStyle(fontSize: 14))
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
      ),
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
            child: Text('${AppLocalizations.of(context)!.asOf}：')
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
                          minDate: DateTime.now(),
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
                              minDate: DateTime.now(),
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
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${AppLocalizations.of(context)!.status}：')
          ),
          DropdownButton(
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Colors.grey,
            ),
            value: sStatus,
            items: [
              DropdownMenuItem(
                value: 'All',
                child: Center(
                  child: Text(AppLocalizations.of(context)!.all),
                )
              ),
              DropdownMenuItem(
                value: 'NotFinished',
                child: Center(
                  child: Text(AppLocalizations.of(context)!.notCompleted),
                )
              )
            ],
            onChanged: (value) {
              setState(() {
                sStatus = value!;
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
    required this.shortage,
    required this.completionRate,
    required this.ry
  });

  final int index;
  final int total;
  final String lean;
  final String pairs;
  final String shortage;
  final String completionRate;
  final List<Widget> ry;

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
                      Visibility(
                        visible: widget.shortage == '',
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade200,
                            borderRadius: const BorderRadius.all(Radius.circular(8))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(widget.pairs, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(0, 100, 0, 1), fontWeight: FontWeight.bold, height: 1)),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('${widget.completionRate} Completed', style: const TextStyle(fontSize: 8, color: Color.fromRGBO(0, 100, 0, 1), height: 1),),
                                )
                              ],
                            )
                          )
                        ),
                      ),
                      Visibility(
                        visible: widget.shortage != '',
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade200,
                            borderRadius: const BorderRadius.all(Radius.circular(8))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(widget.shortage, style: const TextStyle(fontSize: 18, color: Color.fromRGBO(130, 0, 0, 1), fontWeight: FontWeight.bold, height: 1)),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('${widget.completionRate} Completed', style: const TextStyle(fontSize: 8, color: Color.fromRGBO(130, 0, 0, 1), height: 1),),
                                )
                              ],
                            )
                          )
                        ),
                      ),
                      const SizedBox(width: 6),
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