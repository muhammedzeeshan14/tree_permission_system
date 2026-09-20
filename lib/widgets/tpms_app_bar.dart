import 'package:flutter/material.dart';

import '../services/session_service.dart';

import '../screens/tree_permission/caseworker_dashboard_screen.dart';
import '../screens/bfo/bfo_dashboard_screen.dart';
import '../screens/drfo/drfo_dashboard_screen.dart';
import '../screens/rfo/rfo_dashboard_screen.dart';

class TPMSAppBar extends StatelessWidget
    implements PreferredSizeWidget {

  final String title;

  const TPMSAppBar({
    super.key,
    required this.title,
  });

  void goHome(BuildContext context) {

    Widget screen;

    switch (SessionService.instance.role) {

      case "Case Worker":
        screen = const CaseWorkerDashboardScreen();
        break;

      case "BFO":
        screen = const BFODashboardScreen();
        break;

      case "DRFO":
        screen = const DRFODashboardScreen();
        break;

      case "RFO":
        screen = const RFODashboardScreen();
        break;

      default:
        return;

    }

    Navigator.pushAndRemoveUntil(

      context,

      MaterialPageRoute(
        builder: (_) => screen,
      ),

      (route) => false,

    );

  }

  @override
  Widget build(BuildContext context) {

    return AppBar(

      centerTitle: true,

      title: Text(title),

      actions: [

        IconButton(

          icon: const Icon(Icons.home),

          tooltip: "Home",

          onPressed: () {

            goHome(context);

          },

        ),

      ],

    );

  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

}