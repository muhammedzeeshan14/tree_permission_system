import 'package:flutter_test/flutter_test.dart';
import 'package:tree_permission_system/services/rfo_approval_validation.dart';

void main() {
  test('summary can advance without approval categories', () {
    expect(RfoApprovalValidation.error([], {}, {}), isNull);
  });
  test('each category and every individual tree needs a decision', () {
    for (final key in ['APPLICATION_TYPE_0', 'GPS_0', 'PHOTOS_0', 'DOCUMENTS_0',
      'TREE_42', 'TREE_COUNT_0', 'REVENUE_OPINION_0', 'MAHAZAR_0', 'OVERALL_REMARK_0', 'DEFERRED_0']) {
      expect(RfoApprovalValidation.error([key], {}, {}), isNotNull);
      expect(RfoApprovalValidation.error([key], {key: 'Approve'}, {}), isNull);
      expect(RfoApprovalValidation.error([key], {key: 'Modify'}, {}), isNull);
      expect(RfoApprovalValidation.error([key], {key: 'Re-inspect'}, {}), isNotNull);
      expect(RfoApprovalValidation.error([key], {key: 'Re-inspect'}, {key: 'Check again'}), isNull);
    }
    expect(RfoApprovalValidation.error(['TREE_1', 'TREE_2'], {'TREE_1': 'Approve'}, {}), isNotNull);
  });
}
