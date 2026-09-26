import 'package:flutter/material.dart';

import '../../repositories/user_repository.dart';
import '../../repositories/section_repository.dart';
import '../../repositories/beat_repository.dart';

class UserMasterScreen extends StatefulWidget {
  const UserMasterScreen({super.key});

  @override
  State<UserMasterScreen> createState() =>
      _UserMasterScreenState();
}

class _UserMasterScreenState
    extends State<UserMasterScreen> {

  final UserRepository userRepository =
      UserRepository();

  final SectionRepository sectionRepository =
      SectionRepository();

  final BeatRepository beatRepository =
      BeatRepository();

  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {

    users = await userRepository.getAll();

    if (mounted) {
      setState(() {});
    }

  }

  Future<void> showUserDialog({

    Map<String, dynamic>? item,

  }) async {

    final nameController =
        TextEditingController(
      text: item?["name"] ?? "",
    );

    final usernameController =
        TextEditingController(
      text: item?["username"] ?? "",
    );

    final passwordController =
        TextEditingController(
      text: item?["password"] ?? "",
    );

    String role =
        item?["role"] ?? "BFO";

    bool isActive =
        (item?["isActive"] ?? 1) == 1;

    int? selectedSectionId =
        item?["sectionId"];

    int? selectedBeatId =
        item?["beatId"];

    final sections =
        await sectionRepository.getActive();

    List<Map<String, dynamic>> beats = [];

    if (selectedSectionId != null) {

      beats = await beatRepository.getBySection(
        selectedSectionId,
      );

    }

    await showDialog(

      context: context,

      builder: (dialogContext) {

        return StatefulBuilder(

          builder:
              (dialogContext, setDialogState) {

            return AlertDialog(

              title: Text(

                item == null
                    ? "Add User"
                    : "Edit User",

              ),

              content: SizedBox(

                width: 450,

                child: SingleChildScrollView(

                  child: Column(

                    mainAxisSize:
                        MainAxisSize.min,

                    children: [

                      TextField(

                        controller:
                            nameController,

                        decoration:
                            const InputDecoration(

                          labelText: "Name",

                        ),

                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      TextField(

                        controller:
                            usernameController,

                        decoration:
                            const InputDecoration(

                          labelText:
                              "Username",

                        ),

                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      TextField(

                        controller:
                            passwordController,

                        decoration:
                            const InputDecoration(

                          labelText:
                              "Password",

                        ),

                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      DropdownButtonFormField<
                          String>(

                        initialValue:
                            role,

                        decoration:
                            const InputDecoration(

                          labelText:
                              "Role",

                        ),

                        items: const [

                          DropdownMenuItem(

                            value: "RFO",

                            child:
                                Text("RFO"),

                          ),

                          DropdownMenuItem(

                            value:
                                "DRFO",

                            child:
                                Text("DRFO"),

                          ),

                          DropdownMenuItem(

                            value:
                                "BFO",

                            child:
                                Text("BFO"),

                          ),

                          DropdownMenuItem(

                            value:
                                "Case Worker",

                            child: Text(
                              "Case Worker",
                            ),

                          ),

                        ],

                        onChanged:
                            (value) async {

                          role = value!;

                          if (role !=
                              "BFO") {

                            selectedBeatId =
                                null;

                          }

                          setDialogState(
                              () {});

                        },

                      ),
                                            if (role == "DRFO" ||
                          role == "BFO") ...[

                        const SizedBox(
                          height: 15,
                        ),

                        DropdownButtonFormField<int>(

                          initialValue:
                              selectedSectionId,

                          decoration:
                              const InputDecoration(

                            labelText:
                                "Section",

                          ),

                          items: sections
                              .map((section) {

                            return DropdownMenuItem<int>(

                              value: section["id"],

                              child: Text(

                                section["sectionName"],

                              ),

                            );

                          }).toList(),

                          onChanged:
                              (value) async {

                            selectedSectionId =
                                value;

                            selectedBeatId =
                                null;

                            if (value != null) {

                              beats =
                                  await beatRepository
                                      .getBySection(
                                          value);

                            } else {

                              beats = [];

                            }

                            setDialogState(() {});

                          },

                        ),

                      ],

                      if (role == "BFO") ...[

                        const SizedBox(
                          height: 15,
                        ),

                        DropdownButtonFormField<int>(

                          initialValue:
                              selectedBeatId,

                          decoration:
                              const InputDecoration(

                            labelText:
                                "Beat",

                          ),

                          items:
                              beats.map((beat) {

                            return DropdownMenuItem<int>(

                              value: beat["id"],

                              child: Text(

                                beat["beatName"],

                              ),

                            );

                          }).toList(),

                          onChanged: (value) {

                            setDialogState(() {

                              selectedBeatId =
                                  value;

                            });

                          },

                        ),

                      ],

                      const SizedBox(
                        height: 15,
                      ),

                      SwitchListTile(

                        title: const Text(
                          "Active",
                        ),

                        value: isActive,

                        onChanged: (value) {

                          setDialogState(() {

                            isActive = value;

                          });

                        },

                      ),

                    ],

                  ),

                ),

              ),

              actions: [

                TextButton(

                  onPressed: () {

                    Navigator.pop(
                        dialogContext);

                  },

                  child: const Text(
                    "Cancel",
                  ),

                ),

                ElevatedButton(

                  onPressed: () async {

                    if (nameController.text
                        .trim()
                        .isEmpty) {

                      ScaffoldMessenger.of(
                              context)
                          .showSnackBar(

                        const SnackBar(

                          content: Text(
                            "Please enter Name",
                          ),

                        ),

                      );

                      return;

                    }

                    if (usernameController.text
                        .trim()
                        .isEmpty) {

                      ScaffoldMessenger.of(
                              context)
                          .showSnackBar(

                        const SnackBar(

                          content: Text(
                            "Please enter Username",
                          ),

                        ),

                      );

                      return;

                    }

                    if (passwordController.text
                        .trim()
                        .isEmpty) {

                      ScaffoldMessenger.of(
                              context)
                          .showSnackBar(

                        const SnackBar(

                          content: Text(
                            "Please enter Password",
                          ),

                        ),

                      );

                      return;

                    }

                    if (role == "DRFO" &&
                        selectedSectionId ==
                            null) {

                      ScaffoldMessenger.of(
                              context)
                          .showSnackBar(

                        const SnackBar(

                          content: Text(
                            "Please select Section",
                          ),

                        ),

                      );

                      return;

                    }

                    if (role == "BFO") {

                      if (selectedSectionId ==
                          null) {

                        ScaffoldMessenger.of(
                                context)
                            .showSnackBar(

                          const SnackBar(

                            content: Text(
                              "Please select Section",
                            ),

                          ),

                        );

                        return;

                      }

                      if (selectedBeatId ==
                          null) {

                        ScaffoldMessenger.of(
                                context)
                            .showSnackBar(

                          const SnackBar(

                            content: Text(
                              "Please select Beat",
                            ),

                          ),

                        );

                        return;

                      }

                    }
                                        if (item == null) {

                      await userRepository.insert(

                        name: nameController.text.trim(),

                        username: usernameController.text.trim(),

                        password: passwordController.text,

                        role: role,

                        sectionId: selectedSectionId,

                        beatId: selectedBeatId,

                        isActive: isActive,

                      );

                    } else {

                      await userRepository.update(

                        id: item["id"],

                        name: nameController.text.trim(),

                        username: usernameController.text.trim(),

                        password: passwordController.text,

                        role: role,

                        sectionId: selectedSectionId,

                        beatId: selectedBeatId,

                        isActive: isActive,

                      );

                    }

                    if (!mounted) return;

                    Navigator.pop(dialogContext);

                    await loadUsers();

                  },

                  child: const Text(

                    "Save",

                  ),

                ),

              ],

            );

          },

        );

      },

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(

          "User Master",

        ),

        centerTitle: true,

      ),

      body: users.isEmpty

          ? const Center(

              child: Text(

                "No Users Found",

                style: TextStyle(

                  fontSize: 18,

                  fontWeight: FontWeight.bold,

                ),

              ),

            )

          : ListView.builder(

              padding: const EdgeInsets.all(10),

              itemCount: users.length,

              itemBuilder: (context, index) {

                final user = users[index];

                return Card(

                  elevation: 3,

                  margin: const EdgeInsets.only(

                    bottom: 10,

                  ),

                  child: ListTile(

                    leading: CircleAvatar(

                      child: Text(

                        "${index + 1}",

                      ),

                    ),

                    title: Text(

                      user["name"] ?? "",

                      style: const TextStyle(

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                    subtitle: Column(

                      crossAxisAlignment:

                          CrossAxisAlignment.start,

                      children: [

                        Text(

                          "Username : ${user["username"]}",

                        ),

                        Text(

                          "Role : ${user["role"]}",

                        ),

                        if (user["sectionId"] != null)

                          Text(

                            "Section ID : ${user["sectionId"]}",

                          ),

                        if (user["beatId"] != null)

                          Text(

                            "Beat ID : ${user["beatId"]}",

                          ),

                        Text(

                          user["isActive"] == 1

                              ? "Status : Active"

                              : "Status : Inactive",

                          style: TextStyle(

                            color: user["isActive"] == 1

                                ? Colors.green

                                : Colors.red,

                            fontWeight: FontWeight.bold,

                          ),

                        ),

                      ],

                    ),
                                        onTap: () {

                      showUserDialog(

                        item: user,

                      );

                    },

                    onLongPress: () async {

                      final confirm =
                          await showDialog<bool>(

                        context: context,

                        builder: (_) => AlertDialog(

                          title: const Text(

                            "Delete User",

                          ),

                          content: Text(

                            'Delete "${user["name"]}" ?',

                          ),

                          actions: [

                            TextButton(

                              onPressed: () {

                                Navigator.pop(

                                  context,

                                  false,

                                );

                              },

                              child: const Text(

                                "Cancel",

                              ),

                            ),

                            ElevatedButton(

                              onPressed: () {

                                Navigator.pop(

                                  context,

                                  true,

                                );

                              },

                              child: const Text(

                                "Delete",

                              ),

                            ),

                          ],

                        ),

                      );

                      if (confirm == true) {

                        await userRepository.delete(

                          user["id"],

                        );

                        await loadUsers();

                      }

                    },

                  ),

                );

              },

            ),

      floatingActionButton:

          FloatingActionButton(

        onPressed: () {

          showUserDialog();

        },

        child: const Icon(

          Icons.add,

        ),

      ),

    );

  }

}