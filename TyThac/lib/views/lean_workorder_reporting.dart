import 'package:flutter/material.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/components/sizerun_table_lean_reporting.dart';

String apiAddress = '';
bool readOnly = true;

class LeanWorkOrderReporting extends StatefulWidget {
  const LeanWorkOrderReporting({super.key});

  @override
  State<StatefulWidget> createState() => LeanWorkOrderReportingState();
}

class LeanWorkOrderReportingState extends State<LeanWorkOrderReporting> with SingleTickerProviderStateMixin {
  String previousPage = '', order = '', building = '', lean = '', section = '', type = '';
  
  @override
  void initState() {
    super.initState();
    loadInfo();
  }

  void loadInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiAddress = prefs.getString('address') ?? '';
    });
  }

  double getTextWidth(String text, TextStyle style, BuildContext context) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    order = args["ry"];
    building = args["building"];
    lean = args["lean"];
    section = args["section"];
    type = args["type"];
    previousPage = args["previousPage"];
    readOnly = args["mode"] == "ReadOnly" ? true : false;
    String sectionText = (
      section == 'W' ? AppLocalizations.of(context)!.warehouse :
      section == 'A' ? AppLocalizations.of(context)!.assembly :
      section == 'S' ? AppLocalizations.of(context)!.stitching :
      section == 'C' ? AppLocalizations.of(context)!.cutting : ''
    );
    String typeText = (
      type == 'INPUT' ? AppLocalizations.of(context)!.input :
      type == 'OUTPUT' ? AppLocalizations.of(context)!.output : ''
    );

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
            Text('$sectionText [$typeText]', style: const TextStyle(fontSize: 16))
          ],
        ),
      ),
      body: SizeRunTableLeanReporting(
        building: building,
        lean: lean,
        order: order,
        section: section,
        type: type,
        readOnly: readOnly,
      ),
    );
  }
}