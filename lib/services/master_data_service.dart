import '../repositories/master_repository.dart';

class MasterDataService {

  MasterDataService._();

  static final MasterDataService instance =
      MasterDataService._();

  List<Map<String, dynamic>> species = [];

  List<Map<String, dynamic>> problems = [];

  List<Map<String, dynamic>> recommendations = [];

  List<Map<String, dynamic>> purposes = [];

  List<Map<String, dynamic>> returnReasons = [];

  List<Map<String, dynamic>> deferredReasons = [];

  Future<void> loadMasters() async {

    final repo = MasterRepository();

    species =
        await repo.getSpecies();

    problems =
        await repo.getMasters(
            "Problem");

    recommendations =
        await repo.getMasters(
            "Recommendation");

    purposes =
        await repo.getMasters(
            "Purpose");

    returnReasons =
        await repo.getMasters(
            "Return Reason");

    deferredReasons =
        await repo.getMasters(
            "Inspection Deferred Reason");

  }

}