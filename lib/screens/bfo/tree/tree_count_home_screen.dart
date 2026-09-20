import 'package:flutter/material.dart';

import '../../../models/tree_count_site_model.dart';
import '../../../repositories/tree_count_site_repository.dart';
import 'tree_count_site_screen.dart';

class TreeCountHomeScreen extends StatefulWidget {

  final int applicationId;

  const TreeCountHomeScreen({

    super.key,

    required this.applicationId,

  });

  @override
  State<TreeCountHomeScreen> createState() =>
      _TreeCountHomeScreenState();

}

class _TreeCountHomeScreenState
    extends State<TreeCountHomeScreen> {

  final TreeCountSiteRepository repo =
      TreeCountSiteRepository();

  List<TreeCountSiteModel> sites = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {

    sites = await repo.getSites(
      widget.applicationId,
    );

    if (mounted) {
      setState(() {});
    }

  }

  Future<void> addSite() async {

    final bool? saved =
        await Navigator.push<bool>(

      context,

      MaterialPageRoute(

        builder: (_) => TreeCountSiteScreen(

          applicationId:
              widget.applicationId,

        ),

      ),

    );

    if (saved == true) {

      await load();

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Tree Count",
        ),

      ),

      body: Padding(

        padding:
            const EdgeInsets.all(16),

        child: Column(

          children: [

            Expanded(

              child: ListView.builder(

                itemCount: sites.length,

                itemBuilder:
                    (context, index) {

                  final site =
                      sites[index];

                  return Card(
  child: ListTile(

    leading: CircleAvatar(
      child: Text("${index + 1}"),
    ),

   title: Text(site.siteDetails),

    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [

       IconButton(
  icon: const Icon(Icons.edit),
  onPressed: () async {

  final bool? updated =
      await Navigator.push<bool>(

    context,

    MaterialPageRoute(

      builder: (_) => TreeCountSiteScreen(

        applicationId:
            widget.applicationId,

        siteId: site.id,

      ),

    ),

  );

  if (updated == true) {

    await load();

  }

},
),

        IconButton(
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          onPressed: () async {

  final bool? delete =
      await showDialog<bool>(

    context: context,

    builder: (context) {

      return AlertDialog(

        title: const Text(
          "Delete Site",
        ),

        content: Text(

          "Delete this site?\n\n"
          "Site Details:\n"
          "${site.siteDetails}\n\n"
          "All tree count entries for this site "
          "will also be deleted.",

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

      );

    },

  );

  if (delete != true) return;

  await TreeCountSiteRepository()
      .deleteSite(site.id!);

  await load();

},
        ),

      ],
    ),

  ),
);

                },

              ),

            ),

            const SizedBox(height: 15),

            SizedBox(

              width: double.infinity,

              child: ElevatedButton.icon(

                onPressed: addSite,

                icon:
                    const Icon(Icons.add),

                label: const Text(

                  "ADD ANOTHER SITE",

                ),

              ),

            ),

            const SizedBox(height: 10),

            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed: () {

                  Navigator.pop(
                    context,
                    true,
                  );

                },

                child: const Text(

                  "CONTINUE",

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}