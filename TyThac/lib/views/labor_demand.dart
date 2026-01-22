import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:production/components/side_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

String apiAddress = '';
double screenWidth = 0, screenHeight = 0;
String sFactory = '', sLean = '', sType = '', department = '';
DateTime selectedDate = DateTime.now();
String selectedMonth = DateFormat('yyyy/MM').format(DateTime.now());
List<String> factoryDropdownItems = [];
List<DropdownMenuItem<String>> lean = [];
List<List<String>> factoryLeans = [];

class LaborDemand extends StatefulWidget {
  const LaborDemand({super.key});

  @override
  LaborDemandState createState() => LaborDemandState();
}

class LaborDemandState extends State<LaborDemand> {
  String userName = '';
  String group = '';
  List<String> sectionList = ['Total', 'Cutting', 'Stitching', 'Assembly'];
  List<DropdownMenuItem<String>> sections = [];
  List<List<int>> sectionLabor = [];
  List<String> bottomTitle = [];
  List<Map<String, Object>> dataSource = [];
  List<double> minYList = [], maxYList = [];
  double chartWidth = 0, maxX = 0, minY = 0, maxY = 0, intervalY = 0;
  int averageLabor = 0;
  bool checkC = false, checkS = true, checkA = true;
  String loadingStatus = 'isLoading';

  List<Color> gradientColors = [
    const Color(0xFF50E4FF),
    const Color(0xFF2196F3)
  ];

  @override
  void initState() {
    super.initState();
    sFactory = '';
    sLean = '';
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
    List<List<String>> sectionList = [
      ['ALL', AppLocalizations.of(context)!.all],
      ['C', AppLocalizations.of(context)!.cutting],
      ['S', AppLocalizations.of(context)!.stitching],
      ['A', AppLocalizations.of(context)!.assembly]
    ];

    sections = [];
    sections = sectionList.map((List<String> section) {
      return DropdownMenuItem(
        value: section[0],
        child: Center(
          child: Text(section[1]),
        )
      );
    }).toList();
    sType = 'ALL';

    factoryDropdownItems = [];
    factoryLeans = [];
    lean = [];
    sLean = '';
    final body = await RemoteService().getFactoryLean(
      apiAddress,
      selectedMonth,
      'CurrentMonth'
    );
    final jsonData = json.decode(body);
    if (!mounted) return;
    factoryDropdownItems.add('ALL');
    factoryLeans.add(['ALL']);
    for (int i = 0; i < jsonData.length; i++) {
      factoryDropdownItems.add(jsonData[i]['Factory']);
      List<String> leans = [];
      leans.add('ALL');
      for (int j = 0; j < jsonData[i]['Lean'].length; j++) {
        leans.add(jsonData[i]['Lean'][j]);
      }
      factoryLeans.add(leans);
    }

    sFactory = department.split('_')[0];
    sLean = department.indexOf('_') > 0 ? department.split('_')[1] : '';
    if (factoryDropdownItems.contains(sFactory) == false) {
      sFactory = factoryDropdownItems[1];
    }

    lean = factoryLeans[factoryDropdownItems.indexOf(sFactory)].map((String myLean) {
      return DropdownMenuItem(
        value: myLean,
        child: Center(
          child: Text(myLean != 'ALL' ? myLean.toString() : AppLocalizations.of(context)!.all),
        )
      );
    }).toList();

    if (sLean == '' || factoryLeans[factoryDropdownItems.indexOf(sFactory)].contains(sLean) == false) {
      sLean = lean[0].value.toString();
    }

    if (sFactory != '') {
      department = (sLean != lean[0].value.toString() ? '${sFactory}_$sLean' : sFactory);
    }

    loadLineChart();
  }

  Future<void> loadLineChart() async {
    setState(() {
      loadingStatus = 'isLoading';
    });
    
    final body = await RemoteService().getLaborDemand(
      apiAddress,
      selectedMonth,
      sFactory,
      sLean,
      sType
    );
    final jsonData = json.decode(body);

    sectionLabor = [];
    bottomTitle = [];
    chartWidth = 0;
    minYList = [];
    maxYList = [];

    if (jsonData.length > 0 && jsonData['statusCode'] != 400) {
      for (int i = 0; i < sectionList.length; i++) {
        sectionLabor.add([]);
        minYList.add(1000000);
        maxYList.add(0);

        for (int j = 0; j < jsonData[sectionList[i]].length; j++) {
          sectionLabor[i].add(int.parse(jsonData[sectionList[i]][j]['Qty'].toString()));
          bottomTitle.add(jsonData[sectionList[i]][j]['Date']);

          if (double.parse(jsonData[sectionList[i]][j]['Qty'].toString()) < minYList[i]) {
            minYList[i] = double.parse(jsonData[sectionList[i]][j]['Qty'].toString());
          }
          else if (double.parse(jsonData[sectionList[i]][j]['Qty'].toString()) > maxYList[i]) {
            maxYList[i] = double.parse(jsonData[sectionList[i]][j]['Qty'].toString());
          }
        }

        if ((jsonData[sectionList[i]].length + 2) * 100.0 + 100 > chartWidth) {
          chartWidth = (jsonData[sectionList[i]].length + 2) * 100.0 + 100;
        }
      }

      loadSectionChart();
      setState(() {
        loadingStatus = 'Completed';
      });
    }
    else {
      setState(() {
        loadingStatus = 'No Data';
      });
    }
  }

  void loadSectionChart() {
    double checkedMaxY = (checkC ? maxYList[1] : 0) + (checkS ? maxYList[2] : 0) + (checkA ? maxYList[3] : 0);
    double checkedMinY = (checkC ? minYList[1] : 0) + (checkS ? minYList[2] : 0) + (checkA ? minYList[3] : 0);
    List<int> effectiveData = [];
    dataSource = [];
    int counter = 0, lastVal = 0;
    for (int i = 0; i < sectionLabor[0].length; i++) {
      int val = (checkC ? sectionLabor[1][i] : 0) + (checkS ? sectionLabor[2][i] : 0) + (checkA ? sectionLabor[3][i] : 0);
      if (i == 0) {
        dataSource.add({
          'Id': -1,
          'Date': '${bottomTitle[i]}-0',
          'Qty': val
        });
      }
      dataSource.add({
        'Id': i * 2 - 1,
        'Date': '${bottomTitle[i]}-0',
        'Qty': val
      });
      dataSource.add({
        'Id': i * 2,
        'Date': bottomTitle[i],
        'Qty': val
      });
      if (i == sectionLabor[0].length - 1) {
        dataSource.add({
          'Id': i * 2 + 1,
          'Date': '${bottomTitle[i]}-1-0',
          'Qty': val
        });
      }

      if (val != lastVal) {
        if (counter > 3 && effectiveData.contains(val) == false) {
          effectiveData.add(lastVal);
        }
        lastVal = val;
        counter = 1;
      }
      else {
        counter++;
      }
    }

    if (counter > 3 && effectiveData.contains(lastVal) == false) {
      effectiveData.add(lastVal);
    }

    if (effectiveData.isEmpty) {
      averageLabor = 0;
    }
    else {
      averageLabor = (effectiveData.reduce((a, b) => a + b) / effectiveData.length).ceil();
    }

    int gap = ((checkedMaxY - checkedMinY) / 3).ceil();
    setState(() {
      dataSource = dataSource;
      chartWidth = chartWidth;
      maxX = dataSource.length - 2;
      if (gap > 0) {
        minY = (checkedMinY - gap) > 0 ? 0.0 + (checkedMinY - gap) ~/ gap * gap : 0;
        maxY = 0.0 + ((checkedMaxY + gap) ~/ gap + 1) * gap;
        intervalY = gap.toDouble();
      }
      else {
        minY = checkedMinY - 3;
        maxY = checkedMinY + 3;
        intervalY = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - kBottomNavigationBarHeight - 60;

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
            Text(AppLocalizations.of(context)!.sideMenuLaborDemand),
            Text('${sFactory != 'ALL' ? sFactory : AppLocalizations.of(context)!.all}${sLean != 'ALL' ? ' $sLean' : ''} - $selectedMonth', style: const TextStyle(fontSize: 16))
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
            Icons.filter_alt,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return LeanFilter(
                    refresh: loadLineChart,
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
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(30, 39, 48, 1),
                    borderRadius: BorderRadius.all(Radius.circular(16))
                  ),
                  child: loadingStatus == 'Completed' ? Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 70,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        activeColor: Colors.transparent,
                                        checkColor: gradientColors[0],
                                        side: const BorderSide(
                                          color: Colors.white
                                        ),
                                        value: checkC,
                                        onChanged: (value) {
                                          setState(() {
                                            checkC = value!;
                                            loadSectionChart();
                                          });
                                        }
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          checkC = !checkC;
                                          loadSectionChart();
                                        });
                                      },
                                      child: Text(' ${AppLocalizations.of(context)!.cutting}', style: TextStyle(color: checkC ? gradientColors[0] : Colors.white, fontSize: 24)),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        activeColor: Colors.transparent,
                                        checkColor: gradientColors[0],
                                        side: const BorderSide(
                                          color: Colors.white
                                        ),
                                        value: checkS,
                                        onChanged: (value) {
                                          setState(() {
                                            checkS = value!;
                                            loadSectionChart();
                                          });
                                        }
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          checkS = !checkS;
                                          loadSectionChart();
                                        });
                                      },
                                      child: Text(' ${AppLocalizations.of(context)!.stitching}', style: TextStyle(color: checkS ? gradientColors[0] : Colors.white, fontSize: 24)),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        activeColor: Colors.transparent,
                                        checkColor: gradientColors[0],
                                        side: const BorderSide(
                                            color: Colors.white
                                        ),
                                        value: checkA,
                                        onChanged: (value) {
                                          setState(() {
                                            checkA = value!;
                                            loadSectionChart();
                                          });
                                        }
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          checkA = !checkA;
                                          loadSectionChart();
                                        });
                                      },
                                      child: Text(' ${AppLocalizations.of(context)!.assembly}', style: TextStyle(color: checkA ? gradientColors[0] : Colors.white, fontSize: 24)),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        child: Text('${AppLocalizations.of(context)!.average} : $averageLabor', style: const TextStyle(fontSize: 20, color: Colors.redAccent, fontWeight: FontWeight.bold))
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          height: screenHeight,
                          width: chartWidth,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, right: 28, top: 16, bottom: 8),
                            child: SfCartesianChart(
                              plotAreaBorderWidth: 0,
                              primaryXAxis: CategoryAxis(
                                majorTickLines: const MajorTickLines(size: 0),
                                majorGridLines: const MajorGridLines(color: Colors.white10, width: 1),
                                labelPlacement: LabelPlacement.onTicks,
                                axisLabelFormatter: (details) {
                                  return ChartAxisLabel(details.text.indexOf('-0') > 0 ? '' : details.text, const TextStyle(color: Colors.white));
                                },
                                labelStyle: const TextStyle(color: Colors.white),
                                axisLine: const AxisLine(color: Colors.white10, width: 1),
                                interval: 1,
                                minimum: 0,
                                maximum: maxX
                              ),
                              primaryYAxis: NumericAxis(
                                majorTickLines: const MajorTickLines(size: 0),
                                majorGridLines: const MajorGridLines(color: Colors.white10, width: 0),
                                labelStyle: const TextStyle(color: Colors.white),
                                axisLine: const AxisLine(color: Colors.white10, width: 1),
                                interval: intervalY,
                                minimum: minY,
                                maximum: maxY
                              ),
                              series: [
                                StepLineSeries(
                                  width: 10,
                                  color: const Color.fromRGBO(30, 39, 48, 1),
                                  dataSource: dataSource,
                                  xValueMapper: (datum, int index) {
                                    return datum['Date'];
                                  },
                                  yValueMapper: (datum, int index) {
                                    return index % 4 == 2 || index % 4 == 3 ? maxY + 5 : 0;
                                  },
                                  animationDuration: 0
                                ),
                                LineSeries(
                                  width: 1,
                                  color: Colors.white10,
                                  dataSource: dataSource,
                                  xValueMapper: (datum, int index) {
                                    return datum['Date'];
                                  },
                                  yValueMapper: (datum, int index) {
                                    return minY;
                                  },
                                  animationDuration: 0
                                ),
                                LineSeries(
                                  width: 1,
                                  color: Colors.white10,
                                  dataSource: dataSource,
                                  xValueMapper: (datum, int index) {
                                    return datum['Date'];
                                  },
                                  yValueMapper: (datum, int index) {
                                    return minY + intervalY;
                                  },
                                  animationDuration: 0
                                ),
                                LineSeries(
                                  width: 1,
                                  color: Colors.white10,
                                  dataSource: dataSource,
                                  xValueMapper: (datum, int index) {
                                    return datum['Date'];
                                  },
                                  yValueMapper: (datum, int index) {
                                    return minY + intervalY * 2;
                                  },
                                  animationDuration: 0
                                ),
                                LineSeries(
                                  width: 1,
                                  color: Colors.white10,
                                  dataSource: dataSource,
                                  xValueMapper: (datum, int index) {
                                    return datum['Date'];
                                  },
                                  yValueMapper: (datum, int index) {
                                    return minY + intervalY * 3;
                                  },
                                  animationDuration: 0
                                ),
                                LineSeries(
                                  width: 1,
                                  color: Colors.white10,
                                  dataSource: dataSource,
                                  xValueMapper: (datum, int index) {
                                    return datum['Date'];
                                  },
                                  yValueMapper: (datum, int index) {
                                    return minY + intervalY * 4;
                                  },
                                  animationDuration: 0
                                ),
                                LineSeries(
                                  width: 1,
                                  color: Colors.white10,
                                  dataSource: dataSource,
                                  xValueMapper: (datum, int index) {
                                    return datum['Date'];
                                  },
                                  yValueMapper: (datum, int index) {
                                    return minY + intervalY * 5;
                                  },
                                  animationDuration: 0
                                ),
                                LineSeries(
                                  width: 1,
                                  color: Colors.white10,
                                  dataSource: dataSource,
                                  xValueMapper: (datum, int index) {
                                    return datum['Date'];
                                  },
                                  yValueMapper: (datum, int index) {
                                    return minY + intervalY * 6;
                                  },
                                  animationDuration: 0
                                ),
                                LineSeries(
                                  width: 2,
                                  color: Colors.redAccent,
                                  dataSource: dataSource,
                                  xValueMapper: (datum, int index) {
                                    return datum['Date'];
                                  },
                                  yValueMapper: (datum, int index) {
                                    return averageLabor;
                                  },
                                  animationDuration: 0
                                ),
                                StepAreaSeries(
                                  borderGradient: LinearGradient(
                                    colors: gradientColors,
                                  ),
                                  gradient: LinearGradient(
                                    colors: gradientColors.map((color) => color.withAlpha(75)).toList()
                                  ),
                                  dataSource: dataSource,
                                  xValueMapper: (datum, int index) {
                                    return datum['Date'];
                                  },
                                  yValueMapper: (datum, int index) {
                                    return double.parse(datum['Qty'].toString());
                                  },
                                  dataLabelSettings: DataLabelSettings(
                                    isVisible: true,
                                    labelAlignment: ChartDataLabelAlignment.outer,
                                    builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                                      return !data['Date'].toString().contains('-0') ? Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color.fromRGBO(255, 255, 255, 0.8),
                                            border: Border.all(color: Colors.transparent),
                                            borderRadius: BorderRadius.circular(4)
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            child: Text(data['Qty'].toString(), style: const TextStyle(color: Color.fromRGBO(0, 51, 153, 1), fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ) : const SizedBox();
                                    }
                                  ),
                                  animationDuration: 0
                                ),
                                StepLineSeries(
                                  width: 5,
                                  dataSource: dataSource,
                                  xValueMapper: (datum, int index) {
                                    return datum['Date'];
                                  },
                                  yValueMapper: (datum, int index) {
                                    return double.parse(datum['Qty'].toString());
                                  },
                                  pointColorMapper: (datum, int index) {
                                    int r = (gradientColors[0].r * 255).toInt() - (((gradientColors[0].r * 255).toInt() - (gradientColors[1].r * 255).toInt()) / maxX * index).toInt();
                                    int g = (gradientColors[0].g * 255).toInt() - (((gradientColors[0].g * 255).toInt() - (gradientColors[1].g * 255).toInt()) / maxX * index).toInt();
                                    int b = (gradientColors[0].b * 255).toInt() - (((gradientColors[0].b * 255).toInt() - (gradientColors[1].b * 255).toInt()) / maxX * index).toInt();
                                    return Color.fromRGBO(r, g, b, 1);
                                  },
                                  animationDuration: 0
                                )
                              ]
                            )
                          ),
                        ),
                      ),
                    ],
                  ) : loadingStatus == 'isLoading' ? SizedBox(
                    height: screenHeight + 70,
                    child: const Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(color: Colors.blue,)
                      ),
                    ),
                  ) : SizedBox(
                    height: screenHeight + 70,
                    child: Center(
                      child: Text(AppLocalizations.of(context)!.noDataFound, style: const TextStyle(color: Colors.white, fontSize: 16))
                    )
                  )
                ),
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
                      factoryDropdownItems = ['ALL'];
                      factoryLeans = [['ALL']];
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
                      lean = factoryLeans[factoryDropdownItems.indexOf(sFactory)].map((String myLean) {
                        return DropdownMenuItem(
                          value: myLean,
                          child: Center(
                            child: Text(myLean != 'ALL' ? myLean.toString() : AppLocalizations.of(context)!.all),
                          )
                        );
                      }).toList();

                      if (factoryLeans[factoryDropdownItems.indexOf(sFactory)].contains(sLean) == false) {
                        sLean = factoryLeans[factoryDropdownItems.indexOf(sFactory)][0];
                      }
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
                          'CurrentMonth'
                        );
                        final jsonData = json.decode(body);
                        if (jsonData.length > 0) {
                          factoryDropdownItems = ['ALL'];
                          factoryLeans = [['ALL']];
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
                          lean = factoryLeans[factoryDropdownItems.indexOf(sFactory)].map((String myLean) {
                            return DropdownMenuItem(
                              value: myLean,
                              child: Center(
                                child: Text(myLean != 'ALL' ? myLean.toString() : AppLocalizations.of(context)!.all),
                              )
                            );
                          }).toList();

                          if (factoryLeans[factoryDropdownItems.indexOf(sFactory)].contains(sLean) == false) {
                            sLean = factoryLeans[factoryDropdownItems.indexOf(sFactory)][0];
                          }
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
                lean = factoryLeans[factoryDropdownItems.indexOf(sFactory)].map((String myLean) {
                  return DropdownMenuItem(
                    value: myLean,
                    child: Center(
                      child: Text(myLean != 'ALL' ? myLean.toString() : AppLocalizations.of(context)!.all),
                    )
                  );
                }).toList();

                if (factoryLeans[factoryDropdownItems.indexOf(sFactory)].contains(sLean) == false) {
                  sLean = factoryLeans[factoryDropdownItems.indexOf(sFactory)][0];
                }
              });
            },
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.lean)
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
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.type)
          ),
          DropdownButton<String>(
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Colors.grey,
            ),
            value: sType,
            items: [
              DropdownMenuItem(
                value: 'ALL',
                child: Center(
                  child: Text(AppLocalizations.of(context)!.all, textAlign: TextAlign.center)
                ),
              ),
              DropdownMenuItem(
                value: 'DL',
                child: Center(
                  child: Text(AppLocalizations.of(context)!.directLabor, textAlign: TextAlign.center)
                ),
              ),
              DropdownMenuItem(
                value: 'IDL',
                child: Center(
                  child: Text(AppLocalizations.of(context)!.indirectLabor, textAlign: TextAlign.center)
                ),
              )
            ],
            onChanged: (value) {
              setState(() {
                sType = value!;
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