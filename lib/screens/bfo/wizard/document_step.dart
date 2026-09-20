import 'package:flutter/material.dart';

import '../../../models/application_model.dart';
import '../../../models/document_model.dart';
import '../../../repositories/document_repository.dart';
import '../../../repositories/master_repository.dart';
import '../../../services/document_service.dart';
import 'package:open_filex/open_filex.dart';

class DocumentStep extends StatefulWidget {

  final ApplicationModel application;

  final VoidCallback onBack;

  final VoidCallback onNext;

  const DocumentStep({

    super.key,

    required this.application,

    required this.onBack,

    required this.onNext,

  });

  @override
  State<DocumentStep> createState() =>
      _DocumentStepState();
}

class _DocumentStepState
    extends State<DocumentStep> {
final DocumentRepository repository =
    DocumentRepository();

final DocumentService documentService =
    DocumentService();

List<DocumentModel> documentList = [];

List<Map<String, dynamic>> documentTypeList = [];

int? documentTypeId;

final remarksController =
    TextEditingController();
    String selectedDocumentPath = "";

String selectedDocumentName = "";
    Future<void> loadDocuments() async {

  documentList =
      await repository.getDocuments(
    widget.application.id!,
  );

  documentTypeList =
      await MasterRepository().getMasters(
    "Document Type",
  );

  if (mounted) {

    setState(() {});

  }

}
Future<void> pickDocument() async {

  final file = await documentService.pickDocument(

    widget.application.officeNumber,

  );

  if (file == null) return;

  setState(() {

    selectedDocumentPath = file.path;

    selectedDocumentName = file.path.split("\\").last;

  });

}
@override
void initState() {

  super.initState();

  loadDocuments();

}
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Inspection Documents",
        ),

      ),

      body: Padding(

        padding: const EdgeInsets.all(15),

        child: Column(

          children: [

            Card(

              child: ListTile(

                leading: const Icon(
                  Icons.description,
                  color: Colors.blue,
                ),

                title: const Text(
                  "Inspection Documents",
                ),

                subtitle: const Text(
                  "Document upload module",
                ),

              ),

            ),

            const SizedBox(height: 20),

            SizedBox(

              width: double.infinity,

              height: 55,

              child: ElevatedButton.icon(

                icon: const Icon(Icons.upload_file),

                label: const Text(
                  "UPLOAD DOCUMENT",
                ),

               onPressed: () async {

  await pickDocument();

},

              ),

            ),
const SizedBox(height: 20),

if (selectedDocumentName.isNotEmpty)

Card(

  child: Padding(

    padding: const EdgeInsets.all(15),

    child: Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(

          selectedDocumentName,

          style: const TextStyle(

            fontWeight: FontWeight.bold,

            fontSize: 16,

          ),

        ),

        const SizedBox(height: 20),

        DropdownButtonFormField<int>(

          value: documentTypeId,

          decoration: const InputDecoration(

            labelText: "Document Type",

            border: OutlineInputBorder(),

          ),

          items: documentTypeList.map((item){

            return DropdownMenuItem(

              value: item["id"] as int,

              child: Text(

                item["value"],

              ),

            );

          }).toList(),

          onChanged: (value){

            setState(() {

              documentTypeId = value;

            });

          },

        ),

        const SizedBox(height: 20),

        TextFormField(

          controller: remarksController,

          decoration: const InputDecoration(

            labelText: "Remarks",

            border: OutlineInputBorder(),

          ),

        ),

        const SizedBox(height: 20),

        SizedBox(

          width: double.infinity,

          height: 50,

          child: ElevatedButton.icon(

            icon: const Icon(Icons.save),

            label: const Text(

              "SAVE DOCUMENT",

            ),

            onPressed: () async {

              if(documentTypeId==null){

                ScaffoldMessenger.of(context)

                    .showSnackBar(

                  const SnackBar(

                    content: Text(

                      "Select Document Type",

                    ),

                  ),

                );

                return;

              }

              final selectedType =
                  documentTypeList.firstWhere(

                (e)=>e["id"]==documentTypeId,

              );

              try {
  await repository.saveDocument(
    DocumentModel(
      applicationId: widget.application.id!,
      documentTypeId: documentTypeId,
      documentTypeName: selectedType["value"],
      filePath: selectedDocumentPath,
      remarks: remarksController.text,
      createdDate: DateTime.now().toString(),
    ),
  );

  selectedDocumentName = "";
  selectedDocumentPath = "";
  documentTypeId = null;
  remarksController.clear();

  await loadDocuments();

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Document saved successfully."),
      ),
    );
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Unable to save document: $e"),
      ),
    );
  }
}

            },

          ),

        ),

      ],

    ),

  ),

),
           const SizedBox(height: 20),

const Divider(),

const SizedBox(height: 10),

const Align(

  alignment: Alignment.centerLeft,

  child: Text(

    "Uploaded Documents",

    style: TextStyle(

      fontSize: 18,

      fontWeight: FontWeight.bold,

    ),

  ),

),

const SizedBox(height: 10),

Expanded(

  child: documentList.isEmpty

      ? const Center(

          child: Text(

            "No documents uploaded",

          ),

        )

      : ListView.builder(

          itemCount: documentList.length,

          itemBuilder: (context, index) {

            final doc = documentList[index];

            return Card(

              child: ListTile(

                leading: const Icon(

                  Icons.description,

                  color: Colors.blue,

                ),

                title: Text(

                  doc.documentTypeName,

                ),

                subtitle: Column(

                  crossAxisAlignment:

                      CrossAxisAlignment.start,

                  children: [

                    Text(

                      doc.filePath

                          .split("\\")

                          .last,

                    ),

                    if (doc.remarks.isNotEmpty)

                      Text(doc.remarks),

                  ],

                ),

                trailing: Row(

  mainAxisSize: MainAxisSize.min,

  children: [

    IconButton(

      tooltip: "View",

      icon: const Icon(

        Icons.visibility,

        color: Colors.blue,

      ),

      onPressed: () async {

        await OpenFilex.open(
          doc.filePath,
        );

      },

    ),

    IconButton(

      tooltip: "Delete",

      icon: const Icon(

        Icons.delete,

        color: Colors.red,

      ),

      onPressed: () async {

        final result = await showDialog<bool>(

          context: context,

          builder: (context) {

            return AlertDialog(

              title: const Text(
                "Delete Document",
              ),

              content: const Text(
                "Do you want to delete this document?",
              ),

              actions: [

                TextButton(

                  onPressed: () {

                    Navigator.pop(
                      context,
                      false,
                    );

                  },

                  child: const Text("NO"),

                ),

                ElevatedButton(

                  onPressed: () {

                    Navigator.pop(
                      context,
                      true,
                    );

                  },

                  child: const Text("YES"),

                ),

              ],

            );

          },

        );

        if (result != true) return;

        if (doc.id != null) {

          await repository.deleteDocument(
            doc.id!,
          );

          await loadDocuments();

        }

      },

    ),

  ],

),

              ),

            );

          },

        ),

),
            const Spacer(),

            Row(

              children: [

                Expanded(

                  child: ElevatedButton(

                    onPressed: widget.onBack,

                    child: const Text("BACK"),

                  ),

                ),

                const SizedBox(width: 15),

                Expanded(

                  child: ElevatedButton(

                    onPressed: widget.onNext,

                    child: const Text("NEXT"),

                  ),

                ),

              ],

            ),

          ],

        ),

      ),

    );

  }

}