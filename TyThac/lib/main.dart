import 'dart:ui';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:production/views/1day_plan.dart';
import 'package:production/views/3day_plan.dart';
import 'package:production/views/GanttTracking.dart';
import 'package:production/views/assembly_workorder.dart';
import 'package:production/views/assembly_workorder_dispatch.dart';
import 'package:production/views/capacity_standard.dart';
import 'package:production/views/change_password.dart';
import 'package:production/views/component_ready.dart';
import 'package:production/views/cutting_machine.dart';
import 'package:production/views/cutting_machine_dispatch.dart';
import 'package:production/views/cutting_progress.dart';
import 'package:production/views/cutting_progress_reporting.dart';
import 'package:production/views/cutting_tracking.dart';
import 'package:production/views/cutting_workorder.dart';
import 'package:production/views/cutting_workorder_dispatch.dart';
import 'package:production/views/cycle_tracking.dart';
import 'package:production/views/auto_cutting_workorder.dart';
import 'package:production/views/estimated_information.dart';
import 'package:production/views/home_page_capacity.dart';
import 'package:production/views/labor_demand.dart';
import 'package:production/views/lean_capacity_chart.dart';
import 'package:production/views/lean_schedule.dart';
import 'package:production/views/lean_tracking.dart';
import 'package:production/views/lean_tracking_ftt.dart';
import 'package:production/views/lean_tracking_material.dart';
import 'package:production/views/lean_tracking_sp.dart';
import 'package:production/views/lean_workorder.dart';
import 'package:production/views/lean_workorder_reporting.dart';
import 'package:production/views/machine_workorder.dart';
import 'package:production/views/machine_workorder_reporting.dart';
import 'package:production/views/material_requisition.dart';
import 'package:production/views/order_information.dart';
import 'package:production/views/order_information_sku.dart';
import 'package:production/views/order_information_ry.dart';
import 'package:production/views/order_information_ry_bom.dart';
import 'package:production/views/process_chart.dart';
import 'package:production/views/process_merge_chart.dart';
import 'package:production/views/process_progress.dart';
import 'package:production/views/process_progress_chart.dart';
import 'package:production/views/process_progress_reporting.dart';
import 'package:production/views/process_tracking.dart';
import 'package:production/views/process_workorder.dart';
import 'package:production/views/process_workorder_dispatch.dart';
import 'package:production/views/production_schedule.dart';
import 'package:production/views/r2_plan.dart';
import 'package:production/views/schedule.dart';
import 'package:production/views/server_address.dart';
import 'package:production/views/setting.dart';
import 'package:production/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:production/views/shipment_tracking.dart';
import 'package:production/views/shipping_plan.dart';
import 'package:production/views/stitching_workorder.dart';
import 'package:production/views/stitching_workorder_dispatch.dart';
import 'package:production/views/stock_fitting_plan.dart';
import 'package:production/views/testing_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Locale appLanguage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  appLanguage = Locale(prefs.getString('locale').toString() != '' ? prefs.getString('locale').toString() : 'zh');
  prefs.setString('address', 'http://prodapp.tythac.com.vn:80');
  /*if (kIsWeb == false) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseApi().initNotification();
  }*/
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp>{
  @override
  void initState() {
    super.initState();
  }

  changeLanguage(Locale locale) async {
    final appInfo = await SharedPreferences.getInstance();
    appInfo.setString('locale', locale.languageCode);
    setState(() {
      appLanguage = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown
        },
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
        Locale('vi'),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.blue,
          selectionColor: Colors.blue,
          selectionHandleColor: Colors.blue,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue
          )
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          )
        ),
      ),
      locale: appLanguage,
      title: 'Tythac',
      initialRoute: '/login',
      routes: {
        '/home': (context) => const HomePageCapacity(),
        '/home/lean_capacity_chart': (context) => const LeanCapacityChart(),
        '/home/cutting_tracking': (context) => const CuttingTracking(),
        '/home/process_tracking': (context) => const ProcessTracking(),
        '/home/cycle_tracking': (context) => const CycleTracking(),
        '/login': (context) => LoginPage(changeLanguage: changeLanguage),
        '/login/server_address': (context) => const ServerAddress(),
        '/order_information': (context) => const OrderInformation(),
        '/order_information/sku': (context) => const OrderInformationSKU(),
        '/order_information/sku/ry': (context) => const OrderInformationRY(),
        '/order_information/sku/ry/bom': (context) => const OrderInformationRYBOM(),
        '/schedule': (context) => const Schedule(),
        '/production_schedule': (context) => const ProductionSchedule(),
        '/stock_fitting_plan': (context) => const StockFittingPlan(),
        '/r2_plan': (context) => const R2Plan(),
        '/testing_plan': (context) => const TestingPlan(),
        '/3day_plan': (context) => const ThreeDayPlan(),
        '/1day_plan': (context) => const OneDayPlan(),
        '/shipment_tracking': (context) => const ShipmentTracking(),
        '/labor_demand': (context) => const LaborDemand(),
        '/capacity_standard': (context) => const CapacityStandard(),
        '/estimated_information': (context) => const EstimatedInformation(),
        '/material_requisition': (context) => const MaterialRequisition(),
        '/cutting': (context) => const CuttingWorkOrder(),
        '/cutting/dispatch': (context) => const CuttingWorkOrderDispatch(),
        '/cutting_progress': (context) => const CuttingProgress(),
        '/cutting_progress/reporting': (context) => const CuttingProgressReporting(),
        '/auto_cutting': (context) => const AutoCuttingWorkOrder(),
        '/ty_dat_component': (context) => const TyDatComponent(),
        '/cutting_machine': (context) => const CuttingMachine(),
        '/cutting_machine/dispatch': (context) => const CuttingMachineDispatch(),
        '/process': (context) => const ProcessWorkOrder(),
        '/process/chart': (context) => const ProcessChart(),
        '/process/merge_chart': (context) => const ProcessMergeChart(),
        '/process/chart/dispatch': (context) => const ProcessWorkOrderDispatch(),
        '/process_progress': (context) => const ProcessProgress(),
        '/process_progress/chart': (context) => const ProcessProgressChart(),
        '/process_progress/chart/reporting': (context) => const ProcessWorkOrderReporting(),
        '/stitching': (context) => const StitchingWorkOrder(),
        '/stitching/dispatch': (context) => const StitchingWorkOrderDispatch(),
        '/assembly': (context) => const AssemblyWorkOrder(),
        '/assembly/dispatch': (context) => const AssemblyWorkOrderDispatch(),
        '/lean_tracking': (context) => const LeanTracking(),
        '/lean_tracking/second_process': (context) => const LeanTrackingSP(),
        '/lean_tracking/material': (context) => const LeanTrackingMaterial(),
        '/lean_tracking/ftt': (context) => const LeanTrackingFTT(),
        '/gantt_tracking': (context) => const GanttTracking(),
        '/shipping_plan': (context) => const ShippingPlan(),
        '/setting': (context) => Setting(changeLanguage: changeLanguage),
        '/setting/change_password': (context) => const ChangePassword(),
        '/setting/server_address': (context) => const ServerAddress(),
        '/leanWorkOrder': (context) => const LeanWorkOrder(),
        '/lean_schedule': (context) => const LeanSchedule(),
        '/leanWorkOrder/reporting': (context) => const LeanWorkOrderReporting(),
        '/machineWorkOrder': (context) => const MachineWorkOrder(),
        '/machineWorkOrder/reporting': (context) => const MachineWorkOrderReporting(),
      },
      builder: (context, widget) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: widget!,
        );
      },
    );
  }
}
