import 'package:flutter/material.dart';

import '../models/revenue_opinion_model.dart';
import '../repositories/revenue_opinion_repository.dart';

class RevenueOpinionMasterScreen extends StatefulWidget {

  const RevenueOpinionMasterScreen({
    super.key,
  });

  @override
  State<RevenueOpinionMasterScreen> createState() =>
      _RevenueOpinionMasterScreenState();

}

class _RevenueOpinionMasterScreenState
    extends State<RevenueOpinionMasterScreen> {

  final repo = RevenueOpinionRepository();

  List<RevenueOpinionModel> data = [];

  @override
  void initState() {

    super.initState();

    load();

  }

  Future<void> load() async {

    data = await repo.getAll();

    if (mounted) {

      setState(() {});

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Revenue Opinion Master",
        ),

      ),

      floatingActionButton:
          FloatingActionButton(

        onPressed: () {

          openEditor();

        },

        child: const Icon(Icons.add),

      ),

      body: ListView.builder(

        itemCount: data.length,

        itemBuilder: (context,index){

          final item=data[index];

          return Card(

            margin: const EdgeInsets.symmetric(

              horizontal:12,

              vertical:6,

            ),

            child: ListTile(

              title: Text(

                item.revenueOpinion,

              ),

              subtitle: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    "Code : ${item.code}",
                  ),

                  Text(
                    item.officeName,
                  ),

                  Text(
                    item.officeAddress,
                  ),

                  Text(
                    "Display Order : ${item.displayOrder}",
                  ),

                ],

              ),

              trailing: Row(

                mainAxisSize: MainAxisSize.min,

                children: [

                  IconButton(

                    icon: const Icon(

                      Icons.edit,

                    ),

                    onPressed: () {

                      openEditor(item);

                    },

                  ),

                  IconButton(

                    icon: const Icon(

                      Icons.delete,

                      color: Colors.red,

                    ),

                    onPressed: () async {

                      final delete =
                          await showDialog<bool>(

                        context: context,

                        builder: (_) {

                          return AlertDialog(

                            title: const Text(
  "Delete Revenue Opinion",
),

                            content: const Text(

                              "Delete this Revenue Opinion?",

                            ),

                            actions: [

                              TextButton(

                                onPressed: (){

                                  Navigator.pop(
                                    context,
                                    false,
                                  );

                                },

                                child: const Text(
                                  "No",
                                ),

                              ),

                              ElevatedButton(

                                onPressed: (){

                                  Navigator.pop(
                                    context,
                                    true,
                                  );

                                },

                                child: const Text(
                                  "Yes",
                                ),

                              ),

                            ],

                          );

                        },

                      );

                      if(delete==true){

                        await repo.delete(item.id!);

                        await load();

                      }

                    },

                  ),

                ],

              ),

            ),

          );

        },

      ),

    );

  }
Future<void> openEditor([
  RevenueOpinionModel? item,
]) async {

  final revenueOpinionController =
      TextEditingController(
    text: item?.revenueOpinion ?? "",
  );

  final codeController =
      TextEditingController(
    text: item?.code ?? "",
  );

  final officeNameController =
      TextEditingController(
    text: item?.officeName ?? "",
  );

  final officeAddressController =
      TextEditingController(
    text: item?.officeAddress ?? "",
  );

  final remarksController =
      TextEditingController(
    text: item?.remarks ?? "",
  );

  final displayOrderController =
      TextEditingController(
    text: (item?.displayOrder ?? 1)
        .toString(),
  );

  bool active =
      item?.isActive ?? true;

  await showDialog(

    context: context,

    builder: (context) {

      return StatefulBuilder(

        builder: (context, setDialog) {

          return AlertDialog(

            title: Text(

              item == null

                  ? "Add Revenue Opinion"

                  : "Edit Revenue Opinion",

            ),

            content: SizedBox(

              width: 420,

              child: SingleChildScrollView(

                child: Column(

                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    TextField(

                      controller:
                          revenueOpinionController,

                      decoration:
                          const InputDecoration(

                        labelText:
                            "Revenue Opinion",

                      ),

                    ),

                    const SizedBox(height: 15),

                    TextField(

                      controller:
                          codeController,

                      decoration:
                          const InputDecoration(

                        labelText: "Code",

                      ),

                    ),

                    const SizedBox(height: 15),

                    TextField(

                      controller:
                          officeNameController,

                      decoration:
                          const InputDecoration(

                        labelText:
                            "Office Name",

                      ),

                    ),

                    const SizedBox(height: 15),

                    TextField(

                      controller:
                          officeAddressController,

                      minLines: 2,

                      maxLines: 4,

                      decoration:
                          const InputDecoration(

                        labelText:
                            "Office Address",

                      ),

                    ),

                    const SizedBox(height: 15),

                    TextField(

                      controller:
                          remarksController,

                      decoration:
                          const InputDecoration(

                        labelText:
                            "Remarks",

                      ),

                    ),

                    const SizedBox(height: 15),

                    TextField(

                      controller:
                          displayOrderController,

                      keyboardType:
                          TextInputType.number,

                      decoration:
                          const InputDecoration(

                        labelText:
                            "Display Order",

                      ),

                    ),

                    const SizedBox(height: 10),

                    SwitchListTile(

                      value: active,

                      title:
                          const Text("Active"),

                      onChanged: (v) {

                        setDialog(() {

                          active = v;

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

                  Navigator.pop(context);

                },

                child: const Text(

                  "Cancel",

                ),

              ),

              ElevatedButton(

                onPressed: () async {

                  if (revenueOpinionController.text
        .trim()
        .isEmpty ||

    officeNameController.text
        .trim()
        .isEmpty) {

  ScaffoldMessenger.of(context)
      .showSnackBar(

    const SnackBar(

      content: Text(
        "Revenue Opinion and Office Name are required.",
      ),

    ),

  );

  return;

}



                  final model =
                      RevenueOpinionModel(

                    id: item?.id,

                    revenueOpinion:
                        revenueOpinionController
                            .text
                            .trim(),

                    code: codeController.text
                        .trim(),

                    officeName:
                        officeNameController.text
                            .trim(),

                    officeAddress:
                        officeAddressController
                            .text
                            .trim(),

                    remarks:
                        remarksController.text
                            .trim(),

                    displayOrder:
                        int.tryParse(
                              displayOrderController
                                  .text,
                            ) ??
                            1,

                    isActive: active,

                  );

                  if (item == null) {

                    await repo.insert(model);

                  } else {

                    await repo.update(model);

                  }

                  if (!mounted) return;

                  Navigator.pop(context);

                  await load();

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
}