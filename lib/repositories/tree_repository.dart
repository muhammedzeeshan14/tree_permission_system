import 'package:sqflite/sqflite.dart';

import '../models/tree_model.dart';
import 'master_repository.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';

class TreeRepository {
  Future<Database> get _db async =>
      await DatabaseHelper.instance.database;

  // A missing recommendation or an empty application never qualifies.
  static bool hasOnlyBranchRecommendations(
    List<TreeModel> trees, List<Map<String, dynamic>> recommendations, {bool allowNotRecommended = false}
  ) {
    final eligibleIds = recommendations.where((row) {
      final code = row['code']?.toString().trim().toUpperCase() ?? '';
      return code.isNotEmpty && code != 'NR' && code != 'FULL';
    }).map((row) => row['id']).toSet();
    final notRecommendedIds = recommendations.where((row) =>
        row['code']?.toString().trim().toUpperCase() == 'NR').map((row) => row['id']).toSet();
    return trees.any((tree) => eligibleIds.contains(tree.recommendationTypeId)) &&
        trees.every((tree) => eligibleIds.contains(tree.recommendationTypeId) ||
            (allowNotRecommended && notRecommendedIds.contains(tree.recommendationTypeId)));
  }

  Future<bool> areAllTreesBranchOnly(int applicationId) async {
    final applications = await (await _db).query('applications',columns:['applicationType'],where:'id=?',whereArgs:[applicationId]);
    final isPrivateLand = applications.isNotEmpty && applications.single['applicationType']?.toString().trim().toUpperCase() == 'PL';
    return hasOnlyBranchRecommendations(await getTrees(applicationId),
        await MasterRepository().getMasters('Recommendation Type'), allowNotRecommended:isPrivateLand);
  }

  // Insert Tree
  Future<int> insertTree(TreeModel tree) async {
    final db = await _db;
    final map = SyncService.withSyncStamp(tree.toMap());
    final id = await db.insert(
      'trees',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await SyncService.instance.markDirty(
      tableName: 'trees',
      localId: id,
    );
    return id;
  }

  // Update Tree
  Future<int> updateTree(TreeModel tree) async {
    final db = await _db;

    final result = await db.update(
      'trees',
      SyncService.withSyncStamp(tree.toMap()),
      where: 'id=?',
      whereArgs: [tree.id],
    );
    if (tree.id != null) {
      await SyncService.instance.markDirty(
        tableName: 'trees',
        localId: tree.id!,
      );
    }
    return result;
  }

  // Delete Tree
  Future<int> deleteTree(int id) async {
    final db = await _db;

    final result = await db.delete(
      'trees',
      where: 'id=?',
      whereArgs: [id],
    );
    await SyncService.instance.markDirty(
      tableName: 'trees',
      localId: id,
      operation: 'delete',
    );
    return result;
  }

  // Get Trees of one Application
  Future<List<TreeModel>> getTrees(
      int applicationId) async {
    final db = await _db;

    final result = await db.query(
      'trees',
      where: 'applicationId=?',
      whereArgs: [applicationId],
      orderBy: 'baseTreeNumber, stemSequence',
    );

    return result
        .map((e) => TreeModel.fromMap(e))
        .toList();
  }

  // Total Trees (Every Stem Counts)
  Future<int> getTreeCount(
      int applicationId) async {
    final db = await _db;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*)
        FROM trees
        WHERE applicationId=?
        ''',
        [applicationId],
      ),
    );

    return result ?? 0;
  }

  // Get Last Tree
  Future<TreeModel?> getLastTree(
      int applicationId) async {
    final db = await _db;

    final result = await db.query(
      'trees',
      where: 'applicationId=?',
      whereArgs: [applicationId],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    return TreeModel.fromMap(result.first);
  }
  // Total Trees Alias
Future<int> totalTrees(
  int applicationId,
) async {
  return await getTreeCount(applicationId);
}

Future<bool> areAllTreesNotRecommended(
  int applicationId,
) async {
  final db = await _db;

  final result = await db.rawQuery(
    '''
    SELECT
      COUNT(*) AS totalCount,
      SUM(
        CASE
          WHEN UPPER(TRIM(m.code)) = 'NR' THEN 1
          ELSE 0
        END
      ) AS notRecommendedCount
    FROM trees t
    LEFT JOIN master_data m
      ON m.id = t.recommendationTypeId
    WHERE t.applicationId = ?
    ''',
    [applicationId],
  );

  if (result.isEmpty) {
    return false;
  }

  final totalCount =
      (result.first['totalCount'] as num?)?.toInt() ?? 0;

  final notRecommendedCount =
      (result.first['notRecommendedCount'] as num?)
              ?.toInt() ??
          0;

  // Empty tree lists must not be treated as
  // "all trees not recommended".
  return totalCount > 0 &&
      totalCount == notRecommendedCount;
}

}