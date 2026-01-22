import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';

String apiAddress = '';
DateTime sDate = DateTime.now();
DateTime firstDayOfMonth = DateTime(sDate.year, sDate.month, 1);

class LeanCapacityChart extends StatefulWidget {
  const LeanCapacityChart({super.key});

  @override
  LeanCapacityChartState createState() => LeanCapacityChartState();
}

class LeanCapacityChartState extends State<LeanCapacityChart> {
  String building = '', lean = '', type = '', mode = '', selectedMode = '';
  DateTime selectedDate = sDate;
  List<BarChartGroupData> barGroups = [];
  List<LineChartBarData> lineBarData = [];
  List<FlSpot> targetSpot = [], finishedSpot = [], hideSpot =[];
  List<int> showingTooltipOnSpots = [];
  double chartHeight = 0, dailyChartWidth = 0, monthlyChartWidth = 0, maxDailyY = 0, maxMonthlyY = 0, intervalDailyY = 1, intervalMonthlyY = 1;
  late TextEditingController dateController = TextEditingController(text: DateFormat('yyyy/MM').format(sDate));
  bool loadSuccess = true;

  @override
  void initState() {
    super.initState();
    mode = '';
    selectedMode = '';
    sDate = DateTime.now();
    selectedDate = sDate;
    firstDayOfMonth = DateTime(sDate.year, sDate.month, 1);
    dateController = TextEditingController(text: DateFormat('yyyy/MM').format(sDate));
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '';

    setState(() {
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    loadCapacityChart();
  }

  void loadCapacityChart() async {
    setState(() {
      loadSuccess = false;
    });

    maxDailyY = 0;
    maxMonthlyY = 0;
    intervalDailyY = 1;
    intervalMonthlyY = 1;
    barGroups = [];
    lineBarData = [];
    targetSpot = [];
    finishedSpot = [];
    hideSpot = [];
    showingTooltipOnSpots = [];

    try {
      final body = await RemoteService().getLeanMonthlyCapacity(
        apiAddress,
        building,
        lean,
        type,
        DateFormat('yyyy/MM/dd').format(sDate)
      );
      final jsonBody = json.decode(body);

      double sumTarget = 0, sumFinished = 0;
      if (jsonBody.length > 0) {
        dailyChartWidth = jsonBody.length * 120.0 + 74;
        monthlyChartWidth = jsonBody.length * 80.0 + 90;
        for (int i = 0; i < jsonBody.length; i++) {
          if (jsonBody[i]['Target'].toDouble() > maxDailyY) {
            maxDailyY = jsonBody[i]['Target'].toDouble();
          }
          if (jsonBody[i]['Finished'].toDouble() > maxDailyY) {
            maxDailyY = jsonBody[i]['Finished'].toDouble();
          }

          sumTarget = sumTarget + jsonBody[i]['Target'].toDouble();
          targetSpot.add(
            FlSpot(i.toDouble(), sumTarget)
          );

          sumFinished = sumFinished + jsonBody[i]['Finished'].toDouble();
          if (DateFormat('yyyy/MM/dd').parse('${sDate.year}/${jsonBody[i]['Date']}').isBefore(DateTime.now())) {
            finishedSpot.add(
              FlSpot(i.toDouble(), sumFinished)
            );
          }

          if (sumTarget > maxMonthlyY) {
            maxMonthlyY = sumTarget;
          }
          if (sumFinished > maxMonthlyY) {
            maxMonthlyY = sumFinished;
          }

          barGroups.add(
            BarChartGroupData(
              barsSpace: 10,
              x: i,
              barRods: [
                BarChartRodData(
                  toY: jsonBody[i]['Target'].toDouble(),
                  color: Colors.grey,
                  width: 24,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))
                ),
                BarChartRodData(
                  toY: jsonBody[i]['Finished'].toDouble(),
                  color: jsonBody[i]['Finished'].toDouble() >= jsonBody[i]['Target'].toDouble() ? Colors.blue.shade300 : Colors.red.shade300,
                  width: 24,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))
                ),
              ],
              showingTooltipIndicators: [0, 1],
            )
          );

          showingTooltipOnSpots.add(i);
        }

        lineBarData.add(
          LineChartBarData(
            isCurved: false,
            spots: targetSpot,
            color: Colors.grey,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          )
        );

        lineBarData.add(
          LineChartBarData(
            isCurved: false,
            spots: finishedSpot,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          )
        );
      }
    } finally {
      setState(() {
        maxDailyY = calculateNiceMax(maxDailyY);
        intervalDailyY = (maxDailyY / 5) > 0 ? (maxDailyY / 5) : 1;
        maxMonthlyY = calculateNiceMax(maxMonthlyY);
        intervalMonthlyY = (maxMonthlyY / 5) > 0 ? (maxMonthlyY / 5) : 1;
        barGroups = barGroups;
        lineBarData = lineBarData;
        loadSuccess = true;
      });
    }
  }

  double calculateInterval(double maxValue, {int targetSteps = 5}) {
    double roughInterval = maxValue / targetSteps;
    double magnitude = pow(10, (log(roughInterval) / ln10).floor()).toDouble();
    double residual = roughInterval / magnitude;
    double niceFraction;

    if (residual <= 1) {
      niceFraction = 1;
    } else if (residual <= 2) {
      niceFraction = 2;
    } else if (residual <= 5) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }

    return niceFraction * magnitude;
  }

  double calculateNiceMax(double maxValue, {int targetSteps = 5}) {
    double interval = calculateInterval(maxValue, targetSteps: targetSteps);
    return ((maxValue / interval).ceil()) * interval;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    building = args["building"];
    lean = args["lean"];
    type = args["type"];
    chartHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kBottomNavigationBarHeight;
    if (mode == '') {
      mode = args["mode"];
      selectedMode = mode;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.settings.name == '/home');
          },
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$building - $lean', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(DateFormat('yyyy/MM').format(sDate), style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    scrollable: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    content: StatefulBuilder(
                      builder: (BuildContext context, StateSetter innerSetState) {
                        return Column(
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
                                    initialDate: sDate,
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
                                      innerSetState(() {
                                        selectedDate = date;
                                        dateController.text = DateFormat('yyyy/MM').format(selectedDate);
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
                                        initialDate: sDate,
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
                                          innerSetState(() {
                                            selectedDate = date;
                                            dateController.text = DateFormat('yyyy/MM').format(selectedDate);
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
                              value: selectedMode,
                              items: [
                                DropdownMenuItem(
                                  value: 'Daily',
                                  child: Center(
                                    child: Text(AppLocalizations.of(context)!.dailySummary),
                                  )
                                ),
                                DropdownMenuItem(
                                  value: 'Monthly',
                                  child: Center(
                                    child: Text(AppLocalizations.of(context)!.monthlySummary),
                                  )
                                ),
                              ],
                              onChanged: (value) {
                                innerSetState(() {
                                  selectedMode = value!;
                                });
                              },
                            )
                          ],
                        );
                      }
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
                          mode = selectedMode;
                          if (sDate != selectedDate) {
                            sDate = selectedDate;
                            firstDayOfMonth = DateTime(sDate.year, sDate.month, 1);
                            loadCapacityChart();
                          }
                          Navigator.of(context).pop();
                        },
                        child: Text(AppLocalizations.of(context)!.ok),
                      ),
                    ],
                  );
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(50),
                  borderRadius: BorderRadius.circular(6)
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 2, top: 4, bottom: 4),
                  child: Row(
                    children: [
                      Text(mode == 'Daily' ? AppLocalizations.of(context)!.dailySummary : AppLocalizations.of(context)!.monthlySummary),
                      const Icon(Icons.arrow_drop_down_outlined, size: 18,)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: loadSuccess ? SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: chartHeight,
              width: mode == 'Daily' ? dailyChartWidth : monthlyChartWidth,
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
              child: mode == 'Daily' ? BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxDailyY,
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: noTitles,
                        reservedSize: 20
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: noTitles,
                        reservedSize: 20
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: bottomTitles,
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 54,
                        interval: intervalDailyY,
                        getTitlesWidget: leftTitles,
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.transparent,
                      tooltipMargin: 0,
                      getTooltipItem: (BarChartGroupData group, int groupIndex, BarChartRodData rod, int rodIndex,) {
                        return BarTooltipItem(
                          rod.toY > 0 ? NumberFormat('###,###,###').format(rod.toY) : '',
                          TextStyle(
                            fontWeight: FontWeight.bold,
                            color: rod.color,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: barGroups,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: intervalDailyY
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                ),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
              ) : LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxMonthlyY,
                  showingTooltipIndicators: showingTooltipOnSpots.map((index) {
                    if (index <= lineBarData[1].spots.length - 1) {
                      return ShowingTooltipIndicators([
                        LineBarSpot(
                          lineBarData[1],
                          lineBarData.indexOf(lineBarData[1]),
                          lineBarData[1].spots[index],
                        ),
                      ]);
                    }
                    else {
                      return const ShowingTooltipIndicators([]);
                    }
                  }).toList(),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: noTitles,
                        reservedSize: 30
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: noTitles,
                        reservedSize: 20
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        interval: intervalMonthlyY,
                        getTitlesWidget: leftTitles,
                      )
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: bottomTitles,
                        interval: 1,
                        reservedSize: 40,
                      )
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (group) => Colors.transparent,
                      tooltipMargin: 0,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${NumberFormat('###,###,##0').format(spot.y)}\n[${NumberFormat('##0.0').format((finishedSpot[spot.x.toInt()].y * 1000 / targetSpot[spot.x.toInt()].y).floor() / 10)}%]',
                            TextStyle(
                              color: finishedSpot[spot.x.toInt()].y >= targetSpot[spot.x.toInt()].y ? Colors.blue : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      }
                    ),
                  ),
                  lineBarsData: lineBarData,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: intervalMonthlyY
                  ),
                  borderData: FlBorderData(
                    show: false
                  ),
                ),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
              )
            ),
          ),
        ) : const Center(
          child: CircularProgressIndicator(color: Colors.blue,),
        ),
      ),
    );
  }
}

Widget noTitles(double value, TitleMeta meta) {
  return SideTitleWidget(
    meta: meta,
    space: 0,
    child: const SizedBox(),
  );
}

Widget leftTitles(double value, TitleMeta meta) {
  return SideTitleWidget(
    meta: meta,
    space: 8,
    child: Text(NumberFormat('###,###,##0').format(value), style: const TextStyle(color: Color(0xff7589a2), fontWeight: FontWeight.bold, fontSize: 12,)),
  );
}

Widget bottomTitles(double value, TitleMeta meta) {
  String date = DateFormat('M/d').format(firstDayOfMonth.add(Duration(days: value.toInt())));
  
  return SideTitleWidget(
    meta: meta,
    space: 8,
    child: Text(date, style: const TextStyle(color: Color(0xff7589a2), fontWeight: FontWeight.bold, fontSize: 14,),),
  );
}