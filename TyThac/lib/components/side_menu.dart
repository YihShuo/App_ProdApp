import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:production/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({
    super.key,
    required this.userName,
    required this.group
  });

  final String userName;
  final String group;

  @override
  SideMenuState createState() => SideMenuState();
}

class SideMenuState extends State<SideMenu> {
  double titleSize = 18;

  @override
  void initState() {
    super.initState();
    setTitleSize();
  }

  Future<void> setTitleSize() async {
    final prefs = await SharedPreferences.getInstance();
    String locale = prefs.getString('locale') ?? 'zh';
    setState(() {
      titleSize = locale != 'zh' ? 16 : 18;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
      ),
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 100 + MediaQuery.of(context).padding.top,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.layerGroup,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white
                          ),
                        ),
                        Text(
                          widget.group,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.house,
                size: 22,
                color: Colors.black,
              ),
              title: Text(AppLocalizations.of(context)!.sideMenuMainPage, style: TextStyle(fontSize: titleSize)),
              onTap: () {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.dashboard,
                color: Colors.black,
              ),
              title: Text(AppLocalizations.of(context)!.sideMenuOrderInformation, style: TextStyle(fontSize: titleSize)),
              onTap: () {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
                Navigator.pushNamed(context, '/order_information');
              },
            ),
            ExpansionTile(
              leading: const FaIcon(
                FontAwesomeIcons.chartBar,
                size: 24,
                color: Colors.black,
              ),
              title: Text(AppLocalizations.of(context)!.sideMenuProductionPlan, style: TextStyle(fontSize: titleSize)),
              children: [
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenuOrderSchedule, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/schedule');
                  },
                ),
                /*ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenuOrderScheduleGantt, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/production_schedule');
                  },
                ),
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenuStockFittingPlan, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/stock_fitting_plan');
                  },
                ),
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenuR2Plan, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/r2_plan');
                  },
                ),
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenuTestPlan, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/testing_plan');
                  },
                ),*/
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenu3DayPlan, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/3day_plan');
                  },
                ),
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenu1DayPlan, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/1day_plan');
                  },
                ),
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.shippingPlan, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/shipping_plan');
                  },
                ),
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenuLaborDemand, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/labor_demand');
                  },
                ),
                /*ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenuCapacityStandard, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/capacity_standard');
                  },
                ),*/
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenuEstimatedInformation, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/estimated_information');
                  },
                ),
              ]
            ),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.tags,
                color: Colors.black,
              ),
              title: Text(AppLocalizations.of(context)!.sideMenuMaterialRequisition, style: TextStyle(fontSize: titleSize)),
              onTap: () {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
                Navigator.pushNamed(context, '/material_requisition');
              },
            ),
            /*ExpansionTile(
              leading: const Icon(
                Icons.crop,
                size: 24,
                color: Colors.black,
              ),
              title: Text(AppLocalizations.of(context)!.sideMenuCuttingWorkOrders, style: TextStyle(fontSize: titleSize)),
              children: [
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenuDispatching, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/cutting');
                  },
                ),
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenuProgressReporting, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/cutting_progress');
                  },
                ),
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.automaticCutting, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/auto_cutting');
                  },
                ),
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.machineAssignment, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/cutting_machine');
                  },
                ),
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.tyDat, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/ty_dat_component');
                  },
                ),
              ],
            ),
            /*ExpansionTile(
              leading: const Icon(
                Icons.account_tree,
                size: 24,
                color: Colors.black,
              ),
              title: Text(AppLocalizations.of(context)!.sideMenuProcessWorkOrders, style: TextStyle(fontSize: titleSize)),
              children: [
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenuProcessDispatching, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/process');
                  },
                ),
                ListTile(
                  leading: const SizedBox(),
                  title: Text(AppLocalizations.of(context)!.sideMenuProcessReporting, style: TextStyle(fontSize: titleSize)),
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                    Navigator.pushNamed(context, '/process_progress');
                  },
                ),
              ],
            ),*/
            ListTile(
              leading: const ImageIcon(
                AssetImage("assets/images/needle.png"),
                color: Colors.black,
              ),
              title: Text(AppLocalizations.of(context)!.stitching, style: TextStyle(fontSize: titleSize)),
              onTap: () {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
                Navigator.pushNamed(context, '/stitching');
              },
            ),
            ListTile(
              leading: const ImageIcon(
                AssetImage("assets/images/shoes.png"),
                color: Colors.black,
              ),
              title: Text(AppLocalizations.of(context)!.assembly, style: TextStyle(fontSize: titleSize)),
              onTap: () {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
                Navigator.pushNamed(context, '/assembly');
              },
            ),*/
            ListTile(
              leading: const Icon(
                Icons.search,
                color: Colors.black,
              ),
              title: Text(AppLocalizations.of(context)!.sideMenuProductionTracking, style: TextStyle(fontSize: titleSize)),
              onTap: () {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
                Navigator.pushNamed(context, '/lean_tracking');
              },
            ),
            /*ListTile(
              leading: const Icon(
                Icons.bar_chart,
                color: Colors.black,
              ),
              title: Text('追蹤表', style: TextStyle(fontSize: titleSize)),
              onTap: () {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
                Navigator.pushNamed(context, '/gantt_tracking');
              },
            ),*/
            ListTile(
              leading: const Icon(
                Icons.local_shipping,
                color: Colors.black,
              ),
              title: Text(AppLocalizations.of(context)!.shipmentTracking, style: TextStyle(fontSize: titleSize)),
              onTap: () {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
                Navigator.pushNamed(context, '/shipment_tracking');
              },
            ),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.gears,
                size: 20,
                color: Colors.black,
              ),
              title: Text(AppLocalizations.of(context)!.sideMenuSettings, style: TextStyle(fontSize: titleSize)),
              onTap: () {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
                Navigator.pushNamed(context, '/setting');
              },
            ),
          ],
        ),
      ),
    );
  }
}