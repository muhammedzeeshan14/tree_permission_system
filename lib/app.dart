import 'package:flutter/material.dart';

import 'screens/login/login_screen.dart';

import 'screens/rfo/rfo_dashboard_screen.dart';
import 'screens/drfo/drfo_dashboard_screen.dart';
import 'screens/bfo/bfo_dashboard_screen.dart';
import 'screens/tree_permission/caseworker_dashboard_screen.dart';

class TPMSApp extends StatelessWidget {
  const TPMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "Tree Permission Management System",

      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),

      initialRoute: "/login",

      routes: {

        "/login": (context) =>
            const LoginScreen(),

        "/rfo": (context) =>
            const RFODashboardScreen(),

        "/drfo": (context) =>
            const DRFODashboardScreen(),

        "/bfo": (context) =>
            const BFODashboardScreen(),

        "/caseworker": (context) =>
            const CaseWorkerDashboardScreen(),

      },

    );
  }
}