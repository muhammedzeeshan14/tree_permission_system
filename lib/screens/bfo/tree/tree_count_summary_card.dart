import 'package:flutter/material.dart';

import '../../../models/tree_count_detail_model.dart';
import '../../../models/tree_count_site_model.dart';
import '../../../repositories/master_repository.dart';
import '../../../repositories/tree_count_detail_repository.dart';
import '../../../repositories/tree_count_site_repository.dart';

class TreeCountSummaryCard extends StatefulWidget {

  final int applicationId;

  const TreeCountSummaryCard({

    super.key,

    required this.applicationId,

  });

  @override
  State<TreeCountSummaryCard> createState() =>
    TreeCountSummaryCardState();

}

class TreeCountSummaryCardState
    extends State<TreeCountSummaryCard> {

  Future<void> reload() async {
    await load();
  }

  final siteRepo = TreeCountSiteRepository();

  final detailRepo = TreeCountDetailRepository();

  final masterRepo = MasterRepository();

  List<TreeCountSiteModel> sites = [];

  final Map<int, List<TreeCountDetailModel>>
      details = {};

  final Map<int, String> speciesMap = {};

  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {

    final species =
        await masterRepo.getSpecies();

    speciesMap.clear();

    for (final s in species) {

      speciesMap[s["id"]] = s["value"];

    }

    sites = await siteRepo.getSites(
      widget.applicationId,
    );

    details.clear();

    for (final site in sites) {

      details[site.id!] =
          await detailRepo.getBySite(
        site.id!,
      );

    }

    loading = false;

    if (mounted) {
      setState(() {});
    }

  }

  Widget tableCell(String text) {

    return Padding(

      padding: const EdgeInsets.all(8),

      child: Text(
        text,
        textAlign: TextAlign.center,
      ),

    );

  }

  @override
  Widget build(BuildContext context) {

    if (loading) {

      return const Card(

        child: Padding(

          padding: EdgeInsets.all(25),

          child: Center(
            child: CircularProgressIndicator(),
          ),

        ),

      );

    }

    return Card(

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(

              "Tree Count Details",

              style: TextStyle(

                fontSize: 18,

                fontWeight: FontWeight.bold,

              ),

            ),

            const Divider(),

            if (sites.isEmpty)

              const Padding(

                padding: EdgeInsets.all(20),

                child: Center(

                  child: Text(
                    "No Tree Count Entered",
                  ),

                ),

              )

            else

              ...sites.asMap().entries.map(

                (entry) {

                  final siteNo =
                      entry.key + 1;

                  final site =
                      entry.value;

                  final rows =
                      details[site.id] ?? [];

                  return Card(

                    margin:
                        const EdgeInsets.only(
                      bottom: 16,
                    ),

                    child: Padding(

                      padding:
                          const EdgeInsets.all(
                        12,
                      ),

                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          Text(

                            "SITE $siteNo",

                            style:
                                const TextStyle(

                              fontWeight:
                                  FontWeight.bold,

                              fontSize: 16,

                            ),

                          ),

                          const SizedBox(
                              height: 8),

                          Text(
                            "Site Details : ${site.siteDetails}",
                          ),

                          const SizedBox(
                              height: 12),

                          Table(

                            border:
                                TableBorder.all(),

                            columnWidths:
                                const {

                              0:
                                  FixedColumnWidth(
                                      60),

                              1:
                                  FlexColumnWidth(),

                              2:
                                  FixedColumnWidth(
                                      120),

                            },

                            children: [

                              const TableRow(

                                children: [

                                  Padding(

                                    padding:
                                        EdgeInsets
                                            .all(8),

                                    child: Text(

                                      "Sl.No.",

                                      textAlign:
                                          TextAlign
                                              .center,

                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),

                                    ),

                                  ),

                                  Padding(

                                    padding:
                                        EdgeInsets
                                            .all(8),

                                    child: Text(

                                      "Species",

                                      textAlign:
                                          TextAlign
                                              .center,

                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),

                                    ),

                                  ),

                                  Padding(

                                    padding:
                                        EdgeInsets
                                            .all(8),

                                    child: Text(

                                      "No. of Trees",

                                      textAlign:
                                          TextAlign
                                              .center,

                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),

                                    ),

                                  ),

                                ],

                              ),

                              ...rows.asMap().entries.map(

                                (e) {

                                  final row =
                                      e.value;

                                  return TableRow(

                                    children: [

                                      tableCell(
                                        "${e.key + 1}",
                                      ),

                                      tableCell(

                                        speciesMap[
                                                row.speciesId] ??
                                            "",

                                      ),

                                      tableCell(

                                        row.treeCount
                                            .toString(),

                                      ),

                                    ],

                                  );

                                },

                              ),

                            ],

                          ),

                        ],

                      ),

                    ),

                  );

                },

              ),

          ],

        ),

      ),

    );

  }

}