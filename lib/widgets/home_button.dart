import 'package:flutter/material.dart';

import '../services/session_service.dart';

import '../screens/dashboard/dashboard_screen.dart';
import '../screens/drfo/drfo_dashboard_screen.dart';
import '../screens/bfo/bfo_dashboard_screen.dart';
import '../screens/rfo/rfo_dashboard_screen.dart';

class HomeButton extends StatelessWidget {

  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) {

    return IconButton(

      tooltip: "Home",

      icon: const Icon(Icons.home),

      onPressed: () {

        Widget dashboard;

        switch (SessionService.instance.role) {

          case "Case Worker":

            dashboard = DashboardScreen();

            break;

          case "DRFO":

            dashboard = DRFODashboardScreen();

            break;

          case "BFO":

            dashboard = BFODashboardScreen();

            break;

          default:

            dashboard = RFODashboardScreen();

        }

        Navigator.pushAndRemoveUntil(

          context,

          MaterialPageRoute(

            builder: (_) => dashboard,

          ),

          (route) => false,

        );

      },

    );

  }

}