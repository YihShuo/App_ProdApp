import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';

String apiAddress = '';
double screenWidth = 0, screenHeight = 0;

class OrderInformationRY extends StatefulWidget {
  const OrderInformationRY({super.key});

  @override
  OrderInformationRYState createState() => OrderInformationRYState();
}

class OrderInformationRYState extends State<OrderInformationRY> {
  String factory = '';
  String buy = '', ryType = '', cuttingDie = '', sku = '', filterRY = '';
  String loadingStatus = 'No Data';
  List<Widget> ryList = [];

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '';
    setState(() {
      factory = prefs.getString('factory') ?? '';
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    loadBuyRYs();
  }

  Future<void> loadBuyRYs() async {
    setState(() {
      loadingStatus = 'isLoading';
    });

    final body = await RemoteService().getBuyRYs(
      apiAddress,
      factory,
      buy,
      ryType,
      cuttingDie,
      sku,
      filterRY
    );
    final jsonData = json.decode(body);

    ryList = [];
    if (jsonData.length > 0) {
      for (int j = 0; j < jsonData.length; j++) {
        ryList.add(
          RYCard(
            ry: jsonData[j]['RY'],
            receiveDate: jsonData[j]['ReceiveDate'],
            shippingDate: jsonData[j]['ShippingDate'],
            launchDate: jsonData[j]['LaunchDate'],
            launchLine: jsonData[j]['LaunchLine'],
            pairs: jsonData[j]['Pairs'],
            finishedPairs: jsonData[j]['FinishedPairs']
          )
        );
      }

      setState(() {
        ryList = ryList;
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
    List<String> param = (ModalRoute.of(context)?.settings.arguments as String?)!.split(';');
    buy = param[0];
    ryType = param[1];
    cuttingDie = param[2];
    sku = param[3];
    filterRY = param[4];
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - kBottomNavigationBarHeight;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.settings.name == '/order_information/sku');
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sku),
            Text('$buy BUY [$ryType]', style: const TextStyle(fontSize: 14))
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: loadingStatus == 'Completed'
          ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: ryList,
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

class RYCard extends StatefulWidget {
  const RYCard({
    super.key,
    required this.ry,
    required this.receiveDate,
    required this.shippingDate,
    required this.launchDate,
    required this.launchLine,
    required this.pairs,
    required this.finishedPairs
  });

  final String ry;
  final String receiveDate;
  final String shippingDate;
  final String launchDate;
  final String launchLine;
  final int pairs;
  final int finishedPairs;

  @override
  State<StatefulWidget> createState() => RYCardState();
}

class RYCardState extends State<RYCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
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
        child: Material(
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.pushNamed(context, '/order_information/sku/ry/bom', arguments: widget.ry);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(widget.ry, style: const TextStyle(fontSize: 24)),
                  ),
                  const Divider(height: 1, color: Colors.black12),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${AppLocalizations.of(context)!.completionRate} - ${NumberFormat('##0.0').format(widget.finishedPairs * 100.0 / widget.pairs)}%', style: const TextStyle(color: Colors.black54, fontSize: 14),),
                  ),
                  LinearProgressIndicator(
                    value: widget.finishedPairs / widget.pairs,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(2.5),
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation(Colors.blue),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(20)
                                  ),
                                  child: const Center(
                                    child: FaIcon(FontAwesomeIcons.solidFlag, color: Colors.white, size: 18,)
                                  )
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.of(context)!.total, style: const TextStyle(fontSize: 12, color: Colors.black54),),
                                  Text('${NumberFormat('###,###,##0').format(widget.pairs)} Pairs', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
                                ],
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: widget.finishedPairs < widget.pairs ? Colors.grey.withAlpha(100) : Colors.blue,
                                    borderRadius: BorderRadius.circular(20)
                                  ),
                                  child: const Center(
                                    child: FaIcon(FontAwesomeIcons.check, color: Colors.white, size: 24,)
                                  )
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.of(context)!.completed, style: const TextStyle(fontSize: 12, color: Colors.black54),),
                                  Text('${NumberFormat('###,###,##0').format(widget.finishedPairs)} Pairs', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),)
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.assembly, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            Text(widget.launchDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
                          ],
                        ),
                        const Expanded(
                          child: SizedBox(
                            height: 32,
                            child: VerticalDivider(width: 1, color: Colors.black12,)
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.lean, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            Text(widget.launchLine, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),)
                          ],
                        ),
                        const Expanded(
                          child: SizedBox(
                            height: 32,
                            child: VerticalDivider(width: 1, color: Colors.black12,),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.shippingDate, style: const TextStyle(color: Colors.black54, fontSize: 12),),
                            Text(widget.shippingDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    );
  }
}