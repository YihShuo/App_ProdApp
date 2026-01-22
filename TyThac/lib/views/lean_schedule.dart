import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';

String department = '', apiAddress = '', factory = '', lean = '', section = '', orderFactory = '', orderLean = '';
DateTime selectedDate = DateTime.now();
String selectedMonth = DateFormat('yyyy/MM').format(DateTime.now());
double screenWidth = 0, screenHeight = 0, minScale = 1, fitHeightScale = 1, maxScale = 1;
bool loadSuccess = false;

class LeanSchedule extends StatefulWidget {
  const LeanSchedule({super.key});

  @override
  LeanScheduleState createState() => LeanScheduleState();
}

class LeanScheduleState extends State<LeanSchedule> with SingleTickerProviderStateMixin {
  late final TransformationController transformationController;
  late final AnimationController animationController;
  Animation<Matrix4>? animation;
  List<Widget> tableColumnTitles = [];
  List<String> tableFirstCol = [];
  List<List<Widget>> tableContentRows = [];
  Widget schedules = const SizedBox();
  double cardHeight = 205.0, cardWidth = 130.0;
  bool firstLoad = true;

  @override
  void initState() {
    super.initState();
    firstLoad = true;
    transformationController = TransformationController();
    transformationController.addListener(() {
      final matrix = transformationController.value.clone();
      final scale = matrix.getMaxScaleOnAxis();
      final y = matrix.getTranslation().y;

      final contentHeight = tableFirstCol.length * cardHeight + 60;
      final scaledHeight = contentHeight * scale;
      final minY = screenHeight - scaledHeight;

      double clampedY = y.clamp(minY < 0 ? minY : 0, 0);
      matrix.setEntry(1, 3, clampedY);
      transformationController.value = matrix;
    });
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      transformationController.value = animation!.value;
    });
    loadUserInfo();
  }

  @override
  void dispose() {
    transformationController.dispose();
    animationController.dispose();
    super.dispose();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      factory = prefs.getString('building') ?? 'A16';
      lean = prefs.getString('lean') ?? 'LEAN01';
      orderFactory = prefs.getString('orderBuilding') ?? 'A16';
      orderLean = prefs.getString('orderLean') ?? 'LEAN01';
      section = prefs.getString('section') ?? 'S';
      apiAddress = prefs.getString('address') ?? '';
    });

    loadSchedule();
  }

  void loadSchedule() async {
    setState(() {
      loadSuccess = false;
    });
    schedules = const SizedBox();

    try {
      final body = await RemoteService().getLeanScheduleData(
        apiAddress,
        selectedMonth,
        orderFactory,
        orderLean,
        section
      );
      final jsonBody = json.decode(body);

      tableColumnTitles = [];
      tableFirstCol = [];
      tableContentRows = [];
      if (jsonBody.length > 0) {
        DateTime firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
        DateTime lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

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

        List<int> holidays = jsonBody['Holiday'].cast<int>();

        for (int j = 0; j < jsonBody['Sequence'].length; j++) {
          tableFirstCol.add((j + 1).toString());
          List<Widget> orders = [];
          DateTime tempDate = firstDayOfMonth;
          for (int k = 0; k < jsonBody['Sequence'][j]['Schedule'].length; k++) {
            DateTime orderDate = DateFormat('yyyy/MM/dd').parse(jsonBody['Sequence'][j]['Schedule'][k]['Date'].toString());
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

            orders.add(
              OrderCard(
                height: cardHeight,
                width: cardWidth,
                dieCut: jsonBody['Sequence'][j]['Schedule'][k]['DieCutMold'].toString(),
                order: jsonBody['Sequence'][j]['Schedule'][k]['Order'],
                subOrder: jsonBody['Sequence'][j]['Schedule'][k]['SubOrder'],
                buy: jsonBody['Sequence'][j]['Schedule'][k]['BuyNo'],
                sku: jsonBody['Sequence'][j]['Schedule'][k]['SKU'],
                pairs: NumberFormat('###,###,##0').format(jsonBody['Sequence'][j]['Schedule'][k]['Pairs']),
                gac: jsonBody['Sequence'][j]['Schedule'][k]['ShipDate'],
                country: jsonBody['Sequence'][j]['Schedule'][k]['Country'],
                progress: jsonBody['Sequence'][j]['Schedule'][k]['Progress'],
                location: jsonBody['Sequence'][j]['Schedule'][k]['Location'],
                labor: NumberFormat('###,###,##0').format(jsonBody['Sequence'][j]['Schedule'][k]['Labor']),
                loadSchedule: loadSchedule,
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
          tableContentRows.add(orders);
        }
      }
    }
    finally {
      setState(() {
        minScale = screenWidth / ((tableColumnTitles.length - 1) * cardWidth + 60);
        fitHeightScale = screenHeight / (tableFirstCol.length * cardHeight + 60);
        maxScale = fitHeightScale < 1 ? 1 : fitHeightScale;
        if (firstLoad) {
          transformationController.value = Matrix4.identity()..scale(fitHeightScale);
        }
        loadSuccess = true;
      });
      firstLoad = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - AppBar().preferredSize.height - MediaQuery.of(context).viewPadding.bottom;

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
            Text('$factory $lean', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            section == 'S' ? Text('${AppLocalizations.of(context)!.stitching}${'${factory}_$lean' != '${orderFactory}_$orderLean' ? ' - [$orderFactory $orderLean]' : ''}', style: const TextStyle(fontSize: 16, color: Colors.white))
            : section == 'C' ? Text('${AppLocalizations.of(context)!.cutting}${'${factory}_$lean' != '${orderFactory}_$orderLean' ? ' - [$orderFactory $orderLean]' : ''}', style: const TextStyle(fontSize: 16, color: Colors.white))
            : const SizedBox(),
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
                    refresh: loadSchedule,
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white,
        ),
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 120,
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.layerGroup,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$factory $lean', style: const TextStyle(fontSize: 16, color: Colors.white)),
                          section == 'S' ? Text(AppLocalizations.of(context)!.stitching, style: const TextStyle(fontSize: 12, color: Colors.white))
                          : section == 'C' ? Text(AppLocalizations.of(context)!.cutting, style: const TextStyle(fontSize: 12, color: Colors.white))
                          : const SizedBox(),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  size: 22,
                  color: Colors.black,
                ),
                title: Text(AppLocalizations.of(context)!.settingsLogout, style: const TextStyle(fontSize: 18)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        scrollable: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))
                        ),
                        content: Text(AppLocalizations.of(context)!.settingsLogoutConfirm),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
                            },
                            child: Text(AppLocalizations.of(context)!.ok),
                          ),
                        ]
                      );
                    },
                  );
                },
              ),
            ]
          )
        )
      ),
      body: loadSuccess && tableColumnTitles.isNotEmpty ? LayoutBuilder(
        builder: (context, constraints) {
          double tableWidth = (tableColumnTitles.length - 1) * cardWidth + 60;
          double tableHeight = tableWidth * screenHeight / screenWidth ;

          return GestureDetector(
            onDoubleTapDown: (details) {
              final position = details.localPosition;
              final currentMatrix = transformationController.value;
              final currentScale = currentMatrix.getMaxScaleOnAxis();
              double dx = position.dx / screenWidth * tableWidth * fitHeightScale;
              if (dx > tableWidth * fitHeightScale - screenWidth) {
                dx = tableWidth * fitHeightScale - screenWidth;
              }
              final targetMatrix = currentScale > minScale ? (Matrix4.identity()..scale(minScale)) : (Matrix4.identity()..translate(-dx, 0)..scale(fitHeightScale));

              animation = Matrix4Tween(
                begin: transformationController.value,
                end: targetMatrix,
              ).animate(CurveTween(curve: Curves.easeInOut).animate(animationController));

              animationController.forward(from: 0);
            },
            child: InteractiveViewer(
              transformationController: transformationController,
              minScale: minScale,
              maxScale: maxScale,
              panEnabled: true,
              constrained: false,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: tableWidth,
                height: tableHeight,
                child: HorizontalDataTable(
                  scrollPhysics: const NeverScrollableScrollPhysics(),
                  horizontalScrollPhysics: const NeverScrollableScrollPhysics(),
                  leftHandSideColumnWidth: 60,
                  rightHandSideColumnWidth: cardWidth * (tableColumnTitles.length - 1),
                  isFixedHeader: true,
                  headerWidgets: tableColumnTitles,
                  leftSideItemBuilder: (BuildContext context, int index) {
                    return SizedBox(
                      height: cardHeight,
                      child: Center(
                        child: Text(tableFirstCol[index], style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  },
                  rightSideItemBuilder: (BuildContext context, int index) {
                    return Row(children: tableContentRows[index]);
                  },
                  itemCount: tableFirstCol.length,
                  rowSeparatorWidget: Divider(
                    color: Colors.grey.shade300,
                    height: 1.0,
                    thickness: 0.0,
                  ),
                  leftHandSideColBackgroundColor: const Color(0xFFFFFFFF),
                  rightHandSideColBackgroundColor: const Color(0xFFFFFFFF),
                ),
              ),
            ),
          );
        },
      ) : loadSuccess && tableFirstCol.isEmpty ? Center(
        child: Text(AppLocalizations.of(context)!.noDataFound),
      ) : const Center(
        child: CircularProgressIndicator(
          color: Colors.blue,
        ),
      ),
    );
  }
}

class OrderCard extends StatefulWidget {
  const OrderCard({
    super.key,
    required this.height,
    required this.width,
    required this.dieCut,
    required this.order,
    required this.subOrder,
    required this.buy,
    required this.sku,
    required this.pairs,
    required this.gac,
    required this.country,
    required this.progress,
    required this.location,
    required this.labor,
    required this.loadSchedule,
  });

  final double height;
  final double width;
  final String dieCut;
  final String order;
  final String subOrder;
  final String buy;
  final String sku;
  final String pairs;
  final String gac;
  final String country;
  final String progress;
  final String location;
  final String labor;
  final Function loadSchedule;

  @override
  OrderCardState createState() => OrderCardState();
}

class OrderCardState extends State<OrderCard> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: widget.height,
          width: widget.width,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              height: widget.height - 4,
              width: widget.width - 4,
              decoration: BoxDecoration(
                  color: double.parse(widget.progress) == 100 ? Colors.green.shade100 : double.parse(widget.progress) > 0 ? Colors.orange.shade100 : Colors.white,
                  border: Border.all(width: 1, color: double.parse(widget.progress) == 100 ? Colors.green : double.parse(widget.progress) > 0 ? Colors.orange : Colors.black38),
                  borderRadius: BorderRadius.circular(8)
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context, '/leanWorkOrder/reporting',
                      arguments: {
                        "ry": widget.order,
                        "building": factory,
                        "lean": lean,
                        "section": section,
                        "type": "OUTPUT",
                        "previousPage": "/lean_schedule",
                        "mode": widget.location == 'Ty Xuan' ? "Update" : "ReadOnly"
                      },
                    ).then((_) => widget.loadSchedule());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(widget.dieCut, strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                          Text(widget.order + (widget.subOrder == '' ? '' : '-${widget.subOrder}'), strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                          Text(widget.buy, strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                          Text(widget.sku, strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                          Text(widget.pairs, strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                          Text(widget.gac, strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                          Text(widget.country, strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis),
                          Text('[${widget.progress}%]', strutStyle: const StrutStyle(forceStrutHeight: true, leading: 0.5), overflow: TextOverflow.ellipsis)
                        ]
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: widget.location == 'Ty Dat',
          child: Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4)
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                child: Text('TĐ', style: TextStyle(color: Colors.white, height: 1),),
              ),
            ),
          )
        ),
        Visibility(
          visible: false,
          child: Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4)
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                child: Text(widget.labor, style: const TextStyle(color: Colors.white, height: 1),),
              ),
            ),
          ),
        )
      ],
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
                        ),
                      ),
                    ).then((date) async {
                      if (date != null) {
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
