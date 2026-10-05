import '../database/database_helper.dart';
import 'office_number_allocator.dart';
import 'online_mode.dart';
import 'supabase_service.dart';

class OfficeNumberService {
  OfficeNumberService._();
  static int _localLast = 0;

  static Future<String> nextOfficeNumber() async {
    final number = OnlineMode.enabled ? await _nextOnline() : await _nextLocal();
    return 'MYS/RFO/${DateTime.now().year}/$number';
  }

  static Future<int> _nextOnline() async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Cloud connection required to reserve an office number.');
    // The database atomically advances above every saved number, including
    // completed applications. Never use a device-local fallback in cloud mode.
    final result = await client.rpc('reserve_tpms_office_number');
    if (result is! num || result <= 0 || result != result.toInt()) {
      throw StateError('Cloud office-number reservation returned an invalid number.');
    }
    return result.toInt();
  }

  static Future<int> _nextLocal() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('applications', columns: ['officeNumber']);
    final highest = OfficeNumberAllocator.highest(rows.map((r) => r['officeNumber']?.toString() ?? ''));
    _localLast = (_localLast > highest ? _localLast : highest) + 1;
    return _localLast;
  }
}
