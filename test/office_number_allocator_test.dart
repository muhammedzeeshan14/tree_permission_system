import 'package:flutter_test/flutter_test.dart';
import 'package:tree_permission_system/services/office_number_allocator.dart';

void main() {
  test('stale or absent counter starts above completed and current records', () async {
    for (final initial in <int?>[null, 0, 5, 700]) {
      int? counter = initial;
      final result = await OfficeNumberAllocator.reserve(
        highestSaved: () async => OfficeNumberAllocator.highest([
          'MYS/RFO/2025/450', 'MYS/RFO/2026/32', 'MYS/RFO/2026/19']),
        readCounter: () async => counter,
        compareAndSet: (expected, next) async { counter = next; return true; },
      );
      expect(result, initial == 700 ? 701 : 451);
    }
  });
  test('concurrent devices reserve different numbers', () async {
    int? counter = 0;
    Future<int> reserve() => OfficeNumberAllocator.reserve(
      highestSaved: () async => 120,
      readCounter: () async => counter,
      compareAndSet: (expected, next) async {
        if (counter != expected) return false;
        counter = next;
        return true;
      },
    );
    final values = await Future.wait(List.generate(10, (_) => reserve()));
    expect(values.toSet().length, 10);
    expect(values.toSet(), Set.from(List.generate(10, (i) => 121 + i)));
  });
  test('cloud error cannot issue a local number', () async {
    await expectLater(OfficeNumberAllocator.reserve(
      highestSaved: () async => throw StateError('Network unavailable'),
      readCounter: () async => 0,
      compareAndSet: (_, next) async => true,
    ), throwsStateError);
  });
  test('contention exhaustion cannot issue an unreserved number', () async {
    await expectLater(OfficeNumberAllocator.reserve(
      highestSaved: () async => 500,
      readCounter: () async => 0,
      compareAndSet: (_, next) async => false,
    ), throwsStateError);
  });
}
