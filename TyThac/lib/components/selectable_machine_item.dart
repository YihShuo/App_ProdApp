import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:production/services/remote_service.dart';

class SelectableMachineItem extends StatefulWidget {
  const SelectableMachineItem({
    super.key,
    required this.apiAddress,
    required this.order,
    required this.machine,
    required this.partID,
    required this.cycle,
    required this.size,
    required this.textWidget,
    required this.selectable,
    required this.selected,
    required this.checkSizeStatus
  });

  final String apiAddress;
  final String order;
  final String machine;
  final String partID;
  final String cycle;
  final String size;
  final Widget textWidget;
  final bool selectable, selected;
  final Function checkSizeStatus;

  @override
  SelectableMachineItemState createState() => SelectableMachineItemState();
}

class SelectableMachineItemState extends State<SelectableMachineItem> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> scaleAnimation;
  late bool state;

  @override
  void initState() {
    super.initState();
    state = widget.selected;

    controller = AnimationController(
      value: widget.selected ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    scaleAnimation = Tween<double>(begin: 1, end: 0.8).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.ease,
      )
    );
  }

  void setStatus(bool result) {
    result ? controller.forward() : controller.reverse();
    setState(() {
      state = result;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            final body = await RemoteService().submitMachineCuttingProgress(
              widget.apiAddress,
              widget.order,
              widget.machine,
              widget.partID,
              widget.cycle,
              widget.size,
              'Completed'
            );
            final jsonData = json.decode(body);
            if (!mounted) return;
            if (jsonData['statusCode'] == 200) {
              state = !state;
              controller.forward();
              widget.checkSizeStatus(widget.size);
              Navigator.of(context).popUntil((route) => route.settings.name == '/machineWorkOrder/reporting');
            }
            else {
              globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/machineWorkOrder/reporting')}, true);
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
                    globalKey.currentState?.changeContent(AppLocalizations.of(context)!.executing, const SizedBox(height: 72, child: Column(children: [CircularProgressIndicator(color: Colors.blue,),],),), false, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/machineWorkOrder/reporting')}, true);
                    final body = await RemoteService().submitMachineCuttingProgress(
                      widget.apiAddress,
                      widget.order,
                      widget.machine,
                      widget.partID,
                      widget.cycle,
                      widget.size,
                      'Cancelled'
                    );
                    final jsonData = json.decode(body);
                    if (jsonData['statusCode'] == 200) {
                      state = !state;
                      controller.reverse();
                      widget.checkSizeStatus(widget.size);
                      Navigator.of(context).popUntil((route) => route.settings.name == '/machineWorkOrder/reporting');
                    }
                    else {
                      globalKey.currentState?.changeContent(AppLocalizations.of(context)!.failedTitle, Text(AppLocalizations.of(context)!.failedContent), true, false, () => {Navigator.of(context).popUntil((route) => route.settings.name == '/machineWorkOrder/reporting')}, true);
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: calculateColor(),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    child: state ? const Icon(Icons.check, color: Colors.white70, size: 72) : null,
                  ),
                  Container(
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
          child: widget.textWidget,
        ),
      ),
    );
  }

  Color? calculateColor() {
    return Color.lerp(
      Colors.blue.shade200,
      Colors.black38,
      controller.value,
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
          Navigator.of(context).popUntil((route) => route.settings.name == '/machineWorkOrder/reporting');
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