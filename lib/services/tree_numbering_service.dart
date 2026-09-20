import '../models/tree_model.dart';
import '../repositories/tree_repository.dart';

class TreeNumberingService {
  final TreeRepository _repository = TreeRepository();

  /// --------------------------------------------------------
  /// NEXT NEW TREE
  /// --------------------------------------------------------
  Future<Map<String, dynamic>> nextTree(
      int applicationId) async {

    final List<TreeModel> trees =
        await _repository.getTrees(applicationId);

    int maxBaseTree = 0;

    for (final tree in trees) {
      if (tree.baseTreeNumber > maxBaseTree) {
        maxBaseTree = tree.baseTreeNumber;
      }
    }

    final int nextBase = maxBaseTree + 1;

    return {
      "treeNumber": nextBase.toString(),
      "baseTreeNumber": nextBase,
      "stemLetter": "",
    };
  }

  /// --------------------------------------------------------
  /// NEXT STEM
  /// --------------------------------------------------------
  Future<Map<String, dynamic>> nextStem(
    int applicationId,
    int baseTreeNumber,
    String currentStemLetter,
  ) async {
    final List<TreeModel> trees =
        await _repository.getTrees(applicationId);

    int highestLetter = 64; // before 'A'

    for (final tree in trees) {
      if (tree.baseTreeNumber == baseTreeNumber &&
          tree.stemLetter.isNotEmpty) {
        final code = tree.stemLetter.codeUnitAt(0);
        if (code > highestLetter) {
          highestLetter = code;
        }
      }
    }

    final String nextLetter =
        String.fromCharCode(highestLetter + 1);

    return {
      "treeNumber": "$baseTreeNumber$nextLetter",
      "baseTreeNumber": baseTreeNumber,
      "stemLetter": nextLetter,
    };
  }

  /// --------------------------------------------------------
  /// TOTAL TREES
  /// --------------------------------------------------------
  Future<int> totalTrees(
      int applicationId) async {
    return await _repository.getTreeCount(
      applicationId,
    );
  }
}