import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../screens/login/login_screen.dart';

class TPMSDrawer extends StatelessWidget {

  const TPMSDrawer({super.key});

  @override
  Widget build(BuildContext context) {

    return Drawer(

      child: ListView(

        children: [

          UserAccountsDrawerHeader(

            accountName: Text(
              SessionService.instance.name,
            ),

            accountEmail: Text(
              SessionService.instance.role,
            ),

            currentAccountPicture: const CircleAvatar(

              child: Icon(
                Icons.person,
                size: 40,
              ),

            ),

          ),

          ListTile(

            leading: const Icon(Icons.home),

            title: const Text("Home"),

            onTap: () {

              Navigator.pop(context);

            },

          ),

          ListTile(

            leading: const Icon(Icons.person),

            title: const Text("My Profile"),

            onTap: () {

              // The drawer route is popped first, so the drawer's
              // own context is deactivated. Use the Navigator's
              // context (stays mounted) for the dialog.
              final navigator = Navigator.of(context);

              navigator.pop();

              showDialog(

                context: navigator.context,

                builder: (dialogContext) => AlertDialog(

                  title: const Text("My Profile"),

                  content: Column(

                    mainAxisSize: MainAxisSize.min,

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        "Name : ${SessionService.instance.name}",
                      ),

                      Text(
                        "Role : ${SessionService.instance.role}",
                      ),

                      Text(
                        "Username : ${SessionService.instance.username}",
                      ),

                    ],

                  ),

                  actions: [

                    TextButton(

                      onPressed: () {

                        Navigator.pop(dialogContext);

                      },

                      child: const Text("OK"),

                    ),

                  ],

                ),

              );

            },

          ),

          const Divider(),

          ListTile(

            leading: const Icon(

              Icons.logout,

              color: Colors.red,

            ),

            title: const Text("Logout"),

            onTap: () {

              SessionService.instance.logout();

              Navigator.pushAndRemoveUntil(

                context,

                MaterialPageRoute(

                  builder: (_) =>
                      const LoginScreen(),

                ),

                (route) => false,

              );

            },

          ),

        ],

      ),

    );

  }

}