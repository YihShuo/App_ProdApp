import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:production/components/side_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';

String apiAddress = '';
double screenWidth = 0, screenHeight = 0;
String sFactory = '', department = '';
DateTime selectedDate = DateTime.now();
String selectedMonth = DateFormat('yyyy/MM').format(DateTime.now());
List<String> factoryDropdownItems = [];
List<DropdownMenuItem<String>> lean = [];
List<List<String>> factoryLeans = [];

class CapacityStandard extends StatefulWidget {
  const CapacityStandard({super.key});

  @override
  CapacityStandardState createState() => CapacityStandardState();
}

class CapacityStandardState extends State<CapacityStandard> {
  String userName = '';
  String group = '';
  List<Widget> leanList = [];
  String loadingStatus = 'isLoading';

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
      selectedMonth,
      'CurrentMonthWithoutPM'
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

    final body = await RemoteService().getModelStandard(
      apiAddress,
      selectedMonth,
      sFactory
    );
    final jsonData = json.decode(body);

    leanList = [];
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        List<Widget> models = [];
        for (int j = 0; j < jsonData[i]['Models'].length; j++) {
          Color statusColor = jsonData[i]['Models'][j]['Target'].toInt() >= jsonData[i]['Models'][j]['Standard'].toInt() ? Colors.blue : Colors.red;
          models.add(
            ListTile(
              horizontalTitleGap: 0,
              iconColor: darken(statusColor, 0.2),
              leading: const Icon(Icons.fiber_manual_record, size: 8),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${jsonData[i]['Models'][j]['SKU']} [${jsonData[i]['Models'][j]['DieCut']}]', style: TextStyle(fontSize: 16, color: darken(statusColor, 0.2))),
                        Text('[${AppLocalizations.of(context)!.cutting.substring(0, 1)}] ${jsonData[i]['Models'][j]['Labor_C']},  [${AppLocalizations.of(context)!.stitching.substring(0, 1)}] ${jsonData[i]['Models'][j]['Labor_S']},  [${AppLocalizations.of(context)!.assembly.substring(0, 1)}] ${jsonData[i]['Models'][j]['Labor_A']},  [${AppLocalizations.of(context)!.packing.substring(0, 1)}] ${jsonData[i]['Models'][j]['Labor_P']},  [${AppLocalizations.of(context)!.indirect.substring(0, 1)}] ${jsonData[i]['Models'][j]['Labor_Indirect']}', style: TextStyle(fontSize: 12, color: lighten(statusColor, 0.1)))
                      ],
                    )
                  ),
                  Text(
                    jsonData[i]['Models'][j]['Target'].toString(),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: statusColor,
                      shadows: [
                        Shadow(
                          color: darken(statusColor, 0.3),
                          offset: const Offset(1, 1),
                        ),
                      ]
                    )
                  ),
                  SizedBox(
                    height: 36,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(' / ${jsonData[i]['Models'][j]['Standard'].toString()}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          );
        }

        leanList.add(
          LeanCard(
            index: i,
            total: jsonData.length-1,
            lean: jsonData[i]['Lean'],
            models: models,
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

  Color darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  Color lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
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
            Text(AppLocalizations.of(context)!.sideMenuCapacityStandard),
            Text('$sFactory - $selectedMonth', style: const TextStyle(fontSize: 16))
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
                    )
                  )
                ).then((date) async {
                  if (date != null) {
                    final body = await RemoteService().getFactoryLean(
                      apiAddress,
                      DateFormat('yyyy/MM').format(date),
                      'CurrentMonthWithoutPM'
                    );
                    final jsonData = json.decode(body);
                    if (jsonData.length > 0) {
                      factoryDropdownItems = [];
                      for (int i = 0; i < jsonData.length; i++) {
                        factoryDropdownItems.add(jsonData[i]['Factory']);
                      }
                    }

                    setState(() {
                      selectedDate = date;
                      dateController.text = DateFormat('yyyy/MM').format(selectedDate);
                      selectedMonth = dateController.text;
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
                        )
                      )
                    ).then((date) async {
                      if (date != null) {
                        final body = await RemoteService().getFactoryLean(
                          apiAddress,
                          DateFormat('yyyy/MM').format(date),
                          'CurrentMonthWithoutPM'
                        );
                        final jsonData = json.decode(body);
                        if (jsonData.length > 0) {
                          factoryDropdownItems = [];
                          for (int i = 0; i < jsonData.length; i++) {
                            factoryDropdownItems.add(jsonData[i]['Factory']);
                          }
                        }

                        setState(() {
                          selectedDate = date;
                          dateController.text = DateFormat('yyyy/MM').format(selectedDate);
                          selectedMonth = dateController.text;
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
    required this.models
  });

  final int index;
  final int total;
  final String lean;
  final List<Widget> models;

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
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(widget.lean, style: const TextStyle(fontSize: 26, color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      const Expanded(child: SizedBox()),
                      expanded
                      ? const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.keyboard_arrow_up, color: Colors.black54),
                      )
                      : const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                      )
                    ],
                  ),
                ),
                Visibility(
                  visible: expanded,
                  child: Column(
                    children: widget.models,
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