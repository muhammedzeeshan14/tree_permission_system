import 'package:flutter/material.dart';

import 'generic_master_screen.dart';
import 'tree_officer_master_screen.dart';
import '../../repositories/master_repository.dart';
import 'section_master_screen.dart';
import 'beat_master_screen.dart';
import 'user_master_screen.dart';
import 'recommendation_reason_master_screen.dart';
import 'application_type_master_screen.dart';
import '../../master/permission_type_master_screen.dart';
import '../../master/application_permission_mapping_screen.dart';
import '../../master/revenue_opinion_master_screen.dart';
import '../../repositories/revenue_opinion_repository.dart';
import 'species_master_screen.dart';
import 'pole_rate_master_screen.dart';
import 'sandal_destination_master_screen.dart';

class MasterMenuScreen extends StatelessWidget {
  const MasterMenuScreen({super.key});

  Widget masterTile(
    BuildContext context,
    String title,
    String masterType,
  ) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GenericMasterScreen(
                title: title,
                masterType: masterType,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Masters"),
      ),
      body: Column(

  children: [

    Padding(

      padding: const EdgeInsets.all(10),

      child: SizedBox(

        width: double.infinity,

        child: ElevatedButton.icon(

          icon: const Icon(Icons.download),

          label: const Text("Load Default Masters"),

          onPressed: () async {

            await MasterRepository()
                .loadDefaultMasters();

                await RevenueOpinionRepository()
    .loadDefaultRevenueOpinions();

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(

              const SnackBar(

                content: Text(
                    "Default Masters Loaded Successfully"),

              ),

            );

          },

        ),

      ),

    ),

    Expanded(

      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Card(child:ListTile(
            title:const Text('Tree Officer'),
            subtitle:const Text('Felling permission mapping'),
            trailing:const Icon(Icons.arrow_forward_ios),
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const TreeOfficerMasterScreen())),
          )),
          Card(
  child: ListTile(
    leading: const Icon(Icons.location_on),
    title: const Text("Sections"),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SectionMasterScreen(),
        ),
      );
    },
  ),
),

          Card(
  child: ListTile(
    leading: const Icon(Icons.map),
    title: const Text("Beat Master"),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BeatMasterScreen(),
        ),
      );
    },
  ),
),

Card(
  child: ListTile(
    leading: const Icon(Icons.description),
    title: const Text("Application Types"),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicationTypeMasterScreen(),
        ),
      );
    },
  ),
),

Card(
  child: ListTile(
    leading: const Icon(Icons.verified),
    title: const Text("Permission Types"),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PermissionTypeMasterScreen(),
        ),
      );
    },
  ),
),

Card(
  child: ListTile(
    leading: const Icon(Icons.account_tree),
    title: const Text(
      "Application → Permission Mapping",
    ),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicationPermissionMappingScreen(),
        ),
      );
    },
  ),
),

Card(
  child: ListTile(
    leading: const Icon(Icons.account_balance),
    title: const Text("Revenue Opinion"),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const RevenueOpinionMasterScreen(),
        ),
      );
    },
  ),
),

          Card(
  child: ListTile(
    leading: const Icon(Icons.forest),
    title: const Text("Species"),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const SpeciesMasterScreen(),
        ),
      );

    },
  ),
),

Card(
  child: ListTile(
    leading: const Icon(Icons.straighten),
    title: const Text(
      "Pole Rate Master",
    ),
    trailing: const Icon(
      Icons.arrow_forward_ios,
    ),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const PoleRateMasterScreen(),
        ),
      );
    },
  ),
),

masterTile(
  context,
  "Tree Status",
  "Tree Status",
),

masterTile(
  context,
  "Inspecting Officer Overall Remarks",
  "Inspecting Officer Overall Remark",
),

masterTile(
  context,
  "Why Removing",
  "Why Removing",
),

          masterTile(
            context,
            "Purpose",
            "Purpose",
          ),

masterTile(
  context,
  "Government Agencies",
  "Government Agency",
),

masterTile(
  context,
  "Urban / Rural",
  "Urban Rural",
),

masterTile(
  context,
  "Structure Types",
  "Structure Type",
),

masterTile(
  context,
  "Mahazar Locations",
  "Mahazar Location",
),

          masterTile(
            context,
            "Problems",
            "Problem",
          ),

          masterTile(
  context,
  "Recommendation Types",
  "Recommendation Type",
),

Card(
  child: ListTile(
    title: const Text("Recommendation Reasons"),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const RecommendationReasonMasterScreen(),
        ),
      );
    },
  ),
),

          masterTile(
            context,
            "Return Reasons",
            "Return Reason",
          ),

masterTile(
  context,
  "Inspection Defer Reasons",
  "Inspection Deferred Reason",
),

          masterTile(
            context,
            "Standard Remarks",
            "Standard Remark",
          ),
          Card(
  child: ListTile(
    leading: const Icon(Icons.people),
    title: const Text("User Master"),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const UserMasterScreen(),
        ),
      );
    },
  ),
),
         masterTile(
  context,
  "Document Types",
  "Document Type",
),

masterTile(
  context,
  "Verification Reasons",
  "Verification Reason",
),

masterTile(
  context,
  "Document Masters",
  "Document Master",
),

masterTile(
  context,
  "Document Templates",
  "Document Template",
),

masterTile(
  context,
  "Workflow Status",
  "Workflow Status",
),

Card(
  child: ListTile(
    leading: const Icon(Icons.local_shipping),
    title: const Text("Sandal Destinations"),
    subtitle: const Text("Send sandal to locations"),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const SandalDestinationMasterScreen(),
        ),
      );
    },
  ),
),
               ],
      ),

    ),

  ],

),

    );

  }
}