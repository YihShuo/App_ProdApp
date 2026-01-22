import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_gantt/flutter_gantt.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/components/side_menu.dart';
import 'package:production/services/remote_service.dart';
import 'package:production/l10n/app_localizations.dart';

String apiAddress = '';

class GanttTracking extends StatefulWidget {
  const GanttTracking({super.key});

  @override
  GanttTrackingState createState() => GanttTrackingState();
}

class GanttTrackingState extends State<GanttTracking> {
  String userName = '';
  String group = '';
  List<GanttActivity> activities = [];
  late final GanttController controller;

  @override
  void initState() {
    super.initState();
    controller = GanttController(
      startDate: DateTime(2025, 8, 1),
      //daysViews: 10, // Optional: you can set the number of days to be displayed
    );
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '';
    setState(() {
      userName = prefs.getString('userName') ?? '';
      group = prefs.getString('group') ?? '';
      //department = prefs.getString('department') ?? 'A02_LEAN01';
      apiAddress = prefs.getString('address') ?? '';
    });

    if (userID == '') {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }

    loadActivities();
  }

  void loadActivities() async {
    activities = [];
    activities.add(
      GanttActivity(
        key: 'task1',
        start: DateTime(2025, 8, 1),
        end: DateTime(2025, 8, 15),
        title: 'Independent Task',
        tooltip: 'A separate task',
        color: Colors.blue,
        segments: [
          GanttActivitySegment(
            start: DateTime(2025, 8, 1),
            end: DateTime(2025, 8, 5),
            title: 'Cutting',
            description: 'Cutting',
            color: Colors.red,
            onTap: (activity) {
              print('asda');
            }
          ),
          GanttActivitySegment(
            start: DateTime(2025, 8, 5),
            end: DateTime(2025, 8, 15),
            title: 'Stitching',
            description: 'Stitching',
            color: Colors.black,
            onTap: (activity) {
              print('asda');
            }
          )
        ]
      ),
    );

    controller.update();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              }
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.sideMenuOrderScheduleGantt),
            //Text('${AppLocalizations.of(context)!.asOf} ${DateFormat('yyyy/MM/dd').format(selectedDate)}', style: const TextStyle(fontSize: 14))
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              loadActivities();
            },
            icon: const Icon(Icons.refresh)
          )
        ],
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      drawer: SideMenu(userName: userName, group: group),
      backgroundColor: Colors.grey[300],
      body: const GanttChart(),
    );
  }
}

class Task {
  final String name;
  final DateTime start;
  final DateTime end;
  Task(this.name, this.start, this.end);
}

class GanttChart extends StatelessWidget {
  const GanttChart({super.key});

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime(2025, 8, 1);
    final endDate = DateTime(2025, 8, 31);

    final tasks = [
      Task("設計", DateTime(2025, 8, 1), DateTime(2025, 8, 10)),
      Task("開發", DateTime(2025, 8, 11), DateTime(2025, 8, 20)),
      Task("測試", DateTime(2025, 8, 21), DateTime(2025, 8, 25)),
      Task("上線", DateTime(2025, 8, 13), DateTime(2025, 8, 31)),
    ];

    final totalDays = endDate.difference(startDate).inDays + 1;
    const dayWidth = 40.0;
    const rowHeight = 40.0;

    final canvasWidth = totalDays * dayWidth;
    final canvasHeight = 80.0 + tasks.length * 60.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左邊：任務名稱 (固定不動)
        Container(
          width: 150,
          color: Colors.grey.shade200,
          child: Column(
            children: tasks.map((t) => Container(
              height: 40,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(8),
              child: Text(t.name),
            )).toList(),
          ),
        ),

        // 右邊：可橫向滾動的甘特圖
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: CustomPaint(
              size: Size(totalDays * dayWidth, tasks.length * rowHeight + 80),
              painter: GanttChartPainter(
                tasks,
                startDate,
                endDate,
                leftColumnWidth: 120, // 保持一致
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GanttChartPainter extends CustomPainter {
  final List<Task> tasks;
  final DateTime startDate;
  final DateTime endDate;
  final double rowHeight;
  final double dayWidth;
  final double leftColumnWidth;

  GanttChartPainter(this.tasks, this.startDate, this.endDate, {this.rowHeight = 40, this.dayWidth = 40, this.leftColumnWidth = 150});

  @override
  void paint(Canvas canvas, Size size) {
    final totalDays = endDate.difference(startDate).inDays + 1;

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final linePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );

    // --------------------
    // 畫月份標籤 (最上方)
    // --------------------
    DateTime? currentMonth;
    double monthStartX = leftColumnWidth;

    for (int i = 0; i < totalDays; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final dx = leftColumnWidth + i * dayWidth;

      if (currentMonth == null) {
        currentMonth = currentDate;
        monthStartX = dx;
      }

      // 月份切換 或 最後一天 → 畫月份文字
      if (currentDate.month != currentMonth.month || i == totalDays - 1) {
        final monthEndX = (currentDate.month != currentMonth.month) ? dx : dx + dayWidth;

        final monthName = DateFormat('MM月').format(currentMonth);
        textPainter.text = TextSpan(
          text: monthName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        );
        textPainter.layout();

        // 置中繪製月份文字
        final monthWidth = monthEndX - monthStartX;
        final monthX = monthStartX + (monthWidth - textPainter.width) / 2;
        textPainter.paint(canvas, Offset(monthX, 4));

        currentMonth = currentDate;
        monthStartX = dx;
      }
    }

    // --------------------
    // 畫日期 (月份下方一行)
    // --------------------
    for (int i = 0; i < totalDays; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final dx = leftColumnWidth + i * dayWidth;

      textPainter.text = TextSpan(
        text: DateFormat('d').format(currentDate),
        style: const TextStyle(fontSize: 12, color: Colors.black),
      );
      textPainter.layout(minWidth: 0, maxWidth: dayWidth);
      textPainter.paint(canvas, Offset(dx + (dayWidth - textPainter.width) / 2, 26));

      // 垂直格線
      canvas.drawLine(Offset(dx, 50), Offset(dx, size.height), linePaint);
    }

    // --------------------
    // 畫任務區域 (往下移一格，避免壓到日期)
    // --------------------
    for (int i = 0; i < tasks.length; i++) {
      final top = 60.0 + i * rowHeight;

      // 水平分隔線
      canvas.drawLine(
        Offset(0, top + rowHeight),
        Offset(size.width, top + rowHeight),
        linePaint,
      );

      // 任務名稱
      textPainter.text = TextSpan(
        text: tasks[i].name,
        style: const TextStyle(fontSize: 14, color: Colors.black),
      );
      textPainter.layout(minWidth: 0, maxWidth: leftColumnWidth - 8);
      textPainter.paint(canvas, Offset(8, top + (rowHeight - textPainter.height) / 2));

      // 任務長條
      final task = tasks[i];
      final startOffset = leftColumnWidth +
          task.start.difference(startDate).inDays * dayWidth;
      final endOffset =
          leftColumnWidth + (task.end.difference(startDate).inDays + 1) * dayWidth;
      final rect = Rect.fromLTWH(
        startOffset + 4,
        top + 8,
        endOffset - startOffset - 8,
        rowHeight - 16,
      );

      final barPaint = Paint()..color = Colors.blueAccent;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}