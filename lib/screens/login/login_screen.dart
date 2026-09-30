import 'package:flutter/material.dart';

import '../../repositories/user_repository.dart';
import '../../repositories/office_configuration_repository.dart';
import '../../services/session_service.dart';
import '../../services/master_data_service.dart';
import '../../services/supabase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final UserRepository userRepository =
      UserRepository();

  final usernameController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  String officeFooter = '';

  @override
  void initState() {
    super.initState();
    _loadOfficeFooter();
  }

  Future<void> _loadOfficeFooter() async {
    try {
      final configuration = await OfficeConfigurationRepository().getConfiguration();
      final range = configuration?['rangeName']?.toString().trim() ?? '';
      final location = configuration?['rangeLocation']?.toString().trim() ?? '';
      final text = [if (range.isNotEmpty) '$range ವಲಯ', if (location.isNotEmpty) location].join(', ');
      if (mounted) setState(() => officeFooter = text);
    } catch (_) {
      // Office details are optional; loading them must not prevent login.
    }
  }

  bool hidePassword = true;

  bool loading = false;
    Future<void> login() async {
    if (loading) return;

    if (usernameController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text(
            "Enter Username",
          ),

        ),

      );

      return;

    }

    if (passwordController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text(
            "Enter Password",
          ),

        ),

      );

      return;

    }

    setState(() {

      loading = true;

    });

    Map<String,dynamic>? user;
    try {
      user =
        await userRepository.login(

      username:
          usernameController.text.trim(),

      password:
          passwordController.text,

    );

    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to verify cloud login. Check your connection and try again.')));
      return;
    }
    if (!mounted) return;

    if (user == null) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text(
            "Invalid Username or Password",
          ),

        ),

      );

      return;

    }

    SessionService.instance.login(

      userId: user["id"],

      name: user["name"],

      username: user["username"],

      role: user["role"],

      sectionId: user["sectionId"],

      beatId: user["beatId"],

    );

    // Stage 2: link to Supabase Auth in background (offline-safe).
    SupabaseAuthService.linkLocalUser(
      user,
      passwordController.text,
    );

    String route;

switch (user["role"]) {

  case "RFO":

    route = "/rfo";

    break;

  case "DRFO":

    route = "/drfo";

    break;

  case "BFO":

    route = "/bfo";

    break;

  case "Case Worker":

    route = "/caseworker";

    break;

  default:

    route = "/login";

}
try {
  await MasterDataService.instance.loadMasters();
} catch (_) {
  SessionService.instance.logout();
  if (!mounted) return;
  setState(() => loading = false);
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text('Unable to load application masters. Check your connection and try again.'),
  ));
  return;
}
if (!mounted) return;
Navigator.pushReplacementNamed(

  context,

  route,

);

  }
    @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Center(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(24),

          child: SizedBox(

            width: 420,

            child: Card(

              elevation: 8,

              shape: RoundedRectangleBorder(

                borderRadius:
                    BorderRadius.circular(15),

              ),

              child: Padding(

                padding: const EdgeInsets.all(24),

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    const Icon(

                      Icons.forest,

                      size: 80,

                      color: Colors.green,

                    ),

                    const SizedBox(height: 15),

                    const Text(

                      "Tree Permission Management System",

                      textAlign: TextAlign.center,

                      style: TextStyle(

                        fontSize: 22,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                    const SizedBox(height: 8),

                    const Text(

                      "Karnataka Forest Department",

                      style: TextStyle(

                        color: Colors.grey,

                      ),

                    ),

                    const SizedBox(height: 30),

                    TextField(

                      controller: usernameController,

                      decoration: const InputDecoration(

                        labelText: "Username",

                        prefixIcon: Icon(Icons.person),

                        border: OutlineInputBorder(),

                      ),

                    ),

                    const SizedBox(height: 20),

                    TextField(

                      controller: passwordController,

                      obscureText: hidePassword,

                      decoration: InputDecoration(

                        labelText: "Password",

                        prefixIcon:
                            const Icon(Icons.lock),

                        border:
                            const OutlineInputBorder(),

                        suffixIcon: IconButton(

                          icon: Icon(

                            hidePassword

                                ? Icons.visibility

                                : Icons.visibility_off,

                          ),

                          onPressed: () {

                            setState(() {

                              hidePassword =
                                  !hidePassword;

                            });

                          },

                        ),

                      ),

                    ),

                    const SizedBox(height: 30),

                    SizedBox(

                      width: double.infinity,

                      height: 50,

                      child: ElevatedButton(

                        onPressed: loading

                            ? null
                            : login,

                        child: loading

                            ? const SizedBox(

                                height: 22,

                                width: 22,

                                child:
                                    CircularProgressIndicator(

                                  strokeWidth: 2,

                                ),

                              )

                            : const Text(

                                "LOGIN",

                                style: TextStyle(

                                  fontSize: 16,

                                  fontWeight:
                                      FontWeight.bold,

                                ),

                              ),

                      ),

                    ),

                    const SizedBox(height: 20),

                    Text(

                      officeFooter,
                      textAlign: TextAlign.center,

                      style: const TextStyle(

                        color: Colors.grey,

                      ),

                    ),
                                      ],

                ),

              ),

            ),

          ),

        ),

      ),

    );

  }

}