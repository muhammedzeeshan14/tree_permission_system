import '../repositories/application_repository.dart';

class GPSRepository {
  Future<void> saveGPS({
    required int applicationId,
    required String gps,
  }) async {
    final repo = ApplicationRepository();

    final app = await repo.getById(applicationId);

    if (app == null) return;

    app.gpsCoordinates = gps;

    await repo.updateApplication(app);
  }
}