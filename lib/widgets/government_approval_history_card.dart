import 'package:flutter/material.dart';
import '../models/government_approval_model.dart';
import '../repositories/government_approval_repository.dart';
class GovernmentApprovalHistoryCard extends StatelessWidget {
  final int applicationId;
  const GovernmentApprovalHistoryCard({super.key,required this.applicationId});
  @override
  Widget build(BuildContext context)=>FutureBuilder<GovernmentApproval?>(future:GovernmentApprovalRepository().get(applicationId),builder:(context,snapshot){
    final row=snapshot.data;if(row==null)return const SizedBox.shrink();
    return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Government Land Approval',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      Text('RFO permission type: ${row.permissionType}'),Text('Khata details given: ${row.khataGiven==null?'—':row.khataGiven!?'Yes':'No'}'),
      if(row.stage=='completed'&&row.permissionType=='Valuation'&&row.answers['nature']=='Not satisfied')const Text('Final outcome: Auction — DO letter and Taggu Bele Patti'),
      Text('Stage: ${row.stage}'),if(row.requestDate.isNotEmpty)Text('Documents requested: ${row.requestDate.split('T').first}'),
      for(final item in GovernmentApproval.questions.entries)if((row.answers[item.key]??'').isNotEmpty)Text('${item.value}: ${row.answers[item.key]!}'),
    ])));
  });
}
