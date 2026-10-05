/// Reserves above both the shared counter and every saved application.
/// compareAndSet must be atomic; false means another device won the race.
class OfficeNumberAllocator {
  static Future<int> reserve({
    required Future<int> Function() highestSaved,
    required Future<int?> Function() readCounter,
    required Future<bool> Function(int? expected, int next) compareAndSet,
  }) async {
    final highest = await highestSaved();
    for (var attempt = 0; attempt < 20; attempt++) {
      final current = await readCounter();
      final next = ((current ?? 0) > highest ? current! : highest) + 1;
      if (await compareAndSet(current, next)) return next;
    }
    throw StateError('Office number could not be reserved. Please retry.');
  }

  static int highest(Iterable<String> numbers) => numbers.fold<int>(0,
      (max, text) {
        final number = int.tryParse(text.trim().split('/').last) ?? 0;
        return number > max ? number : max;
      });
}
