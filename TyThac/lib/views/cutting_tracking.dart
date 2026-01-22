import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:production/services/remote_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/l10n/app_localizations.dart';

String apiAddress = '';

class CuttingTracking extends StatefulWidget {
  const CuttingTracking({super.key});

  @override
  State<StatefulWidget> createState() => CuttingTrackingState();
}

class CuttingTrackingState extends State<CuttingTracking> {
  String order = '';
  String type = '';
  List<Widget> tableColumnTitles = [];
  List<String> tableFirstRow = [];
  List<List<int>> tableContentRows = [];
  late final Future<bool> myFuture;

  @override
  void initState() {
    super.initState();
    loadInfo();
    myFuture = loadTableData();
  }

  void loadInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '';
    String group = prefs.getString('group') ?? '';
    type = ['A0', 'A1'].contains(group.substring(0, 2)) == false ? 'Demo' : 'Real';
    setState(() {
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  Future<bool> loadTableData() async {
    tableColumnTitles = [];
    tableFirstRow = [];
    tableContentRows = [];

    final prefs = await SharedPreferences.getInstance();
    String locale = prefs.getString('locale') ?? 'zh';
    final body = await RemoteService().getOrderCuttingTrackingData(
      apiAddress,
      order,
      type
    );
    final jsonBody = json.decode(body);
    if (!mounted) return false;
    tableColumnTitles.add(
      SizedBox(
        height: 70,
        child: Center(child: Text(AppLocalizations.of(context)!.homePageCycle)),
      )
    );
    for (int i = 0; i < jsonBody[0]['Part'].length; i++) {
      tableColumnTitles.add(
        SizedBox(
          height: 70,
          width: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  jsonBody[0]['Part'][i]['CuttingType'] == 'Auto' ? const Icon(Icons.precision_manufacturing, size: 18) : const Icon(Icons.person_outline, size: 18),
                  Text(jsonBody[0]['Part'][i]['ID'], style: const TextStyle(height: 1.4))
                ],
              ),
              //Text(),
              Text(jsonBody[0]['Part'][i]['Material']),
              AutoSizeText(jsonBody[0]['Part'][i][locale.toUpperCase()], maxLines: 1, minFontSize: 1)
            ],
          ),
        )
      );
    }
    for (int i = 0; i < jsonBody.length; i++) {
      tableFirstRow.add(jsonBody[i]['Cycle']);
      List<int> partData = [];
      for (int j = 0; j < jsonBody[i]['Part'].length; j++) {
        if (int.parse(jsonBody[i]['Part'][j]['TargetPairs'].toString()) == 0) {
          partData.add(-1);
        }
        else if (int.parse(jsonBody[i]['Part'][j]['DispatchedPairs'].toString()) == 0) {
          partData.add(0);
        }
        else if (int.parse(jsonBody[i]['Part'][j]['ScanPairs'].toString()) < int.parse(jsonBody[i]['Part'][j]['TargetPairs'].toString())) {
          partData.add(1);
        }
        else {
          partData.add(2);
        }
      }
      tableContentRows.add(partData);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    order = (ModalRoute.of(context)?.settings.arguments as String?)!;
    return FutureBuilder(
      future: myFuture,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Text(order),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: Colors.blue)
            )
          );
        }
        else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Text(order),
            ),
            body: Center(
              child: Text('Error: ${snapshot.error}')
            )
          );
        }
        else {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Text(order)
            ),
            body: HorizontalDataTable(
              leftHandSideColumnWidth: 60,
              rightHandSideColumnWidth: 100.0 * (tableColumnTitles.length - 1),
              isFixedHeader: true,
              headerWidgets: tableColumnTitles,
              leftSideItemBuilder: (BuildContext context, int index) {
                return SizedBox(
                  height: 40,
                  child: Center(child: Text('T${tableFirstRow[index]}', style: const TextStyle(fontSize: 20)))
                );
              },
              rightSideItemBuilder: (BuildContext context, int index) {
                List<Widget> cells = [];
                for (int i = 0; i < tableContentRows[index].length; i++) {
                  Color partColor;
                  Icon partIcon;
                  if (tableContentRows[index][i] == 2) {
                    partColor = Colors.green.shade200;
                    partIcon = const Icon(Icons.done);
                  }
                  else if (tableContentRows[index][i] == 1) {
                    partColor = Colors.yellow.shade300;
                    partIcon = const Icon(Icons.hourglass_empty);
                  }
                  else if (tableContentRows[index][i] == 0) {
                    partColor = Colors.red.shade200;
                    partIcon = const Icon(Icons.close);
                  }
                  else {
                    partColor = Colors.white;
                    partIcon = const Icon(Icons.check_box_outline_blank, color: Colors.white);
                  }
                  cells.add(
                    Container(
                      color: partColor,
                      height: 40,
                      width: 100,
                      child: Center(
                        child: partIcon
                      )
                    )
                  );
                }
                return Row(
                  children: cells
                );
              },
              itemCount: tableFirstRow.length,
              rowSeparatorWidget: const Divider(
                color: Colors.grey,
                height: 1.0,
                thickness: 0.0,
              ),
              leftHandSideColBackgroundColor: const Color(0xFFFFFFFF),
              rightHandSideColBackgroundColor: const Color(0xFFFFFFFF),
            )
          );
        }
      },
    );
  }
}