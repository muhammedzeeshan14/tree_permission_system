import 'package:flutter/material.dart';
import '../models/revenue_reply_model.dart';
import '../repositories/revenue_reply_repository.dart';

class RevenueReplyHistoryCard extends StatefulWidget {
  final int applicationId;
  const RevenueReplyHistoryCard({super.key, required this.applicationId});
  @override
  State<RevenueReplyHistoryCard> createState() =>
      _RevenueReplyHistoryCardState();
}

class _RevenueReplyHistoryCardState extends State<RevenueReplyHistoryCard> {
  late Future<List<RevenueReply>> history;
  @override
  void initState() {
    super.initState();
    history = RevenueReplyRepository().history(widget.applicationId);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<RevenueReply>>(
    future: history,
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return const Text('Revenue opinion history could not be loaded.');
      if (!snapshot.hasData || snapshot.data!.isEmpty)
        return const SizedBox.shrink();
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Revenue Opinion — Requests and Replies',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              for (final reply in snapshot.data!) ...[
                const Divider(),
                Text(
                  'Request ' + reply.cycle.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Sent to: ' + reply.requestAuthority),
                Text(
                  'RFO request approval date: ' +
                      reply.requestedAt.split('T').first,
                ),
                Text(
                  'Printed: ' +
                      (reply.printedAt.isEmpty
                          ? 'Pending printing'
                          : reply.printedAt.split('T').first),
                ),
                Text('Stage: ' + reply.stage),
                if (reply.answers.isNotEmpty)
                  for (final field in RevenueReply.fields(reply.answers))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(RevenueReply.questions[field]!),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Text(
                              (reply.answers[field]?.isNotEmpty == true
                                      ? reply.answers[field]!
                                      : '—') +
                                  (reply.decisions[field] == null
                                      ? ''
                                      : ' [' + reply.decisions[field]! + ']'),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
