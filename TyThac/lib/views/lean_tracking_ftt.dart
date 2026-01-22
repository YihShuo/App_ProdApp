import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

String apiAddress = '', locale = 'zh';
List<Widget> defectList = [];
const List<Color> customPalette = [
  Color(0xFF1F77B4), Color(0xFFFF7F0E), Color(0xFF2CA02C), Color(0xFFD62728), Color(0xFF9467BD),
  Color(0xFF8C564B), Color(0xFFE377C2), Color(0xFF7F7F7F), Color(0xFFBCBD22), Color(0xFF17BECF),
  Color(0xFF393B79), Color(0xFF637939), Color(0xFF8C6D31), Color(0xFF843C39), Color(0xFF7B4173),
  Color(0xFF3182BD), Color(0xFF6BAED6), Color(0xFF9ECAE1), Color(0xFFC6DBEF), Color(0xFFE6550D),
  Color(0xFFFD8D3C), Color(0xFFFDD0A2), Color(0xFF31A354), Color(0xFF74C476), Color(0xFFBAE4B3),
  Color(0xFF756BB1), Color(0xFF9E9AC8), Color(0xFFDADAEB), Color(0xFFFCAE91), Color(0xFFFEE0D2),
  Color(0xFFFB6A4A), Color(0xFFCB181D), Color(0xFFA1D99B), Color(0xFFBFD3E6), Color(0xFF6BAED6),
  Color(0xFF9ECAE1), Color(0xFFBDD7E7), Color(0xFF8856A7), Color(0xFFEFEDF5), Color(0xFFBCBDDC),
  Color(0xFFD9D9D9), Color(0xFFBC80BD), Color(0xFFCCEBC5), Color(0xFFFFED6F), Color(0xFFFFB3BA),
  Color(0xFFFFDFBA), Color(0xFFFFFBA1), Color(0xFFB5EAD7), Color(0xFFC7CEEA), Color(0xFFFAD02E),
  Color(0xFF6B5B95), Color(0xFF944743), Color(0xFFFF6F61), Color(0xFF88B04B), Color(0xFF009688),
  Color(0xFF795548), Color(0xFFFF9800), Color(0xFFE91E63), Color(0xFF3F51B5), Color(0xFF2196F3),
  Color(0xFF03A9F4), Color(0xFF00BCD4), Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFFFC107),
  Color(0xFFFFEB3B), Color(0xFFCDDC39), Color(0xFF607D8B), Color(0xFF9C27B0), Color(0xFF673AB7),
  Color(0xFF9E9E9E), Color(0xFFF44336), Color(0xFF9FA8DA), Color(0xFF00ACC1), Color(0xFF8D6E63),
  Color(0xFFB39DDB), Color(0xFFDCE775), Color(0xFFFFB74D), Color(0xFFAED581), Color(0xFF4DD0E1),
  Color(0xFF9575CD), Color(0xFFFF8A65), Color(0xFFA1887F), Color(0xFF80CBC4), Color(0xFFE6EE9C),
  Color(0xFF81C784), Color(0xFFFFD54F), Color(0xFF64B5F6), Color(0xFF7986CB), Color(0xFFA5D6A7),
  Color(0xFFE57373), Color(0xFFFFF176), Color(0xFF4DB6AC), Color(0xFFF06292), Color(0xFF4FC3F7),
  Color(0xFFFF8A65), Color(0xFF90A4AE), Color(0xFFCE93D8), Color(0xFFFFCC80), Color(0xFFB0BEC5),
];

class ChartData {
  ChartData(this.title, this.value, this.color);
  final String title;
  final double value;
  final Color color;
}

class LeanTrackingFTT extends StatefulWidget {
  const LeanTrackingFTT({super.key});

  @override
  LeanTrackingFTTState createState() => LeanTrackingFTTState();
}

class LeanTrackingFTTState extends State<LeanTrackingFTT> {
  String order = '', pairs = '', building = '', lean = '', section = '', previousPage = '';
  double ftt = 0;
  int total = 0;
  List<ChartData> dataSource = [];
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

    loadDefects();
  }

  void loadDefects() async {
    setState(() {
      loadSuccess = false;
    });

    total = 0;
    dataSource = [];
    defectList = [];
    try {
      final body = await RemoteService().getLeanRYDefects(
        apiAddress,
        order,
        building,
        lean,
        section
      );
      final jsonBody = json.decode(body);

      if (jsonBody.length > 0) {
        for (int i = 0; i < jsonBody.length; i++) {
          int defectPairs = jsonBody[i]['Pairs'];
          total += defectPairs;
        }

        for (int i = 0; i < jsonBody.length; i++) {
          String reason = '';

          if (locale == 'zh') {
            reason = jsonBody[i]['CH'];
          }
          else if (locale == 'vi') {
            reason = jsonBody[i]['VN'];
          }
          else {
            reason = jsonBody[i]['EN'];
          }

          dataSource.add(
            ChartData(reason, jsonBody[i]['Pairs'] * 1.0, customPalette[i])
          );

          defectList.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(254, 247, 255, 1),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 64,
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.all(0),
                        leading: jsonBody[i]['Seq'] <= 3 ? Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: SizedBox(
                            width: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('TOP'),
                                Text(jsonBody[i]['Seq'].toString())
                              ],
                            ),
                          ),
                        ) : Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: SizedBox(
                            width: 24,
                            child: Center(
                              child: Text(jsonBody[i]['Seq'].toString(), style: const TextStyle(fontSize: 18),)
                            )
                          ),
                        ),
                        title: Text(reason, style: const TextStyle(fontSize: 16),),
                        subtitle: Text('${NumberFormat('###,##0').format(jsonBody[i]['Pairs'])} ${AppLocalizations.of(context)!.times}', style: const TextStyle(fontSize: 12)),
                        trailing: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text('${NumberFormat('##0.0').format(jsonBody[i]['Pairs'] * 100.0 / total)}%', style: const TextStyle(fontSize: 16),),
                        ),
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 64,
                      decoration: BoxDecoration(
                        color: customPalette[i],
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8))
                      ),
                    )
                  ],
                ),
              )
            )
          );
        }
      }
    } finally {
      setState(() {
        defectList = defectList;
        loadSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    order = args["ry"];
    pairs = args["pairs"];
    building = args["building"];
    lean = args["lean"];
    section = args["section"];
    ftt = double.parse(args["ftt"]);
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
            Text(AppLocalizations.of(context)!.defectCause, style: const TextStyle(fontSize: 16))
          ],
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: loadSuccess ? SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(254, 247, 255, 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    offset: Offset(0, 1),
                    blurRadius: 2
                  )
                ],
                borderRadius: BorderRadius.circular(8)
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: SfCircularChart(
                      annotations: [
                        CircularChartAnnotation(
                          widget: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Text('FTT', style: TextStyle(fontWeight: FontWeight.bold, color: ftt >= 91 ? Colors.green : Colors.deepOrange, height: 1),),
                              ),
                              const SizedBox(height: 2,),
                              Text('${NumberFormat('##0.0').format(ftt)}%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ftt >= 91 ? Colors.green : Colors.deepOrange, height: 1))
                            ],
                          )
                        ),
                      ],
                      series: [
                        DoughnutSeries<ChartData, String>(
                          dataSource: dataSource,
                          innerRadius: '75%',
                          animationDuration: 0,
                          strokeColor: const Color.fromRGBO(254, 247, 255, 1),
                          strokeWidth: 1,
                          pointColorMapper:(ChartData data, _) => data.color,
                          xValueMapper: (ChartData data, _) => data.title,
                          yValueMapper: (ChartData data, _) => data.value,
                          dataLabelMapper: (ChartData data, _) => data.title,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            labelPosition: ChartDataLabelPosition.outside,
                            textStyle: TextStyle(
                              fontFamily: 'NotoSansSC',
                            ),
                            showZeroValue: false,
                            connectorLineSettings: ConnectorLineSettings(
                              type: ConnectorType.line,
                              width: 1,
                              color: Colors.black54
                            ),
                          ),
                        ),
                        DoughnutSeries<ChartData, String>(
                          dataSource: [
                            ChartData('FTT', ftt, ftt >= 91 ? Colors.green : Colors.deepOrange),
                            ChartData('BLANK', (100 - ftt), const Color.fromRGBO(254, 247, 255, 1)),
                          ],
                          radius: '59%',
                          innerRadius: '86%',
                          animationDuration: 0,
                          cornerStyle: ftt == 0 || ftt == 100 ? CornerStyle.bothFlat : CornerStyle.bothCurve,
                          pointColorMapper:(ChartData data, _) => data.color,
                          xValueMapper: (ChartData data, _) => data.title,
                          yValueMapper: (ChartData data, _) => data.value,
                        )
                      ]
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: defectList,
                    ),
                  )
                ],
              ),
            ),
          )
        ) : const Center(
          child: CircularProgressIndicator(color: Colors.blue,),
        ),
      ),
    );
  }
}