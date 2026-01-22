import 'dart:convert';
import 'dart:ui' as ui;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:intl/intl.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:production/components/side_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

String apiAddress = '', lastWorkingDay = '';
DateTime mySelectedDate = DateTime.now();
String sFactory = '';
List<String> factoryDropdownItems = [];
List<Widget> leanTab = [], totalMatList = [];
List<List<String>> factoryLeans = [];
List<String> ry = [];
List<List<Widget>> ryChips = [], ryReadOnlyChips = [];
List<List<dynamic>> cardMaterials = [];
List<List<TextEditingController>> materialUsage = [];
List<bool> orderVisible = [];
List<Color> orderColor = [];
List<String> orderFilterValue = [];
List<GlobalKey<OrderItemState>> keys = [];
String userID = '', userName = '', factory = '', group = '', mode = '', warehouse = '', ryTitle = '';
String cardSection = 'C';
bool loadSuccess = false;
TextEditingController filterTitle = TextEditingController();
TextEditingController filterBUY = TextEditingController(text: '');
TextEditingController filterSKU = TextEditingController();

class MaterialRequisition extends StatefulWidget {
  const MaterialRequisition({super.key});

  @override
  MaterialRequisitionState createState() => MaterialRequisitionState();
}

class MaterialRequisitionState extends State<MaterialRequisition> with TickerProviderStateMixin {
  Color cardTextColor = Colors.white;
  Color cardLineColor = Colors.white;
  List<String> sectionList = [], sectionIDList = [];
  List<Widget> tableColumnTitles = [];
  List<List<Widget>> tableFirstRow = [];
  List<List<List<Widget>>> tableContentRows = [];
  List<Widget> mrCards = [];
  List<List<List<Widget>>> fakeTimeSlotTitle = [];
  late TabController tabController;
  double cardWidth = 300, fakeCardWidth = 0;
  dynamic futureTab;

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
      factory = prefs.getString('factory') ?? '';
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
      DateFormat('yyyy/MM').format(mySelectedDate),
      'CurrentMonth',
    );
    final jsonData = json.decode(body);
    for (int i = 0; i < jsonData.length; i++) {
      factoryDropdownItems.add(jsonData[i]['Factory']);
    }
    setState(() {
      futureTab = loadMRCard(0);
    });
  }

  Future<bool> loadMRCard(int tabIndex) async {
    setState(() {
      loadSuccess = false;
    });

    final bodyWD = await RemoteService().getLastWorkingDay(
      apiAddress,
      DateFormat('yyyy/MM/dd').format(mySelectedDate),
      'VDH'
    );
    final jsonDataWD = json.decode(bodyWD);
    lastWorkingDay = jsonDataWD['Date'];

    factoryDropdownItems = [];
    factoryLeans = [];
    final body = await RemoteService().getFactoryLean(
      apiAddress,
      DateFormat('yyyy/MM').format(mySelectedDate),
      'MasterLean'
    );
    final jsonData = json.decode(body);
    for (int i = 0; i < jsonData.length; i++) {
      factoryDropdownItems.add(jsonData[i]['Factory'].toString());
      List<String> leans = [];
      for (int j = 0; j < jsonData[i]['Lean'].length; j++) {
        leans.add(jsonData[i]['Lean'][j]);
      }
      factoryLeans.add(leans);
    }

    leanTab = [];
    mrCards = [];
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
            width: getTextSize(factoryLeans[factoryDropdownItems.indexOf(sFactory)][i], const TextStyle(fontSize: 16, height: 1.4)).width + 30,
            child: Align(
              alignment: Alignment.center,
              child: Text(factoryLeans[factoryDropdownItems.indexOf(sFactory)][i], style: const TextStyle(fontSize: 16, height: 1.4))
            )
          )
        )
      );
    }
    setState(() {
      loadSuccess = true;
    });

    try {
      final body = await RemoteService().getMaterialRequisitionCard(
        apiAddress,
        DateFormat('yyyy/MM/dd').format(mySelectedDate),
        sFactory
      );
      final jsonBody = json.decode(body);

      tableColumnTitles = [];
      tableFirstRow = [];
      tableContentRows = [];
      fakeTimeSlotTitle = [];

      if (!mounted) return false;
      tableColumnTitles.add(
        const SizedBox(
          height: 40
        )
      );
      for (int j = 0; j < sectionList.length; j++) {
        tableColumnTitles.add(
          SizedBox(
            width: cardWidth,
            height: 40,
            child: Center(
              child: SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: () async {
                    BuildContext? dialogLoading;
                    showDialog(
                      context: context,
                      barrierColor: Colors.transparent,
                      builder: (BuildContext context) {
                        dialogLoading = context;
                        return Center(
                          child: Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              color: Color.fromRGBO(180, 180, 180, 0.85)
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        );
                      }
                    );

                    final body = await RemoteService().getDailyMaterialUsage(
                      apiAddress,
                      sectionIDList[j],
                      sFactory,
                      factoryLeans[factoryDropdownItems.indexOf(sFactory)][tabController.index],
                      DateFormat('yyyy/MM/dd').format(mySelectedDate)
                    );
                    final jsonBody = json.decode(body);
                    List<Widget> matList = [];
                    for (int i = 0; i < jsonBody.length; i++) {
                      String totalUsage = ((double.parse(jsonBody[i]['Qty'].toString())*100).floor()/100).toStringAsFixed(1);
                      while (totalUsage.substring(totalUsage.length-1) == '0') {
                        totalUsage = totalUsage.substring(0, totalUsage.length - 1);
                      }
                      if (totalUsage.substring(totalUsage.length-1) == '.') {
                        totalUsage = totalUsage.substring(0, totalUsage.length - 1);
                      }
                      matList.add(
                        Row(
                          children: [
                            Text('${i+1}.  ${jsonBody[i]['MaterialID']}  :  '),
                            SizedBox(
                              width: 50,
                              child: Text(totalUsage)
                            ),
                            Text('  ${jsonBody[i]['Unit']}')
                          ],
                        ),
                      );
                    }

                    if (!mounted) return;
                    Navigator.pop(dialogLoading!);
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
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('${AppLocalizations.of(context)!.materialRequisitionTotalUsage} - ${sectionList[j]}')
                              ),
                              const Divider(),
                              Column(
                                children: matList,
                              )
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(AppLocalizations.of(context)!.ok),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                  child: Text(sectionList[j], style: const TextStyle(fontSize: 18, color: Colors.white))
                ),
              )
            ),
          )
        );
      }

      for (int i = 0; i < factoryLeans[factoryDropdownItems.indexOf(sFactory)].length; i++) {
        int index = -1;
        for (int j = 0; j < jsonBody.length; j++) {
          if (jsonBody[j]['Lean'].toString().toUpperCase() == factoryLeans[factoryDropdownItems.indexOf(sFactory)][i]) {
            index = j;
            break;
          }
        }
        if (index >= 0) {
          List<Widget> firstRow = [];
          List<List<Widget>> contentRows = [];
          List<List<Widget>> fakeTitleBlock = [];
          for (int j = 0; j < jsonBody[index]['TimeSlots'].length; j++) {
            String time = jsonBody[index]['TimeSlots'][j]['Time'].toString();
            List<String> timeText = time.split(' ');
            firstRow.add(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(timeText[0]),
                  const Text('|', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                  Text(timeText[2])
                ],
              )
            );

            List<Widget> fakeCards = [];
            List<Widget> cards = [];
            for (int k = 0; k < sectionIDList.length; k++) {
              if (jsonBody[index]['TimeSlots'][j]['Section'].length > 0) {
                bool isExist = false;
                for (int l = 0; l < jsonBody[index]['TimeSlots'][j]['Section'].length; l++) {
                  if (jsonBody[index]['TimeSlots'][j]['Section'][l]['ID'].toString() == sectionIDList[k]) {
                    List<Widget> fakeBlockCard = [];
                    List<Widget> blockCard = [];
                    for (int m = 0; m < jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'].length; m++) {
                      String listNo = jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['ListNo'];
                      String source = jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['Source'];
                      String sourceTitle = source == 'SQ'
                      ? AppLocalizations.of(context)!.productionManagement
                      : source == 'WH'
                      ? AppLocalizations.of(context)!.warehouse
                      : source;
                      String remark = jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['Remark'];
                      String confirmDate = jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['ConfirmDate'];
                      String deliveryCFMDate = jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['DeliveryCFMDate'];
                      String receiverConfirmDate = jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['ReceiverConfirmDate'];
                      String cardStatus = receiverConfirmDate.isNotEmpty
                        ? 'applicantSigned'
                        : deliveryCFMDate.isNotEmpty
                        ? 'warehouseConfirmed'
                        : confirmDate.isNotEmpty
                        ? 'warehousePreparing'
                        : 'warehouseUnread';
                      String status = cardStatus == 'warehouseUnread'
                      ? '${AppLocalizations.of(context)!.status} : ${AppLocalizations.of(context)!.warehouseUnread}'
                      : cardStatus == 'warehousePreparing'
                      ? '${AppLocalizations.of(context)!.status} : ${AppLocalizations.of(context)!.warehousePreparing}'
                      : cardStatus == 'warehouseConfirmed'
                      ? '${AppLocalizations.of(context)!.status} : ${AppLocalizations.of(context)!.warehouseConfirmed}'
                      : '${AppLocalizations.of(context)!.status} : ${AppLocalizations.of(context)!.applicantSigned}';

                      List<Widget> fakeCard = [
                        const SizedBox(
                          height: 24
                        )
                      ];
                      List<Widget> card = [
                        SizedBox(
                          height: 24,
                          width: cardWidth - 75,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text(status, style: TextStyle(color: cardTextColor))
                          )
                        )
                      ];
                      for (int n = 0; n < jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['MRCardInfo'].length; n++) {
                        String orderBegin = jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['MRCardInfo'][n]['RY_Begin'] + (jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['MRCardInfo'][n]['Date'] != '' ? ' [' + jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['MRCardInfo'][n]['Date'] + ']' : '');
                        String sku = jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['MRCardInfo'][n]['SKU'].toString();
                        String buy = jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['MRCardInfo'][n]['BUY'].toString();
                        List<Widget> fakeMaterials = [];
                        List<Widget> materials = [];
                        for (int o = 0; o < jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['MRCardInfo'][n]['Materials'].length; o++) {
                          String materialID = jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['MRCardInfo'][n]['Materials'][o]['ID'].toString();
                          double mUsage = double.parse(jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['MRCardInfo'][n]['Materials'][o]['Usage'].toString());
                          String materialUsage = mUsage % 1 == 0 ? mUsage.toInt().toString() : mUsage.toString();
                          double mIssuanceUsage = double.parse(jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['MRCardInfo'][n]['Materials'][o]['IssuanceUsage'].toString());
                          String materialIssuanceUsage = mIssuanceUsage % 1 == 0 ? mIssuanceUsage.toInt().toString() : mIssuanceUsage.toString();
                          bool confirmed = bool.parse(jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['MRCardInfo'][n]['Materials'][o]['Confirmed'].toString());
                          String materialUnit = jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['MRCardInfo'][n]['Materials'][o]['Unit'].toString();
                          String materialRemark = jsonBody[index]['TimeSlots'][j]['Section'][l]['MRCard'][m]['MRCardInfo'][n]['Materials'][o]['Remark'].toString();
                          fakeMaterials.add(
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Colors.transparent),
                                  right: BorderSide(color: Colors.transparent),
                                  bottom: BorderSide(color: Colors.transparent)
                                )
                              ),
                              width: fakeCardWidth,
                              child: Row(
                                children: [
                                  const Text(' '),
                                  materialRemark.isNotEmpty ? const Icon(Icons.fiber_manual_record, color: Colors.transparent, size: 8) : const Text('')
                                ],
                              ),
                            )
                          );
                          materials.add(
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: cardLineColor),
                                  right: BorderSide(color: cardLineColor),
                                  bottom: BorderSide(color: cardLineColor)
                                )
                              ),
                              width: cardWidth - 75,
                              child: Row(
                                children: [
                                  Text('  ${o+1}. ', style: TextStyle(color: cardTextColor)),
                                  Text(materialID, style: TextStyle(color: cardTextColor)),
                                  Text(' - ', style: TextStyle(color: cardTextColor)),
                                  confirmed == true && materialUsage != materialIssuanceUsage
                                  ? Row(
                                    children: [
                                      Text(materialUsage, style: TextStyle(color: cardTextColor, decoration: TextDecoration.lineThrough, decorationColor: Colors.red, decorationThickness: 4)),
                                      Text('  $materialIssuanceUsage', style: TextStyle(color: cardTextColor))
                                    ],
                                  )
                                  : Text(materialUsage, style: TextStyle(color: cardTextColor)),
                                  Text(' ', style: TextStyle(color: cardTextColor)),
                                  Text(materialUnit, style: TextStyle(color: cardTextColor)),
                                  const Text(' '),
                                  materialRemark.isNotEmpty ? const Icon(Icons.fiber_manual_record, color: Colors.lightBlueAccent, size: 8) : const Text('')
                                ],
                              ),
                            )
                          );
                        }

                        fakeCard.add(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.transparent)
                                ),
                                width: fakeCardWidth,
                                child: const Column(
                                  children: [
                                    Text(' ', style: TextStyle(color: Colors.transparent, fontWeight: FontWeight.bold)),
                                    Text(' ', style: TextStyle(color: Colors.transparent, fontWeight: FontWeight.bold))
                                  ],
                                )
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: fakeMaterials,
                              ),
                              SizedBox(height: 4, width: fakeCardWidth)
                            ]
                          )
                        );
                        card.add(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: cardLineColor)
                                ),
                                width: cardWidth - 75,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(' RY : $orderBegin', style: TextStyle(color: cardTextColor, fontWeight: FontWeight.bold)),
                                    Text(' $buy - $sku', style: TextStyle(color: cardTextColor, fontWeight: FontWeight.bold))
                                  ],
                                )
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: materials,
                              ),
                              SizedBox(height: 4, width: cardWidth - 75)
                            ]
                          )
                        );
                      }

                      fakeCard.add(
                        SizedBox(
                          width: fakeCardWidth,
                          height: 42
                        )
                      );
                      card.add(
                        SizedBox(
                          width: cardWidth - 75,
                          height: 42,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${AppLocalizations.of(context)!.fromDep} : $sourceTitle', overflow: TextOverflow.ellipsis, style: TextStyle(color: cardTextColor)),
                              Text('${AppLocalizations.of(context)!.remark} : ${remark.replaceAll("\n", " ")}', overflow: TextOverflow.ellipsis, style: TextStyle(color: cardTextColor)),
                            ],
                          )
                        )
                      );

                      fakeBlockCard.add(
                        MRCard(
                          width: fakeCardWidth,
                          shadowColor: Colors.transparent,
                          cardStatusColor: Colors.transparent,
                          tabIndex: -1,
                          status: '',
                          section: '',
                          listNo: '',
                          time: '',
                          source: '',
                          remark: '',
                          refresh: () {},
                          content: fakeCard,
                          type: 'fake'
                        )
                      );

                      blockCard.add(
                        MRCard(
                          width: cardWidth,
                          shadowColor: cardStatus == 'warehouseUnread'
                            ? Colors.red
                            : cardStatus == 'warehousePreparing'
                            ? Colors.purple
                            : cardStatus == 'warehouseConfirmed'
                            ? Colors.orange
                            : Colors.green,
                          cardStatusColor: cardStatus == 'warehouseUnread'
                            ? Colors.red.shade400
                            : cardStatus == 'warehousePreparing'
                            ? Colors.purple
                            : cardStatus == 'warehouseConfirmed'
                            ? Colors.orange
                            : Colors.green,
                          tabIndex: i,
                          status: cardStatus,
                          section: sectionIDList[k],
                          listNo: listNo,
                          time: time,
                          source: source,
                          remark: remark,
                          refresh: reloadMRCard,
                          content: card,
                          type: 'real'
                        )
                      );
                    }
                    fakeCards.add(
                      Column(
                        children: fakeBlockCard,
                      )
                    );

                    cards.add(
                      Column(
                        children: blockCard,
                      )
                    );
                    isExist = true;
                    break;
                  }
                }
                if (isExist == false) {
                  fakeCards.add(
                    SizedBox(
                      width: fakeCardWidth,
                      height: 100
                    )
                  );
                  cards.add(
                    SizedBox(
                      width: cardWidth,
                      height: 100
                    )
                  );
                }
              }
              else {
                fakeCards.add(
                  SizedBox(
                    width: fakeCardWidth,
                    height: 100
                  )
                );
                cards.add(
                  SizedBox(
                    width: cardWidth,
                    height: 100,
                  )
                );
              }
            }
            fakeTitleBlock.add(fakeCards);
            contentRows.add(cards);
          }
          tableFirstRow.add(firstRow);
          tableContentRows.add(contentRows);
          fakeTimeSlotTitle.add(fakeTitleBlock);
          mrCards.add(
            HorizontalDataTable(
              leftHandSideColumnWidth: 60,
              rightHandSideColumnWidth: cardWidth * (tableColumnTitles.length - 1),
              isFixedHeader: true,
              headerWidgets: tableColumnTitles,
              leftSideItemBuilder: (BuildContext context, int index2) {
                List<Widget> cells = [];
                for (int j = 0; j < fakeTimeSlotTitle[index][index2].length; j++) {
                  cells.add(fakeTimeSlotTitle[index][index2][j]);
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: cells,
                    ),
                    Center(child: tableFirstRow[index][index2])
                  ],
                );
              },
              rightSideItemBuilder: (BuildContext context, int index2) {
                List<Widget> cells = [];
                for (int j = 0; j < tableContentRows[index][index2].length; j++) {
                  cells.add(tableContentRows[index][index2][j]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cells
                );
              },
              itemCount: tableFirstRow[index].length,
              rowSeparatorWidget: const Divider(
                color: Color.fromRGBO(120, 120, 120, 1),
                height: 1.0,
                thickness: 0.0,
              ),
              leftHandSideColBackgroundColor: const Color(0xFFFFFFFF),
              rightHandSideColBackgroundColor: const Color(0xFFFFFFFF),
            ),
          );
        }
        else {
          mrCards.add(
            Center(child: Text(AppLocalizations.of(context)!.dataNotExist))
          );
        }
      }
      setState(() {
        loadSuccess = true;
      });
      tabController = TabController(initialIndex: tabIndex, length: leanTab.length, vsync: this);
      return true;
    } catch (ex) {
      setState(() {
        loadSuccess = true;
      });
      return false;
    }
  }

  void reloadMRCard(int tabIndex) {
    futureTab = loadMRCard(tabIndex);
  }

  Size getTextSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style), maxLines: 1, textDirection: ui.TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  @override
  Widget build(BuildContext context) {
    sectionIDList = ['C', 'S', 'SF', 'A'];
    sectionList = [AppLocalizations.of(context)!.cutting, AppLocalizations.of(context)!.stitching, AppLocalizations.of(context)!.stockFitting, AppLocalizations.of(context)!.assembly];
    warehouse = AppLocalizations.of(context)!.warehouse;
    ryTitle = AppLocalizations.of(context)!.ry;

    return FutureBuilder(
      future: futureTab,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || loadSuccess == false || mrCards.length != leanTab.length) {
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
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$sFactory ${AppLocalizations.of(context)!.materialRequisitionTitle}'),
                  Text(DateFormat('yyyy/MM/dd').format(mySelectedDate), style: const TextStyle(fontSize: 16),),
                ],
              ),
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
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$sFactory ${AppLocalizations.of(context)!.materialRequisitionTitle}'),
                  Text(DateFormat('yyyy/MM/dd').format(mySelectedDate), style: const TextStyle(fontSize: 16),),
                ],
              ),
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
          return Scaffold(
            resizeToAvoidBottomInset: true,
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
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$sFactory ${AppLocalizations.of(context)!.materialRequisitionTitle}'),
                  Text(DateFormat('yyyy/MM/dd').format(mySelectedDate), style: const TextStyle(fontSize: 16),),
                ],
              ),
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
                          refresh: reloadMRCard,
                        );
                      },
                    );
                  },
                ),
              ],
              bottom: TabBar(
                controller: tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: EdgeInsets.zero,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.white,
                indicator: const BoxDecoration(
                  color: Colors.white,
                ),
                tabs: leanTab
              )
            ),
            drawer: SideMenu(
              userName: userName,
              group: group,
            ),
            body: TabBarView(
              controller: tabController,
              children: mrCards
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  showDragHandle: true,
                  isScrollControlled: true,
                  context: context, builder: (BuildContext context) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).copyWith().size.height * 0.9),
                      child: AddCardDialog(
                        tabIndex: tabController.index,
                        status: 'apply',
                        mode: 'Add',
                        listSection: '',
                        listNo: '',
                        time: '',
                        source: '',
                        remark: '',
                        refresh: reloadMRCard,
                      ),
                    );
                  },
                );
              },
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              child: Text(
                String.fromCharCode(Icons.add.codePoint),
                style: TextStyle(
                  inherit: false,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: Icons.add.fontFamily,
                  color: Colors.white
                ),
              )
            ),
          );
        }
      }
    );
  }
}

class MRCard extends StatefulWidget {
  const MRCard({
    super.key,
    required this.width,
    required this.shadowColor,
    required this.cardStatusColor,
    required this.tabIndex,
    required this.status,
    required this.section,
    required this.listNo,
    required this.time,
    required this.source,
    required this.remark,
    required this.refresh,
    required this.content,
    required this.type
  });
  final double width;
  final Color shadowColor;
  final Color cardStatusColor;
  final int tabIndex;
  final String status;
  final String section;
  final String listNo;
  final String time;
  final String source;
  final String remark;
  final Function refresh;
  final List<Widget> content;
  final String type;

  @override
  MRCardState createState() => MRCardState();
}

class MRCardState extends State<MRCard> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Card(
        elevation: 4,
        shadowColor: widget.shadowColor,
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
        ),
        color: widget.cardStatusColor,
        child: InkWell(
          customBorder: const BeveledRectangleBorder(
            borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          onTap: widget.type == 'real' ? () {
            showModalBottomSheet(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              showDragHandle: true,
              isScrollControlled: true,
              context: context, builder: (BuildContext context) {
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).copyWith().size.height * 0.9),
                  child: AddCardDialog(
                    tabIndex: widget.tabIndex,
                    status: widget.status,
                    mode: 'Modify',
                    listSection: widget.section,
                    listNo: widget.listNo,
                    time: widget.time,
                    source: widget.source,
                    remark: widget.remark,
                    refresh: widget.refresh,
                  ),
                );
              },
            );
          } : null,
          child: Padding(
            padding: const EdgeInsets.only(left: 22, top: 8, right: 8, bottom: 8),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.content
                ),
                SizedBox(
                  width: 36,
                  child: Center(
                    child: widget.section == 'SF'
                    ? const Text('GCD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))
                    : widget.section == 'PM'
                    ? const Text('SQ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))
                    : Text(widget.section, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white))
                  ),
                )
              ],
            ),
          ),
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
  FilterDialogState createState() => FilterDialogState();
}

class FilterDialogState extends State<FilterDialog> {
  final TextEditingController dateController = TextEditingController(text: DateFormat('yyyy/MM/dd').format(mySelectedDate));

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - kBottomNavigationBarHeight;

    return AlertDialog(
      scrollable: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      content: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.date)
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
                          initialSelectedDate: mySelectedDate,
                          backgroundColor: Colors.transparent,
                          todayHighlightColor: Colors.blue,
                          selectionColor: Colors.blue,
                          headerStyle: const DateRangePickerHeaderStyle(
                            backgroundColor: Colors.transparent
                          ),
                          showActionButtons: true,
                          confirmText: AppLocalizations.of(context)!.ok,
                          cancelText: AppLocalizations.of(context)!.cancel,
                          onSubmit: (Object? value) {
                            mySelectedDate = sfDateController.selectedDate!;
                            dateController.text = DateFormat('yyyy/MM/dd').format(mySelectedDate);
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
                              initialSelectedDate: mySelectedDate,
                              backgroundColor: Colors.transparent,
                              todayHighlightColor: Colors.blue,
                              selectionColor: Colors.blue,
                              headerStyle: const DateRangePickerHeaderStyle(
                                backgroundColor: Colors.transparent
                              ),
                              showActionButtons: true,
                              confirmText: AppLocalizations.of(context)!.ok,
                              cancelText: AppLocalizations.of(context)!.cancel,
                              onSubmit: (Object? value) {
                                mySelectedDate = sfDateController.selectedDate!;
                                dateController.text = DateFormat('yyyy/MM/dd').format(mySelectedDate);
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
            widget.refresh(0);
          },
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    );
  }
}

class AddCardDialog extends StatefulWidget {
  const AddCardDialog({
    super.key,
    required this.tabIndex,
    required this.status,
    required this.mode,
    required this.listSection,
    required this.listNo,
    required this.time,
    required this.source,
    required this.remark,
    required this.refresh
  });
  final Function refresh;
  final int tabIndex;
  final String status;
  final String mode;
  final String listSection;
  final String listNo;
  final String time;
  final String source;
  final String remark;

  @override
  AddCardDialogState createState() => AddCardDialogState();
}

class AddCardDialogState extends State<AddCardDialog> {
  final TextEditingController dateController = TextEditingController(text: DateFormat('yyyy/MM/dd').format(mySelectedDate));
  final TextEditingController factoryController = TextEditingController();
  final TextEditingController leanController = TextEditingController();
  final TextEditingController flController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();
  List<Widget> ryList = [], skuRYList = [], chips = [];
  List<GlobalKey<ChipsState>> chipKeys = [];
  String section = 'C', source = '';
  String timeSlot = '07:30 - 09:30';
  String tipsTime = '';
  bool loadSuccess2 = true, cardGenerating = false;
  dynamic futureParameter;

  @override
  initState() {
    super.initState();
    mode = widget.mode;
    cardSection = section;
    factoryController.text = sFactory;
    leanController.text = factoryLeans[factoryDropdownItems.indexOf(sFactory)][widget.tabIndex];
    flController.text = '${factoryController.text} ${leanController.text}';
    source = widget.source != '' ? widget.source : 'WH';
    if (mode == 'Add') {
      loadSkuRYList();
    }
    else {
      loadCardData();
    }
  }

  void removeRYChips(int index) {
    setState(() {
      chipKeys.removeAt(index);
      ryList.removeAt(index);
    });
  }

  void addRYChips(int index, String order, String date, List<MultiSelectItem> materialItems, List<String> materials, List<String> units, List<String> initialUsage, String mode) {
    setState(() {
      GlobalKey<ChipsState> key = GlobalKey();
      chipKeys.add(key);
      ry.add(order);
      ryList.add(
        Chips(
          key: key,
          index: index,
          removeRYChips: removeRYChips,
          buttonText: order,
          date: date,
          materialItems: materialItems,
          materials: materials,
          units: units,
          materialRemark: const [],
          initialMaterial: const [],
          initialMaterialUsage: const [],
          initialMaterialUnit: const [],
          initialUsage: initialUsage,
          mode: mode,
        )
      );
    });
  }

  Future<bool> loadSkuRYList() async {
    setState(() {
      loadSuccess2 = false;
    });
    keys = [];
    skuRYList = [];
    ry = [];
    ryReadOnlyChips = [];
    ryChips = [];
    cardMaterials = [];
    materialUsage = [];
    orderVisible = [];
    orderColor = [];
    orderFilterValue = [];
    totalMatList = [];
    tipsTime = '$lastWorkingDay 14:30';

    final body = await RemoteService().getLeanScheduleRY(
      apiAddress,
      dateController.text,
      factoryController.text,
      leanController.text
    );

    final jsonBody = json.decode(body);
    skuRYList.add(const Divider(height: 1));
    for (int i = 0; i < jsonBody.length; i++) {
      orderFilterValue.add('${jsonBody[i]['BuyNo']} - ${jsonBody[i]['SKU']}');
      orderVisible.add(orderFilterValue[i].contains(filterTitle.text) ? true : false);
      orderColor.add(Colors.black);
      GlobalKey<OrderItemState> globalKey = GlobalKey();
      keys.add(globalKey);
      skuRYList.add(
        OrderItem(
          key: globalKey,
          index: i,
          date: jsonBody[i]['Date'],
          buy: jsonBody[i]['BuyNo'],
          sku: jsonBody[i]['SKU'],
          ry: jsonBody[i]['RY'],
          searchDate: dateController.text,
          searchFactory: factoryController.text,
          searchLean: leanController.text,
          mode: 'Add',
          addChips: addRYChips
        )
      );
    }

    setState(() {
      loadSuccess2 = true;
    });
    return true;
  }

  Future<bool> loadCardData() async {
    setState(() {
      loadSuccess2 = false;
    });
    section = widget.listSection;
    cardSection = widget.listSection;
    timeSlot = widget.time;
    tipsTime = timeSlot == '07:30 - 09:30'
    ? '$lastWorkingDay 14:30'
    : timeSlot == '09:30 - 11:30'
    ? '${dateController.text} 08:00'
    : timeSlot == '12:30 - 14:30'
    ? '${dateController.text} 09:30'
    : timeSlot == '14:30 - 16:30'
    ? '${dateController.text} 12:30'
    : '${dateController.text} 14:30';
    remarkController.text = widget.remark;

    keys = [];
    skuRYList = [];
    ry = [];
    ryReadOnlyChips = [];
    ryChips = [];
    cardMaterials = [];
    materialUsage = [];
    orderVisible = [];
    orderColor = [];
    orderFilterValue = [];
    totalMatList = [];

    final cardBody = await RemoteService().getMRCardInfo(
      apiAddress,
      widget.listNo
    );
    final jsonCardBody = json.decode(cardBody);

    for (int i = 0; i < jsonCardBody.length; i++) {
      if (jsonCardBody[i]['RY_Begin'] != 'Total') {
        List<dynamic> initialMaterial = [];
        List<String> initialMaterialUsage = [];
        List<String> initialMaterialUnit = [];
        List<String> materialRemark = [];
        for (int j = 0; j < jsonCardBody[i]['RYMaterial'].length; j++) {
          initialMaterial.add(jsonCardBody[i]['RYMaterial'][j]['MaterialID'].toString());
          double mUsage = double.parse(jsonCardBody[i]['RYMaterial'][j]['Qty'].toString());
          initialMaterialUsage.add(mUsage % 1 == 0 ? mUsage.toInt().toString() : mUsage.toString());
          initialMaterialUnit.add(jsonCardBody[i]['RYMaterial'][j]['Unit'].toString());
          materialRemark.add(jsonCardBody[i]['RYMaterial'][j]['Remark'].toString());
        }

        List<MultiSelectItem> materialItems = [];
        List<String> materials = [], units = [];
        List<String> initialUsage = [];
        final chipBody = await RemoteService().getRYMaterials(
          apiAddress,
          jsonCardBody[i]['RY_Begin'],
          jsonCardBody[i]['Section']
        );
        final jsonChipBody = json.decode(chipBody);
        for (int i = 0; i < jsonChipBody.length; i++) {
          initialUsage.add(jsonChipBody[i]["Qty"] % 1 == 0 ? jsonChipBody[i]["Qty"].toInt().toString() : jsonChipBody[i]["Qty"].toString());
          String reqQty = jsonChipBody[i]["ReqQty"] % 1 == 0 ? jsonChipBody[i]["ReqQty"].toInt().toString() : jsonChipBody[i]["ReqQty"].toString();
          if (mounted) {
            materialItems.add(
              MultiSelectItem(
                jsonChipBody[i]["MaterialID"],
                jsonChipBody[i]["Remark"] == ''
                ? '${jsonChipBody[i]["MaterialID"]} (${jsonChipBody[i]["Unit"]})\n${AppLocalizations.of(context)!.requisitioned}: $reqQty, ${AppLocalizations.of(context)!.notRequisitioned}: ${initialUsage[i]}'
                : '${jsonChipBody[i]["MaterialID"]} (${jsonChipBody[i]["Unit"]})\n${jsonChipBody[i]["Remark"].toString().replaceAll('[*]', '*${AppLocalizations.of(context)!.notInStock}: ')}\n${AppLocalizations.of(context)!.requisitioned}: $reqQty, ${AppLocalizations.of(context)!.notRequisitioned}: ${initialUsage[i]}'
              )
            );
            materials.add(jsonChipBody[i]["MaterialID"]);
            units.add(jsonChipBody[i]["Unit"]);
          }
        }

        GlobalKey<ChipsState> key = GlobalKey();
        chipKeys.add(key);
        ry.add(jsonCardBody[i]['RY_Begin']);
        ryList.add(
          Chips(
            key: key,
            index: i,
            removeRYChips: removeRYChips,
            buttonText: jsonCardBody[i]['RY_Begin'],
            date: jsonCardBody[i]['Date'],
            materialItems: materialItems,
            materials: materials,
            units: units,
            materialRemark: materialRemark,
            initialMaterial: initialMaterial,
            initialMaterialUsage: initialMaterialUsage,
            initialMaterialUnit: initialMaterialUnit,
            initialUsage: initialUsage,
            mode: 'Modify'
          )
        );
        setState(() {
          ryList = ryList;
        });
      }
      else {
        for (int j = 0; j < jsonCardBody[i]['RYMaterial'].length; j++) {
          String totalUsage = ((double.parse(jsonCardBody[i]['RYMaterial'][j]['Qty'].toString())*100).floor()/100).toStringAsFixed(1);
          while (totalUsage.substring(totalUsage.length-1) == '0') {
            totalUsage = totalUsage.substring(0, totalUsage.length - 1);
          }
          if (totalUsage.substring(totalUsage.length-1) == '.') {
            totalUsage = totalUsage.substring(0, totalUsage.length - 1);
          }
          totalMatList.add(
            Row(
              children: [
                Text('${j+1}.  ${jsonCardBody[i]['RYMaterial'][j]['MaterialID']}  :  ', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(
                  width: 50,
                  child: Text(totalUsage, style: const TextStyle(fontSize: 16, color: Colors.grey))
                ),
                Text('  ${jsonCardBody[i]['RYMaterial'][j]['Unit']}', style: const TextStyle(fontSize: 16, color: Colors.grey))
              ],
            ),
          );
        }
      }
    }

    final body = await RemoteService().getLeanScheduleRY(
      apiAddress,
      dateController.text,
      factoryController.text,
      leanController.text
    );

    final jsonBody = json.decode(body);
    skuRYList.add(const Divider(height: 1));
    for (int i = 0; i < jsonBody.length; i++) {
      orderFilterValue.add(jsonBody[i]['BuyNo'] + ' - ' + jsonBody[i]['SKU']);
      orderVisible.add(orderFilterValue[i].contains(filterTitle.text) ? true : false);
      if (ry.contains(jsonBody[i]['RY'])) {
        orderColor.add(Colors.red);
      }
      else {
        orderColor.add(Colors.black);
      }
      GlobalKey<OrderItemState> globalKey = GlobalKey();
      keys.add(globalKey);
      skuRYList.add(
        OrderItem(
          key: globalKey,
          index: i,
          date: jsonBody[i]['Date'],
          buy: jsonBody[i]['BuyNo'],
          sku: jsonBody[i]['SKU'],
          ry: jsonBody[i]['RY'],
          searchDate: dateController.text,
          searchFactory: factoryController.text,
          searchLean: leanController.text,
          mode: 'Add',
          addChips: addRYChips
        )
      );
    }

    setState(() {
      loadSuccess2 = true;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureParameter,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || loadSuccess2 == false) {
          return const CircularProgressIndicator(
            color: Colors.blue,
          );
        }
        else if (snapshot.hasError) {
          return const CircularProgressIndicator(
            color: Colors.blue,
          );
        }
        else {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context)!.date, style: const TextStyle(fontSize: 20))
                  ),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      readOnly: true,
                      style: mode == 'Add' ? const TextStyle(fontSize: 20) : const TextStyle(fontSize: 20, color: Colors.grey),
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.bottom,
                      controller: dateController,
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromRGBO(182, 180, 184, 1)
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromRGBO(182, 180, 184, 1)
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                        suffix: SizedBox(width: 20)
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context)!.lean, style: const TextStyle(fontSize: 20))
                  ),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      readOnly: true,
                      style: mode == 'Add' ? const TextStyle(fontSize: 20) : const TextStyle(fontSize: 20, color: Colors.grey),
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.bottom,
                      controller: flController,
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromRGBO(182, 180, 184, 1)
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromRGBO(182, 180, 184, 1)
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                        suffix: SizedBox(width: 20)
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context)!.section, style: const TextStyle(fontSize: 20))
                  ),
                  SizedBox(
                    height: 45,
                    child: DropdownButton(
                      isExpanded: true,
                      underline: Container(
                        height: 1,
                        color: const Color.fromRGBO(182, 180, 184, 1)
                      ),
                      value: section,
                      items: [
                        DropdownMenuItem(
                          value: 'C',
                          child: Center(
                            child: Text(AppLocalizations.of(context)!.cutting, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'S',
                          child: Center(
                            child: Text(AppLocalizations.of(context)!.stitching, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'SF',
                          child: Center(
                            child: Text(AppLocalizations.of(context)!.stockFitting, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'A',
                          child: Center(
                            child: Text(AppLocalizations.of(context)!.assembly, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        )
                      ],
                      onChanged: mode == 'Add' ? (value) {
                        if (section != value.toString()) {
                          for (int i = chipKeys.length - 1; i >= 0; i--) {
                            chipKeys[i].currentState?.removeThisChip();
                          }
                        }

                        setState(() {
                          section = value.toString();
                          cardSection = section;
                          source = section != 'SF' ? 'WH' : source;
                        });
                      } : null
                    ),
                  ),
                  Visibility(
                    visible: false,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(AppLocalizations.of(context)!.fromDep, style: const TextStyle(fontSize: 20))
                        ),
                        SizedBox(
                          height: 45,
                          child: DropdownButton(
                            isExpanded: true,
                            underline: Container(
                              height: 1,
                              color: const Color.fromRGBO(182, 180, 184, 1)
                            ),
                            value: source,
                            items: [
                              const DropdownMenuItem(
                                value: 'A05',
                                child: Center(
                                  child: Text('A05', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                                ),
                              ),
                              const DropdownMenuItem(
                                value: 'C09-1F',
                                child: Center(
                                  child: Text('C09-1F', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                                ),
                              ),
                              const DropdownMenuItem(
                                value: 'C09-2F',
                                child: Center(
                                  child: Text('C09-2F', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                                ),
                              ),
                              const DropdownMenuItem(
                                value: 'R02',
                                child: Center(
                                  child: Text('R02', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'SQ',
                                child: Center(
                                  child: Text(AppLocalizations.of(context)!.productionManagement, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'WH',
                                child: Center(
                                  child: Text(AppLocalizations.of(context)!.warehouse, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                                ),
                              )
                            ],
                            onChanged: mode == 'Add' ? (value) {
                              setState(() {
                                source = value.toString();
                              });
                            }: null
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context)!.time, style: const TextStyle(fontSize: 20))
                  ),
                  SizedBox(
                    height: 45,
                    child: DropdownButton(
                      isExpanded: true,
                      underline: Container(
                        height: 1,
                        color: const Color.fromRGBO(182, 180, 184, 1)
                      ),
                      value: timeSlot,
                      items: const [
                        DropdownMenuItem(
                          value: '07:30 - 09:30',
                          child: Center(
                            child: Text('07:30 - 09:30', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        ),
                        DropdownMenuItem(
                          value: '09:30 - 11:30',
                          child: Center(
                            child: Text('09:30 - 11:30', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        ),
                        DropdownMenuItem(
                          value: '12:30 - 14:30',
                          child: Center(
                            child: Text('12:30 - 14:30', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        ),
                        DropdownMenuItem(
                          value: '14:30 - 16:30',
                          child: Center(
                            child: Text('14:30 - 16:30', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        ),
                        DropdownMenuItem(
                          value: '16:30 - 18:00',
                          child: Center(
                            child: Text('16:30 - 18:00', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                          ),
                        )
                      ],
                      onChanged: mode == 'Add' ? (value) {
                        setState(() {
                          timeSlot = value.toString();
                          tipsTime = timeSlot == '07:30 - 09:30'
                          ? '$lastWorkingDay 14:30'
                          : timeSlot == '09:30 - 11:30'
                          ? '${dateController.text} 08:00'
                          : timeSlot == '12:30 - 14:30'
                          ? '${dateController.text} 09:30'
                          : timeSlot == '14:30 - 16:30'
                          ? '${dateController.text} 12:30'
                          : '${dateController.text} 14:30';
                        });
                      }
                      : null,
                    ),
                  ),
                  Visibility(
                    visible: widget.status == 'apply' || widget.status == 'warehouseUnread',
                    child: Center(
                      child: Text('${AppLocalizations.of(context)!.materialRequisitionProhibitTips} : $tipsTime', style: const TextStyle(color: Colors.red, fontSize: 14)),
                    )
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(ryTitle, style: const TextStyle(fontSize: 20))
                  ),
                  Column(
                    children: ryList,
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                    visible: mode == 'Add',
                    child: Center(
                      child: Ink(
                        height: 36,
                        width: 36,
                        decoration: const ShapeDecoration(
                          color: Colors.blue,
                          shape: CircleBorder(),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          color: Colors.white,
                          iconSize: 26,
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return OrderBox(
                                  ryList: skuRYList
                                );
                              }
                            );
                          }
                        ),
                      ),
                    )
                  ),
                  Visibility(
                    visible: mode == 'Modify',
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: Divider(color: mode == 'Add' ? Colors.black : Colors.grey)),
                            Text('  ${AppLocalizations.of(context)?.total}  ', style: TextStyle(color: mode == 'Add' ? Colors.black : Colors.grey)),
                            Expanded(child: Divider(color: mode == 'Add' ? Colors.black : Colors.grey))
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: totalMatList,
                            ),
                          ),
                        )
                      ]
                    )
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppLocalizations.of(context)!.remark, style: const TextStyle(fontSize: 20))
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1))
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextField(
                          readOnly: mode == 'Add' ? false : true,
                          controller: remarkController,
                          maxLines: null,
                          maxLength: 150,
                          keyboardType: TextInputType.multiline,
                          style: mode == 'Add' ? const TextStyle(fontSize: 18) : const TextStyle(fontSize: 18, color: Colors.grey),
                          decoration: const InputDecoration.collapsed(hintText: '')
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: mode == 'Add',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Expanded(child: SizedBox()),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8))
                              ),
                            ),
                            child: Center(
                              child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            )
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              String checkResult = 'Pass';
                              if (ry.isNotEmpty) {
                                for (int i = 0; i < ry.length; i++) {
                                  if (cardMaterials.isNotEmpty) {
                                    for (int j = 0; j < cardMaterials[i].length; j++) {
                                      if (double.tryParse(materialUsage[i][j].text) == null) {
                                        checkResult = 'NotDoubleValue';
                                        break;
                                      }
                                    }
                                  }
                                  else {
                                    checkResult = 'NotSelect';
                                  }
                                  if (checkResult == 'NotDoubleValue') {
                                    break;
                                  }
                                }
                              }
                              else {
                                checkResult = 'NotSelect';
                              }

                              if (checkResult == 'Pass') {
                                GlobalKey<MessageDialogState> globalKey = GlobalKey();
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return MessageDialog(
                                      key: globalKey,
                                      titleText: AppLocalizations.of(context)!.confirmTitle,
                                      contentText: widget.listNo.isEmpty ? AppLocalizations.of(context)!.materialRequisitionConfirmAdd : AppLocalizations.of(context)!.materialRequisitionConfirmUpdate,
                                      showOKButton: true,
                                      showCancelButton: true,
                                      onPressed: () async {
                                        if (cardGenerating == false) {
                                          cardGenerating = true;
                                          globalKey.currentState?.changeContent(AppLocalizations.of(context)!.generating, const SizedBox(height: 72, child: Column(children: [CircularProgressIndicator(color: Colors.blue,),],),), false, false, () => {Navigator.of(context).pop()}, true);
                                          String requestString = '';
                                          for (int i = 0; i < ry.length; i++) {
                                            requestString += '${ry[i]}@';
                                            for (int j = 0; j < cardMaterials[i].length; j++) {
                                              requestString += cardMaterials[i][j] + '-' + materialUsage[i][j].text;
                                              if (j < cardMaterials[i].length - 1) {
                                                requestString += ':';
                                              }
                                            }
                                            if (i < ry.length - 1) {
                                              requestString += ';';
                                            }
                                          }
                                          final String body;
                                          if (widget.listNo.isEmpty) {
                                            body = await RemoteService().generateMRCard(
                                              apiAddress,
                                              section,
                                              sFactory,
                                              leanController.text,
                                              dateController.text,
                                              timeSlot,
                                              source,
                                              remarkController.text,
                                              requestString,
                                              userID,
                                              factory
                                            );
                                          }
                                          else {
                                            body = await RemoteService().updateMRCard(
                                              apiAddress,
                                              widget.listNo,
                                              section,
                                              sFactory,
                                              leanController.text,
                                              dateController.text,
                                              timeSlot,
                                              source,
                                              remarkController.text,
                                              requestString,
                                              userID,
                                              factory
                                            );
                                          }
                                          final jsonData = json.decode(body);
                                          cardGenerating = false;
                                          if (!mounted) return;
                                          if (jsonData['statusCode'] == 200) {
                                            widget.refresh(widget.tabIndex);
                                            globalKey.currentState?.changeContent(AppLocalizations.of(context)!.successTitle, Text(AppLocalizations.of(context)!.successContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/material_requisition')}, true);
                                          }
                                          else if (jsonData['statusCode'] == 401) {
                                            globalKey.currentState?.changeContent(AppLocalizations.of(context)!.information, Text(AppLocalizations.of(context)!.materialRequisitionProhibited), true, false, () => {Navigator.of(context).pop()}, true);
                                          }
                                          else if (jsonData['statusCode'] == 402) {
                                            globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.dataNotExist), true, false, () => {Navigator.of(context).pop()}, true);
                                          }
                                          else if (jsonData['statusCode'] == 403) {
                                            globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.materialRequisitionWarehouseConfirmed), true, false, () => {Navigator.of(context).pop()}, true);
                                          }
                                          else if (jsonData['statusCode'] == 404) {
                                            globalKey.currentState?.changeContent(AppLocalizations.of(context)!.information, Text(AppLocalizations.of(context)!.materialRequisitionNotSigned.replaceAll('%', jsonData['Date'])), true, false, () => {Navigator.of(context).pop()}, true);
                                          }
                                          else {
                                            globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).pop()}, true);
                                          }
                                        }
                                      },
                                    );
                                  }
                                );
                              }
                              else if (checkResult == 'NotSelect') {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return MessageDialog(
                                      titleText: AppLocalizations.of(context)!.materialRequisitionGenerateCardFailedTitle,
                                      contentText: AppLocalizations.of(context)!.materialRequisitionGenerateCardNotSelectContent,
                                      showOKButton: true,
                                      showCancelButton: false,
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  }
                                );
                              }
                              else {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return MessageDialog(
                                      titleText: AppLocalizations.of(context)!.materialRequisitionGenerateCardFailedTitle,
                                      contentText: AppLocalizations.of(context)!.materialRequisitionGenerateCardNoUsage,
                                      showOKButton: true,
                                      showCancelButton: false,
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  }
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8))
                              ),
                            ),
                            child: Center(
                              child: Text(AppLocalizations.of(context)!.ok, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            )
                          ),
                        ],
                      ),
                    )
                  ),
                  Visibility(
                    visible: mode == 'Modify',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Visibility(
                            visible: widget.status == 'warehouseConfirmed',
                            child: Expanded(
                              child: Row(
                                children: [
                                  const Expanded(child: SizedBox()),
                                  OutlinedButton(
                                    onPressed: () async {
                                      GlobalKey<MessageDialogState> globalKey = GlobalKey();
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return MessageDialog(
                                            key: globalKey,
                                            titleText: AppLocalizations.of(context)!.confirmTitle,
                                            contentText: AppLocalizations.of(context)!.materialRequisitionSignConfirmContent,
                                            showOKButton: true,
                                            showCancelButton: true,
                                            onPressed: () async {
                                              final body = await RemoteService().signMRCard(
                                                apiAddress,
                                                widget.listNo,
                                                userID
                                              );
                                              final jsonData = json.decode(body);
                                              if (!mounted) return;
                                              if (jsonData['statusCode'] == 200) {
                                                widget.refresh(widget.tabIndex);
                                                globalKey.currentState?.changeContent(AppLocalizations.of(context)!.successTitle, Text(AppLocalizations.of(context)!.successContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/material_requisition')}, true);
                                              }
                                              else if (jsonData['statusCode'] == 401) {
                                                globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.dataNotExist), true, false, () => {Navigator.of(context).pop()}, true);
                                              }
                                              else if (jsonData['statusCode'] == 402) {
                                                globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.materialRequisitionWarehouseNotConfirmed), true, false, () => {Navigator.of(context).pop()}, true);
                                              }
                                              else if (jsonData['statusCode'] == 403) {
                                                globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.materialRequisitionAlreadySigned), true, false, () => {Navigator.of(context).pop()}, true);
                                              }
                                              else {
                                                globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).pop()}, true);
                                              }
                                            }
                                          );
                                        }
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(8))
                                      ),
                                    ),
                                    child: Center(
                                      child: AppLocalizations.of(context)!.materialRequisitionLeanReceived.contains('|') == false
                                      ? Text(AppLocalizations.of(context)!.materialRequisitionLeanReceived, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
                                      : Column(
                                          children: [
                                            Text(AppLocalizations.of(context)!.materialRequisitionLeanReceived.split('|')[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                            Text(AppLocalizations.of(context)!.materialRequisitionLeanReceived.split('|')[1], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
                                          ],
                                        ),
                                    )
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: widget.status == 'warehouseUnread',
                            child: Expanded(
                              child: Row(
                                children: [
                                  const Expanded(child: SizedBox()),
                                  OutlinedButton(
                                    onPressed: () async {
                                      GlobalKey<MessageDialogState> globalKey = GlobalKey();
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return MessageDialog(
                                            key: globalKey,
                                            titleText: AppLocalizations.of(context)!.confirmTitle,
                                            contentText: AppLocalizations.of(context)!.confirmToDelete,
                                            showOKButton: true,
                                            showCancelButton: true,
                                            onPressed: () async {
                                              final body = await RemoteService().deleteMRCard(
                                                apiAddress,
                                                widget.listNo
                                              );
                                              final jsonData = json.decode(body);
                                              if (!mounted) return;
                                              if (jsonData['statusCode'] == 200) {
                                                widget.refresh(widget.tabIndex);
                                                globalKey.currentState?.changeContent(AppLocalizations.of(context)!.successTitle, Text(AppLocalizations.of(context)!.successContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/material_requisition')}, true);
                                              }
                                              else if (jsonData['statusCode'] == 401) {
                                                globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.dataNotExist), true, false, () => {Navigator.of(context).pop()}, true);
                                              }
                                              else if (jsonData['statusCode'] == 402) {
                                                globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.materialRequisitionWarehouseConfirmed), true, false, () => {Navigator.of(context).pop()}, true);
                                              }
                                              else {
                                                globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).pop()}, true);
                                              }
                                            }
                                          );
                                        }
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(8))
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                    )
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        mode = 'Add';
                                      });
                                      for (int i = 0; i < chipKeys.length; i++) {
                                        chipKeys[i].currentState?.setMode();
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(8))
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(AppLocalizations.of(context)!.modify, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                    )
                                  ),
                                ]
                              ),
                            )
                          )
                        ]
                      )
                    )
                  )
                ],
              ),
            ),
          );
        }
      }
    );
  }
}

class Chips extends StatefulWidget {
  const Chips({
    super.key,
    required this.index,
    required this.removeRYChips,
    required this.buttonText,
    required this.date,
    required this.materialItems,
    required this.materials,
    required this.units,
    required this.materialRemark,
    required this.initialMaterial,
    required this.initialMaterialUsage,
    required this.initialMaterialUnit,
    required this.initialUsage,
    required this.mode
  });
  final int index;
  final Function removeRYChips;
  final String buttonText;
  final String date;
  final List<MultiSelectItem> materialItems;
  final List<String> materials;
  final List<String> units;
  final List<String> materialRemark;
  final List<dynamic> initialMaterial;
  final List<String> initialMaterialUsage;
  final List<String> initialMaterialUnit;
  final List<String> initialUsage;
  final String mode;

  @override
  ChipsState createState() => ChipsState();
}

class ChipsState extends State<Chips> {
  List<Widget> chips = [], readOnlyChips = [];
  List<String> materialList = [];
  List<TextEditingController> usage = [];
  List<String> resetList = [];
  List<dynamic> iniMat = [];

  @override
  void initState() {
    super.initState();
    mode = widget.mode;
    if (mode == 'Modify') {
      loadInitialValue();
    }
  }

  void loadInitialValue() {
    iniMat = widget.initialMaterial;
    for (int i = 0; i < widget.initialMaterial.length; i++){
      materialList.add(widget.initialMaterial[i]);
      usage.add(TextEditingController(text: widget.initialMaterialUsage[i]));
      readOnlyChips.add(
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                child: Icon(Icons.fiber_manual_record, size: 10, color: Colors.blue),
              ),
              Text(widget.initialMaterial[i] + '  :  ', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(
                width: 80,
                height: 24,
                child: TextField(
                  enabled: false,
                  controller: usage[usage.length-1],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'(^\d*\.?\d*)'))
                  ], // Only numbers can be entered
                ),
              ),
              Text('  ${widget.initialMaterialUnit[i]}', style: const TextStyle(fontSize: 16, color: Colors.grey))
            ],
          ),
        )
      );
      chips.add(
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                child: Icon(Icons.fiber_manual_record, size: 10, color: Colors.blue),
              ),
              Text(widget.initialMaterial[i] + '  :  ', style: const TextStyle(fontSize: 16)),
              SizedBox(
                width: 80,
                height: 24,
                child: TextField(
                  onChanged: (value) {
                    double maxUsage = double.parse(widget.initialUsage[widget.materials.indexOf(widget.initialMaterial[i])]) + double.parse(widget.initialMaterialUsage[i]);
                    if (value != '' && double.parse(value) > maxUsage) {
                      usage[i].text = maxUsage.toString();
                      Fluttertoast.showToast(
                        msg: '${AppLocalizations.of(context)!.materialRequisitionExceed} $maxUsage ${widget.units[widget.materials.indexOf(widget.initialMaterial[i])]}',
                        gravity: ToastGravity.BOTTOM,
                        toastLength: Toast.LENGTH_SHORT,
                      );
                    }
                  },
                  controller: usage[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'(^\d*\.?\d*)'))
                  ], // Only numbers can be entered
                ),
              ),
              Text('  ${widget.initialMaterialUnit[i]}', style: const TextStyle(fontSize: 16))
            ],
          ),
        )
      );

      if (widget.materialRemark[i].isNotEmpty) {
        readOnlyChips.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 40),
                const Icon(Icons.subdirectory_arrow_right_rounded, color: Colors.grey, size: 18,),
                Text('$warehouse : ', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Flexible(
                  child: Text(widget.materialRemark[i], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                )
              ],
            )
          )
        );
        chips.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 40),
                const Icon(Icons.subdirectory_arrow_right_rounded, color: Colors.grey, size: 18,),
                Text('$warehouse : ', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Flexible(
                  child: Text(widget.materialRemark[i], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                )
              ],
            )
          )
        );
      }
    }
    ryReadOnlyChips.add(readOnlyChips);
    ryChips.add(chips);
    cardMaterials.add(widget.initialMaterial);
    materialUsage.add(usage);
    setState(() {
      ryChips = ryChips;
    });
  }

  void setMode() {
    setState(() {
      mode = mode;
    });
  }

  void removeThisChip() {
    int index = ry.indexOf(widget.buttonText);
    if (cardMaterials.length > index) {
      cardMaterials.removeAt(index);
    }
    if (materialUsage.length > index) {
      materialUsage.removeAt(index);
    }
    widget.removeRYChips(index);
    if (ryChips.length > index) {
      ryChips.removeAt(index);
    }
    ry.removeAt(index);
    orderColor[widget.index] = Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      enabled: mode == 'Add',
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_forever,
            label: AppLocalizations.of(context)!.delete,
            onPressed: (BuildContext context) {
              GlobalKey<MessageDialogState> globalKey = GlobalKey();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return MessageDialog(
                    key: globalKey,
                    titleText: AppLocalizations.of(context)!.confirmTitle,
                    contentText: AppLocalizations.of(context)!.confirmToDelete,
                    showOKButton: true,
                    showCancelButton: true,
                    onPressed: () async {
                      removeThisChip();
                      Navigator.of(context).pop();
                    },
                  );
                }
              );
            },
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromRGBO(182, 180, 184, 1))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Visibility(
              visible: mode == 'Modify',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(widget.buttonText + (widget.date != '' ? '[${widget.date}]' : ''), style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  ),
                  Column(
                    children: ry.contains(widget.buttonText) && ryReadOnlyChips.length > ry.indexOf(widget.buttonText) ? ryReadOnlyChips[ry.indexOf(widget.buttonText)] : []
                  )
                ],
              ),
            ),
            Visibility(
              visible: mode == 'Add',
              child: Column(
                children: [
                  MultiSelectDialogField(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${AppLocalizations.of(context)!.material} (${widget.buttonText})', style: const TextStyle(fontSize: 20)),
                        const Divider(color: Color.fromRGBO(120, 120, 120, 1))
                      ],
                    ),
                    decoration: const BoxDecoration(
                      border: Border()
                    ),
                    buttonText: Text(widget.buttonText + (widget.date != '' ? '[${widget.date}]' : ''), style: const TextStyle(fontSize: 18)),
                    buttonIcon: const Icon(Icons.add, color: Colors.blue),
                    selectedColor: Colors.blue,
                    selectedItemsTextStyle: const TextStyle(color: Colors.blue),
                    checkColor: Colors.white,
                    confirmText: Text(AppLocalizations.of(context)!.ok),
                    cancelText: Text(AppLocalizations.of(context)!.cancel),
                    chipDisplay: MultiSelectChipDisplay.none(),
                    items: widget.materialItems,
                    initialValue: widget.initialMaterial,
                    onConfirm: (values) {
                      for (int i = 0; i < values.length; i++){
                        if (materialList.contains(values[i]) == false) {
                          materialList.add(values[i]);
                          usage.add(TextEditingController(text: widget.initialUsage[widget.materials.indexOf(values[i])]));
                          chips.add(
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 40,
                                    child: Icon(Icons.fiber_manual_record, size: 10, color: Colors.blue),
                                  ),
                                  Text(values[i] + '  :  ', style: const TextStyle(fontSize: 16),),
                                  SizedBox(
                                    width: 80,
                                    height: 24,
                                    child: TextField(
                                      onChanged: (value) {
                                        if (value != '' && double.parse(value) > double.parse(widget.initialUsage[widget.materials.indexOf(values[i])])) {
                                          usage[i].text = widget.initialUsage[widget.materials.indexOf(values[i])];
                                          Fluttertoast.showToast(
                                            msg: '${AppLocalizations.of(context)!.materialRequisitionExceed} ${widget.initialUsage[widget.materials.indexOf(values[i])]} ${widget.units[widget.materials.indexOf(values[i])]}',
                                            gravity: ToastGravity.BOTTOM,
                                            toastLength: Toast.LENGTH_SHORT,
                                          );
                                        }
                                      },
                                      controller: usage[usage.length-1],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.blue, width: 2),
                                        ),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'(^\d*\.?\d*)'))
                                      ], // Only numbers can be entered
                                    ),
                                  ),
                                  Text('  ${widget.units[widget.materials.indexOf(values[i])]}', style: const TextStyle(fontSize: 16))
                                ],
                              ),
                            )
                          );
                        }
                      }

                      for (int i = materialList.length - 1; i >= 0; i--){
                        if (values.contains(materialList[i]) == false) {
                          chips.removeAt(i);
                          materialList.removeAt(i);
                          usage.removeAt(i);
                        }
                      }

                      if (materialUsage.length != ry.length) {
                        ryChips.add(chips);
                        cardMaterials.add(values);
                        materialUsage.add(usage);
                      }
                      else {
                        ryChips[ry.indexOf(widget.buttonText)] = chips;
                        cardMaterials[ry.indexOf(widget.buttonText)] = values;
                        materialUsage[ry.indexOf(widget.buttonText)] = usage;
                      }
                      setState(() {
                        ryChips = ryChips;
                      });
                    }
                  ),
                  Column(
                    children: ry.contains(widget.buttonText) && ryChips.length > ry.indexOf(widget.buttonText) ? ryChips[ry.indexOf(widget.buttonText)] : []
                  )
                ],
              )
            )
          ],
        ),
      ),
    );
  }
}

class OrderBox extends StatefulWidget {
  const OrderBox({
    super.key,
    required this.ryList
  });
  final List<Widget> ryList;

  @override
  OrderBoxState createState() => OrderBoxState();
}

class OrderBoxState extends State<OrderBox> {
  Widget title = filterTitle.text.isNotEmpty ? Text(filterTitle.text, style: const TextStyle(fontWeight: FontWeight.bold)) : Text(ryTitle, style: const TextStyle(fontWeight: FontWeight.bold));

  void updateTitle() {
    setState(() {
      title = filterTitle.text.isNotEmpty ? Text(filterTitle.text, style: const TextStyle(fontWeight: FontWeight.bold)) : Text(ryTitle, style: const TextStyle(fontWeight: FontWeight.bold));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      titlePadding: const EdgeInsets.all(4),
      contentPadding: const EdgeInsets.all(4),
      actionsPadding: const EdgeInsets.all(4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      title: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, left: 10),
              child: title,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return FilterBox(
                      updateTitle: updateTitle
                    );
                  }
                );
              },
              child: Text(AppLocalizations.of(context)!.filter),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          children: widget.ryList
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        )
      ],
    );
  }
}

class OrderItem extends StatefulWidget {
  const OrderItem({
    super.key,
    required this.index,
    required this.date,
    required this.buy,
    required this.sku,
    required this.ry,
    required this.searchDate,
    required this.searchFactory,
    required this.searchLean,
    required this.mode,
    required this.addChips,
  });
  final int index;
  final String date;
  final String buy;
  final String sku;
  final String ry;
  final String searchDate;
  final String searchFactory;
  final String searchLean;
  final String mode;
  final Function addChips;

  @override
  OrderItemState createState() => OrderItemState();
}

class OrderItemState extends State<OrderItem> {
  void setVisible(bool value) {
    setState(() {
      orderVisible[widget.index] = value;
    });
  }

  @override
  void initState() {
    super.initState();
    loadFontColor();
  }

  void loadFontColor() {
    setState(() {
      orderColor[widget.index] = orderColor[widget.index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: orderVisible[widget.index],
      child: Column(
        children: [
          ListTile(
            leading: SizedBox(
              width: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AutoSizeText(widget.date, minFontSize: 1, wrapWords: false, style: TextStyle(color: orderColor[widget.index])),
                  AutoSizeText(widget.buy, minFontSize: 1, wrapWords: false, style: TextStyle(color: orderColor[widget.index])),
                ],
              ),
            ),
            dense: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('[${widget.sku}]', style: TextStyle(fontSize: 10, color: orderColor[widget.index], height: 0)),
                Text(widget.ry, style: TextStyle(fontSize: 16, color: orderColor[widget.index], height: 0)),
              ],
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 4,
            ),
            onTap: () async {
              if (ry.contains(widget.ry) == false) {
                BuildContext? dialogLoading;
                showDialog(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (BuildContext context) {
                    dialogLoading = context;
                    return Center(
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          color: Color.fromRGBO(180, 180, 180, 0.85)
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    );
                  }
                );

                List<MultiSelectItem> materialItems = [];
                List<String> materials = [], units = [], initialUsage = [];
                final chipBody = await RemoteService().getRYMaterials(
                  apiAddress,
                  widget.ry,
                  cardSection
                );
                final jsonChipBody = json.decode(chipBody);
                for (int i = 0; i < jsonChipBody.length; i++) {
                  initialUsage.add(jsonChipBody[i]["Qty"] % 1 == 0 ? jsonChipBody[i]["Qty"].toInt().toString() : jsonChipBody[i]["Qty"].toString());
                  String reqQty = jsonChipBody[i]["ReqQty"] % 1 == 0 ? jsonChipBody[i]["ReqQty"].toInt().toString() : jsonChipBody[i]["ReqQty"].toString();
                  if (!mounted) return;
                  materialItems.add(
                    MultiSelectItem(
                      jsonChipBody[i]["MaterialID"],
                      jsonChipBody[i]["Remark"] == ''
                      ? '${jsonChipBody[i]["MaterialID"]} (${jsonChipBody[i]["Unit"]})\n${AppLocalizations.of(context)!.requisitioned}: $reqQty, ${AppLocalizations.of(context)!.notRequisitioned}: ${initialUsage[i]}'
                      : '${jsonChipBody[i]["MaterialID"]} (${jsonChipBody[i]["Unit"]})\n${jsonChipBody[i]["Remark"].toString().replaceAll('[*]', '*${AppLocalizations.of(context)!.notInStock}: ')}\n${AppLocalizations.of(context)!.requisitioned}: $reqQty, ${AppLocalizations.of(context)!.notRequisitioned}: ${initialUsage[i]}'
                    )
                  );
                  materials.add(jsonChipBody[i]["MaterialID"]);
                  units.add(jsonChipBody[i]["Unit"]);
                }
                widget.addChips(widget.index, widget.ry, widget.date, materialItems, materials, units, initialUsage, widget.mode);
                orderColor[widget.index] = Colors.red;
                if (mounted) {
                  Navigator.pop(dialogLoading!);
                  Navigator.of(context).pop();
                }
              }
              else {
                Fluttertoast.showToast(
                  msg: AppLocalizations.of(context)!.alreadyAdded,
                  gravity: ToastGravity.BOTTOM,
                  toastLength: Toast.LENGTH_SHORT,
                );
              }
            },
          ),
          const Divider(height: 1)
        ],
      ),
    );
  }
}

class FilterBox extends StatefulWidget {
  const FilterBox({
    super.key,
    required this.updateTitle
  });
  final Function updateTitle;

  @override
  FilterBoxState createState() => FilterBoxState();
}

class FilterBoxState extends State<FilterBox> {
  String buy = filterBUY.text;
  String sku = filterSKU.text;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      titlePadding: const EdgeInsets.all(4),
      contentPadding: const EdgeInsets.all(4),
      actionsPadding: const EdgeInsets.all(4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*const Text('BUY', style: TextStyle(fontSize: 18)),
            SizedBox(
              height: 45,
              child: DropdownButton(
                isExpanded: true,
                underline: Container(
                  height: 1,
                  color: const Color.fromRGBO(182, 180, 184, 1)
                ),
                value: buy,
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Center(
                      child: Text(AppLocalizations.of(context)!.chooseNone, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '1 BUY',
                    child: Center(
                      child: Text('1 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '2 BUY',
                    child: Center(
                      child: Text('2 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '3 BUY',
                    child: Center(
                      child: Text('3 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '4 BUY',
                    child: Center(
                      child: Text('4 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '5 BUY',
                    child: Center(
                      child: Text('5 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '6 BUY',
                    child: Center(
                      child: Text('6 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '7 BUY',
                    child: Center(
                      child: Text('7 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '8 BUY',
                    child: Center(
                      child: Text('8 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '9 BUY',
                    child: Center(
                      child: Text('9 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '10 BUY',
                    child: Center(
                      child: Text('10 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '11 BUY',
                    child: Center(
                      child: Text('11 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '12 BUY',
                    child: Center(
                      child: Text('12 BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center)
                    ),
                  )
                ],
                onChanged: (value) {
                  setState(() {
                    buy = value.toString();
                  });
                },
              ),
            ),
            const SizedBox(height: 10),*/
            const Text('SKU', style: TextStyle(fontSize: 18)),
            SizedBox(
              height: 40,
              child: TextField(
                controller: filterSKU,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.bottom,
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromRGBO(182, 180, 184, 1)
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blue
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  suffix: SizedBox(width: 20)
                ),
              ),
            ),
          ]
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            buy = filterBUY.text;
            filterSKU.text = sku;
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () {
            filterBUY.text = buy;
            if (filterBUY.text.isNotEmpty && filterSKU.text.isEmpty) {
              filterTitle.text = filterBUY.text;
            }
            else if (filterBUY.text.isEmpty && filterSKU.text.isNotEmpty) {
              filterTitle.text = filterSKU.text;
            }
            else if (filterBUY.text.isNotEmpty && filterSKU.text.isNotEmpty) {
              filterTitle.text = '${filterBUY.text} - ${filterSKU.text}';
            }
            else {
              filterTitle.text = '';
            }
            widget.updateTitle();
            for (int i = 0; i < orderFilterValue.length; i++){
              keys[i].currentState?.setVisible(orderFilterValue[i].contains(filterTitle.text) ? true : false);
            }
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.ok),
        )
      ],
    );
  }
}

class MessageDialog extends StatefulWidget {
  const MessageDialog({
    super.key,
    required this.titleText,
    required this.contentText,
    required this.onPressed,
    required this.showOKButton,
    required this.showCancelButton
  });

  final String titleText;
  final String contentText;
  final void Function()? onPressed;
  final bool showOKButton;
  final bool showCancelButton;

  @override
  State<StatefulWidget> createState() => MessageDialogState();
}

class MessageDialogState extends State<MessageDialog> {
  bool applyChange = false;
  String setTitle = '';
  Widget setContent = const Text('');
  bool setOkButton = true;
  bool setCancelButton = true;
  void Function()? setPressed;

  @override
  void initState() {
    super.initState();
  }

  void changeContent(String title, Widget content, bool oKButton, bool cancelButton, Function()? onPressed, bool change) {
    setState(() {
      applyChange = change;
      setTitle = title;
      setContent = content;
      setOkButton = oKButton;
      setCancelButton = cancelButton;
      setPressed = onPressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actionButtons = [];
    if (applyChange == false ? widget.showCancelButton : setCancelButton) {
      actionButtons.add(TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text(AppLocalizations.of(context)!.cancel),
      ));
    }
    if (applyChange == false ? widget.showOKButton : setOkButton) {
      actionButtons.add(TextButton(
        onPressed: applyChange == false ? widget.onPressed : setPressed,
        child: Text(AppLocalizations.of(context)!.ok),
      ));
    }

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      title: Text(applyChange == false ? widget.titleText : setTitle),
      content: applyChange == false ? Text(widget.contentText) : setContent,
      actions: actionButtons
    );
  }
}