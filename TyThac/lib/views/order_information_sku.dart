import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';

String apiAddress = '';
double screenWidth = 0, screenHeight = 0;

class OrderInformationSKU extends StatefulWidget {
  const OrderInformationSKU({super.key});

  @override
  OrderInformationSKUState createState() => OrderInformationSKUState();
}

class OrderInformationSKUState extends State<OrderInformationSKU> with SingleTickerProviderStateMixin {
  String factory = '';
  String buy = '', ryType = '', cuttingDie = '', filterLast = '', filterSKU = '', filterRY = '';
  List<Widget> skuList = [];
  String loadingStatus = 'No Data';

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

    loadBuySKUs();
  }

  Future<void> loadBuySKUs() async {
    setState(() {
      loadingStatus = 'isLoading';
    });

    final body = await RemoteService().getBuySKUs(
      apiAddress,
      buy,
      factory,
      ryType,
      cuttingDie,
      filterLast,
      filterSKU,
      filterRY
    );
    final jsonData = json.decode(body);

    skuList = [];
    if (jsonData.length > 0) {
      for (int i = 0; i < jsonData.length; i++) {
        skuList.add(
          SKUCard(
            index: jsonData[i]['ID'],
            buy: buy,
            type: ryType,
            name: jsonData[i]['Name'],
            color: jsonData[i]['Color'],
            last: jsonData[i]['Last'],
            sku: jsonData[i]['SKU'],
            sr: jsonData[i]['SR'],
            buildings: jsonData[i]['Buildings'],
            pairs: jsonData[i]['Pairs'],
            finishedPairs: jsonData[i]['FinishedPairs'],
            total: jsonData.length - 1,
            cuttingDie: cuttingDie,
            filterRY: filterRY
          )
        );
      }

      setState(() {
        skuList = skuList;
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
    filterLast = param[3];
    filterSKU = param[4];
    filterRY = param[5];
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - kBottomNavigationBarHeight;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.settings.name == '/order_information');
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cuttingDie),
            Text('$buy BUY [$ryType]', style: const TextStyle(fontSize: 14))
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: loadingStatus == 'Completed'
          ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: skuList,
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

class SKUCard extends StatefulWidget {
  const SKUCard({
    super.key,
    required this.buy,
    required this.type,
    required this.index,
    required this.name,
    required this.color,
    required this.last,
    required this.sku,
    required this.sr,
    required this.buildings,
    required this.pairs,
    required this.finishedPairs,
    required this.total,
    required this.cuttingDie,
    required this.filterRY
  });

  final int index;
  final String buy;
  final String type;
  final String name;
  final String color;
  final String last;
  final String sku;
  final String sr;
  final String buildings;
  final int pairs;
  final int finishedPairs;
  final int total;
  final String cuttingDie;
  final String filterRY;

  @override
  State<StatefulWidget> createState() => SKUCardState();
}

class SKUCardState extends State<SKUCard> {
  Color vulcanizeColor = const Color.fromRGBO(229, 115, 115, 1);
  Color coldVulcanizeColor = const Color.fromRGBO(175, 60, 250, 1);
  Color coldCementColor = const Color.fromRGBO(100, 181, 246, 1);
  String category = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 12, right: 12, bottom: 12),
      child: Container(
        height: 150,
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
              Navigator.pushNamed(context, '/order_information/sku/ry', arguments: '${widget.buy};${widget.type};${widget.cuttingDie};${widget.sku};${widget.filterRY}');
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Text(widget.sku, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 25,
                        height: 25,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: widget.finishedPairs / widget.pairs,
                              color: Colors.blue,
                              backgroundColor: Colors.grey[300],
                              strokeWidth: 2,
                            ),
                            Center(
                              child: Text('${NumberFormat('##0').format(widget.finishedPairs * 100.0 / widget.pairs)}%', style: const TextStyle(fontSize: 8, color: Colors.blue),)
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                const Divider(height: 1, color: Colors.black12),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 4),
                  child: SizedBox(
                    height: 100,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 20,
                              child: Center(
                                child: Text('${AppLocalizations.of(context)!.shoeName}：', style: const TextStyle(fontSize: 12, height: 1))
                              )
                            ),
                            SizedBox(
                              height: 20,
                              child: Center(
                                child: Text('${AppLocalizations.of(context)!.color}：', style: const TextStyle(fontSize: 12, height: 1))
                              )
                            ),
                            SizedBox(
                              height: 20,
                              child: Center(
                                child: Text(AppLocalizations.of(context)!.scheduleLast, style: const TextStyle(fontSize: 12, height: 1)),
                              )
                            ),
                            const SizedBox(
                              height: 20,
                              child: Center(
                                child: Text('SR：', style: TextStyle(fontSize: 12, height: 1))
                              )
                            ),
                            const SizedBox(
                              height: 20,
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: FaIcon(FontAwesomeIcons.solidStar, size: 10, color: Colors.orange),
                                ),
                              )
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 20,
                              child: Center(
                                child: Text(widget.name, style: const TextStyle(fontSize: 12, height: 1))
                              ),
                            ),
                            SizedBox(
                              height: 20,
                              child: Center(
                                child: Text(widget.color, style: const TextStyle(fontSize: 12, height: 1))
                              ),
                            ),
                            SizedBox(
                              height: 20,
                              child: Center(
                                child: Text(widget.last, style: const TextStyle(fontSize: 12, height: 1)),
                              )
                            ),
                            SizedBox(
                              height: 20,
                              child: Center(
                                  child: Text(widget.sr, style: const TextStyle(fontSize: 12, height: 1))
                              ),
                            ),
                            SizedBox(
                              height: 20,
                              child: Center(
                                child: Text(widget.buildings, style: const TextStyle(fontSize: 12, height: 1))
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(AppLocalizations.of(context)!.pairs, style: const TextStyle(fontSize: 12),),
                              Text(NumberFormat('###,###,##0').format(widget.pairs), style: const TextStyle(fontSize: 20,))
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}