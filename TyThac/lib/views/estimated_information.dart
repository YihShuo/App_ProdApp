import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:production/services/remote_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math';
import 'package:production/components/side_menu.dart';

String apiAddress = '', sFactory = '', sModel = 'CuttingDie', userID = '';
double screenWidth = 0, screenHeight = 0;
DateTime sDate = DateTime.now();
List<String> factoryList = ['3F', '4F'];
List<String> modelList = ['CuttingDie', 'SKU'];

class BGData {
  BGData(this.x, this.y);
  final num? x;
  final num? y;
}

class HighRiskModel {
  HighRiskModel(this.eff, this.diff, this.model);
  final double eff;
  final int diff;
  final String model;
}

class EstimatedInformation extends StatefulWidget {
  const EstimatedInformation({
    super.key
  });

  @override
  EstimatedInformationState createState() => EstimatedInformationState();
}

class EstimatedInformationState extends State<EstimatedInformation> {
  String loadingStatus = 'No Data';
  String userName = '', group = '';
  dynamic chartData;
  int maxHighRiskQty = 0;
  List<Widget> leanTabs = [];
  List<Widget> leanTabViews = [];
  double riskChartHeight = 0;

  @override
  void initState() {
    super.initState();
    sFactory = '';
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString('userID') ?? '';
      userName = prefs.getString('userName') ?? '';
      group = prefs.getString('group') ?? '';
      sFactory = prefs.getString('department')?.split('_')[0] ?? '3F';
      if (factoryList.contains(sFactory) == false) {
        sFactory = factoryList[0];
      }
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    loadEstimatedInfo();
  }

  Future<void> loadEstimatedInfo() async {
    setState(() {
      loadingStatus = 'isLoading';
    });

    leanTabs = [];
    leanTabViews = [];

    final body = await RemoteService().getEstimatedInfo(
      apiAddress,
      DateFormat('yyyy/MM/dd').format(DateTime(sDate.year, sDate.month, 1)),
      DateFormat('yyyy/MM/dd').format(DateTime(sDate.year, sDate.month + 1, 0)),
      sFactory,
      sModel
    );
    chartData = json.decode(body);

    int maxLaborDiff = 0;
    double minHisEff = 1;
    List<List<HighRiskModel>> assemblyHighRiskModel = [], stitchingHighRiskModel = [];
    List<List<String>> newModel = [];
    maxHighRiskQty = 0;

    if (chartData.length > 0) {
      for (int i = 0; i < chartData.length; i++) {
        newModel.add([]);

        assemblyHighRiskModel.add([]);
        for (int j = 0; j < chartData[i]['Model_A'].length; j++) {
          double eff = double.parse(chartData[i]['Model_A'][j]['HisEff']);
          if (eff < minHisEff && eff > 0) {
            minHisEff = eff;
          }

          int diff = chartData[i]['Model_A'][j]['LaborDiff'];
          if (diff > maxLaborDiff && eff > 0) {
            maxLaborDiff = diff;
          }

          if (150 * (1 - eff) + diff - 30 > 0 && chartData[i]['Model_A'][j]['Type'] != 'NEW') {
            assemblyHighRiskModel[i].add(
              HighRiskModel(eff, diff, chartData[i]['Model_A'][j]['Model'])
            );
          }
          else if (chartData[i]['Model_A'][j]['Type'] == 'NEW') {
            if (newModel[i].contains(chartData[i]['Model_A'][j]['Model']) == false) {
              newModel[i].add(chartData[i]['Model_A'][j]['Model']);
            }
          }
        }
        assemblyHighRiskModel[i].sort((a, b) {
          return a.eff.compareTo(b.eff);
        });
        if (assemblyHighRiskModel[i].length > maxHighRiskQty) {
          maxHighRiskQty = assemblyHighRiskModel[i].length;
        }

        stitchingHighRiskModel.add([]);
        for (int j = 0; j < chartData[i]['Model_S'].length; j++) {
          double eff = double.parse(chartData[i]['Model_S'][j]['HisEff']);
          if (eff < minHisEff && eff > 0) {
            minHisEff = eff;
          }

          int diff = chartData[i]['Model_S'][j]['LaborDiff'];
          if (diff > maxLaborDiff && eff > 0) {
            maxLaborDiff = diff;
          }

          if (50 * (1 - eff) + diff - 15 > 0 && chartData[i]['Model_S'][j]['Type'] != 'NEW') {
            stitchingHighRiskModel[i].add(
              HighRiskModel(eff, diff, chartData[i]['Model_S'][j]['Model'])
            );
          }
          else if (chartData[i]['Model_S'][j]['Type'] == 'NEW') {
            if (newModel[i].contains(chartData[i]['Model_S'][j]['Model']) == false) {
              newModel[i].add(chartData[i]['Model_S'][j]['Model']);
            }
          }
        }
        stitchingHighRiskModel[i].sort((a, b) {
          return a.eff.compareTo(b.eff);
        });
        if (stitchingHighRiskModel[i].length > maxHighRiskQty) {
          maxHighRiskQty = stitchingHighRiskModel[i].length;
        }

        if (newModel[i].length > maxHighRiskQty) {
          maxHighRiskQty = newModel[i].length;
        }
      }
      maxLaborDiff = maxLaborDiff <= 50 ? 50 : maxLaborDiff + 10 - maxLaborDiff % 10;
      minHisEff = minHisEff >= 0.5 ? 0.5 : (minHisEff * 10).toInt() / 10;

      for (int i = 0; i < chartData.length; i++) {
        List<Widget> assemblyHighRiskWidget = [
          SizedBox(
            height: 40,
            child: Center(
              child: AutoSizeText(AppLocalizations.of(context)!.assembly, minFontSize: 6, maxFontSize: 14, style: const TextStyle(color: Color.fromRGBO(68, 84, 106, 1), fontWeight: FontWeight.bold))
            ),
          )
        ];

        if (assemblyHighRiskModel[i].isNotEmpty) {
          for (int j = 0; j < assemblyHighRiskModel[i].length; j++) {
            assemblyHighRiskWidget.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SizedBox(
                  height: 28,
                  child: AutoSizeText(assemblyHighRiskModel[i][j].model, minFontSize: 6, maxFontSize: 14),
                ),
              )
            );
          }
        }
        else {
          assemblyHighRiskWidget.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SizedBox(
                height: 28,
                child: AutoSizeText(AppLocalizations.of(context)!.noHighRiskModel, minFontSize: 6, maxFontSize: 14)
              )
            )
          );
        }

        List<Widget> stitchingHighRiskWidget = [
          SizedBox(
            height: 40,
            child: Center(
              child: AutoSizeText(AppLocalizations.of(context)!.stitching, minFontSize: 6, maxFontSize: 14, style: const TextStyle(color: Color.fromRGBO(68, 84, 106, 1), fontWeight: FontWeight.bold))
            ),
          )
        ];

        if (stitchingHighRiskModel[i].isNotEmpty) {
          for (int j = 0; j < stitchingHighRiskModel[i].length; j++) {
            stitchingHighRiskWidget.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SizedBox(
                  height: 28,
                  child: AutoSizeText(stitchingHighRiskModel[i][j].model, minFontSize: 6, maxFontSize: 14),
                ),
              )
            );
          }
        }
        else {
          stitchingHighRiskWidget.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SizedBox(
                height: 28,
                child: AutoSizeText(AppLocalizations.of(context)!.noHighRiskModel, minFontSize: 6, maxFontSize: 14)
              )
            )
          );
        }

        List<Widget> newModelWidget = [
          SizedBox(
            height: 40,
            child: Center(
              child: AutoSizeText(AppLocalizations.of(context)!.newModel, minFontSize: 6, maxFontSize: 14, style: const TextStyle(color: Color.fromRGBO(68, 84, 106, 1), fontWeight: FontWeight.bold))
            ),
          )
        ];

        if (newModel[i].isNotEmpty) {
          for (int j = 0; j < newModel[i].length; j++) {
            newModelWidget.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SizedBox(
                  height: 28,
                  child: AutoSizeText(newModel[i][j], minFontSize: 6, maxFontSize: 14),
                ),
              )
            );
          }
        }
        else {
          newModelWidget.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SizedBox(
                height: 28,
                child: AutoSizeText(AppLocalizations.of(context)!.noNewModel, minFontSize: 6, maxFontSize: 14)
              )
            )
          );
        }

        List<CartesianSeries<dynamic, dynamic>> leanRiskSeries = [];
        leanRiskSeries.add(
          ScatterSeries(
            name: AppLocalizations.of(context)!.assembly,
            color: const Color.fromRGBO(68, 84, 106, 1),
            dataSource: chartData[i]['Model_A'],
            xValueMapper: (datum, int index) {
              return double.parse(datum['HisEff']);
            },
            yValueMapper: (datum, int index) {
              return datum['LaborDiff'];
            },
            markerSettings: const MarkerSettings(
              isVisible: true,
              height: 10,
              width: 10,
              shape: DataMarkerType.diamond,
              color: Color.fromRGBO(68, 84, 106, 1),
              borderColor: Colors.white,
              borderWidth: 0.4
            ),
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              margin: EdgeInsets.zero,
              labelAlignment: ChartDataLabelAlignment.top,
              builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                return Text(data['Model'], style: const TextStyle(fontSize: 10));
              }
            ),
            animationDuration: 0,
          )
        );

        leanRiskSeries.add(
          ScatterSeries(
            name: AppLocalizations.of(context)!.stitching,
            color: const Color.fromRGBO(197, 90, 17, 1),
            dataSource: chartData[i]['Model_S'],
            xValueMapper: (datum, int index) {
              return double.parse(datum['HisEff']);
            },
            yValueMapper: (datum, int index) {
              return datum['LaborDiff'];
            },
            markerSettings: const MarkerSettings(
              isVisible: true,
              height: 10,
              width: 10,
              shape: DataMarkerType.triangle,
              color: Color.fromRGBO(197, 90, 17, 1),
              borderColor: Colors.white,
              borderWidth: 0.4
            ),
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              margin: EdgeInsets.zero,
              labelAlignment: ChartDataLabelAlignment.top,
              builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                return Text(data['Model'], style: const TextStyle(fontSize: 10));
              }
            ),
            animationDuration: 0,
          )
        );

        leanTabs.add(
          Tab(text: chartData[i]['Lean'])
        );

        leanTabViews.add(
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 50, bottom: 20),
                child: HighRiskChart(
                  minHisEff: minHisEff,
                  maxLaborDiff: maxLaborDiff,
                  leanRiskSeries: leanRiskSeries,
                  setSize: setSize,
                ),
              ),
              SizedBox(
                height: 26,
                child: Text(AppLocalizations.of(context)!.highRiskModel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[900]))
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Column(
                        children: assemblyHighRiskWidget,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: maxHighRiskQty * 32 + 40,
                    child: const VerticalDivider(
                      width: 1,
                      indent: 40,
                      endIndent: 8
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: Column(
                        children: stitchingHighRiskWidget,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: maxHighRiskQty * 32 + 40,
                    child: const VerticalDivider(
                      width: 1,
                      indent: 40,
                      endIndent: 8
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      child: Column(
                        children: newModelWidget,
                      ),
                    ),
                  )
                ],
              )
            ],
          )
        );
      }

      setState(() {
        riskChartHeight = (screenHeight / 2 >= 300 ? screenHeight / 2 : 300) + 132 + maxHighRiskQty * 32 - 44;
        loadingStatus = 'Completed';
      });
    }
    else {
      setState(() {
        loadingStatus = 'No Data';
      });
    }
  }

  void setSize(double height) {
    setState(() {
      riskChartHeight = height + 132 + maxHighRiskQty * 32;
    });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - kBottomNavigationBarHeight;
    double maxY = (screenWidth - 72 + 80) / (screenWidth - 72) ;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.sideMenuEstimatedInformation),
            Text('$sFactory - ${DateFormat('yyyy/MM').format(sDate)}', style: const TextStyle(fontSize: 16))
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
                    refresh: loadEstimatedInfo,
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
        child: loadingStatus == 'Completed'
        ? SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(AppLocalizations.of(context)!.estEff, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
              ),
              SizedBox(
                height: chartData.length * 68.0,//screenHeight / 2 >= 320 ? screenHeight / 2 : 320,
                child: Stack(
                  children: [
                    SfCartesianChart(
                      primaryXAxis: const CategoryAxis(
                        isInversed: true
                      ),
                      primaryYAxis: NumericAxis(
                        isVisible: false,
                        minimum: 0,
                        maximum: maxY,
                        majorGridLines: const MajorGridLines(
                          width: 0
                        ),
                        majorTickLines: const MajorTickLines(
                          width: 0
                        ),
                        labelStyle: const TextStyle(color: Colors.transparent),
                        axisLine: const AxisLine(
                          width: 0
                        )
                      ),
                      series: [
                        BarSeries(
                          dataSource: chartData,
                          xValueMapper: (datum, int index) {
                            return datum['Lean'];
                          },
                          yValueMapper: (datum, int index) {
                            double target = double.parse(datum['TargetEff']);
                            double estA = double.parse(datum['EstEff_A']);
                            double estS = double.parse(datum['EstEff_S']);

                            return max(target, max(estA, estS));
                          },
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            margin: EdgeInsets.zero,
                            builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                              return Text('${AppLocalizations.of(context)!.target}\n${(double.parse(data['TargetEff']) * 100).toStringAsFixed(1)}%', textAlign: TextAlign.center);
                            }
                          ),
                          color: Colors.transparent,
                          width: 0.9,
                          animationDuration: 0,
                        )
                      ]
                    ),
                    SfCartesianChart(
                      primaryXAxis: const CategoryAxis(
                        isInversed: true
                      ),
                      primaryYAxis: NumericAxis(
                        isVisible: false,
                        minimum: 0,
                        maximum: maxY,
                        majorGridLines: const MajorGridLines(
                          width: 0
                        ),
                        majorTickLines: const MajorTickLines(
                          width: 0
                        ),
                        labelStyle: const TextStyle(color: Colors.transparent),
                        axisLine: const AxisLine(
                          width: 0
                        )
                      ),
                      series: [
                        BarSeries(
                          dataSource: chartData,
                          xValueMapper: (datum, int index) {
                            return datum['Lean'];
                          },
                          yValueMapper: (datum, int index) {
                            return double.parse(datum['TargetEff']);
                          },
                          color: Colors.grey,
                          width: 0.9,
                          animationDuration: 0,
                        )
                      ]
                    ),
                    SfCartesianChart(
                      primaryXAxis: const CategoryAxis(
                        isInversed: true,
                      ),
                      primaryYAxis: NumericAxis(
                        isVisible: false,
                        minimum: 0,
                        maximum: maxY,
                        majorGridLines: const MajorGridLines(
                          width: 0
                        ),
                        majorTickLines: const MajorTickLines(
                          width: 0
                        ),
                        labelStyle: const TextStyle(color: Colors.transparent),
                        axisLine: const AxisLine(
                          width: 0
                        ),
                      ),
                      series: [
                        BarSeries(
                          dataSource: chartData,
                          xValueMapper: (datum, int index) {
                            return datum['Lean'];
                          },
                          yValueMapper: (datum, int index) {
                            return double.parse(datum['EstEff_A']);
                          },
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            labelAlignment: ChartDataLabelAlignment.top,
                            margin: EdgeInsets.zero,
                            builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                              return Text('${AppLocalizations.of(context)!.estAssemblyEff} ${(double.parse(data['EstEff_A']) * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, height: 0));
                            }
                          ),
                          color: const Color.fromRGBO(68, 84, 106, 1),
                          width: 0.7,
                          animationDuration: 0,
                        ),
                        BarSeries(
                          dataSource: chartData,
                          xValueMapper: (datum, int index) {
                            return datum['Lean'];
                          },
                          yValueMapper: (datum, int index) {
                            return double.parse(datum['EstEff_S']);
                          },
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            labelAlignment: ChartDataLabelAlignment.top,
                            margin: EdgeInsets.zero,
                            builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                              return Text('${AppLocalizations.of(context)!.estStitchingEff} ${(double.parse(data['EstEff_S']) * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, height: 0));
                            }
                          ),
                          color: const Color.fromRGBO(197, 90, 17, 1),
                          width: 0.7,
                          animationDuration: 0,
                        ),
                      ]
                    )
                  ]
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 10, right: 10, bottom: 4),
                child: Divider(height: 1),
              ),
              Text(AppLocalizations.of(context)!.riskDistribution, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
              DefaultTabController(
                length: leanTabs.length,
                child: SizedBox(
                  height: riskChartHeight,
                  child: Column(
                    children: [
                      ButtonsTabBar(
                        height: 40,
                        backgroundColor: Colors.blue,
                        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        unselectedBackgroundColor: Colors.grey[400],
                        unselectedLabelStyle: const TextStyle(color: Colors.black87),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        radius: 20,
                        tabs: leanTabs,
                      ),
                      Expanded(
                        child: TabBarView(
                          children: leanTabViews,
                        ),
                      ),
                    ]
                  ),
                ),
              )
            ],
          ),
        )
        : loadingStatus == 'isLoading'
        ? const Center(
          child: SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(color: Colors.blue),
          ),
        )
        : Center(
          child: Text(AppLocalizations.of(context)!.noDataFound, style: const TextStyle(fontSize: 16))
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
  final TextEditingController sMonthController = TextEditingController(text: DateFormat('yyyy/MM').format(sDate));

  @override
  void initState() {
    super.initState();
  }

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
            child: Text(AppLocalizations.of(context)!.month)
          ),
          SizedBox(
            height: 40,
            child: TextField(
              readOnly: true,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.bottom,
              controller: sMonthController,
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
                    )
                  )
                ).then((date) async {
                  if (date != null) {
                    setState(() {
                      sDate = date;
                      sMonthController.text = DateFormat('yyyy/MM').format(sDate);
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
                        )
                      )
                    ).then((date) async {
                      if (date != null) {
                        setState(() {
                          sDate = date;
                          sMonthController.text = DateFormat('yyyy/MM').format(sDate);
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
            items: factoryList.map((String factory) {
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.model)
          ),
          DropdownButton<String>(
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Colors.grey,
            ),
            value: sModel,
            items: modelList.map((String model) {
              return DropdownMenuItem(
                value: model,
                child: Center(
                  child: Text(model == 'CuttingDie' ? AppLocalizations.of(context)!.cuttingDie : model.toString()),
                )
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                sModel = value!;
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

class HighRiskChart extends StatefulWidget {
  const HighRiskChart({
    super.key,
    required this.minHisEff,
    required this.maxLaborDiff,
    required this.leanRiskSeries,
    required this.setSize
  });

  final double minHisEff;
  final int maxLaborDiff;
  final List<CartesianSeries<dynamic, dynamic>> leanRiskSeries;
  final Function setSize;

  @override
  HighRiskChartState createState() => HighRiskChartState();
}

class HighRiskChartState extends State<HighRiskChart> with WidgetsBindingObserver {
  double tabViewHeight = (screenHeight / 2 >= 300 ? screenHeight / 2 : 300) - 44;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /*@override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      double sHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - kBottomNavigationBarHeight;
      setState(() {
        tabViewHeight = (sHeight / 2 >= 300 ? sHeight / 2 : 300) - 44;
        widget.setSize(tabViewHeight);
      });
    });
  }*/

  @override
  void dispose() {
    //WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double radians = atan((0.25 / (1-widget.minHisEff) * (screenWidth - 120)) / (25 / widget.maxLaborDiff * (tabViewHeight - 105)));
    double width = screenWidth - 120, height = tabViewHeight - 105;
    double dx = cos(radians);
    double dy = sin(radians);

    double beginX = -dx / width;
    double beginY = dy / height;
    double endX = dx / width;
    double endY = -dy / height;

    double ratio = -6 * pow(10, -7) * pow(screenWidth - 128, 2) + 0.00174 * (screenWidth - 128) + 0.76;

    if (beginX.abs() > beginY.abs()) {
      beginX = -1 * ratio;
      beginY = (beginY / beginX).abs() * ratio;
    }
    else {
      beginX = -((beginX / beginY).abs()) * ratio;
      beginY = 1 * ratio;
    }

    if (endX.abs() > endY.abs()) {
      endX = 1 * ratio;
      endY = -((endY / endX).abs()) * ratio;
    }
    else {
      endX = (endX / endY).abs() * ratio;
      endY = -1 * ratio;
    }

    return SizedBox(
      height: tabViewHeight,
      child: Stack(
        children: [
          SfCartesianChart(
            legend: Legend(
              isVisible: true,
              position: LegendPosition.top,
              iconWidth: 0,
              iconHeight: 0,
              textStyle: TextStyle(color: Colors.grey[300])
            ),
            primaryXAxis: NumericAxis(
              title: AxisTitle(text: AppLocalizations.of(context)!.hisEff),
              isInversed: true,
              majorGridLines: const MajorGridLines(
                width: 1,
                color: Colors.white
              ),
              maximum: 1,
              minimum: widget.minHisEff,
              interval: 0.1,
              plotOffset: 4,
              axisLabelFormatter: (details) {
                String label = '${(double.parse(details.text) * 100).toStringAsFixed(0)}%';
                return ChartAxisLabel(label, null);
              }
            ),
            primaryYAxis: NumericAxis(
              title: AxisTitle(text: AppLocalizations.of(context)!.laborDiff),
              maximum: widget.maxLaborDiff.toDouble(),
              minimum: 0,
              interval: 10,
              plotOffset: 4
            ),
            series: [
              AreaSeries(
                dataSource: [
                  BGData(1, widget.maxLaborDiff),
                  BGData(widget.minHisEff, widget.maxLaborDiff)
                ],
                xValueMapper: (datum, int index) {
                  return datum.x;
                },
                yValueMapper: (datum, int index) {
                  return datum.y;
                },
                gradient: LinearGradient(
                  begin: Alignment(beginX, beginY),
                  end: Alignment(endX, endY),
                  colors: const [
                    Colors.green,
                    Color.fromARGB(160, 121, 67, 1),
                    Colors.red
                  ],
                  stops: [0, 0.15/(1-widget.minHisEff), 1]
                ),
                animationDuration: 0,
              ),
              LineSeries(
                dataSource: [
                  BGData(1, 30),
                  BGData(0.8, 0),
                ],
                xValueMapper: (datum, int index) {
                  return datum.x;
                },
                yValueMapper: (datum, int index) {
                  return datum.y;
                },
                width: 1,
                dashArray: const [8, 8],
                color: const Color.fromRGBO(68, 84, 106, 1),
                animationDuration: 0,
              ),
              LineSeries(
                dataSource: [
                  BGData(1, 15),
                  BGData(0.7, 0),
                ],
                xValueMapper: (datum, int index) {
                  return datum.x;
                },
                yValueMapper: (datum, int index) {
                  return datum.y;
                },
                width: 1,
                dashArray: const [8, 8],
                color: const Color.fromRGBO(197, 90, 17, 1),
                animationDuration: 0,
              )
            ]
          ),
          SfCartesianChart(
            legend: const Legend(
              isVisible: true,
              position: LegendPosition.top,
              padding: 6
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text('${AppLocalizations.of(context)!.section} : ${series.name}\n${AppLocalizations.of(context)!.model} : ${data['Model']}\n${AppLocalizations.of(context)!.hisEff} : ${(double.parse(data['HisEff']) * 100).toStringAsFixed(1)}%\n${AppLocalizations.of(context)!.laborDiff} : ${data['LaborDiff']}', style: const TextStyle(color: Colors.white)),
                );
              }
            ),
            primaryXAxis: NumericAxis(
              title: AxisTitle(text: AppLocalizations.of(context)!.hisEff),
              isInversed: true,
              majorGridLines: const MajorGridLines(
                width: 1
              ),
              maximum: 1,
              minimum: widget.minHisEff,
              interval: 0.1,
              plotOffset: 4,
              axisLabelFormatter: (details) {
                String label = '${(double.parse(details.text) * 100).toStringAsFixed(0)}%';
                return ChartAxisLabel(label, null);
              }
            ),
            primaryYAxis: NumericAxis(
              title: AxisTitle(text: AppLocalizations.of(context)!.laborDiff),
              majorGridLines: const MajorGridLines(
                width: 1
              ),
              maximum: widget.maxLaborDiff.toDouble(),
              minimum: 0,
              interval: 10,
              plotOffset: 4,
            ),
            series: widget.leanRiskSeries
          )
        ],
      ),
    );
  }
}