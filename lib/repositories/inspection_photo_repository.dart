import '../models/photo_model.dart';
import 'photo_repository.dart';

/// Legacy map API shares the exact upload/download path used by inspection views.
class InspectionPhotoRepository {
  final _repository = PhotoRepository();
  Future<List<Map<String, dynamic>>> getPhotos(int applicationId) async =>
      (await _repository.getPhotos(applicationId)).map((p) => <String, dynamic>{
        'id': p.id, 'applicationId': p.applicationId, 'photoPath': p.photoPath,
        'sourcePath': p.storedPath, 'attachmentError': p.attachmentError,
        'caption': p.caption, 'createdDate': p.createdDate,
      }).toList();
  Future<int> insertPhoto(Map<String, dynamic> data) async {
    final item = PhotoModel(applicationId: (data['applicationId'] as num).toInt(),
      photoPath: data['photoPath']?.toString() ?? '', caption: data['caption']?.toString() ?? '',
      createdDate: data['createdDate']?.toString() ?? '');
    await _repository.savePhoto(item);
    return item.id!;
  }
  Future<void> deletePhoto(int id) => _repository.deletePhoto(id);
}
