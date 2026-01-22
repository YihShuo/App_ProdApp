import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';

String apiAddress = '', locale = 'zh';
List<Widget> spList = [];

class LeanTrackingSP extends StatefulWidget {
  const LeanTrackingSP({super.key});

  @override
  LeanTrackingSPState createState() => LeanTrackingSPState();
}

class LeanTrackingSPState extends State<LeanTrackingSP> {
  String order = '', previousPage = '';
  bool loadSuccess = true;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '';

    setState(() {
      apiAddress = prefs.getString('address') ?? '';
      locale = prefs.getString('locale') ?? 'zh';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    loadSecondProcess();
  }

  void loadSecondProcess() async {
    setState(() {
      loadSuccess = false;
    });

    spList = [];
    try {
      final body = await RemoteService().getLeanRYSecondProcess(
        apiAddress,
        order
      );
      final jsonBody = json.decode(body);

      if (jsonBody.length > 0) {
        for (int i = 0; i < jsonBody.length; i++) {
          String process = '', component = '';

          if (locale == 'zh') {
            process = jsonBody[i]['P_CH'];
            component = jsonBody[i]['C_CH'];
          }
          else if (locale == 'vi') {
            process = jsonBody[i]['P_VN'];
            component = jsonBody[i]['C_VN'];
          }
          else {
            process = jsonBody[i]['P_EN'];
            component = jsonBody[i]['C_EN'];
          }

          spList.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(254, 247, 255, 1),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(4, 4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('$process - $component', style: const TextStyle(fontSize: 20)),
                        ),
                        const Divider(height: 1, color: Colors.black12),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 2),
                          child: Center(
                            child: Text('${NumberFormat('###,###,##0').format(jsonBody[i]['Finished'])}/${NumberFormat('###,###,##0').format(jsonBody[i]['Pairs'])} [${NumberFormat('##0.0').format(jsonBody[i]['Finished'] * 100.0 / jsonBody[i]['Pairs'])}%]', style: const TextStyle(fontSize: 14),)
                          ),
                        ),
                        SizedBox(
                          height: 32,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final progress = jsonBody[i]['Finished'] / jsonBody[i]['Pairs'];
                              final barWidth = constraints.maxWidth;
                              final currentX = (barWidth * progress).clamp(8.0, barWidth - 8.0);

                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: 8,
                                    right: 8,
                                    top: 0,
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 5,
                                      borderRadius: BorderRadius.circular(2.5),
                                      backgroundColor: Colors.grey[300],
                                      valueColor: const AlwaysStoppedAnimation(Colors.blue),
                                    ),
                                  ),
                                  Positioned(
                                    left: 5,
                                    top: -1,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.blue, width: 1),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: currentX - 5,
                                    top: -1,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.blue, width: 1),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: -12,
                                    top: 8,
                                    child: SizedBox(
                                      width: 40,
                                      child: Text(jsonBody[i]['LaunchDate'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                  Positioned(
                                    left: currentX - 20,
                                    top: 8,
                                    child: SizedBox(
                                      width: 40,
                                      child: Text(jsonBody[i]['EndDate'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ],
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                  )
                ),
              ),
            )
          );
        }
      }
    } finally {
      setState(() {
        spList = spList;
        loadSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    order = args["ry"];
    previousPage = args["previousPage"];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.settings.name == previousPage);
          },
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('${AppLocalizations.of(context)!.secondProcess} [${AppLocalizations.of(context)!.output}]', style: const TextStyle(fontSize: 16))
          ],
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: loadSuccess ? SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: spList,
            ),
          ),
        ) : const Center(
          child: CircularProgressIndicator(color: Colors.blue,),
        ),
      ),
    );
  }
}