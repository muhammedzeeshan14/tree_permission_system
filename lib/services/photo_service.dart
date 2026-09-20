import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class PhotoService {

  final ImagePicker _picker = ImagePicker();
  // ======================================
// TPMS PHOTO FOLDER
// ======================================

Future<Directory> getApplicationFolder(
  String officeNumber,
) async {

  final baseDirectory =
      await getApplicationDocumentsDirectory();

  final photoRoot = Directory(
    "${baseDirectory.path}/TPMS/Photos",
  );

  if (!await photoRoot.exists()) {

    await photoRoot.create(
      recursive: true,
    );

  }

  final applicationFolder = Directory(

    "${photoRoot.path}/$officeNumber",

  );

  if (!await applicationFolder.exists()) {

    await applicationFolder.create(
      recursive: true,
    );

  }

  return applicationFolder;

}
// ======================================
// GENERATE PHOTO FILE
// ======================================

Future<File> createPhotoFile(
  String officeNumber,
) async {

  final folder =
      await getApplicationFolder(
    officeNumber,
  );

  final now = DateTime.now();

  final fileName =

      "PHOTO_"

      "${now.year}"

      "${now.month.toString().padLeft(2, '0')}"

      "${now.day.toString().padLeft(2, '0')}_"

      "${now.hour.toString().padLeft(2, '0')}"

      "${now.minute.toString().padLeft(2, '0')}"

      "${now.second.toString().padLeft(2, '0')}.jpg";

  return File(

    "${folder.path}/$fileName",

  );

}
  // ======================================
// TAKE PHOTO
// ======================================

Future<File?> takePhoto(
  String officeNumber,
) async {

  final XFile? image = await _picker.pickImage(

    source: ImageSource.camera,

    imageQuality: 85,

  );

  if (image == null) {

    return null;

  }

  final destinationFile =
      await createPhotoFile(
    officeNumber,
  );

  await File(image.path).copy(
    destinationFile.path,
  );

  return destinationFile;

}
  // ======================================
// PICK FROM GALLERY
// ======================================

Future<File?> pickFromGallery(
  String officeNumber,
) async {

  final XFile? image = await _picker.pickImage(

    source: ImageSource.gallery,

    imageQuality: 85,

  );

  if (image == null) {

    return null;

  }

  final destinationFile =
      await createPhotoFile(
    officeNumber,
  );

  await File(image.path).copy(
    destinationFile.path,
  );

  return destinationFile;

}

}