import 'package:flutter/material.dart';

class SelectableItem extends StatefulWidget {
  const SelectableItem({
    super.key,
    required this.cycleIndex,
    required this.size,
    required this.textWidget,
    required this.selectable,
    required this.selected,
    required this.changeSelection
  });

  final int cycleIndex;
  final String size;
  final Function changeSelection;
  final Widget textWidget;
  final bool selectable, selected;

  @override
  SelectableItemState createState() => SelectableItemState();
}

class SelectableItemState extends State<SelectableItem> with SingleTickerProviderStateMixin {
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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void setStatus(bool result) {
    if (widget.selectable) {
      state = result;
      if (state) {
        controller.forward();
        widget.changeSelection('Add', widget.cycleIndex, widget.size);
      }
      else {
        controller.reverse();
        widget.changeSelection('Remove', widget.cycleIndex, widget.size);
      }
    }
    else {
      state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.selectable) {
          state = !state;
          if (state) {
            controller.forward();
            widget.changeSelection('Add', widget.cycleIndex, widget.size);
          }
          else {
            controller.reverse();
            widget.changeSelection('Remove', widget.cycleIndex, widget.size);
          }
        }
      },
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.selectable ? scaleAnimation.value : 0.8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: widget.selectable ? calculateColor() : const Color.fromRGBO(150, 150, 150, 1),
              ),
              child: child,
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
      Colors.red.shade200,
      controller.value,
    );
  }
}