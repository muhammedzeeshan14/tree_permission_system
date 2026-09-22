import 'package:flutter/material.dart';

import '../../../models/application_model.dart';
import '../../../widgets/responsive_actions.dart';
import '../../../models/photo_model.dart';
import '../../../repositories/photo_repository.dart';
import '../../../services/cloud_file_service.dart';
import '../../../services/photo_service.dart';
import 'dart:io';

class PhotoStep extends StatefulWidget {

  final ApplicationModel application;

  final VoidCallback onBack;

  final VoidCallback onNext;

  const PhotoStep({

    super.key,

    required this.application,

    required this.onBack,

    required this.onNext,

  });

  @override
  State<PhotoStep> createState() =>
      _PhotoStepState();
}

class _PhotoStepState
    extends State<PhotoStep> {

  final PhotoRepository repository =
      PhotoRepository();
      final PhotoService photoService =
    PhotoService();

  List<PhotoModel> photos = [];

  @override
  void initState() {

    super.initState();

    loadPhotos();

  }

  Future<void> loadPhotos() async {

    photos = await repository.getPhotos(
      widget.application.id!,
    );

    // Cloud: download photos taken on other devices.
    for (final photo in photos) {
      if (photo.photoPath.isEmpty) continue;
      try {
        await CloudFileService.ensureLocal(
          bucket: CloudFileService.photosBucket,
          key: CloudFileService.photoKey(
            widget.application.officeNumber,
            photo.photoPath,
          ),
          localPath: photo.photoPath,
        );
      } catch (_) {
        // Offline; show whatever is available locally.
      }
    }

    if (mounted) {

      setState(() {});

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Inspection Photos",
        ),

      ),

      body: Padding(

        padding: const EdgeInsets.all(15),

        child: Column(

          children: [

            Card(

              child: ListTile(

                leading: const Icon(
                  Icons.photo,
                  color: Colors.green,
                ),

                title: const Text(
                  "Total Photos",
                ),

                trailing: Text(
                  photos.length.toString(),
                ),

              ),

            ),

            const SizedBox(height: 15),

            ResponsiveActions(

              children: [

                ElevatedButton.icon(

                    icon: const Icon(
                      Icons.camera_alt,
                    ),

                    label: const Text(
                      "Camera",
                    ),

                    onPressed: () async {

  final file = await photoService.takePhoto(

    widget.application.officeNumber,

  );

  if (file == null) return;

  final now = DateTime.now();

  await repository.savePhoto(

    PhotoModel(

      applicationId: widget.application.id!,

      photoPath: file.path,

      caption: "",

      createdDate:

          "${now.day.toString().padLeft(2,'0')}/"

          "${now.month.toString().padLeft(2,'0')}/"

          "${now.year} "

          "${now.hour.toString().padLeft(2,'0')}:"

          "${now.minute.toString().padLeft(2,'0')}",

    ),

  );

  // Cloud: photo travels to other devices.
  CloudFileService.uploadPhoto(
    widget.application.officeNumber,
    file,
  );

  await loadPhotos();

},

                  ),

                ElevatedButton.icon(

                    icon: const Icon(
                      Icons.photo_library,
                    ),

                    label: const Text(
                      "Gallery",
                    ),

                    onPressed: () async {

  final file =
      await photoService.pickFromGallery(

    widget.application.officeNumber,

  );

  if (file == null) return;

  final now = DateTime.now();

  await repository.savePhoto(

    PhotoModel(

      applicationId:
          widget.application.id!,

      photoPath: file.path,

      caption: "",

      createdDate:

          "${now.day.toString().padLeft(2,'0')}/"

          "${now.month.toString().padLeft(2,'0')}/"

          "${now.year} "

          "${now.hour.toString().padLeft(2,'0')}:"

          "${now.minute.toString().padLeft(2,'0')}",

    ),

  );

  // Cloud: photo travels to other devices.
  CloudFileService.uploadPhoto(
    widget.application.officeNumber,
    file,
  );

  await loadPhotos();

},

                  ),

              ],

            ),

            const SizedBox(height: 20),

            Expanded(

              child: photos.isEmpty

                  ? const Center(

                      child: Text(

                        "No Photos Added",

                        style: TextStyle(
                          fontSize: 18,
                        ),

                      ),

                    )

                  : ListView.builder(

                      itemCount: photos.length,

                      itemBuilder:
                          (context, index) {

                        final photo =
                            photos[index];

                        return Card(

                          child: ListTile(

                            leading: ClipRRect(

  borderRadius:

      BorderRadius.circular(8),

  child: Image.file(

    File(photo.photoPath),

    width: 60,

    height: 60,

    fit: BoxFit.cover,

  ),

),

                            title: Text(
                              photo.caption.isEmpty
                                  ? "No Caption"
                                  : photo.caption,
                            ),

                            subtitle: Text(
                              photo.createdDate,
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
      onPressed: () {

        showDialog(

          context: context,

          builder: (_) {

            return Dialog(

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  AppBar(
                    automaticallyImplyLeading: false,
                    title: const Text("Photo Preview"),
                  ),

                  InteractiveViewer(

                    child: Image.file(
                      File(photo.photoPath),
                      fit: BoxFit.contain,
                    ),

                  ),

                  const SizedBox(height: 10),

                  Padding(

                    padding: const EdgeInsets.only(bottom: 15),

                    child: ElevatedButton(

                      onPressed: () {

                        Navigator.pop(context);

                      },

                      child: const Text("CLOSE"),

                    ),

                  ),

                ],

              ),

            );

          },

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
                "Delete Photo",
              ),

              content: const Text(
                "Do you want to delete this photo?",
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

        CloudFileService.deleteKey(
          CloudFileService.photosBucket,
          CloudFileService.photoKey(
            widget.application.officeNumber,
            photo.photoPath,
          ),
        );

        await repository.deletePhoto(
          photo.id!,
        );

        await loadPhotos();

      },

    ),

  ],

),
 ),
 );
                      },

                    ),

            ),

            ResponsiveActions(

              children: [

                ElevatedButton(

                    onPressed:
                        widget.onBack,

                    child: const Text(
                      "BACK",
                    ),

                  ),

                ElevatedButton(

                    onPressed:
                        widget.onNext,

                    child: const Text(
                      "NEXT",
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