import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:production/components/side_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';

String apiAddress = '';
double screenWidth = 0, screenHeight = 0;
String sFactory = '', sLean = '', department = '', mode = 'Today';

class HomePageCapacity extends StatefulWidget {
  const HomePageCapacity({super.key});

  @override
  HomePageCapacityState createState() => HomePageCapacityState();
}

class HomePageCapacityState extends State<HomePageCapacity> {
  String userName = '';
  String group = '';
  List<Widget> buildings = [];
  List<GlobalKey<BuildingCapacityState>> buildingKeys = [];
  bool loadSuccess = false;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    String userID = '';

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString('userID') ?? '';
      userName = prefs.getString('userName') ?? '';
      group = prefs.getString('group') ?? '';
      department = prefs.getString('department') ?? 'A02_LEAN01';
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    loadBuildingCapacity();
  }

  Future<void> loadBuildingCapacity() async {
    setState(() {
      loadSuccess = false;
    });

    try {
      buildings = [];
      buildingKeys = [];
      final body = await RemoteService().getBuildingMonthlyCapacity(
        apiAddress,
        DateFormat('yyyy/MM/dd').format(DateTime.now()),
      );
      final jsonData = json.decode(body);

      if (jsonData.length > 0) {
        for (int i = 0; i < jsonData.length; i++) {
          GlobalKey<BuildingCapacityState> key = GlobalKey();
          buildingKeys.add(key);
          buildings.add(
            BuildingCapacity(
              key: buildingKeys[buildingKeys.length - 1],
              group: jsonData[i]['Group'],
              building: jsonData[i]['Building'],
              leanData: jsonData[i]['Lean'],
            )
          );
        }
      }

      setState(() {
        buildings = buildings;
        loadSuccess = true;
      });
    } on Exception {
      setState(() {
        buildings = [];
        loadSuccess = true;
      });
    }
  }

  Future<void> reloadInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiAddress = prefs.getString('address') ?? '';
    });
    loadBuildingCapacity();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
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
        title: Text(AppLocalizations.of(context)!.homePageTitle),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    content: Column(
                      children: [
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.todaySummary),
                          onTap: () {
                            setState(() {
                              mode = 'Today';
                              for (int i = 0; i < buildingKeys.length; i++) {
                                buildingKeys[i].currentState?.modeSwitch();
                              }
                            });
                            Navigator.of(context).pop();
                          }
                        ),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.monthlySummary),
                          onTap: () {
                            setState(() {
                              mode = 'Monthly';
                              for (int i = 0; i < buildingKeys.length; i++) {
                                buildingKeys[i].currentState?.modeSwitch();
                              }
                            });
                            Navigator.of(context).pop();
                          }
                        )
                      ],
                    )
                  );
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(50),
                borderRadius: BorderRadius.circular(6)
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 2, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Text(mode == 'Today' ? AppLocalizations.of(context)!.todaySummary : AppLocalizations.of(context)!.monthlySummary),
                    const Icon(Icons.arrow_drop_down_outlined, size: 18,)
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              reloadInfo();
            },
            icon: const Icon(Icons.refresh)
          )
        ],
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      drawer: SideMenu(userName: userName, group: group),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: loadSuccess && buildings.isNotEmpty ? SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: buildings,
            ),
          ),
        ) : loadSuccess && buildings.isEmpty ? Center(
          child: Text(AppLocalizations.of(context)!.noDataFound),
        ) : const Center(
          child: CircularProgressIndicator(color: Colors.blue,),
        )
      )
    );
  }
}

class BuildingCapacity extends StatefulWidget {
  const BuildingCapacity({
    super.key,
    required this.group,
    required this.building,
    required this.leanData
  });

  final String group;
  final String building;
  final dynamic leanData;

  @override
  BuildingCapacityState createState() => BuildingCapacityState();
}

class BuildingCapacityState extends State<BuildingCapacity> {
  double tProgress = 0, utProgress = 0;
  int tTarget = 0, tFinished = 0, utTarget = 0, utFinished = 0;
  List<Widget> leanList = [];
  List<GlobalKey<LeanCapacityState>> leanKeys = [];

  @override
  void initState() {
    super.initState();
    leanList = [];
    leanKeys = [];
    tTarget = 0;
    tFinished = 0;
    utTarget = 0;
    utFinished = 0;

    if (widget.leanData.isNotEmpty) {
      for (int i = 0; i < widget.leanData.length; i++) {
        if (widget.leanData[i]['T_Target'] > 0 && widget.leanData[i]['Type'] != 'CBY') {
          int temp = widget.leanData[i]['T_Target'];
          tTarget += temp;
        }
        if (widget.leanData[i]['T_Finished'] > 0 && widget.leanData[i]['Type'] != 'CBY') {
          int temp = widget.leanData[i]['T_Finished'];
          tFinished += temp;
        }
        if (widget.leanData[i]['UT_Target'] > 0 && widget.leanData[i]['Type'] != 'CBY') {
          int temp = widget.leanData[i]['UT_Target'];
          utTarget += temp;
        }
        if (widget.leanData[i]['UT_Finished'] > 0 && widget.leanData[i]['Type'] != 'CBY') {
          int temp = widget.leanData[i]['UT_Finished'];
          utFinished += temp;
        }

        GlobalKey<LeanCapacityState> key = GlobalKey();
        leanKeys.add(key);
        leanList.add(
          LeanCapacity(
            key: leanKeys[leanKeys.length - 1],
            building: widget.building,
            lean: widget.leanData[i]['Lean'],
            type: widget.leanData[i]['Type'],
            tFinished: widget.leanData[i]['T_Finished'],
            tTarget: widget.leanData[i]['T_Target'],
            utFinished: widget.leanData[i]['UT_Finished'],
            utTarget: widget.leanData[i]['UT_Target'],
            mTarget: widget.leanData[i]['M_Target']
          )
        );
      }

      tProgress = tTarget > 0 ? tFinished * 1.0 / tTarget : 0;
      utProgress = utTarget > 0 ? utFinished * 1.0 / utTarget : 0;
    }
  }

  void modeSwitch() {
    setState(() {
      mode = mode;
      for (int i = 0; i < leanKeys.length; i++) {
        leanKeys[i].currentState?.modeSwitch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(254, 247, 255, 1),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(1, 1),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context, '/home/lean_capacity_chart',
                      arguments: {
                        "building": widget.building,
                        "lean": "",
                        "type": "MP",
                        "mode": mode == "Today" ? "Daily" : "Monthly"
                      },
                    );
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,//Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4)
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const FaIcon(FontAwesomeIcons.locationPin, size: 36, color: Color.fromRGBO(234, 67, 53, 1),),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Container(
                                        height: 20,
                                        width: 20,
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(179, 20, 18, 1),
                                          borderRadius: BorderRadius.circular(10)
                                        ),
                                        child: Center(
                                          child: Text(widget.group, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),)
                                        )
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.building, style: const TextStyle(fontSize: 24, height: 1),),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(mode == 'Today' ? NumberFormat('###,##0').format(tFinished) : NumberFormat('###,##0').format(utFinished), style: const TextStyle(fontSize: 14)),
                                    const Text(' / ', style: TextStyle(fontSize: 10),),
                                    Text(mode == 'Today' ? NumberFormat('###,##0').format(tTarget) : NumberFormat('###,##0').format(utTarget), style: const TextStyle(fontSize: 10),)
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: mode == 'Today' ? tTarget > 0 : utTarget > 0,
                        child: Row(
                          children: [
                            Expanded(
                              child: TweenAnimationBuilder(
                                tween: Tween(begin: 0.0, end: mode == 'Today' ? tProgress : utProgress),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(2.5),
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation(Color.fromRGBO(96, 84, 222, 1)),
                                  );
                                }
                              ),
                            ),
                            SizedBox(
                              width: 52,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text('${NumberFormat('##0.0').format(((mode == 'Today' ? tProgress : utProgress) * 1000).floor() / 10)}%', style: const TextStyle(color: Color.fromRGBO(96, 84, 222, 1), fontWeight: FontWeight.bold),)
                              )
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Divider(height: 1, color: Colors.black12),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: leanList,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class LeanCapacity extends StatefulWidget {
  const LeanCapacity({
    super.key,
    required this.building,
    required this.lean,
    required this.type,
    required this.tFinished,
    required this.tTarget,
    required this.utFinished,
    required this.utTarget,
    required this.mTarget
  });

  final String building;
  final String lean;
  final String type;
  final int tFinished;
  final int tTarget;
  final int utFinished;
  final int utTarget;
  final int mTarget;

  @override
  LeanCapacityState createState() => LeanCapacityState();
}

class LeanCapacityState extends State<LeanCapacity> {
  double tProgress = 0, utProgress = 0;

  @override
  void initState() {
    super.initState();
    tProgress = widget.tTarget > 0 ? widget.tFinished * 1.0 / widget.tTarget : 0;
    utProgress = widget.utTarget > 0 ? widget.utFinished * 1.0 / widget.utTarget : 0;
  }

  void modeSwitch() {
    setState(() {
      mode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context, '/home/lean_capacity_chart',
            arguments: {
              "building": widget.building,
              "lean": widget.lean,
              "type": widget.type,
              "mode": mode == "Today" ? "Daily" : "Monthly"
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4)
                            ),
                          ),
                          const Icon(Icons.double_arrow, color: Colors.blue,)
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(widget.type == 'CBY' ? 'CBY' : widget.lean, style: const TextStyle(fontSize: 16, height: 1),),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 2, top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(mode == 'Today' ? NumberFormat('###,##0').format(widget.tFinished) : NumberFormat('###,##0').format(widget.utFinished), style: const TextStyle(fontSize: 14)),
                                Visibility(
                                  visible: widget.type != 'CBY',
                                  child: const Text(' / ', style: TextStyle(fontSize: 10),)
                                ),
                                Visibility(
                                  visible: widget.type != 'CBY',
                                  child: Text(mode == 'Today' ? NumberFormat('###,##0').format(widget.tTarget) : NumberFormat('###,##0').format(widget.utTarget), style: const TextStyle(fontSize: 10),)
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: Visibility(
                        visible: (mode == 'Today' ? widget.tTarget : widget.utTarget) > 0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 48,
                              width: 48,
                              child: TweenAnimationBuilder(
                                tween: Tween(begin: 0.0, end: mode == 'Today' ? tProgress : utProgress),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return CircularProgressIndicator(
                                    value: value,
                                    backgroundColor: Colors.grey[300],
                                    color: Colors.blue,
                                    strokeWidth: 3,
                                    padding: const EdgeInsets.all(4),
                                  );
                                }
                              ),
                            ),
                            Text('${NumberFormat('##0.0').format(((mode == 'Today' ? tProgress : utProgress) * 1000).floor() / 10)}%', style: const TextStyle(fontSize: 10),)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black12)
            ],
          ),
        ),
      ),
    );
  }
}