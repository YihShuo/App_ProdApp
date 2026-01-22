import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:horizontal_data_table/refresh/pull_to_refresh/src/indicator/material_indicator.dart';
import 'package:horizontal_data_table/refresh/pull_to_refresh/src/smart_refresher.dart';
import 'package:production/components/side_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';

String apiAddress = '', userName = '', group = '';
String sBuilding = 'A16';
double screenHeight = 0;

class CuttingMachine extends StatefulWidget {
  const CuttingMachine({super.key});

  @override
  CuttingMachineState createState() => CuttingMachineState();
}

class CuttingMachineState extends State<CuttingMachine> {
  RefreshController refreshController = RefreshController(initialRefresh: false);
  List<Widget> machineList = [];

  @override
  void initState() {
    super.initState();
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

    manualRefresh();
  }

  void getMachineList() async {
    machineList = [];
    final body = await RemoteService().getBuildingMachine(
      apiAddress,
      sBuilding,
      'Cutting'
    );
    final jsonData = json.decode(body);

    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        machineList.add(
          Padding(
            padding: EdgeInsets.only(top: machineList.isEmpty ? 8 : 4, bottom: 4, left: 8, right: 8),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/cutting_machine/dispatch', arguments: '$sBuilding;${jsonData[i]['Machine'].toString()}');
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 1,
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.arrow_right_rounded, size: 28),
                      ),
                      Text(jsonData[i]['Machine'],
                          style: const TextStyle(fontSize: 18)),
                    ],
                  )
                ),
              ),
            ),
          )
        );
      }
    }
    else {
      machineList.add(
        SizedBox(
          height: screenHeight - AppBar().preferredSize.height,
          child: Align(
            alignment: Alignment.center,
            child: Text(AppLocalizations.of(context)!.noDataFound)
          )
        )
      );
    }

    setState(() {
      machineList = machineList;
    });
    refreshController.refreshCompleted();
  }

  void manualRefresh() {
    refreshController.requestRefresh();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top;
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
        title: Text('$sBuilding ${AppLocalizations.of(context)!.machineAssignment}'),
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
                  return FilterDialog(
                    refresh: manualRefresh
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: SideMenu(
        userName: userName,
        group: group,
      ),
      backgroundColor: Colors.grey[300],
      body: SmartRefresher(
        header: const MaterialClassicHeader(color: Colors.blue),
        controller: refreshController,
        onRefresh: getMachineList,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: machineList,
          ),
        ),
      ),
    );
  }
}

class FilterDialog extends StatefulWidget {
  final Function refresh;
  const FilterDialog({
    super.key,
    required this.refresh
  });

  @override
  FilterDialogState createState() => FilterDialogState();
}

class FilterDialogState extends State<FilterDialog> {
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
            child: Text(AppLocalizations.of(context)!.building)
          ),
          DropdownButton<String>(
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Colors.grey,
            ),
            value: sBuilding,
            items: const [
              DropdownMenuItem(
                value: 'A16',
                child: Center(
                  child: Text('A16'),
                )
              ),
              DropdownMenuItem(
                value: 'A15',
                child: Center(
                  child: Text('A15'),
                )
              )
            ],
            onChanged: (value) {
              setState(() {
                sBuilding = value!;
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