import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';

String apiAddress = '';
List<Widget> msList = [];

class LeanTrackingMaterial extends StatefulWidget {
  const LeanTrackingMaterial({super.key});

  @override
  LeanTrackingMaterialState createState() => LeanTrackingMaterialState();
}

class LeanTrackingMaterialState extends State<LeanTrackingMaterial> {
  String order = '', section = '', previousPage = '';
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

    msList = [];
    try {
      final body = await RemoteService().getLeanRYMatStatus(
        apiAddress,
        order,
        section
      );
      final jsonBody = json.decode(body);

      if (jsonBody.length > 0) {
        for (int i = 0; i < jsonBody.length; i++) {
          msList.add(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: jsonBody[i]['InStock'] == 0 ? Colors.red : jsonBody[i]['InStock'] < jsonBody[i]['Usage'] ? Colors.orange : Colors.green,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(jsonBody[i]['MatID'], style: const TextStyle(fontSize: 20, color: Colors.white))
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${jsonBody[i]['InStock']}', style: const TextStyle(fontSize: 16, color: Colors.white,)),
                                  Text('/${jsonBody[i]['Usage']}', style: const TextStyle(fontSize: 10, color: Colors.white,)),
                                  Text(' ${jsonBody[i]['Unit']}', style: const TextStyle(fontSize: 10, color: Colors.white))
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
                        child: Text('${AppLocalizations.of(context)!.supplier}：[${jsonBody[i]['SupID']}] ${jsonBody[i]['SupName']}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Text('${AppLocalizations.of(context)!.material}：'),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(220, 220, 220, 1),
                                    borderRadius: BorderRadius.circular(6)
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    child: Text(jsonBody[i]['MatName'], style: const TextStyle(fontSize: 14, height: 1),),
                                  ),
                                )
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
                        child: jsonBody[i]['InStock'] < jsonBody[i]['Usage'] ? Text('ETA：${jsonBody[i]['EstimatedDate']}') : Text('ATA：${jsonBody[i]['ArrivalDate']}'),
                      ),
                    ],
                  )
                ),
              ),
            )
          );
        }
      }
    } finally {
      setState(() {
        msList = msList;
        loadSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    order = args["ry"];
    section = args["section"];
    previousPage = args["previousPage"];
    String sectionText = section == 'C' ? AppLocalizations.of(context)!.cutting : section == 'S' ? AppLocalizations.of(context)!.stitching : AppLocalizations.of(context)!.assembly;

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
            Text('${AppLocalizations.of(context)!.material} - $sectionText', style: const TextStyle(fontSize: 16))
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
              children: msList,
            ),
          ),
        ) : const Center(
          child: CircularProgressIndicator(color: Colors.blue,),
        ),
      ),
    );
  }
}