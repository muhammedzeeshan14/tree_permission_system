import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tree_permission_system/repositories/inspection_defer_reason_repository.dart';
import 'package:tree_permission_system/services/deferred_reason_labels.dart';

void main() {
  late Database db;
  late InspectionDeferredReasonRepository repo;
  setUp(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      'CREATE TABLE master_data(id INTEGER PRIMARY KEY,masterType TEXT,value TEXT,kannadaName TEXT)',
    );
    await db.execute(
      'CREATE TABLE inspection_deferred_reasons(id INTEGER PRIMARY KEY AUTOINCREMENT,applicationId INTEGER,reasonId INTEGER,reasonName TEXT,displayOrder INTEGER)',
    );
    for (final row in [
      {
        'id': 46,
        'masterType': 'Inspection Deferred Reason',
        'value': 'Applicant Not Available',
        'kannadaName': 'ಅರ್ಜಿದಾರರು ಲಭ್ಯವಿಲ್ಲ',
      },
      {
        'id': 47,
        'masterType': 'Inspection Deferred Reason',
        'value': 'Site Not Traceable',
        'kannadaName': 'ಸ್ಥಳ ಪತ್ತೆಯಾಗಿಲ್ಲ',
      },
      {
        'id': 49,
        'masterType': 'Inspection Deferred Reason',
        'value': 'Wrong Location',
        'kannadaName': 'ತಪ್ಪು ಸ್ಥಳ',
      },
      {
        'id': 19,
        'masterType': 'Tree Status',
        'value': 'Dangerous',
        'kannadaName': 'ಅಪಾಯಕರ',
      },
    ]) {
      await db.insert('master_data', row);
    }
    repo = InspectionDeferredReasonRepository(databaseOverride: db);
  });
  tearDown(() async => db.close());
  test(
    'Selected master IDs survive a saved-row resave and reopening',
    () async {
      await repo.saveReasons(
        applicationId: 1,
        reasons: [
          {'id': 47},
          {'id': 49},
        ],
      );
      final saved = await repo.getReasons(1);
      expect(saved.first['id'], isNot(47));
      await repo.saveReasons(applicationId: 1, reasons: saved);
      expect(await repo.getReasonIds(1), [47, 49]);
      expect(
        deferredReasonSummary(await repo.getReasons(1)),
        contains('Site Not Traceable'),
      );
    },
  );
  test(
    'Empty or stale saved display names resolve from current master',
    () async {
      await db.insert('inspection_deferred_reasons', {
        'applicationId': 1,
        'reasonId': 47,
        'reasonName': '',
        'displayOrder': 1,
      });
      var rows = await repo.getReasons(1);
      expect(rows.single['reasonName'], 'Site Not Traceable');
      expect(deferredReasonDocumentText(rows), 'ಸ್ಥಳ ಪತ್ತೆಯಾಗಿಲ್ಲ');
      await db.update('master_data', {
        'value': 'Updated screen title',
        'kannadaName': 'Custom entered print text',
      }, where: 'id=47');
      rows = await repo.getReasons(1);
      expect(rows.single['reasonName'], 'Updated screen title');
      expect(deferredReasonDocumentText(rows), 'Custom entered print text');
    },
  );
  test(
    'All selected reasons print in order for DRFO and RFO formatting',
    () async {
      await repo.saveReasons(
        applicationId: 1,
        reasons: [
          {'id': 46},
          {'id': 47},
          {'id': 49},
        ],
      );
      final rows = await repo.getReasons(1);
      expect(
        deferredReasonDocumentText(rows),
        'ಅರ್ಜಿದಾರರು ಲಭ್ಯವಿಲ್ಲ, ಸ್ಥಳ ಪತ್ತೆಯಾಗಿಲ್ಲ ಮತ್ತು ತಪ್ಪು ಸ್ಥಳ',
      );
      expect(
        deferredReasonDocumentText(rows, commaSeparated: true),
        'ಅರ್ಜಿದಾರರು ಲಭ್ಯವಿಲ್ಲ, ಸ್ಥಳ ಪತ್ತೆಯಾಗಿಲ್ಲ, ತಪ್ಪು ಸ್ಥಳ',
      );
    },
  );
  test(
    'Wrong master or duplicate selection cannot replace valid saved reasons',
    () async {
      await repo.saveReasons(
        applicationId: 1,
        reasons: [
          {'id': 47},
        ],
      );
      await expectLater(
        repo.saveReasons(
          applicationId: 1,
          reasons: [
            {'id': 19},
          ],
        ),
        throwsStateError,
      );
      await expectLater(
        repo.saveReasons(
          applicationId: 1,
          reasons: [
            {'id': 47},
            {'id': 47},
          ],
        ),
        throwsStateError,
      );
      expect(await repo.getReasonIds(1), [47]);
    },
  );
  test(
    'Historical invalid IDs show a repair message and never print another master text',
    () async {
      await db.insert('inspection_deferred_reasons', {
        'applicationId': 1,
        'reasonId': 19,
        'reasonName': 'Dangerous',
        'displayOrder': 1,
      });
      final rows = await repo.getReasons(1);
      expect(deferredReasonSummary(rows), contains('unavailable'));
      expect(deferredReasonSummary(rows), isNot(contains('Dangerous')));
      expect(() => deferredReasonDocumentText(rows), throwsStateError);
      expect(await repo.getReasonIds(1), isEmpty);
    },
  );
  test('Missing print text does not silently use English or a dash', () async {
    await repo.saveReasons(
      applicationId: 1,
      reasons: [
        {'id': 47},
      ],
    );
    await db.update('master_data', {'kannadaName': ''}, where: 'id=47');
    final rows = await repo.getReasons(1);
    expect(() => deferredReasonDocumentText(rows), throwsStateError);
    await repo.deleteReasons(1);
    expect(await repo.getReasons(1), isEmpty);
    expect(() => deferredReasonDocumentText([]), throwsStateError);
  });
}
