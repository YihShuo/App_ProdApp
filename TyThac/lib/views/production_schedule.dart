import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:production/services/remote_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:production/components/side_menu.dart';

String apiAddress = '', userName = '', group = '', sArea = 'A', sFactory = 'ALL', title = '生產排程';
double screenWidth = 0, screenHeight = 0;
DateTime startDate = DateTime.now(), endDate = DateTime.now(), buyDate = DateTime(startDate.year, startDate.month-1, 1);
String startMonth = DateFormat('yyyy/MM').format(DateTime.now());
String endMonth = DateFormat('yyyy/MM').format(DateTime.now());
List<String> factoryListA = ['ALL', 'A02', 'A03', 'A07', 'A08', 'A09', 'A11', 'A12', 'A15', 'A16'];
List<String> factoryListC = ['ALL', 'C02'];
List<String> keyList = [];
List<GlobalKey<LegendItemState>> legendKey = [];
List<Widget> legend = [];
List<String> legendInvisible = [];
List<Color> palette = [], colorList = [];
List<Color> alertColor = [Colors.green, Colors.orangeAccent, Colors.red, Colors.grey];
List<Color> alertColor2 = [const Color.fromRGBO(56, 94, 15, 1), Colors.green, Colors.orangeAccent, Colors.red, Colors.grey];
List<Color> buyColor = const [
  Color.fromRGBO(200, 60, 60, 1),
  Color.fromRGBO(160, 110, 60, 1),
  Color.fromRGBO(65, 125, 25, 1),
  Color.fromRGBO(40, 100, 230, 1),
  Color.fromRGBO(140, 30, 150, 1),
  Color.fromRGBO(80, 80, 80, 1),
  Color.fromRGBO(150, 20, 20, 1),
  Color.fromRGBO(175, 190, 0, 1),
  Color.fromRGBO(10, 65, 20, 1),
  Color.fromRGBO(170, 80, 100, 1),
  Color.fromRGBO(40, 40, 230, 1),
  Color.fromRGBO(120, 120, 120, 1)
];
dynamic chartData;
String dataMode = 'BUY', scheduleMode = 'Stage2', version = '';
List<String> versionList = [], versionDate = [];
List<String> customTitle = ['現場目標效率', '成型歷史效率', '針車歷史效率', '成型人數', '針車人數'];
List<String> customOptions = ['C_TargetEff', 'C_HisEff_A', 'C_HisEff_S', 'LACategory', 'LSCategory'];
List<bool> customOptionStatus = [false, false, false, false, false, false, false];
List<String> customSelections = [];
String customDLTitle = '自定義比較';
String tempHFM = 'FitScreenSize', heightFitMode = 'FitScreenSize', tempWFM = 'FitScreenSize', widthFitMode = 'FitScreenSize';

class ProductionSchedule extends StatefulWidget {
  const ProductionSchedule({
    super.key,
  });

  @override
  ProductionScheduleState createState() => ProductionScheduleState();
}

class ProductionScheduleState extends State<ProductionSchedule> {
  bool firstLoad = true;
  String loadingStatus = 'No Data';
  double fixedWidth = 0, fixedHeight = 0;
  List<CartesianSeries<dynamic, dynamic>> chartSeries = [];
  Widget scheduleChart = const SizedBox();

  @override
  void initState() {
    super.initState();
    palette = generateFixedColorArray(500);
    loadUserInfo();
  }

  void loadUserInfo() async {
    String userID = '';

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString('userID') ?? '';
      userName = prefs.getString('userName') ?? '';
      group = prefs.getString('group') ?? '';
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  Future<void> loadScheduleData(String mode, version, orderDate) async {
    setState(() {
      loadingStatus = 'isLoading';
    });

    String versionDate = orderDate;
    if (mode == 'Stage1') {
      versionDate = await RemoteService().getStage1Date(
        apiAddress,
        version
      );
    }

    final body = await RemoteService().getProductionSchedule(
      apiAddress,
      DateFormat('yyyy/MM/dd').format(DateTime(startDate.year, startDate.month, 1)),
      DateFormat('yyyy/MM/dd').format(DateTime(endDate.year, endDate.month + 1, 0)),
      sArea,
      sFactory == 'ALL' ? '' : sFactory,
      mode,
      version,
      versionDate
    );
    chartData = json.decode(body);
    fixedWidth = (DateTime(endDate.year, endDate.month + 1, 0).difference(DateTime(startDate.year, startDate.month, 1)).inDays + 2) * 150;
    fixedHeight = (chartData.length) * 22.0 + 36;
    generateChart(chartData, 'Default', dataMode, DateTime(startDate.year, startDate.month, 1), DateTime(endDate.year, endDate.month + 1, 0));
  }

  List<Color> generateFixedColorArray(int length) {
    final Random random = Random(50);
    List<Color> colors = [];
    for (int i = 0; i < length; i++) {
      colors.add(Color.fromARGB(
        255,
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
      ));
    }
    return colors;
  }

  void legendChanged() {
    generateChart(chartData, 'Legend', dataMode, DateTime(startDate.year, startDate.month, 1), DateTime(endDate.year, endDate.month + 1, 0));
  }

  void generateChart(dynamic jsonData, String generateMode, String displayMode, DateTime sDate, DateTime eDate) {
    setState(() {
      loadingStatus = 'isLoading';
    });

    chartSeries = [];
    scheduleChart = const SizedBox();

    if (jsonData != null && jsonData.length > 0) {
      for (int custom = 0; custom < (displayMode == 'Custom' ? customSelections.length : 1); custom++) {
        String dpMode = displayMode == 'Custom' ? customSelections[custom] : displayMode;

        if (generateMode == 'Default') {
          keyList = [];
          legendKey = [];
          legend = [];
          legendInvisible = [];
          colorList = [];

          if (displayMode == 'Custom') {
            for (int i = 0; i < customSelections.length; i++) {
              List<String> customLegend = [];
              if (customSelections[i] == 'C_TargetEff' || customSelections[i] == 'C_Eff_RY_A'|| customSelections[i] == 'C_HisEff_A') {
                customLegend = ['高於 90%', '高於 80%', '低於 80%', '未設定參數'];
              }
              else if (customSelections[i] == 'C_Eff_RY_S' || customSelections[i] == 'C_HisEff_S') {
                customLegend = ['高於 85%', '高於 70%', '低於 70%', '未設定參數'];
              }
              else if (customSelections[i] == 'LACategory' || customSelections[i] == 'LSCategory') {
                customLegend = ['低於 5%', '低於 15%', '高於 15%', '未設定參數'];
              }

              legend.add(
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('${customTitle[customOptions.indexOf(customSelections[i])]}:'),
                )
              );
              for (int j = 0; j < customLegend.length; j++) {
                legend.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart, color: alertColor[j]),
                        Text(customLegend[j], style: TextStyle(color: alertColor[j]))
                      ],
                    ),
                  ),
                );
              }
              if (i < customSelections.length - 1) {
                legend.add(
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('|'),
                  )
                );
              }
            }
          }

          if (dpMode == 'C_Eff_RY_A' || dpMode == 'C_Eff_RY_S' || dpMode == 'C_TargetEff' || dpMode == 'C_HisEff_A' || dpMode == 'C_HisEff_S' || dpMode == 'C_HisPPH_A' || dpMode == 'C_HisPPH_S' || dpMode == 'GACCategory' || dpMode == 'WorkHour' || dpMode == 'LACategory' || dpMode == 'LSCategory') {
            List<String> items = [];
            if (dpMode == 'C_Eff_RY_A' || dpMode == 'C_TargetEff' || dpMode == 'C_HisEff_A' || dpMode == 'C_HisPPH_A') {
              items = ['高於 90%', '高於 80%', '低於 80%', '未設定參數'];
            }
            else if (dpMode == 'C_Eff_RY_S' || dpMode == 'C_HisEff_S' || dpMode == 'C_HisPPH_S') {
              items = ['高於 85%', '高於 70%', '低於 70%', '未設定參數'];
            }
            else if (dpMode == 'GACCategory') {
              items = ['超過 20 天', '20 天內', '10 天內', '5 天內'];
            }
            else if (dpMode == 'WorkHour') {
              items = ['8 小時', '9.5 小時', '12 小時', '無'];
            }
            else if (dpMode == 'LACategory' || dpMode == 'LSCategory') {
              items = ['低於 5%', '低於 15%', '高於 15%', '未設定參數'];
            }

            for (int i = 0; i < items.length; i++) {
              keyList.add(items[i]);
              if (displayMode != 'Custom') {
                GlobalKey<LegendItemState> key = GlobalKey();
                legendKey.add(key);
                legend.add(
                  LegendItem(
                    key: key,
                    index: i,
                    title: items[i],
                    foreColor: dpMode == 'GACCategory' ? alertColor2[i] : alertColor[i],
                    legendChanged: legendChanged
                  )
                );
                key.currentState?.resetStatus(true);
              }
            }
          }
        }

        int index = -1;
        String item = '', start = '', end = '';
        List<String> itemList = [];
        List<int> itemColorIndex = [];
        List<List<Map<String, Object>>> dataSourceList = [];

        for (int i = 0; i < jsonData.length; i++) {
          int dataLength = dpMode == 'WorkHour' ? jsonData[i]['WorkDays'].length : jsonData[i]['Schedule'].length;
          for (int j = 0; j < dataLength; j++) {
            item = dpMode == 'WorkHour' ? jsonData[i]['WorkDays'][j]['WorkHour'].toString() : jsonData[i]['Schedule'][j][dpMode].toString();
            if (generateMode == 'Default') {
              if (dpMode != 'C_Eff_RY_A' && dpMode != 'C_Eff_RY_S' && dpMode != 'C_TargetEff' && dpMode != 'C_HisEff_A' && dpMode != 'C_HisEff_S' && dpMode != 'C_HisPPH_A' && dpMode != 'C_HisPPH_S' && dpMode != 'GACCategory' && dpMode != 'WorkHour' && dpMode != 'LACategory' && dpMode != 'LSCategory' && keyList.contains(item) == false) {
                if (jsonData[i]['Schedule'][j]['Type'].toString() != 'EMPTY') {
                  keyList.add(item);
                  colorList.add(palette[keyList.length - 1]);
                  if (displayMode != 'Custom') {
                    int colorIndex = 1;
                    int? tryIndex;
                    if (dpMode == 'BUY') {
                      tryIndex = int.tryParse(item.substring(0, item.indexOf(' ')));
                      if (tryIndex == null) {
                        if (item.contains('SPRING')) {
                          colorIndex = 1;
                        }
                        else if (item.contains('SUMMER')) {
                          colorIndex = 2;
                        }
                        else if (item.contains('FALL')) {
                          colorIndex = 3;
                        }
                        else if (item.contains('WINTER')) {
                          colorIndex = 4;
                        }
                      }
                      else {
                        colorIndex = tryIndex;
                      }
                    }
                    GlobalKey<LegendItemState> key = GlobalKey();
                    legendKey.add(key);
                    legend.add(
                      LegendItem(
                        key: key,
                        index: keyList.length - 1,
                        title: item,
                        foreColor: dpMode == 'BUY' ? buyColor[colorIndex - 1] : palette[keyList.length - 1],
                        legendChanged: legendChanged
                      )
                    );
                    key.currentState?.resetStatus(true);
                  }
                }
              }
            }

            String efficiency = '';
            if (dpMode == 'C_TargetEff') {
              efficiency = jsonData[i]['TargetEff'].toString().isNotEmpty ? '[${jsonData[i]['TargetEff']}%] ' : '[無法預估] ';
            }
            else if (dpMode == 'C_Eff_RY_A') {
              efficiency = jsonData[i]['ActualEff_A'].toString().isNotEmpty ? '[${jsonData[i]['ActualEff_A']}%] ' : '[無相關資料] ';
            }
            else if (dpMode == 'C_Eff_RY_S') {
              efficiency = jsonData[i]['ActualEff_S'].toString().isNotEmpty ? '[${jsonData[i]['ActualEff_S']}%] ' : '[無相關資料] ';
            }
            else if (dpMode == 'C_HisEff_A') {
              efficiency = jsonData[i]['HisEff_A'].toString().isNotEmpty ? '[${jsonData[i]['HisEff_A']}%] ' : '[無歷史資料] ';
            }
            else if (dpMode == 'C_HisEff_S') {
              efficiency = jsonData[i]['HisEff_S'].toString().isNotEmpty ? '[${jsonData[i]['HisEff_S']}%] ' : '[無歷史資料] ';
            }
            else if (dpMode == 'C_HisPPH_A') {
              efficiency = jsonData[i]['HisPPH_A'].toString().isNotEmpty ? '[${jsonData[i]['HisPPH_A']}] ' : '[無歷史資料] ';
            }
            else if (dpMode == 'C_HisPPH_S') {
              efficiency = jsonData[i]['HisPPH_S'].toString().isNotEmpty ? '[${jsonData[i]['HisPPH_S']}] ' : '[無歷史資料] ';
            }

            index = itemList.indexOf(item);
            if (index < 0) {
              if (start != '') {
                itemList[itemList.length-1] = '${itemList[itemList.length-1]}@($start-$end)';
              }

              itemList.add(item);
              if (legendInvisible.contains(item)) {
                itemColorIndex.add(-1);
              }
              else {
                if (dpMode == 'BUY' && jsonData[i]['Schedule'][j]['Type'].toString() != 'EMPTY') {
                  int colorIndex = 1;
                  int? tryIndex = int.tryParse(item.substring(0, item.indexOf(' ')));
                  if (tryIndex == null) {
                    if (item.contains('SPRING')) {
                      colorIndex = 1;
                    }
                    else if (item.contains('SUMMER')) {
                      colorIndex = 2;
                    }
                    else if (item.contains('FALL')) {
                      colorIndex = 3;
                    }
                    else if (item.contains('WINTER')) {
                      colorIndex = 4;
                    }
                  }
                  else {
                    colorIndex = tryIndex;
                  }
                  itemColorIndex.add(colorIndex - 1);
                }
                else {
                  itemColorIndex.add(keyList.indexOf(item));
                }
              }
              if (dpMode == 'WorkHour') {
                dataSourceList.add([
                  {
                    'Lean': '$efficiency${jsonData[i]['Building']} ${jsonData[i]['Lean']}',
                    'Date': jsonData[i]['WorkDays'][j]['StartDate'].toString(),
                    'WorkHour': jsonData[i]['WorkDays'][j]['WorkHour'].toString(),
                    dpMode: item,
                    'Value': 86400
                  }
                ]);
                start = jsonData[i]['WorkDays'][j]['StartDate'].toString().substring(5, 10);
                end = jsonData[i]['WorkDays'][j]['EndDate'].toString().substring(5, 10);
              }
              else {
                dataSourceList.add([
                  {
                    'Lean': '${displayMode != 'Custom' ? efficiency : ''}${jsonData[i]['Building']} ${jsonData[i]['Lean']}',
                    'SKU': jsonData[i]['Schedule'][j]['SKU'].toString(),
                    'RY': jsonData[i]['Schedule'][j]['RY'].toString(),
                    'Pairs': jsonData[i]['Schedule'][j]['Pairs'],
                    'GAC': jsonData[i]['Schedule'][j]['GAC'].toString(),
                    dpMode: item,
                    'Value': jsonData[i]['Schedule'][j]['Value'],
                    'DaysBeforeGAC': jsonData[i]['Schedule'][j]['DaysBeforeGAC'],
                    'PM_Capacity': jsonData[i]['Schedule'][j]['PM_Capacity'],
                    'IE_Capacity': jsonData[i]['Schedule'][j]['IE_Capacity'],
                    //'Eff_RY_A': jsonData[i]['Schedule'][j]['Eff_RY_A'],
                    //'Eff_RY_S': jsonData[i]['Schedule'][j]['Eff_RY_S'],
                    'TargetEff': jsonData[i]['Schedule'][j]['TargetEff'],
                    'HisEff_A': jsonData[i]['Schedule'][j]['HisEff_A'],
                    'HisPPH_A': jsonData[i]['Schedule'][j]['HisPPH_A'],
                    'TargetPPH_A': jsonData[i]['Schedule'][j]['TargetPPH_A'],
                    'PPHRate_A': jsonData[i]['Schedule'][j]['PPHRate_A'],
                    'LaborA': jsonData[i]['Schedule'][j]['IE_LaborA'],
                    'HisEff_S': jsonData[i]['Schedule'][j]['HisEff_S'],
                    'HisPPH_S': jsonData[i]['Schedule'][j]['HisPPH_S'],
                    'TargetPPH_S': jsonData[i]['Schedule'][j]['TargetPPH_S'],
                    'PPHRate_S': jsonData[i]['Schedule'][j]['PPHRate_S'],
                    'Lean_S': jsonData[i]['Schedule'][j]['Lean_S'],
                    'LaborS': jsonData[i]['Schedule'][j]['IE_LaborS']
                  }
                ]);
                start = jsonData[i]['Schedule'][j]['StartDate'].toString().substring(5, 10);
                end = jsonData[i]['Schedule'][j]['EndDate'].toString().substring(5, 10);
              }
            }
            else {
              if (dpMode == 'WorkHour') {
                dataSourceList[index].add(
                  {
                    'Lean': '$efficiency${jsonData[i]['Building']} ${jsonData[i]['Lean']}',
                    'Date': jsonData[i]['WorkDays'][j]['StartDate'].toString(),
                    'WorkHour': jsonData[i]['WorkDays'][j]['WorkHour'].toString(),
                    dpMode: item,
                    'Value': 86400
                  }
                );
                end = jsonData[i]['WorkDays'][j]['EndDate'].toString().substring(5, 10);
              }
              else {
                dataSourceList[index].add(
                  {
                    'Lean': '${displayMode != 'Custom' ? efficiency : ''}${jsonData[i]['Building']} ${jsonData[i]['Lean']}',
                    'SKU': jsonData[i]['Schedule'][j]['SKU'].toString(),
                    'RY': jsonData[i]['Schedule'][j]['RY'].toString(),
                    'Pairs': jsonData[i]['Schedule'][j]['Pairs'],
                    'GAC': jsonData[i]['Schedule'][j]['GAC'].toString(),
                    dpMode: item,
                    'Value': jsonData[i]['Schedule'][j]['Value'],
                    'DaysBeforeGAC': jsonData[i]['Schedule'][j]['DaysBeforeGAC'],
                    'PM_Capacity': jsonData[i]['Schedule'][j]['PM_Capacity'],
                    'IE_Capacity': jsonData[i]['Schedule'][j]['IE_Capacity'],
                    //'Eff_RY_A': jsonData[i]['Schedule'][j]['Eff_RY_A'],
                    //'Eff_RY_S': jsonData[i]['Schedule'][j]['Eff_RY_S'],
                    'TargetEff': jsonData[i]['Schedule'][j]['TargetEff'],
                    'HisEff_A': jsonData[i]['Schedule'][j]['HisEff_A'],
                    'HisPPH_A': jsonData[i]['Schedule'][j]['HisPPH_A'],
                    'TargetPPH_A': jsonData[i]['Schedule'][j]['TargetPPH_A'],
                    'PPHRate_A': jsonData[i]['Schedule'][j]['PPHRate_A'],
                    'LaborA': jsonData[i]['Schedule'][j]['IE_LaborA'],
                    'HisEff_S': jsonData[i]['Schedule'][j]['HisEff_S'],
                    'HisPPH_S': jsonData[i]['Schedule'][j]['HisPPH_S'],
                    'TargetPPH_S': jsonData[i]['Schedule'][j]['TargetPPH_S'],
                    'PPHRate_S': jsonData[i]['Schedule'][j]['PPHRate_S'],
                    'Lean_S': jsonData[i]['Schedule'][j]['Lean_S'],
                    'LaborS': jsonData[i]['Schedule'][j]['IE_LaborS']
                  }
                );
                end = jsonData[i]['Schedule'][j]['EndDate'].toString().substring(5, 10);
              }
            }
          }
        }
        itemList[itemList.length-1] = '${itemList[itemList.length-1]}@($start-$end)';

        for (int i = 0; i < itemList.length; i++) {
          Color chartColor, borderColor;
          double borderWidth = 0.1;
          if (dpMode == 'C_Eff_RY_A' || dpMode == 'C_Eff_RY_S' || dpMode == 'C_TargetEff' || dpMode == 'C_HisEff_A' || dpMode == 'C_HisEff_S' || dpMode == 'C_HisPPH_A' || dpMode == 'C_HisPPH_S' || dpMode == 'GACCategory' || dpMode == 'WorkHour' || dpMode == 'LACategory' || dpMode == 'LSCategory') {
            if (itemColorIndex[i] >= 0) {
              if (dpMode == 'GACCategory') {
                chartColor = alertColor2[itemColorIndex[i]];
                borderColor = alertColor2[itemColorIndex[i]];
              }
              else {
                chartColor = alertColor[itemColorIndex[i]];
                borderColor = alertColor[itemColorIndex[i]];
              }
            }
            else {
              chartColor = Colors.transparent;
              borderColor = Colors.transparent;
            }
          }
          else {
            if (itemColorIndex[i] >= 0) {
              if (dpMode == 'BUY') {
                if (itemList[i].contains('SLT')) {
                  chartColor = buyColor[itemColorIndex[i]].withAlpha(75);
                  borderColor = buyColor[itemColorIndex[i]];
                  borderWidth = 1;
                }
                else {
                  chartColor = buyColor[itemColorIndex[i]];
                  borderColor = buyColor[itemColorIndex[i]];
                }
              }
              else {
                chartColor = colorList[itemColorIndex[i]];
                borderColor = colorList[itemColorIndex[i]];
              }
            }
            else {
              chartColor = Colors.transparent;
              borderColor = Colors.transparent;
            }
          }

          chartSeries.add(
            StackedBarSeries(
              groupName: displayMode == 'Custom' ? customSelections[custom] : '',
              onPointLongPress: (details) {
                legendInvisible = [];
                legendInvisible.addAll(keyList);
                String legend = itemList[i].substring(0, itemList[i].indexOf('@'));
                legendInvisible.remove(legend);

                for (int i = 0; i < legendKey.length; i++) {
                  legendKey[i].currentState?.resetStatus(keyList[i] == legend);
                }

                legendChanged();
              },
              dataLabelSettings: DataLabelSettings(
                isVisible: false,
                showCumulativeValues: true,
                builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                  return Text(data['RY']);
                }
              ),
              dataSource: dataSourceList[i],
              xValueMapper: (datum, int index) {
                return datum['Lean'];
              },
              yValueMapper: (datum, int index) {
                return datum['Value'];
              },
              name: itemList[i],
              borderColor: borderColor,
              borderWidth: borderWidth,
              color: chartColor,
              animationDuration: 0
            ),
          );
        }
      }

      List<CategoricalMultiLevelLabel> buyTitle = [];
      int buy = 0, buyStart = -1, buyEnd = -1;

      for (int i = 0; i <= eDate.difference(sDate).inDays; i++) {
        DateTime tempDate = sDate.add(Duration(seconds: 86400 * i));
        int tempBuy = tempDate.month - (tempDate.day >= 16 ? 2 : 3);
        tempBuy = tempBuy <= 0 ? tempBuy + 12 : tempBuy;

        if (tempBuy != buy) {
          if (buyStart >= 0) {
            buyTitle.add(
              CategoricalMultiLevelLabel(
                start: buyStart.toString(),
                end: buyEnd.toString(),
                text: '[ $buy BUY 預計負荷區間 ]'
              )
            );
          }

          buyStart = 86400 * i;
          buyEnd = 86400 * (i + 1);
          buy = tempBuy;
        }
        else {
          buyEnd = 86400 * (i + 1);
        }
      }
      buyTitle.add(
        CategoricalMultiLevelLabel(
          start: buyStart.toString(),
          end: buyEnd.toString(),
          text: '[ $buy BUY 預計負荷區間 ]'
        )
      );

      scheduleChart = SfCartesianChart(
        plotAreaBorderWidth: 0,
        tooltipBehavior: TooltipBehavior(
          enable: true,
          activationMode: ActivationMode.doubleTap,
          tooltipPosition: TooltipPosition.pointer,
          builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
            String lean = data['Lean'].toString().contains('] ') ? data['Lean'].toString().substring(data['Lean'].toString().indexOf('] ') + 2) : data['Lean'];
            String toolTitle = '';
            if (displayMode == 'C_TargetEff') {
              toolTitle = '現場目標效率';
              String pm = data['PM_Capacity'] > 0 ? data['PM_Capacity'].toString() : '未設定';
              String ie = data['IE_Capacity'] > 0 ? data['IE_Capacity'].toString() : '未設定';
              if (data['TargetEff'].toString().contains('-')) {
                if (data['RY'].toString().contains('預告')) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  0%', style: const TextStyle(color: Colors.white)),
                  );
                }
                else {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  0% [生管 $pm] / [IE $ie]', style: const TextStyle(color: Colors.white)),
                  );
                }
              }
              else {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  ${data['TargetEff']}% [生管 $pm] / [IE $ie]', style: const TextStyle(color: Colors.white)),
                );
              }
            }
            else if (displayMode == 'C_Eff_RY_A') {
              toolTitle = '成型實際基礎效率';
              if (data['Eff_RY_A'].toString().contains('-')) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  0%', style: const TextStyle(color: Colors.white)),
                );
              }
              else {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  ${data['Eff_RY_A']}%', style: const TextStyle(color: Colors.white)),
                );
              }
            }
            else if (displayMode == 'C_Eff_RY_S') {
              toolTitle = '針車實際基礎效率';
              String leanS = data['Lean_S'].toString().isNotEmpty ? '\n生產線:  ${data['Lean_S']}' : '';
              if (data['Eff_RY_S'].toString().contains('-')) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  0%$leanS', style: const TextStyle(color: Colors.white)),
                );
              }
              else {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  ${data['Eff_RY_S']}%$leanS', style: const TextStyle(color: Colors.white)),
                );
              }
            }
            else if (displayMode == 'C_HisEff_A') {
              toolTitle = '成型歷史效率';
              if (data['HisEff_A'].toString().contains('-')) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  0%', style: const TextStyle(color: Colors.white)),
                );
              }
              else {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  ${data['HisEff_A']}%', style: const TextStyle(color: Colors.white)),
                );
              }
            }
            else if (displayMode == 'C_HisEff_S') {
              toolTitle = '針車歷史效率';
              String leanS = data['Lean_S'].toString().isNotEmpty ? '\n生產線:  ${data['Lean_S']}' : '';
              if (data['HisEff_S'].toString().contains('-')) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  0%$leanS', style: const TextStyle(color: Colors.white)),
                );
              }
              else {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  ${data['HisEff_S']}%$leanS', style: const TextStyle(color: Colors.white)),
                );
              }
            }
            else if (displayMode == 'C_HisPPH_A') {
              toolTitle = '成型歷史 PPH 達成率';
              String his = double.parse(data['HisPPH_A'].toString()) > 0 ? data['HisPPH_A'].toString() : '未設定';
              String ie = double.parse(data['TargetPPH_A'].toString()) > 0 ? data['TargetPPH_A'].toString() : '未設定';
              if (double.parse(data['PPHRate_A']) <= 0) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  0% [歷史 $his] / [標準 $ie]', style: const TextStyle(color: Colors.white)),
                );
              }
              else {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  ${data['PPHRate_A']}% [歷史 $his] / [標準 $ie]', style: const TextStyle(color: Colors.white)),
                );
              }
            }
            else if (displayMode == 'C_HisPPH_S') {
              toolTitle = '針車歷史 PPH 達成率';
              String leanS = data['Lean_S'].toString().isNotEmpty ? '\n生產線:  ${data['Lean_S']}' : '';
              String his = double.parse(data['HisPPH_S'].toString()) > 0 ? data['HisPPH_S'].toString() : '未設定';
              String ie = double.parse(data['TargetPPH_S'].toString()) > 0 ? data['TargetPPH_S'].toString() : '未設定';
              if (double.parse(data['PPHRate_S']) <= 0) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  0% [歷史 $his] / [標準 $ie]$leanS', style: const TextStyle(color: Colors.white)),
                );
              }
              else {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  ${data['PPHRate_S']}% [歷史 $his] / [標準 $ie]$leanS', style: const TextStyle(color: Colors.white)),
                );
              }
            }
            else if (displayMode == 'GACCategory') {
              toolTitle = '出貨預留天數';

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  ${data['DaysBeforeGAC']} 天', style: const TextStyle(color: Colors.white)),
              );
            }
            else if (displayMode == 'WorkHour') {
              toolTitle = '排定工時';

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text('日期:  ${data['Date']}\n排定工時:  ${data['WorkHour']}', style: const TextStyle(color: Colors.white)),
              );
            }
            else if (displayMode == 'LACategory') {
              toolTitle = '成型人數';

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  ${data['LaborA']} 人', style: const TextStyle(color: Colors.white)),
              );
            }
            else if (displayMode == 'LSCategory') {
              toolTitle = '針車人數';

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  ${data['LaborS']} 人', style: const TextStyle(color: Colors.white)),
              );
            }
            else if (displayMode == 'Custom') {
              toolTitle = '';
              String leanS = data['Lean_S'].toString().isNotEmpty ? '\n生產線:  ${data['Lean_S']}' : '';
              if (data.containsKey(customSelections[0])) {
                if (customSelections[0].contains('Category')) {
                  if (customSelections[0] == 'LACategory') {
                    toolTitle = '成型人數:  ${data['LaborA']}人';
                  }
                  else {
                    toolTitle = '針車人數:  ${data['LaborS']}人';
                  }
                }
                else {
                  toolTitle = '${customTitle[customOptions.indexOf(customSelections[0])]}:  ${data[customSelections[0].replaceAll('C_', '')]}%';
                }
              }
              else {
                if (customSelections[1].contains('Category')) {
                  if (customSelections[1] == 'LACategory') {
                    toolTitle = '成型人數:  ${data['LaborA']}人';
                  }
                  else {
                    toolTitle = '針車人數:  ${data['LaborS']}人';
                  }
                }
                else {
                  toolTitle = '${customTitle[customOptions.indexOf(customSelections[1])]}:  ${data[customSelections[1].replaceAll('C_', '')]}%';
                }
              }

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle$leanS', style: const TextStyle(color: Colors.white)),
              );
            }
            else {
              if (displayMode == 'BUY') {
                toolTitle = 'BUY 別';
              }
              else if (displayMode == 'CuttingDie') {
                toolTitle = '斬刀';
              }
              else if (displayMode == 'ModelCategory') {
                toolTitle = '產品族';
              }
              else if (displayMode == 'AssemblyCode') {
                toolTitle = '成型編碼';
              }
              else if (displayMode == 'StitchingCode') {
                toolTitle = '針車編碼';
              }

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text('線別:  $lean\nSKU:  ${data['SKU']}\nRY:  ${data['RY']}\n雙數:  ${data['Pairs']}\n訂單交期:  ${data['GAC']}\n$toolTitle:  ${data[displayMode]}', style: const TextStyle(color: Colors.white)),
              );
            }
          }
        ),
        primaryXAxis: const CategoryAxis(
          isInversed: true,
          interval: 1,
          labelStyle: TextStyle(fontSize: 10),
        ),
        primaryYAxis: CategoryAxis(
          opposedPosition: true,
          interval: 86400,
          minimum: 0,
          maximum: eDate.difference(sDate).inSeconds * 1.0 + 86400,
          majorGridLines: const MajorGridLines(
            width: 1,
            color: Color.fromRGBO(207, 203, 212, 1)
          ),
          axisLabelFormatter: (details) {
            DateTime valueDate = sDate.add(Duration(seconds: details.value.ceil()));
            String label = valueDate.isBefore(eDate) || valueDate == eDate ? DateFormat(' MM/dd ').format(valueDate) : '';
            return ChartAxisLabel(label, null);
          },
          multiLevelLabels: buyTitle,
          multiLevelLabelStyle: const MultiLevelLabelStyle(
            textStyle: TextStyle(color: Colors.blue),
            borderColor: Colors.grey,
            borderWidth: 1,
            borderType: MultiLevelBorderType.squareBrace
          ),
        ),
        series: chartSeries
      );

      setState(() {
        title = sFactory != 'ALL' ? '$sFactory 生產排程' : '全廠 生產排程';
        loadingStatus = 'Completed';
      });
    }
    else {
      setState(() {
        loadingStatus = 'No Data';
      });
    }
  }

  void reFit(String heightMode, widthMode) {
    setState(() {
      heightFitMode = heightMode;
      widthFitMode = widthMode;
    });

  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - kBottomNavigationBarHeight;

    Future.delayed(Duration.zero, () {
      if (firstLoad) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return LeanFilter(
              refresh: loadScheduleData,
            );
          },
        );
        firstLoad = false;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
                    refresh: loadScheduleData,
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
        child: Column(
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, right: 4),
                  child: Text('顯示資料'),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 8),
                    child: SizedBox(
                      height: 45,
                      width: 100,
                      child: DropdownButton(
                        isExpanded: true,
                        underline: Container(
                          height: 1,
                          color: const Color.fromRGBO(182, 180, 184, 1)
                        ),
                        value: dataMode,
                        items: [
                          const DropdownMenuItem(
                            value: 'C_TargetEff',
                            child: Center(
                              child: Text('現場目標效率')
                            ),
                          ),
                          /*const DropdownMenuItem(
                            value: 'C_Eff_RY_A',
                            child: Center(
                              child: Text('成型實際基礎效率')
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'C_Eff_RY_S',
                            child: Center(
                              child: Text('針車實際基礎效率')
                            ),
                          ),*/
                          const DropdownMenuItem(
                            value: 'C_HisEff_A',
                            child: Center(
                              child: Text('成型歷史效率')
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'C_HisEff_S',
                            child: Center(
                              child: Text('針車歷史效率')
                            ),
                          ),
                          /*DropdownMenuItem(
                            value: 'C_HisPPH_A',
                            child: Center(
                              child: Text('成型歷史 PPH 達成率')
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'C_HisPPH_S',
                            child: Center(
                              child: Text('針車歷史 PPH 達成率')
                            ),
                          ),*/
                          const DropdownMenuItem(
                            value: 'BUY',
                            child: Center(
                              child: Text('接單 BUY 別')
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'CuttingDie',
                            child: Center(
                              child: Text('斬刀')
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'ModelCategory',
                            child: Center(
                              child: Text('產品族')
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'AssemblyCode',
                            child: Center(
                              child: Text('成型編碼')
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'StitchingCode',
                            child: Center(
                              child: Text('針車編碼')
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'LACategory',
                            child: Center(
                              child: Text('成型人數')
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'LSCategory',
                            child: Center(
                              child: Text('針車人數')
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'GACCategory',
                            child: Center(
                              child: Text('出貨預留天數')
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'WorkHour',
                            child: Center(
                              child: Text('排定工時')
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Custom',
                            child: Center(
                              child: Text(customDLTitle)
                            ),
                          )
                        ],
                        onChanged: (value) {
                          FocusScope.of(context).requestFocus(FocusNode());
                          if (value == 'Custom') {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  scrollable: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8))
                                  ),
                                  content: Column(
                                    children: [
                                      CheckboxListItem(index: 0, title: customTitle[0]),
                                      CheckboxListItem(index: 1, title: customTitle[1]),
                                      CheckboxListItem(index: 2, title: customTitle[2]),
                                      CheckboxListItem(index: 3, title: customTitle[3]),
                                      CheckboxListItem(index: 4, title: customTitle[4]),
                                      const Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text('* 請選擇兩個項目進行比較', style: TextStyle(color: Colors.red)),
                                      )
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        if (customSelections.length == 2) {
                                          if (customOptions.indexOf(customSelections[0]) > customOptions.indexOf(customSelections[1])) {
                                            customSelections.insert(0, customSelections[1]);
                                            customSelections.removeAt(2);
                                          }

                                          setState(() {
                                            customDLTitle = '自定義比較 - [${customTitle[customOptions.indexOf(customSelections[0])]}] 對比 [${customTitle[customOptions.indexOf(customSelections[1])]}]';
                                            dataMode = 'Custom';
                                          });
                                          generateChart(chartData, 'Default', dataMode, DateTime(startDate.year, startDate.month, 1), DateTime(endDate.year, endDate.month + 1, 0));
                                          Navigator.of(context).pop();
                                        }
                                        else {
                                          Fluttertoast.showToast(
                                            msg: '請選擇 2 個項目',
                                            gravity: ToastGravity.BOTTOM,
                                            toastLength: Toast.LENGTH_SHORT,
                                          );
                                        }
                                      },
                                      child: const Text('確定'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                          else {
                            setState(() {
                              dataMode = value!;
                            });
                            generateChart(chartData, 'Default', dataMode, DateTime(startDate.year, startDate.month, 1), DateTime(endDate.year, endDate.month + 1, 0));
                          }
                        }
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      showDragHandle: true,
                      isScrollControlled: false,
                      context: context, builder: (BuildContext context) {
                        return ConstrainedBox(
                          constraints: const BoxConstraints(),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 8, left: 16, right: 16),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('各棟產品族', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))
                                    ),
                                  ),
                                  const Text('A02', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: TextField(
                                          readOnly: true,
                                          maxLines: null,
                                          keyboardType: TextInputType.multiline,
                                          decoration: const InputDecoration.collapsed(hintText: ''),
                                          controller: TextEditingController(text: 'L1:  鑰匙圈、開口笑、基本款\nL2:  基本款\nL3:  基本款\nL4:  基本款')
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                    child: Divider(),
                                  ),
                                  const Text('A03', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: TextField(
                                          readOnly: true,
                                          maxLines: null,
                                          keyboardType: TextInputType.multiline,
                                          decoration: const InputDecoration.collapsed(hintText: ''),
                                          controller: TextEditingController(text: 'L1:  D52\nL2:  079、080\nL3:  079、080\nL4:  LIFT、基本款 (特殊)\nL5:  基本款')
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                    child: Divider(),
                                  ),
                                  const Text('A07', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: TextField(
                                          readOnly: true,
                                          maxLines: null,
                                          keyboardType: TextInputType.multiline,
                                          decoration: const InputDecoration.collapsed(hintText: ''),
                                          controller: TextEditingController(text: 'L1:  毛勾帶\nL2:  毛勾帶\nL3:  CHUCK 70\nL4:  E16、基本款 (特殊)')
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                    child: Divider(),
                                  ),
                                  const Text('A08', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: TextField(
                                          readOnly: true,
                                          maxLines: null,
                                          keyboardType: TextInputType.multiline,
                                          decoration: const InputDecoration.collapsed(hintText: ''),
                                          controller: TextEditingController(text: 'L1:  LIFT\nL2:  LIFT\nL3:  滑板鞋B\nL4:  滑板鞋B')
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                    child: Divider(),
                                  ),
                                  const Text('A09', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: TextField(
                                          readOnly: true,
                                          maxLines: null,
                                          keyboardType: TextInputType.multiline,
                                          decoration: const InputDecoration.collapsed(hintText: ''),
                                          controller: TextEditingController(text: 'L1:  滑板鞋A、CHUCK 70、CHUCK 70 (特殊)\nL2:  滑板鞋A、CHUCK 70、CHUCK 70 (特殊)\nL3:  滑板鞋A、CHUCK 70、CHUCK 70 (特殊)\nL4:  滑板鞋A、CHUCK 70、CHUCK 70 (特殊)')
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                    child: Divider(),
                                  ),
                                  const Text('A11', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: TextField(
                                          readOnly: true,
                                          maxLines: null,
                                          keyboardType: TextInputType.multiline,
                                          decoration: const InputDecoration.collapsed(hintText: ''),
                                          controller: TextEditingController(text: 'L1:  基本款\nL2:  基本款\nL3:  基本款\nL4:  基本款\nL6: BB鞋')
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                    child: Divider(),
                                  ),
                                  const Text('A12', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: TextField(
                                          readOnly: true,
                                          maxLines: null,
                                          keyboardType: TextInputType.multiline,
                                          decoration: const InputDecoration.collapsed(hintText: ''),
                                          controller: TextEditingController(text: 'L1:  加硫 (防水)\nL2:  CHUCK 70 (複雜)\nL3:  LIFT\nL4:  基本款')
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                    child: Divider(),
                                  ),
                                  const Text('A15', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: TextField(
                                          readOnly: true,
                                          maxLines: null,
                                          keyboardType: TextInputType.multiline,
                                          decoration: const InputDecoration.collapsed(hintText: ''),
                                          controller: TextEditingController(text: 'L1:  半加硫半冷貼\nL3:  半加硫半冷貼\nL4:  半加硫半冷貼\nL5:  冷貼\nL6:  半加硫半冷貼')
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                    child: Divider(),
                                  ),
                                  const Text('A16', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: TextField(
                                          readOnly: true,
                                          maxLines: null,
                                          keyboardType: TextInputType.multiline,
                                          decoration: const InputDecoration.collapsed(hintText: ''),
                                          controller: TextEditingController(text: 'L1:  半加硫半冷貼 (防水)\nL2:  CHUCK 70\nL3:  基本款\nL4:  基本款')
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.info_outline)
                ),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      showDragHandle: true,
                      isScrollControlled: false,
                      context: context, builder: (BuildContext context) {
                        return FitModeBox(
                          reFit: reFit
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.settings)
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: legend,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    legendInvisible = [];
                    for (int i = 0; i < legendKey.length; i++) {
                      legendKey[i].currentState?.resetStatus(true);
                    }
                    legendChanged();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('重設', style: TextStyle(color: Colors.blue)
                    )
                  )
                )
              ],
            ),
            loadingStatus == 'Completed'
            ? Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: heightFitMode == 'FitScreenSize' ? MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - kBottomNavigationBarHeight - 13 : fixedHeight * (dataMode == 'Custom' ? 2 : 1),
                    width: widthFitMode == 'FitScreenSize' ? MediaQuery.of(context).size.width : fixedWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: scheduleChart
                    )
                  )
                ),
              ),
            )
            : loadingStatus == 'isLoading'
            ? SizedBox(
                height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - kBottomNavigationBarHeight - 20,
                child: const Center(
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(color: Colors.blue),
                  ),
                ),
              )
            : SizedBox(
                height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - kBottomNavigationBarHeight - 20,
                child: const Center(
                  child: Text('查無排程資訊', style: TextStyle(fontSize: 16))
                )
              )
          ],
        )
      )
    );
  }
}

class LegendItem extends StatefulWidget {
  const LegendItem({
    super.key,
    required this.index,
    required this.title,
    required this.foreColor,
    required this.legendChanged
  });
  final int index;
  final String title;
  final Color foreColor;
  final Function legendChanged;

  @override
  State<StatefulWidget> createState() => LegendItemState();
}

class LegendItemState extends State<LegendItem> {
  bool selected = true;

  void resetStatus(bool status) {
    setState(() {
      selected = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          selected = !selected;
          if (selected) {
            legendInvisible.remove(widget.title);
          }
          else {
            legendInvisible.add(widget.title);
          }
          widget.legendChanged();
        });
      },
      onLongPress: () {
        setState(() {
          legendInvisible = [];
          legendInvisible.addAll(keyList);
          legendInvisible.remove(widget.title);
          for (int i = 0; i < legendKey.length; i++) {
            legendKey[i].currentState?.resetStatus(false);
          }
          selected = true;
          widget.legendChanged();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            widget.title.contains('SLT')
            ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 18,
                height: 15,
                decoration: BoxDecoration(
                  color: selected ? widget.foreColor.withAlpha(75) : Colors.grey.withAlpha(75),
                  border: Border.all(color: selected ? widget.foreColor : Colors.grey, width: 1)
                ),
              ),
            )
            : Icon(Icons.bar_chart, color: selected ? widget.foreColor : Colors.grey),
            Text(widget.title, style: TextStyle(color: selected ? widget.foreColor : Colors.grey, decoration: selected ? TextDecoration.none : TextDecoration.lineThrough))
          ],
        ),
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
  final TextEditingController buyController = TextEditingController(text: DateFormat('yyyy/MM').format(buyDate));
  final TextEditingController startDateController = TextEditingController(text: DateFormat('yyyy/MM').format(startDate));
  final TextEditingController endDateController = TextEditingController(text: DateFormat('yyyy/MM').format(endDate));
  bool loadSuccess = true;

  @override
  void initState() {
    getScheduleVersion();
    super.initState();
  }

  Future<void> getScheduleVersion() async {
    setState(() {
      loadSuccess = false;
    });

    final body = await RemoteService().getScheduleVersion(
      apiAddress,
      DateFormat('yyyy/MM/dd').format(DateTime(startDate.year, startDate.month, 1)),
      DateFormat('yyyy/MM/dd').format(DateTime(endDate.year, endDate.month + 1, 0)),
      sArea,
      sFactory == 'ALL' ? '' : sFactory
    );
    final jsonData = json.decode(body);

    versionList = [];
    versionDate = [];
    for (int i = 0; i < jsonData.length; i++) {
      versionList.add(jsonData[i]['Version']);
      versionDate.add(jsonData[i]['OrderDate']);
    }

    setState(() {
      versionList = versionList;
    });

    if (versionList.contains(version) == false) {
      setState(() {
        version = versionList[0];
      });
    }

    setState(() {
      loadSuccess = true;
    });
  }

  bool checkMonthRange(DateTime sDate, DateTime eDate) {
    int yearGap = eDate.year - sDate.year;
    int monthGap = eDate.month + yearGap * 12 - sDate.month;
    return monthGap > 5;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      content: loadSuccess ? Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('起始月份：')
          ),
          SizedBox(
            height: 40,
            child: TextField(
              readOnly: true,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.bottom,
              controller: startDateController,
              onTap: () {
                showMonthPicker(
                  context: context,
                  initialDate: startDate,
                  monthPickerDialogSettings: const MonthPickerDialogSettings(
                    headerSettings: PickerHeaderSettings(
                      headerBackgroundColor: Colors.blue
                    ),
                    dialogSettings: PickerDialogSettings(
                      dialogRoundedCornersRadius: 10,
                    ),
                    dateButtonsSettings: PickerDateButtonsSettings(
                      selectedMonthBackgroundColor: Colors.blue
                    ),
                    actionBarSettings: PickerActionBarSettings(
                      confirmWidget: Text('確定'),
                      cancelWidget: Text('取消')
                    ),
                  ),
                ).then((date) async {
                  if (date != null) {
                    setState(() {
                      startDate = date;
                      startDateController.text = DateFormat('yyyy/MM').format(startDate);
                      startMonth = startDateController.text;
                      if (endDate.isBefore(startDate)) {
                        endDate = startDate;
                        endDateController.text = DateFormat('yyyy/MM').format(endDate);
                        endMonth = endDateController.text;
                      }
                      else if (checkMonthRange(startDate, endDate)) {
                        endDate = DateTime(startDate.year, startDate.month + 5, startDate.day);
                        endDateController.text = DateFormat('yyyy/MM').format(endDate);
                        endMonth = endDateController.text;
                      }
                    });
                    getScheduleVersion();
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
                      initialDate: startDate,
                      monthPickerDialogSettings: const MonthPickerDialogSettings(
                        headerSettings: PickerHeaderSettings(
                          headerBackgroundColor: Colors.blue
                        ),
                        dialogSettings: PickerDialogSettings(
                          dialogRoundedCornersRadius: 10,
                        ),
                        dateButtonsSettings: PickerDateButtonsSettings(
                          selectedMonthBackgroundColor: Colors.blue
                        ),
                        actionBarSettings: PickerActionBarSettings(
                          confirmWidget: Text('確定'),
                          cancelWidget: Text('取消')
                        ),
                      ),
                    ).then((date) async {
                      if (date != null) {
                        setState(() {
                          startDate = date;
                          startDateController.text = DateFormat('yyyy/MM').format(startDate);
                          startMonth = startDateController.text;
                          if (endDate.isBefore(startDate)) {
                            endDate = startDate;
                            endDateController.text = DateFormat('yyyy/MM').format(endDate);
                            endMonth = endDateController.text;
                          }
                          else if (checkMonthRange(startDate, endDate)) {
                            endDate = DateTime(startDate.year, startDate.month + 5, startDate.day);
                            endDateController.text = DateFormat('yyyy/MM').format(endDate);
                            endMonth = endDateController.text;
                          }
                        });
                        getScheduleVersion();
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('結束月份：')
          ),
          SizedBox(
            height: 40,
            child: TextField(
              readOnly: true,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.bottom,
              controller: endDateController,
              onTap: () {
                showMonthPicker(
                  context: context,
                  initialDate: endDate,
                  monthPickerDialogSettings: const MonthPickerDialogSettings(
                    headerSettings: PickerHeaderSettings(
                      headerBackgroundColor: Colors.blue
                    ),
                    dialogSettings: PickerDialogSettings(
                      dialogRoundedCornersRadius: 10,
                    ),
                    dateButtonsSettings: PickerDateButtonsSettings(
                      selectedMonthBackgroundColor: Colors.blue
                    ),
                    actionBarSettings: PickerActionBarSettings(
                      confirmWidget: Text('確定'),
                      cancelWidget: Text('取消')
                    ),
                  ),
                ).then((date) async {
                  if (date != null) {
                    setState(() {
                      endDate = date;
                      endDateController.text = DateFormat('yyyy/MM').format(endDate);
                      endMonth = endDateController.text;
                      if (startDate.isAfter(endDate)) {
                        startDate = endDate;
                        startDateController.text = DateFormat('yyyy/MM').format(startDate);
                        startMonth = startDateController.text;
                      }
                      else if (checkMonthRange(startDate, endDate)) {
                        startDate = DateTime(endDate.year, endDate.month - 5, endDate.day);
                        startDateController.text = DateFormat('yyyy/MM').format(startDate);
                        startMonth = startDateController.text;
                      }
                    });
                    getScheduleVersion();
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
                      initialDate: endDate,
                      monthPickerDialogSettings: const MonthPickerDialogSettings(
                        headerSettings: PickerHeaderSettings(
                          headerBackgroundColor: Colors.blue
                        ),
                        dialogSettings: PickerDialogSettings(
                          dialogRoundedCornersRadius: 10,
                        ),
                        dateButtonsSettings: PickerDateButtonsSettings(
                          selectedMonthBackgroundColor: Colors.blue
                        ),
                        actionBarSettings: PickerActionBarSettings(
                          confirmWidget: Text('確定'),
                          cancelWidget: Text('取消')
                        ),
                      ),
                    ).then((date) async {
                      if (date != null) {
                        setState(() {
                          endDate = date;
                          endDateController.text = DateFormat('yyyy/MM').format(endDate);
                          endMonth = endDateController.text;
                          if (startDate.isAfter(endDate)) {
                            startDate = endDate;
                            startDateController.text = DateFormat('yyyy/MM').format(startDate);
                            startMonth = startDateController.text;
                          }
                          else if (checkMonthRange(startDate, endDate)) {
                            startDate = DateTime(endDate.year, endDate.month - 5, endDate.day);
                            startDateController.text = DateFormat('yyyy/MM').format(startDate);
                            startMonth = startDateController.text;
                          }
                        });
                        getScheduleVersion();
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          /*const Align(
            alignment: Alignment.centerLeft,
            child: Text('排程類型：')
          ),
          SizedBox(
            height: 45,
            child: DropdownButton(
              isExpanded: true,
              underline: Container(
                height: 1,
                color: const Color.fromRGBO(182, 180, 184, 1)
              ),
              value: scheduleMode,
              items: const [
                DropdownMenuItem(
                  value: 'Stage1',
                  child: Center(
                    child: Text('一階排程')
                  ),
                ),
                DropdownMenuItem(
                  value: 'Stage2',
                  child: Center(
                    child: Text('二階排程')
                  ),
                )
              ],
              onChanged: (value) {
                setState(() {
                  scheduleMode = value.toString();
                });
              }
            ),
          ),
          Visibility(
            visible: scheduleMode == 'Stage1',
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('BUY 別：')
            ),
          ),
          Visibility(
            visible: scheduleMode == 'Stage1',
            child: SizedBox(
              height: 40,
              child: TextField(
                readOnly: true,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.bottom,
                controller: buyController,
                onTap: () {
                  showMonthPicker(
                    context: context,
                    headerColor: Colors.blue,
                    selectedMonthBackgroundColor: Colors.blue,
                    initialDate: buyDate,
                    roundedCornersRadius: 10,
                    cancelWidget: const Text('取消'),
                    confirmWidget: const Text('確定'),
                  ).then((date) async {
                    if (date != null) {
                      setState(() {
                        buyDate = date;
                        buyController.text = DateFormat('yyyy/MM').format(buyDate);
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
                        headerColor: Colors.blue,
                        selectedMonthBackgroundColor: Colors.blue,
                        initialDate: buyDate,
                        roundedCornersRadius: 10,
                        cancelWidget: const Text('取消'),
                        confirmWidget: const Text('確定'),
                      ).then((date) async {
                        if (date != null) {
                          setState(() {
                            buyDate = date;
                            buyController.text = DateFormat('yyyy/MM').format(date);
                          });
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: scheduleMode == 'Stage1',
            child: const SizedBox(height: 10)
          ),*/
          Visibility(
            visible: scheduleMode == 'Stage2',
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('排程版本：')
            ),
          ),
          Visibility(
            visible: scheduleMode == 'Stage2',
            child: DropdownButton<String>(
              isExpanded: true,
              underline: Container(
                height: 1,
                color: Colors.grey,
              ),
              value: version,
              items: versionList.map((String ver) {
                return DropdownMenuItem(
                  value: ver,
                  child: Center(
                    child: Text(ver.toString()),
                  )
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  version = value!;
                });
              },
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('廠區')
          ),
          DropdownButton<String>(
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Colors.grey,
            ),
            value: sArea,
            items: const [
              DropdownMenuItem(
                value: 'A',
                child: Center(
                  child: Text('A廠區'),
                )
              ),
              /*DropdownMenuItem(
                value: 'C',
                child: Center(
                  child: Text('C廠區'),
                )
              )*/
            ],
            onChanged: (value) {
              setState(() {
                if (sArea != value) {
                  sFactory = 'ALL';
                }
                sArea = value!;
              });
              getScheduleVersion();
            },
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('棟別')
          ),
          DropdownButton<String>(
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Colors.grey,
            ),
            value: sFactory,
            items: sArea == 'A' ? factoryListA.map((String factory) {
              return DropdownMenuItem(
                value: factory,
                child: Center(
                  child: factory == 'ALL' ? const Text('全廠') : Text(factory.toString()),
                )
              );
            }).toList()
            : factoryListC.map((String factory) {
              return DropdownMenuItem(
                value: factory,
                child: Center(
                  child: factory == 'ALL' ? const Text('全廠') : Text(factory.toString()),
                )
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                sFactory = value!;
              });
              getScheduleVersion();
            },
          ),
          const Align(
            alignment: Alignment.center,
            child: Text('* 查詢跨度上限為6個月', style: TextStyle(color: Colors.red))
          ),
        ],
      ) : const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.blue,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            if (scheduleMode == 'Stage1') {
              widget.refresh(scheduleMode, buyController.text, '');
            }
            else {
              widget.refresh(scheduleMode, version, versionDate[versionList.indexOf(version)]);
            }
          },
          child: const Text('確定'),
        ),
      ],
    );
  }
}

class FitModeBox extends StatefulWidget {
  const FitModeBox({
    super.key,
    required this.reFit
  });

  final Function reFit;

  @override
  State<StatefulWidget> createState() => FitModeBoxState();
}

class FitModeBoxState extends State<FitModeBox> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 250),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('高度：')
                ),
                SizedBox(
                  height: 45,
                  child: DropdownButton(
                    isExpanded: true,
                    underline: Container(
                      height: 1,
                      color: const Color.fromRGBO(182, 180, 184, 1)
                    ),
                    value: tempHFM,
                    items: const [
                      DropdownMenuItem(
                        value: 'FitScreenSize',
                        child: Center(
                          child: Text('符合螢幕大小', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'FixedSize',
                        child: Center(
                          child: Text('固定間距', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                        ),
                      )
                    ],
                    onChanged: (value) {
                      setState(() {
                        tempHFM = value.toString();
                      });
                    }
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('寬度：')
                ),
                SizedBox(
                  height: 45,
                  child: DropdownButton(
                    isExpanded: true,
                    underline: Container(
                      height: 1,
                      color: const Color.fromRGBO(182, 180, 184, 1)
                    ),
                    value: tempWFM,
                    items: const [
                      DropdownMenuItem(
                        value: 'FitScreenSize',
                        child: Center(
                          child: Text('符合螢幕大小', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'FixedSize',
                        child: Center(
                          child: Text('固定間距', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                        ),
                      )
                    ],
                    onChanged: (value) {
                      setState(() {
                        tempWFM = value.toString();
                      });
                    }
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      OutlinedButton(
                        onPressed: () async {
                          setState(() {
                            tempHFM = heightFitMode;
                            tempWFM = widthFitMode;
                          });
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8))
                          ),
                        ),
                        child: const Center(
                          child: Text('取消', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        )
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () async {
                          widget.reFit(tempHFM, tempWFM);
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8))
                          ),
                        ),
                        child: const Center(
                          child: Text('確定', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        )
                      ),
                    ],
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

class CheckboxListItem extends StatefulWidget {
  const CheckboxListItem({
    super.key,
    required this.index,
    required this.title
  });

  final int index;
  final String title;

  @override
  State<StatefulWidget> createState() => CheckboxListItemState();
}

class CheckboxListItemState extends State<CheckboxListItem> {
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: customOptionStatus[widget.index],
      title: Text(widget.title),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.blue,
      onChanged: (bool? value) {
        String id = customOptions[widget.index];
        if (value! && customSelections.contains(id) == false) {
          if (customSelections.length < 2) {
            customSelections.add(id);
            setState(() {
              customOptionStatus[widget.index] = value;
            });
          }
        }
        else {
          customSelections.remove(id);
          setState(() {
            customOptionStatus[widget.index] = value;
          });
        }
      },
    );
  }
}