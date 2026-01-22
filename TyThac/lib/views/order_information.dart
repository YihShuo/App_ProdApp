import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:production/components/side_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

String apiAddress = '';
double screenWidth = 0, screenHeight = 0;
DateTime selectedDate = DateTime.now();
String cuttingDie = '', last = '', sku = '', ry = '';

class ChartData {
  ChartData(this.title, this.value, this.color);
  final String title;
  final double value;
  final Color color;
}

class OrderInformation extends StatefulWidget {
  const OrderInformation({super.key});

  @override
  OrderInformationState createState() => OrderInformationState();
}

class OrderInformationState extends State<OrderInformation> with SingleTickerProviderStateMixin {
  String userName = '', factory = '', group = '';
  int total = 0, global = 0, slt = 0, tabIndex = 0, finishedRate = 0;
  double cHeight = 0, vulcanize = 0, coldVulcanize = 0, coldCement = 0, noCategory = 0;
  List<Widget> globalModel = [], sltModel = [];
  List<double> containerHeight = [0, 0];
  bool firstLoad = true;
  String loadingStatus = 'No Data';
  final events = [];
  bool scrollable = true;
  late TabController tabBarController;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    cuttingDie = '';
    last = '';
    sku = '';
    ry = '';
    tabBarController = TabController(length: 1, vsync: this);
    tabBarController.addListener(() {
      if (tabBarController.indexIsChanging) return;
      setState(() {
        cHeight = containerHeight[tabBarController.index];
      });
    });
    loadUserInfo();
  }

  @override
  void dispose() {
    tabBarController.dispose();
    super.dispose();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '';
    setState(() {
      userName = prefs.getString('userName') ?? '';
      factory = prefs.getString('factory') ?? '';
      group = prefs.getString('group') ?? '';
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  Future<void> loadBuyModels() async {
    setState(() {
      loadingStatus = 'isLoading';
    });

    final body = await RemoteService().getBuyModels(
      apiAddress,
      DateFormat('yyyyMM').format(selectedDate),
      factory,
      cuttingDie,
      last,
      sku,
      ry
    );
    final jsonData = json.decode(body);

    globalModel = [];
    sltModel = [];

    if (jsonData.length > 0) {
      global = jsonData['Global'];
      //slt = jsonData['SLT'];
      vulcanize = jsonData['Vulcanize'].toDouble();
      coldVulcanize = jsonData['ColdVulcanize'].toDouble();
      coldCement = jsonData['ColdCement'].toDouble();
      noCategory = jsonData['NoCategory'].toDouble();
      total = global /*+ slt*/;
      finishedRate = (jsonData['FinishedPairs'] * 100 / total).toInt();

      if (jsonData['GlobalModels'].length > 0) {
        containerHeight[0] = jsonData['GlobalModels'].length * 88.0 + 8;
        for (int j = 0; j < jsonData['GlobalModels'].length; j++) {
          globalModel.add(
            ModelCard(
              index: jsonData['GlobalModels'][j]['ID'],
              buy: jsonData['BuyNo'],
              type: 'GLOBAL',
              category: jsonData['GlobalModels'][j]['Category'],
              subCategory: jsonData['GlobalModels'][j]['SubCategory'],
              cuttingDie: jsonData['GlobalModels'][j]['CuttingDie'],
              buildings: jsonData['GlobalModels'][j]['Buildings'],
              pairs: jsonData['GlobalModels'][j]['Pairs'],
              finishedPairs: jsonData['GlobalModels'][j]['FinishedPairs'],
              percentage: jsonData['GlobalModels'][j]['Pairs'] * 100.0 / total,
              total: jsonData['GlobalModels'].length - 1,
              filterLast: last,
              filterSKU: sku,
              filterRY: ry
            )
          );
        }
      }
      else {
        containerHeight[0] = screenHeight - 250;
        globalModel.add(
          SizedBox(
            height: 20,
            child: Center(
              child: Text(AppLocalizations.of(context)!.noDataFound)
            )
          )
        );
      }

      /*if (jsonData['SLTModels'].length > 0) {
        containerHeight[1] = jsonData['SLTModels'].length * 88.0 + 8;
        for (int j = 0; j < jsonData['SLTModels'].length; j++) {
          sltModel.add(
            ModelCard(
              index: jsonData['SLTModels'][j]['ID'],
              buy: jsonData['BuyNo'],
              type: 'SLT',
              category: jsonData['SLTModels'][j]['Category'],
              subCategory: jsonData['SLTModels'][j]['SubCategory'],
              cuttingDie: jsonData['SLTModels'][j]['CuttingDie'],
              buildings: jsonData['SLTModels'][j]['Buildings'],
              pairs: jsonData['SLTModels'][j]['Pairs'],
              finishedPairs: jsonData['SLTModels'][j]['FinishedPairs'],
              percentage: jsonData['SLTModels'][j]['Pairs'] * 100.0 / total,
              total: jsonData['SLTModels'].length - 1,
              filterLast: last,
              filterSKU: sku,
              filterRY: ry
            )
          );
        }
      }
      else {
        containerHeight[1] = screenHeight - 250;
        sltModel.add(
          SizedBox(
            height: 20,
            child: Center(
              child: Text(AppLocalizations.of(context)!.noDataFound)
            )
          )
        );
      }*/

      if (jsonData['GlobalModels'].length > 0) {
        tabBarController.index = 0;
        cHeight = containerHeight[0];
      }
      /*else if (jsonData['SLTModels'].length > 0) {
        tabBarController.index = 1;
        cHeight = containerHeight[1];
      }*/
      else {
        tabBarController.index = 0;
        cHeight = containerHeight[0];
      }

      setState(() {
        globalModel = globalModel;
        sltModel = sltModel;
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

    Future.delayed(Duration.zero, () {
      if (firstLoad) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return FilterDialog(
              refresh: loadBuyModels,
            );
          },
        );
        firstLoad = false;
      }
    });

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
            Text(AppLocalizations.of(context)!.sideMenuOrderInformation),
            Text(DateFormat('yyyyMM').format(selectedDate), style: const TextStyle(fontSize: 14))
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
                  return FilterDialog(
                    refresh: loadBuyModels,
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
          child: loadingStatus == 'Completed'
          ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
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
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: SfCircularChart(
                      annotations: [
                        CircularChartAnnotation(
                          widget: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(NumberFormat('###,###,##0').format(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              Text('${NumberFormat('##0').format(finishedRate)}% Completed', style: const TextStyle(fontSize: 10))
                            ],
                          )
                        ),
                      ],
                      series: [
                        DoughnutSeries<ChartData, String>(
                          dataSource: [
                            ChartData(AppLocalizations.of(context)!.vulcanize, vulcanize, const Color.fromRGBO(229, 115, 115, 1)),
                            ChartData(AppLocalizations.of(context)!.coldCement, coldCement, const Color.fromRGBO(100, 181, 246, 1)),
                            ChartData(AppLocalizations.of(context)!.coldVulcanize, coldVulcanize, const Color.fromRGBO(200, 120, 250, 1)),
                            ChartData(AppLocalizations.of(context)!.noCategory, noCategory, Colors.grey),
                          ],
                          innerRadius: '75%',
                          animationDuration: 0,
                          strokeColor: const Color.fromRGBO(254, 247, 255, 1),
                          strokeWidth: 1,
                          pointColorMapper:(ChartData data, _) => data.color,
                          xValueMapper: (ChartData data, _) => data.title,
                          yValueMapper: (ChartData data, _) => data.value,
                          dataLabelMapper: (ChartData data, _) => '${data.title} [${NumberFormat('##0.0').format(data.value * 100 / total)}%]',
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            textStyle: TextStyle(
                              fontFamily: 'NotoSansSC',
                            ),
                            labelPosition: ChartDataLabelPosition.outside,
                            showZeroValue: false,
                            connectorLineSettings: ConnectorLineSettings(
                              type: ConnectorType.line,
                              width: 1,
                              color: Colors.black54
                            ),
                          )
                        ),
                        DoughnutSeries<ChartData, String>(
                          dataSource: [
                            ChartData('Finished', finishedRate.toDouble(), Colors.green.shade200),
                            ChartData('NotFinished', (100 - finishedRate).toDouble(), const Color.fromRGBO(254, 247, 255, 1)),
                          ],
                          radius: '59%',
                          innerRadius: '86%',
                          animationDuration: 0,
                          cornerStyle: finishedRate == 0 || finishedRate == 100 ? CornerStyle.bothFlat : CornerStyle.bothCurve,
                          pointColorMapper:(ChartData data, _) => data.color,
                          xValueMapper: (ChartData data, _) => data.title,
                          yValueMapper: (ChartData data, _) => data.value,
                        )
                      ]
                    ),
                  ),
                  TabBar(
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorColor: Colors.transparent,
                    labelStyle: const TextStyle(fontWeight: FontWeight.normal),
                    labelColor: Colors.white,
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                    unselectedLabelColor: Colors.black,
                    controller: tabBarController,
                    tabs: [
                      Tab(
                        height: 52,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4, bottom: 4),
                                child: Text('GLOBAL', style: TextStyle(fontSize: 14, height: 0)),
                              ),
                              Text(NumberFormat('###,###,##0').format(global), style: const TextStyle(fontSize: 24, height: 0)),
                            ],
                          ),
                        ),
                      ),
                      /*Tab(
                        height: 52,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4, bottom: 4),
                                child: Text('SLT', style: TextStyle(fontSize: 14)),
                              ),
                              Text(NumberFormat('###,###,##0').format(slt), style: const TextStyle(fontSize: 24)),
                            ],
                          ),
                        ),
                      ),*/
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 12),
                    child: Divider(height: 2, color: Colors.grey,),
                  ),
                  Container(
                    color: Colors.transparent,
                    height: cHeight,
                    child: TabBarView(
                      controller: tabBarController,
                      children: [
                        SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            children: globalModel,
                          ),
                        ),
                        /*SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            children: sltModel,
                          ),
                        ),*/
                      ]
                    ),
                  ),
                ],
              ),
            ),
          )
          : loadingStatus == 'isLoading'
          ? SizedBox(
            height: screenHeight,
            child: const Center(
              child: SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),
          )
          : SizedBox(
            height: screenHeight,
            child: Center(
              child: Text(AppLocalizations.of(context)!.noDataFound, style: const TextStyle(fontSize: 16))
            )
          )
        )
      )
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
  State<StatefulWidget> createState() => FilterDialogState();
}

class FilterDialogState extends State<FilterDialog> {
  DateTime sDate = selectedDate;
  final TextEditingController dateController = TextEditingController(text: DateFormat('yyyyMM').format(selectedDate));
  final TextEditingController cuttingDieController = TextEditingController(text: cuttingDie);
  final TextEditingController lastController = TextEditingController(text: last);
  final TextEditingController skuController = TextEditingController(text: sku);
  final TextEditingController ryController = TextEditingController(text: ry);

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
            child: Text('${AppLocalizations.of(context)!.orderMonth}：')
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
                    )
                  )
                ).then((date) async {
                  if (date != null) {
                    setState(() {
                      sDate = date;
                      dateController.text = DateFormat('yyyyMM').format(sDate);
                    });
                  }
                });
              },
              decoration: InputDecoration(
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(width: 1, color: Colors.black54),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
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
                          dateController.text = DateFormat('yyyyMM').format(sDate);
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
            child: Text('${AppLocalizations.of(context)!.cuttingDie}：')
          ),
          SizedBox(
            height: 40,
            child: TextField(
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.bottom,
              controller: cuttingDieController,
              decoration: const InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.scheduleLast)
          ),
          SizedBox(
            height: 40,
            child: TextField(
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.bottom,
              controller: lastController,
              decoration: const InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${AppLocalizations.of(context)!.sku}：')
          ),
          SizedBox(
            height: 40,
            child: TextField(
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.bottom,
              controller: skuController,
              decoration: const InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${AppLocalizations.of(context)!.ry}：')
          ),
          SizedBox(
            height: 40,
            child: TextField(
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.bottom,
              controller: ryController,
              decoration: const InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
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
            selectedDate = sDate;
            cuttingDie = cuttingDieController.text;
            last = lastController.text;
            sku = skuController.text;
            ry = ryController.text;
            Navigator.of(context).pop();
            widget.refresh();
          },
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    );
  }
}

class ModelCard extends StatefulWidget {
  const ModelCard({
    super.key,
    required this.index,
    required this.buy,
    required this.type,
    required this.category,
    required this.subCategory,
    required this.cuttingDie,
    required this.buildings,
    required this.pairs,
    required this.finishedPairs,
    required this.percentage,
    required this.total,
    required this.filterLast,
    required this.filterSKU,
    required this.filterRY
  });

  final int index;
  final String buy;
  final String type;
  final String category;
  final String subCategory;
  final String cuttingDie;
  final String buildings;
  final int pairs;
  final int finishedPairs;
  final double percentage;
  final int total;
  final String filterLast;
  final String filterSKU;
  final String filterRY;

  @override
  State<StatefulWidget> createState() => ModelCardState();
}

class ModelCardState extends State<ModelCard> {
  Color vulcanizeColor = const Color.fromRGBO(229, 115, 115, 1);
  Color coldVulcanizeColor = const Color.fromRGBO(175, 60, 250, 1);
  Color coldCementColor = const Color.fromRGBO(100, 181, 246, 1);
  String category = '';

  @override
  Widget build(BuildContext context) {
    Color modelColor = widget.category == 'Vulcanize' ? vulcanizeColor : widget.category == 'Cold Vulcanize' ? coldVulcanizeColor : widget.category == 'Cold Cement' ? coldCementColor : Colors.black;
    category = widget.category == 'Vulcanize' ? AppLocalizations.of(context)!.vulcanize : widget.category == 'Cold Vulcanize' ? AppLocalizations.of(context)!.coldVulcanize : widget.category == 'Cold Cement' ? AppLocalizations.of(context)!.coldCement : AppLocalizations.of(context)!.noCategory;

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 12, right: 12, bottom: 4),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(254, 247, 255, 1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(1, 1),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.pushNamed(context, '/order_information/sku', arguments: '${widget.buy};${widget.type};${widget.cuttingDie};${widget.filterLast};${widget.filterSKU};${widget.filterRY}');
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    /*Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: widget.category == 'Vulcanize' ? Image.asset("assets/images/vulcanize.png", width: 20,)
                      : widget.category == 'Cold Vulcanize' ? Image.asset("assets/images/cold_vulcanize.png", width: 20,)
                      : widget.category == 'Cold Cement' ? Image.asset("assets/images/cold_cement.png", width: 20,)
                      : Image.asset("assets/images/no_category.png", width: 20,)
                    ),*/
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: modelColor,
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4,vertical: 3),
                                child: Text('$category - ${widget.subCategory} [${NumberFormat('##0.0').format(widget.percentage) == '0.0' ? '<0.1%' : '${NumberFormat('##0.0').format(widget.percentage)}%'}]', style: const TextStyle(fontSize: 12, color: Colors.white, height: 1)),
                              )
                            ),
                            const SizedBox(height: 4,),
                            Text(widget.cuttingDie, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1)),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: FaIcon(FontAwesomeIcons.solidStar, size: 10, color: Colors.orange),
                                  ),
                                  Text(widget.buildings, style: const TextStyle(fontSize: 12),),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(AppLocalizations.of(context)!.pairs, style: const TextStyle(fontSize: 12),),
                          const SizedBox(height: 4,),
                          Text(NumberFormat('###,###,##0').format(widget.pairs), style: const TextStyle(fontSize: 20, height: 1)),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                              child: Text('${AppLocalizations.of(context)!.completionRate} ${NumberFormat('##0.0').format(widget.finishedPairs * 100.0 / widget.pairs)}%', style: const TextStyle(fontSize: 10, height: 1)),
                            )
                          ),
                        ],
                      ),
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