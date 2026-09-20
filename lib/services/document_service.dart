import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class DocumentService {

  Future<Directory> getApplicationFolder(
      String officeNumber) async {

    final base =
        await getApplicationDocumentsDirectory();

    final folder = Directory(
      "${base.path}/TPMS/Documents/$officeNumber",
    );

    if (!await folder.exists()) {

      await folder.create(
        recursive: true,
      );

    }

    return folder;

  }

  Future<File?> pickDocument(
      String officeNumber) async {

    FilePickerResult? result =
        await FilePicker.platform.pickFiles();

    if (result == null) {

      return null;

    }

    final folder =
        await getApplicationFolder(
      officeNumber,
    );

    final source =
        File(result.files.single.path!);

    final destination = File(

      "${folder.path}/${result.files.single.name}",

    );

    await source.copy(destination.path);

    return destination;

  }

}