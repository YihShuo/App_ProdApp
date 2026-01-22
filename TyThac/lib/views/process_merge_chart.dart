import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';

String apiAddress = '';

class ProcessMergeChart extends StatefulWidget {
  const ProcessMergeChart({super.key});

  @override
  ProcessMergeChartState createState() => ProcessMergeChartState();
}

class ProcessMergeChartState extends State<ProcessMergeChart> {
  String order = '';
  String lean = '';
  String userName = '';
  String group = '';
  bool loadSuccess = false;
  bool chartLoadSuccess = false;
  dynamic futureFlow;
  List<List<String>> sectionList = [];
  List<String> dispatchedList = [];
  List<int> dispatchedLevel = [];
  List<String> dispatchedName = [];
  List<String> itemList = [];
  List<String> nameList = [];
  List<String> statusList = [];
  Graph graph = Graph()..isTree = true;

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

    futureFlow = loadProcessPart();
  }

  Future<bool> loadProcessPart() async {
    setState(() {
      loadSuccess = false;
      chartLoadSuccess = true;
    });

    try {
      graph = Graph()..isTree = true;
      final fakeRootNode = Node.Id('Root');

      final prefs = await SharedPreferences.getInstance();
      String locale = prefs.getString('locale') ?? 'zh';

      final body = await RemoteService().getProcessingDispatchFlow(
        apiAddress,
        order,
      );
      final jsonData = json.decode(body);
      List<int> rootIndex = [];
      sectionList = [];
      dispatchedList = ['Root'];
      dispatchedLevel = [0];
      dispatchedName = ['Root'];
      itemList = ['Root'];
      nameList = ['Root'];
      statusList = ['0'];
      for (int i = 0; i < jsonData.length; i++) {
        itemList.add(jsonData[i]['Section'].toString());
        nameList.add(jsonData[i][locale.toUpperCase()].toString());
        if (jsonData[i]['Parent'].toString() == 'Root') {
          dispatchedList.add(jsonData[i]['Section'].toString());
          dispatchedLevel.add(1);
          dispatchedName.add(jsonData[i][locale.toUpperCase()].toString());
          statusList.add(jsonData[i]['Status'].toString());
          rootIndex.add(i);
          graph.addEdge(fakeRootNode, Node.Id(jsonData[i]['Section'].toString()), paint: Paint()..color = Colors.transparent);
        }
        else {
          sectionList.add([jsonData[i]['Section'].toString(), jsonData[i][locale.toUpperCase()].toString(), jsonData[i]['Parent'].toString(), jsonData[i]['Status'].toString()]);
        }
      }

      int prevQty = sectionList.length;
      while (sectionList.isNotEmpty) {
        for (int i = 0; i < sectionList.length; i++) {
          if (dispatchedList.contains(sectionList[i][2].toString())) {
            graph.addEdge(Node.Id(sectionList[i][2].toString()), Node.Id(sectionList[i][0].toString()), paint: Paint()..strokeWidth = (1.5)..color = const Color.fromRGBO(120, 120, 120, 1));
            dispatchedLevel.add(dispatchedLevel[dispatchedList.indexOf(sectionList[i][2].toString())] + 1);
            dispatchedList.add(sectionList[i][0].toString());
            dispatchedName.add(sectionList[i][1].toString());
            statusList.add(sectionList[i][3]);
            sectionList.removeAt(i);
            break;
          }
        }
        if (prevQty == sectionList.length) {
          chartLoadSuccess = false;
          break;
        }
        else {
          prevQty = sectionList.length;
        }
      }

      setState(() {
        loadSuccess = true;
      });
      return true;
    } catch (ex) {
      setState(() {
        loadSuccess = true;
      });
      return false;
    }
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
    final args = (ModalRoute.of(context)!.settings.arguments ?? <List<String>, String>{}) as Map;
    order = args['orders'].join(', ');
    lean = args['lean'];
    return FutureBuilder(
      future: futureFlow,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || loadSuccess == false) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.settings.name == '/process');
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Text(order)
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
                  Navigator.of(context).popUntil((route) => route.settings.name == '/process');
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Text(order)
            ),
            body: Center(
              child: Text('Error: ${snapshot.error}')
            )
          );
        }
        else {
          double sectionHeight = 80;
          BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
          builder
            ..siblingSeparation = (30)
            ..levelSeparation = (50)
            ..subtreeSeparation = (30)
            ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP);

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.settings.name == '/process');
                },
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: Text(order),
            ),
            body: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
                    child: GraphView(
                      graph: graph,
                      algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                      builder: (Node node) {
                        String section = node.key?.value;
                        String sectionName = nameList[itemList.indexOf(section)];
                        if (section.contains('@')) {
                          sectionName = '${nameList[itemList.indexOf(section.substring(0, section.indexOf('@')))]}@$sectionName';
                        }
                        String bottomText = dispatchedName[dispatchedList.indexOf(section)];
                        double topCardWidth = getTextWidth(section.contains('@') ? section.substring(section.indexOf('@') + 1) : section, const TextStyle(fontSize: 20), context);
                        double bottomCardWidth = bottomText.contains('/n') == false ? getTextWidth(bottomText, const TextStyle(fontSize: 20), context) : getTextWidth(bottomText.split('/n')[0], const TextStyle(fontSize: 20), context) > getTextWidth(bottomText.split('/n')[1], const TextStyle(fontSize: 20), context) ? getTextWidth(bottomText.split('/n')[0], const TextStyle(fontSize: 20), context) : getTextWidth(bottomText.split('/n')[1], const TextStyle(fontSize: 20), context);
                        double cardWidth = topCardWidth > bottomCardWidth ? topCardWidth : bottomCardWidth;
                        int statusCode = int.parse(statusList[dispatchedList.indexOf(section)]);

                        return Visibility(
                          visible: sectionName != 'Root',
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Card(
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: section.contains('0G') ? const Color.fromRGBO(101, 141, 174, 1) : const Color.fromRGBO(154, 154, 154, 1),
                              ),
                              borderRadius: const BorderRadius.all(Radius.circular(4))
                            ),
                            child: InkWell(
                              onTap: section.contains('0G')
                              ? () {
                                  if (statusCode < 2) {
                                    GlobalKey<MessageDialogState> globalKey = GlobalKey();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return MessageDialog(
                                          key: globalKey,
                                          titleText: AppLocalizations.of(context)!.processWorkOrderMergeChartConfirmTitle,
                                          contentText: AppLocalizations.of(context)!.processWorkOrderMergeChartConfirmContent,
                                          onPressed: () async {
                                            globalKey.currentState?.changeContent(AppLocalizations.of(context)!.processWorkOrderDispatchDialogGeneratingTitle, const SizedBox(height: 72, child: Column(children: [CircularProgressIndicator(color: Colors.blue)])), false, false, null, true);
                                            final prefs = await SharedPreferences.getInstance();
                                            String userID = prefs.getString('userID') ?? '';
                                            String factory = prefs.getString('factory') ?? '';
                                            final body = await RemoteService().generateProcessingMergeWorkOrder(
                                              apiAddress,
                                              order,
                                              userID,
                                              lean,
                                              factory,
                                              section
                                            );
                                            final jsonData = json.decode(body);
                                            if (!mounted) return;
                                            if (jsonData['statusCode'] == 200) {
                                              globalKey.currentState?.changeContent(AppLocalizations.of(context)!.processWorkOrderMergeDispatchSuccessTitle, Text(AppLocalizations.of(context)!.processWorkOrderMergeDispatchSuccessContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/process/merge_chart')}, true);
                                            }
                                            else {
                                              globalKey.currentState?.changeContent(AppLocalizations.of(context)!.processWorkOrderMergeDispatchFailedTitle, Text(AppLocalizations.of(context)!.processWorkOrderMergeDispatchFailedContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/process/merge_chart')}, true);
                                            }
                                          },
                                          showOKButton: true,
                                          showCancelButton: true
                                        );
                                      }
                                    );
                                  }
                                  else {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return MessageDialog(
                                          titleText: AppLocalizations.of(context)!.processWorkOrderMergeChartConfirmTitle,
                                          contentText: AppLocalizations.of(context)!.processWorkOrderMergeChartAllDispatched,
                                          onPressed: () {
                                            Navigator.of(context).popUntil((route) => route.settings.name == '/process/merge_chart');
                                          },
                                          showOKButton: true,
                                          showCancelButton: false
                                        );
                                      }
                                    );
                                  }
                                }
                              : null,
                              child: Column(
                                children: [
                                  Ink(
                                    color: section.contains('0G') ? Colors.blue.shade200 : const Color.fromRGBO(220, 220, 220, 1),
                                    width: cardWidth + 50,
                                    height: sectionHeight * 0.4,
                                    child: section.contains('0G')
                                    ? Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Text(section.substring(section.indexOf('@') + 1), style: const TextStyle(fontSize: 20))
                                          )
                                        ),
                                        statusCode == 2
                                        ? Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            height: 16,
                                            width: 16,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(Radius.circular(10))
                                            ),
                                            child: const Icon(Icons.check_circle, color: Colors.green, size: 16,)
                                          ),
                                        )
                                        : statusCode == 1
                                        ? Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            height: 16,
                                            width: 16,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(Radius.circular(10))
                                            ),
                                            child: const Icon(Icons.watch_later, color: Colors.orangeAccent, size: 16,)
                                          ),
                                        )
                                        : Container()
                                      ],
                                    )
                                    : Center(
                                      child: Text(section, style: const TextStyle(fontSize: 20))
                                    ),
                                  ),
                                  Ink(
                                    height: 1,
                                    width: cardWidth + 50,
                                    color: section.contains('0G') ? const Color.fromRGBO(101, 141, 174, 1) : const Color.fromRGBO(154, 154, 154, 1),
                                  ),
                                  Ink(
                                    color: Colors.white,
                                    width: cardWidth + 50,
                                    height: sectionHeight * 0.6,
                                    child: Center(
                                      child: dispatchedName[dispatchedList.indexOf(section)].contains('/n') == false
                                      ? Text(dispatchedName[dispatchedList.indexOf(section)], style: const TextStyle(fontSize: 20))
                                      : Column(
                                        children: [
                                          Text(dispatchedName[dispatchedList.indexOf(section)].split('/n')[0], style: const TextStyle(fontSize: 16)),
                                          Text(dispatchedName[dispatchedList.indexOf(section)].split('/n')[1], style: const TextStyle(fontSize: 16)),
                                        ],
                                      )
                                    ),
                                  ),
                                ],
                              )
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ),
              ]
            )
          );
        }
      }
    );
  }
}

class MessageDialog extends StatefulWidget {
  const MessageDialog({
    super.key,
    required this.titleText,
    required this.contentText,
    required this.onPressed,
    required this.showOKButton,
    required this.showCancelButton
  });

  final String titleText;
  final String contentText;
  final void Function()? onPressed;
  final bool showOKButton;
  final bool showCancelButton;

  @override
  State<StatefulWidget> createState() => MessageDialogState();
}

class MessageDialogState extends State<MessageDialog> {
  bool applyChange = false;
  String setTitle = '';
  Widget setContent = const Text('');
  bool setOkButton = true;
  bool setCancelButton = true;
  void Function()? setPressed;

  @override
  void initState() {
    super.initState();
  }

  void changeContent(String title, Widget content, bool oKButton, bool cancelButton, Function()? onPressed, bool change) {
    setState(() {
      applyChange = change;
      setTitle = title;
      setContent = content;
      setOkButton = oKButton;
      setCancelButton = cancelButton;
      setPressed = onPressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actionButtons = [];
    if (applyChange == false ? widget.showCancelButton : setCancelButton) {
      actionButtons.add(TextButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.settings.name == '/process/merge_chart');
        },
        child: Text(AppLocalizations.of(context)!.cancel),
      ));
    }
    if (applyChange == false ? widget.showOKButton : setOkButton) {
      actionButtons.add(TextButton(
        onPressed: applyChange == false ? widget.onPressed : setPressed,
        child: Text(AppLocalizations.of(context)!.ok),
      ));
    }

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      title: Text(applyChange == false ? widget.titleText : setTitle),
      content: applyChange == false ? Text(widget.contentText) : setContent,
      actions: actionButtons
    );
  }
}