import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';

String apiAddress = '';
double screenWidth = 0, screenHeight = 0;

class OrderInformationRYBOM extends StatefulWidget {
  const OrderInformationRYBOM({super.key});

  @override
  OrderInformationRYBOMState createState() => OrderInformationRYBOMState();
}

class OrderInformationRYBOMState extends State<OrderInformationRYBOM> {
  String ry = '';
  String loadingStatus = 'No Data';
  List<Widget> bomList = [];

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

    loadRYBom();
  }

  Future<void> loadRYBom() async {
    setState(() {
      loadingStatus = 'isLoading';
    });

    final body = await RemoteService().getRYBom(
      apiAddress,
      ry
    );
    final jsonData = json.decode(body);

    bomList = [];
    if (jsonData.length > 0) {
      for (int j = 0; j < jsonData.length; j++) {
        bomList.add(
          BomCard(
            partID: jsonData[j]['PartID'],
            partName: jsonData[j]['PartName'],
            supID: jsonData[j]['SupID'],
            supName: jsonData[j]['SupName'],
            matID: jsonData[j]['MatID'],
            matName: jsonData[j]['MatName'],
            usage: jsonData[j]['Usage'].toDouble(),
            unit: jsonData[j]['Unit'],
            subMaterials: jsonData[j]['SubMaterials'],
          )
        );
      }

      setState(() {
        bomList = bomList;
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
    ry = (ModalRoute.of(context)?.settings.arguments as String?)!;
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - kBottomNavigationBarHeight;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.settings.name == '/order_information/sku/ry');
          },
        ),
        title: Text(ry),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: loadingStatus == 'Completed'
          ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: bomList,
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

class BomCard extends StatefulWidget {
  const BomCard({
    super.key,
    required this.partID,
    required this.partName,
    required this.supID,
    required this.supName,
    required this.matID,
    required this.matName,
    required this.usage,
    required this.unit,
    required this.subMaterials
  });

  final String partID;
  final String partName;
  final String supID;
  final String supName;
  final String matID;
  final String matName;
  final double usage;
  final String unit;
  final dynamic subMaterials;

  @override
  State<StatefulWidget> createState() => BomCardState();
}

class BomCardState extends State<BomCard> {
  final formatter = NumberFormat()..maximumFractionDigits = 2;
  List<Widget> subMaterials = [];

  @override
  void initState() {
    super.initState();
    loadSubMaterials();
  }

  void loadSubMaterials() {
    subMaterials = [];
    for (int i = 0; i < widget.subMaterials.length; i++) {
      subMaterials.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 4 : 0, bottom: 4),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 19, right: 6),
                child: Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: Colors.black54),
              ),
              SizedBox(
                height: 20,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.black26),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          scrollable: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8))
                          ),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('${AppLocalizations.of(context)!.material}：')
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(240, 240, 240, 1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.black26, width: 1),
                                      ),
                                      child: Text('[${widget.subMaterials[i]['MatID']}] ${widget.subMaterials[i]['MatName']}', softWrap: true,)
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('${AppLocalizations.of(context)!.supplier}：')
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(240, 240, 240, 1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.black26, width: 1),
                                      ),
                                      child: Text('[${widget.subMaterials[i]['SupID']}] ${widget.subMaterials[i]['SupName']}')
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('${AppLocalizations.of(context)!.usage}：')
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(240, 240, 240, 1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.black26, width: 1),
                                      ),
                                      child: Text('${widget.subMaterials[i]['Usage']} ${widget.subMaterials[i]['Unit']}')
                                    ),
                                  ),
                                ],
                              ),
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
                  child: Text('[${widget.subMaterials[i]['MatID']}] ${formatter.format(widget.subMaterials[i]['Usage'])} ${widget.subMaterials[i]['Unit']}'),
                ),
              )
            ],
          ),
        ),
      );

      for (int j = 0; j < widget.subMaterials[i]['SubMaterials'].length; j++) {
        subMaterials.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 40, right: 6),
                  child: Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: Colors.black54),
                ),
                SizedBox(
                  height: 20,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black54,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.black26),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            scrollable: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8))
                            ),
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('${AppLocalizations.of(context)!.material}：')
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(240, 240, 240, 1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.black26, width: 1),
                                        ),
                                        child: Text('[${widget.subMaterials[i]['SubMaterials'][j]['MatID']}] ${widget.subMaterials[i]['SubMaterials'][j]['MatName']}', softWrap: true,)
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('${AppLocalizations.of(context)!.supplier}：')
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(240, 240, 240, 1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.black26, width: 1),
                                        ),
                                        child: Text('[${widget.subMaterials[i]['SubMaterials'][j]['SupID']}] ${widget.subMaterials[i]['SubMaterials'][j]['SupName']}')
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('${AppLocalizations.of(context)!.usage}：')
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(240, 240, 240, 1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.black26, width: 1),
                                        ),
                                        child: Text('${widget.subMaterials[i]['SubMaterials'][j]['Usage']} ${widget.subMaterials[i]['SubMaterials'][j]['Unit']}')
                                      ),
                                    ),
                                  ],
                                ),
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
                    child: Text('[${widget.subMaterials[i]['SubMaterials'][j]['MatID']}] ${formatter.format(widget.subMaterials[i]['SubMaterials'][j]['Usage'])} ${widget.subMaterials[i]['SubMaterials'][j]['Unit']}'),
                  ),
                )
              ],
            ),
          ),
        );
      }
    }

    setState(() {
      subMaterials = subMaterials;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(widget.partID, style: const TextStyle(fontSize: 16, color: Colors.white),),
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(widget.partName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black12,),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${AppLocalizations.of(context)!.supplier}：[${widget.supID}] ${widget.supName}'),
              ),
              Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 2, right: 8),
                    child: FaIcon(FontAwesomeIcons.solidStar, size: 10, color: Colors.orange),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(6)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text('[${widget.matID}] ${widget.matName}', style: const TextStyle(color: Colors.white),),
                        )
                      )
                    ),
                  ),
                ],
              ),
              Stack(
                alignment: AlignmentDirectional.bottomCenter,
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                    ),
                    child: Column(
                      children: subMaterials
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: SizedBox()
                      ),
                      SizedBox(
                        height: 34,
                        child: Text(formatter.format(widget.usage), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),)
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 1),
                        child: Text(widget.unit, style: const TextStyle(fontSize: 10),),
                      )
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}