import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/components/side_menu.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:crypto/crypto.dart';

String apiAddress = '';
DateTime selectedDate = DateTime.now();
String selectedMonth = DateFormat('yyyy/MM').format(DateTime.now());
String sFactory = '';
List<String> factoryDropdownItems = [];
List<Widget> leanTab = [];
List<List<String>> factoryLeans = [];
bool loadSuccess = false;

class Schedule extends StatefulWidget {
  const Schedule({super.key});

  @override
  ScheduleState createState() => ScheduleState();
}

class ScheduleState extends State<Schedule> with TickerProviderStateMixin {
  String userName = '';
  String group = '';
  List<String> tab = [];
  List<Widget> tableColumnTitles = [];
  List<List<String>> tableFirstRow = [];
  List<List<List<Widget>>> tableContentRows = [];
  List<Widget> schedules = [];
  double cardHeight = 225.0, cardWidth = 180.0;
  dynamic futureTab;

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
      'MasterLean'
    );
    final jsonData = json.decode(body);
    for (int i = 0; i < jsonData.length; i++) {
      factoryDropdownItems.add(jsonData[i]['Factory']);
    }
    setState(() {
      futureTab = loadSchedule();
    });
  }

  Future<bool> loadSchedule() async {
    setState(() {
      loadSuccess = false;
    });

    factoryLeans = [];
    final body = await RemoteService().getFactoryLean(
      apiAddress,
      selectedMonth,
      'CurrentMonth'
    );
    final jsonData = json.decode(body);
    for (int i = 0; i < jsonData.length; i++) {
      List<String> leans = [];
      for (int j = 0; j < jsonData[i]['Lean'].length; j++) {
        leans.add(jsonData[i]['Lean'][j]);
      }
      factoryLeans.add(leans);
    }

    leanTab = [];
    schedules = [];
    if (sFactory == '') {
      final prefs = await SharedPreferences.getInstance();
      sFactory = prefs.getString('department')?.split('_')[0] ?? '3F';
      if (factoryDropdownItems.contains(sFactory) == false) {
        sFactory = factoryDropdownItems[0];
      }
    }

    for (int i = 0; i < factoryLeans[factoryDropdownItems.indexOf(sFactory)].length; i++) {
      leanTab.add(
        Tab(
          child: SizedBox(
            width: getTextSize(factoryLeans[factoryDropdownItems.indexOf(sFactory)][i], const TextStyle(fontSize: 16, height: 1.4)).width + 50,
            child: Align(
              alignment: Alignment.center,
              child: Text(factoryLeans[factoryDropdownItems.indexOf(sFactory)][i], style: const TextStyle(fontSize: 16, height: 1.4))
            )
          )
        )
      );
    }

    try {
      final body = await RemoteService().getScheduleData(
        apiAddress,
        selectedMonth,
        sFactory
      );
      final jsonBody = json.decode(body);
      DateTime firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
      DateTime lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
      tableColumnTitles = [];
      tableFirstRow = [];
      tableContentRows = [];

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

      for (int i = 0; i < factoryLeans[factoryDropdownItems.indexOf(sFactory)].length; i++) {
        int index = -1;
        for (int j = 0; j < jsonBody.length; j++) {
          if (jsonBody[j]['Lean'].toString() == '$sFactory ${factoryLeans[factoryDropdownItems.indexOf(sFactory)][i]}') {
            index = j;
          }
        }
        if (index >= 0) {
          List<String> firstRow = [];
          List<List<Widget>> contentRows = [];
          List<int> holidays = jsonBody[index]['Holiday'].cast<int>();

          for (int j = 0; j < jsonBody[index]['Sequence'].length; j++) {
            firstRow.add((j + 1).toString());
            List<Widget> orders = [];
            DateTime tempDate = firstDayOfMonth;
            for (int k = 0; k < jsonBody[index]['Sequence'][j]['Schedule'].length; k++) {
              DateTime orderDate = DateFormat('yyyy/MM/dd').parse(jsonBody[index]['Sequence'][j]['Schedule'][k]['Date'].toString());
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

              String dieCut = jsonBody[index]['Sequence'][j]['Schedule'][k]['DieCutMold'].toString().replaceAll('LY-', '');
              String order = jsonBody[index]['Sequence'][j]['Schedule'][k]['Order'];
              String subTitle = jsonBody[index]['Sequence'][j]['Schedule'][k]['SubTitle'];
              String material = jsonBody[index]['Sequence'][j]['Schedule'][k]['Material'];
              String last = jsonBody[index]['Sequence'][j]['Schedule'][k]['LastMold'];
              String buy = jsonBody[index]['Sequence'][j]['Schedule'][k]['BuyNo'];
              String sku = jsonBody[index]['Sequence'][j]['Schedule'][k]['SKU'];
              String pairs = jsonBody[index]['Sequence'][j]['Schedule'][k]['Pairs'].toString();
              String gac = jsonBody[index]['Sequence'][j]['Schedule'][k]['ShipDate'];
              String country = jsonBody[index]['Sequence'][j]['Schedule'][k]['Country'];

              orders.add(
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        width: cardWidth - 8,
                        height: cardHeight - 8,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(5)),
                          color: textToColor(jsonBody[index]['Sequence'][j]['Schedule'][k]['DieCutMold'].toString(), 0.6)
                        )
                      )
                    ),
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: Card(
                        elevation: 0,
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  scrollable: true,
                                  title: Text(AppLocalizations.of(context)!.scheduleDetailTitle),
                                  content: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${AppLocalizations.of(context)!.dieCut}：$dieCut'),
                                      Text(AppLocalizations.of(context)!.scheduleOrder + order + (subTitle != '' ? ' ($subTitle)' : '')),
                                      Text(AppLocalizations.of(context)!.scheduleMaterial + material),
                                      Text(AppLocalizations.of(context)!.scheduleLast + last),
                                      Text(AppLocalizations.of(context)!.scheduleBUY + buy),
                                      Text(AppLocalizations.of(context)!.scheduleSKU + sku),
                                      Text('${AppLocalizations.of(context)!.pairs}：$pairs'),
                                      Text(AppLocalizations.of(context)!.scheduleShipDate + gac),
                                      Text(AppLocalizations.of(context)!.scheduleCountry + country)
                                    ],
                                  )
                                );
                              },
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${AppLocalizations.of(context)!.dieCut}：$dieCut', strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                                Text(AppLocalizations.of(context)!.scheduleOrder + order + (subTitle != '' ? '($subTitle)' : ''), strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                                Text(AppLocalizations.of(context)!.scheduleMaterial + material, strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                                Text(AppLocalizations.of(context)!.scheduleLast + last, strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                                Text(AppLocalizations.of(context)!.scheduleBUY + buy, strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                                Text(AppLocalizations.of(context)!.scheduleSKU + sku, strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                                Text('${AppLocalizations.of(context)!.pairs}：$pairs', strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                                Text(AppLocalizations.of(context)!.scheduleShipDate + gac, strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                                Text(AppLocalizations.of(context)!.scheduleCountry + country, strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis)
                              ]
                            ),
                          ),
                        ),
                      )
                    ),
                  ],
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
            contentRows.add(orders);
          }
          tableFirstRow.add(firstRow);
          tableContentRows.add(contentRows);

          schedules.add(
            HorizontalDataTable(
              leftHandSideColumnWidth: 60,
              rightHandSideColumnWidth: cardWidth * (tableColumnTitles.length - 1),
              isFixedHeader: true,
              headerWidgets: tableColumnTitles,
              leftSideItemBuilder: (BuildContext context, int index2) {
                return SizedBox(
                  height: cardHeight,
                  child: Center(child: Text(tableFirstRow[index][index2], style: const TextStyle(fontSize: 20)))
                );
              },
              rightSideItemBuilder: (BuildContext context, int index2) {
                List<Widget> cells = [];
                for (int j = 0; j < tableContentRows[index][index2].length; j++) {
                  cells.add(tableContentRows[index][index2][j]);
                }
                return Row(
                  children: cells
                );
              },
              itemCount: tableFirstRow[index].length,
              rowSeparatorWidget: const Divider(
                color: Color(0xFFCCCCCC),
                height: 1.0,
                thickness: 0.0,
              ),
              leftHandSideColBackgroundColor: const Color(0xFFFFFFFF),
              rightHandSideColBackgroundColor: const Color(0xFFFFFFFF),
            ),
          );
        }
        else {
          schedules.add(
            Center(child: Text(AppLocalizations.of(context)!.scheduleNoOrder))
          );
        }
      }
      setState(() {
        loadSuccess = true;
      });
      return true;
    } catch (ex) {
      setState(() {
        loadSuccess = true;
      });
      return false;
    }
  }

  void reloadSchedule() {
    futureTab = loadSchedule();
  }

  Color textToColor(String text, double factor) {
    var bytes = utf8.encode(text);
    var digest = sha256.convert(bytes);
    var hash = digest.toString();
    Color color;
    if (hash.length >= 6) {
      color = Color(int.parse('0xFF${hash.substring(hash.length - 6)}'));
    }
    else {
      color = Color(int.parse('0xFF$hash'));
    }
    int r = (color.r * 255).toInt();
    int g = (color.g * 255).toInt();
    int b = (color.b * 255).toInt();
    return Color.fromRGBO(
      (r + (255 - r) * factor).round(),
      (g + (255 - g) * factor).round(),
      (b + (255 - b) * factor).round(),
      1
    );
  }

  Size getTextSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style), maxLines: 1, textDirection: ui.TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureTab,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || loadSuccess == false || schedules.length != leanTab.length) {
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
              title: Text('$sFactory ${AppLocalizations.of(context)!.scheduleTitle}')
            ),
            drawer: SideMenu(
              userName: userName,
              group: group,
            ),
            body: const Center(
              child: CircularProgressIndicator(color: Colors.blue)
            )
          );
        }
        else if (snapshot.hasError) {
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
              title: Text('$sFactory ${AppLocalizations.of(context)!.scheduleTitle}')
            ),
            drawer: SideMenu(
              userName: userName,
              group: group,
            ),
            body: Center(
              child: Text('Error: ${snapshot.error}')
            )
          );
        }
        else {
          return DefaultTabController(
            length: leanTab.length,
            child: Scaffold(
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
                title: Text('$sFactory ${AppLocalizations.of(context)!.scheduleTitle}'),
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
                            refresh: reloadSchedule,
                          );
                        },
                      );
                    },
                  ),
                ],
                bottom: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelPadding: EdgeInsets.zero,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white,
                  indicator: const BoxDecoration(
                    color: Colors.white,
                  ),
                  tabs: leanTab,
                )
              ),
              drawer: SideMenu(
                userName: userName,
                group: group,
              ),
              body: TabBarView(
                children: schedules
              )
            )
          );
        }
      }
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
                    factoryDropdownItems = [];
                    final body = await RemoteService().getFactoryLean(
                      apiAddress,
                      DateFormat('yyyy/MM').format(date),
                      'CurrentMonth'
                    );
                    final jsonData = json.decode(body);
                    for (int i = 0; i < jsonData.length; i++) {
                      factoryDropdownItems.add(jsonData[i]['Factory']);
                    }

                    setState(() {
                      selectedDate = date;
                      dateController.text = DateFormat('yyyy/MM').format(selectedDate);
                      selectedMonth = dateController.text;
                      factoryDropdownItems = factoryDropdownItems;
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
                        factoryDropdownItems = [];
                        final body = await RemoteService().getFactoryLean(
                          apiAddress,
                          DateFormat('yyyy/MM').format(date),
                          'CurrentMonth'
                        );
                        final jsonData = json.decode(body);
                        for (int i = 0; i < jsonData.length; i++) {
                          factoryDropdownItems.add(jsonData[i]['Factory']);
                        }

                        setState(() {
                          selectedDate = date;
                          dateController.text = DateFormat('yyyy/MM').format(selectedDate);
                          selectedMonth = dateController.text;
                          factoryDropdownItems = factoryDropdownItems;
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
            child: Text('${AppLocalizations.of(context)!.floor}：')
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

