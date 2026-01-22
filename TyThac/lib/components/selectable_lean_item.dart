import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:production/services/remote_service.dart';

class SelectableLeanItem extends StatefulWidget {
  const SelectableLeanItem({
    super.key,
    required this.apiAddress,
    required this.order,
    required this.section,
    required this.type,
    required this.cycle,
    required this.size,
    required this.pairs,
    required this.shortage,
    required this.text,
    required this.selectable,
    required this.selected,
    required this.checkSizeRunStatus,
    required this.userID,
  });

  final String apiAddress;
  final String order;
  final String section;
  final String type;
  final String cycle;
  final String size;
  final int pairs;
  final int shortage;
  final String text;
  final bool selectable, selected;
  final Function checkSizeRunStatus;
  final String userID;

  @override
  SelectableLeanItemState createState() => SelectableLeanItemState();
}

class SelectableLeanItemState extends State<SelectableLeanItem> with SingleTickerProviderStateMixin {
  late final AnimationController tapController, longPressController;
  late final Animation<double> scaleAnimation;
  late bool state;
  int shortage = 0;

  @override
  void initState() {
    super.initState();
    state = widget.selected && widget.shortage == 0;
    shortage = widget.shortage;

    tapController = AnimationController(
      value: state ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    scaleAnimation = Tween<double>(begin: 1, end: 0.8).animate(
      CurvedAnimation(
        parent: tapController,
        curve: Curves.ease,
      )
    );
  }

  void setStatus(bool result) {
    result ? tapController.forward() : tapController.reverse();
    setState(() {
      shortage = 0;
      state = result;
    });
  }

  void refreshWidget(int val) {
    val == 0 ? tapController.forward() : tapController.reverse();
    setState(() {
      shortage = val;
      state = (val == 0);
    });
  }

  @override
  void dispose() {
    tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: widget.selectable ? () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return ShortageDialog(
                apiAddress: widget.apiAddress,
                order: widget.order,
                section: widget.section,
                type: widget.type,
                cycle: widget.cycle,
                size: widget.size,
                pairs: widget.pairs,
                shortage: shortage,
                userID: widget.userID,
                refreshWidget: refreshWidget
              );
            }
          );
        } : null,
        onTap: () async {
          if (widget.selectable) {
            GlobalKey<MessageDialogState> globalKey = GlobalKey();
            if (state == false) {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (BuildContext context) {
                  return MessageDialog(
                    key: globalKey,
                    titleText: AppLocalizations.of(context)!.information,
                    contentText: AppLocalizations.of(context)!.executing,
                    showOKButton: false,
                    showCancelButton: false,
                    onPressed: null,
                  );
                }
              );
              final body = await RemoteService().submitLeanSectionProgress(
                widget.apiAddress,
                widget.order,
                widget.section,
                widget.type,
                widget.cycle,
                widget.size,
                0,
                widget.userID,
                'Completed'
              );
              final jsonData = json.decode(body);
              if (!mounted) return;
              if (jsonData['statusCode'] == 200) {
                setState(() {
                  shortage = 0;
                });
                state = !state;
                tapController.forward();
                widget.checkSizeRunStatus(widget.size, widget.cycle);
                Navigator.of(context).popUntil((route) => route.settings.name == '/leanWorkOrder/reporting');
              }
              else {
                Navigator.of(context).popUntil((route) => route.settings.name == '/leanWorkOrder/reporting');
                showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return MessageDialog(
                      key: globalKey,
                      titleText: AppLocalizations.of(context)!.failedTitle,
                      contentText: AppLocalizations.of(context)!.failedContent,
                      showOKButton: true,
                      showCancelButton: false,
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.settings.name == '/leanWorkOrder/reporting');
                      },
                    );
                  }
                );
              }
            }
            else {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (BuildContext context) {
                  return MessageDialog(
                    key: globalKey,
                    titleText: AppLocalizations.of(context)!.confirmTitle,
                    contentText: AppLocalizations.of(context)!.confirmToCancel,
                    showOKButton: true,
                    showCancelButton: true,
                    onPressed: () async {
                      globalKey.currentState?.changeContent(AppLocalizations.of(context)!.executing, const SizedBox(height: 72, child: Column(children: [CircularProgressIndicator(color: Colors.blue,),],),), false, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/leanWorkOrder/reporting')}, true);
                      final body = await RemoteService().submitLeanSectionProgress(
                        widget.apiAddress,
                        widget.order,
                        widget.section,
                        widget.type,
                        widget.cycle,
                        widget.size,
                        0,
                        widget.userID,
                        'Cancelled',
                      );
                      final jsonData = json.decode(body);
                      if (jsonData['statusCode'] == 200) {
                        setState(() {
                          shortage = 0;
                        });
                        state = !state;
                        tapController.reverse();
                        widget.checkSizeRunStatus(widget.size, widget.cycle);
                        Navigator.of(context).popUntil((route) => route.settings.name == '/leanWorkOrder/reporting');
                      }
                      else {
                        Navigator.of(context).popUntil((route) => route.settings.name == '/leanWorkOrder/reporting');
                        showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return MessageDialog(
                              key: globalKey,
                              titleText: AppLocalizations.of(context)!.failedTitle,
                              contentText: AppLocalizations.of(context)!.failedContent,
                              showOKButton: true,
                              showCancelButton: false,
                              onPressed: () {
                                Navigator.of(context).popUntil((route) => route.settings.name == '/leanWorkOrder/reporting');
                              },
                            );
                          }
                        );
                      }
                    },
                  );
                }
              );
            }
          }
        },
        child: AnimatedBuilder(
          animation: scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: scaleAnimation.value,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: shortage > 0 ? Colors.red.shade200 : calculateColor(),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      color: Colors.transparent,
                      child: state ? const Icon(Icons.check, color: Colors.white70, size: 72) : null,
                    ),
                    Container(
                      color: Colors.transparent,
                      child: child
                    )
                  ],
                ),
              ),
            );
          },
          child: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Text(widget.text, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, decoration: shortage > 0 ? TextDecoration.lineThrough : TextDecoration.none)),
                Positioned(
                  bottom: 24,
                  child: Visibility(
                    visible: shortage > 0,
                    child: Text('-$shortage', style: const TextStyle(fontSize: 16),)
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color? calculateColor() {
    return Color.lerp(
      Colors.blue.shade200,
      Colors.black38,
      tapController.value,
    );
  }
}

class ShortageDialog extends StatefulWidget {
  const ShortageDialog({
    super.key,
    required this.apiAddress,
    required this.order,
    required this.section,
    required this.type,
    required this.cycle,
    required this.size,
    required this.pairs,
    required this.shortage,
    required this.userID,
    required this.refreshWidget
  });

  final String apiAddress;
  final String order;
  final String section;
  final String type;
  final String cycle;
  final String size;
  final int pairs;
  final int shortage;
  final String userID;
  final Function refreshWidget;

  @override
  State<StatefulWidget> createState() => ShortageDialogState();
}

class ShortageDialogState extends State<ShortageDialog> {
  int shortage = 0;

  @override
  void initState() {
    super.initState();
    shortage = widget.shortage;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('[${widget.cycle == widget.order ? 'T1' : 'T${int.parse(widget.cycle.substring(widget.cycle.length - 3))}'} - ${widget.size}]', style: const TextStyle(fontSize: 20),),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.grey,)
        ],
      ),
      titlePadding: const EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 12),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4,),
          Text('${AppLocalizations.of(context)!.pairs}：${widget.pairs}', style: const TextStyle(fontSize: 16),),
          Row(
            children: [
              Text('${AppLocalizations.of(context)!.shortage}：', style: const TextStyle(fontSize: 16),),
              Expanded(
                child: DropdownButton(
                  value: shortage,
                  isExpanded: true,
                  underline: Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey))
                    ),
                  ),
                  items: List.generate(widget.pairs, (index) {
                    int number = index;
                    return DropdownMenuItem(
                    value: number,
                    child: Text(number.toString(), style: const TextStyle(fontWeight: FontWeight.normal),),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      shortage = value!;
                    });
                  },
                ),
              ),
            ],
          )
        ],
      ),
      contentPadding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
      actionsPadding: const EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.settings.name == '/leanWorkOrder/reporting');
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () async {
            final body = await RemoteService().submitLeanSectionProgress(
              widget.apiAddress,
              widget.order,
              widget.section,
              widget.type,
              widget.cycle,
              widget.size,
              shortage,
              widget.userID,
              'Shortage',
            );
            final jsonData = json.decode(body);
            if (jsonData['statusCode'] == 200) {
              widget.refreshWidget(shortage);
              Navigator.of(context).popUntil((route) => route.settings.name == '/leanWorkOrder/reporting');
            }
            else {
              Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.failedContent,
                gravity: ToastGravity.BOTTOM,
                toastLength: Toast.LENGTH_SHORT,
              );
            }
          },
          child: Text(AppLocalizations.of(context)!.ok),
        )
      ]
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
          Navigator.of(context).popUntil((route) => route.settings.name == '/leanWorkOrder/reporting');
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