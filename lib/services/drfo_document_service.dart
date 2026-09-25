import '../models/revenue_reply_model.dart';
import '../models/government_approval_model.dart';
import '../repositories/government_approval_repository.dart';
import '../repositories/officer_repository.dart';
import '../repositories/application_repository.dart';
import '../repositories/revenue_reply_repository.dart';
import '../repositories/tree_officer_repository.dart';
import '../repositories/rfo_item_approval_repository.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../models/application_model.dart';
import '../models/application_reference_model.dart';
import '../database/database_helper.dart';
import '../repositories/application_type_repository.dart';
import '../repositories/mahazar_repository.dart';
import '../repositories/tree_repository.dart';
import '../repositories/tree_count_detail_repository.dart';
import '../repositories/tree_count_site_repository.dart';
import '../repositories/master_repository.dart';
import '../repositories/inspection_defer_reason_repository.dart';
import '../repositories/office_configuration_repository.dart';
import '../repositories/pole_rate_repository.dart';
import '../repositories/application_revenue_opinion_repository.dart';
import '../repositories/revenue_opinion_repository.dart';
import '../repositories/application_verification_repository.dart';
import '../repositories/tree_verification_repository.dart';
import '../repositories/mahazar_verification_repository.dart';
import '../repositories/rfo_deferred_letter_recipient_repository.dart';
import 'forwarded_address_service.dart';
import 'cloud_file_service.dart';

class _RtcTreeTableRow {
  final int serialNumber;
  final String applicantName;
  final String siteDetails;
  final List<String> speciesNames;
  final List<int> treeCounts;

  const _RtcTreeTableRow({
    required this.serialNumber,
    required this.applicantName,
    required this.siteDetails,
    required this.speciesNames,
    required this.treeCounts,
  });
}

class _NotRecommendedTreeTableRow {
  final int serialNumber;
  final String applicantAndLocation;
  final String speciesName;
  final String reasonNames;

  const _NotRecommendedTreeTableRow({
    required this.serialNumber,
    required this.applicantAndLocation,
    required this.speciesName,
    required this.reasonNames,
  });
}

class _GlTreeEnumerationRow {
  final int serialNumber;
  final String treeNumber;
  final String speciesName;

  final String gbh;
  final String height;

  final bool mergeGbhAndHeight;
  final String mergedMeasurement;

  final String timberVolume;
  final String poleCount;
  final String firewood;

  final String timberValue;
  final String poleValue;
  final String firewoodValue;
  final String totalValue;

  final String recommendationDetails;
  final String recommendationReason;

  final double timberVolumeNumber;
  final int poleCountNumber;
  final double firewoodNumber;
  final double timberValueNumber;
  final double poleValueNumber;
  final double firewoodValueNumber;
  final double totalValueNumber;

  const _GlTreeEnumerationRow({
    required this.serialNumber,
    required this.treeNumber,
    required this.speciesName,
    required this.gbh,
    required this.height,
    required this.mergeGbhAndHeight,
    required this.mergedMeasurement,
    required this.timberVolume,
    required this.poleCount,
    required this.firewood,
    required this.timberValue,
    required this.poleValue,
    required this.firewoodValue,
    required this.totalValue,
    required this.recommendationDetails,
    this.recommendationReason = '',
    required this.timberVolumeNumber,
    required this.poleCountNumber,
    required this.firewoodNumber,
    required this.timberValueNumber,
    required this.poleValueNumber,
    required this.firewoodValueNumber,
    required this.totalValueNumber,
  });
}

class _RfoLetterheadData {
  final String letterNumber;
  final String rangeName;
  final String rangeLocation;
  final String rangeOfficeAddress;
  final String rangeEmail;
  final String logoPath;
  final String approvalDate;
  final String? doSenderName;
  final String doSenderAddress;

  const _RfoLetterheadData({
    required this.letterNumber,
    required this.rangeName,
    required this.rangeLocation,
    required this.rangeOfficeAddress,
    required this.rangeEmail,
    required this.logoPath,
    required this.approvalDate,
    this.doSenderName,
    this.doSenderAddress = '',
  });
}

class DrfoDocumentService {
  // ==========================================================
  // LAND TYPE
  // ==========================================================

  String getLandType(ApplicationModel application) {
    final type = application.applicationType.trim().toUpperCase();

    switch (type) {
      case 'PL':
      case 'SPL':
        return 'ಖಾಸಗಿ ಜಾಗ';

      case 'GL':
      case 'STGL':
      case 'CGL':
      case 'SGL':
      case 'MCC':
        return 'ಸರ್ಕಾರಿ ಜಾಗ';

      default:
        return 'ಸರ್ಕಾರಿ ಜಾಗ';
    }
  }

  // ==========================================================
  // CONSTANTS
  // ==========================================================

  static const String _fontFamily = 'TPMSKannada';

  static bool _fontLoaded = false;

  // Render at high resolution so printed PDF remains sharp.
  static const double _scale = 3.0;

  static const double _pageWidth = 595.28;
  static const double _pageHeight = 841.89;

  static const double _leftMargin = 65;
  static const double _rightMargin = 55;
  static const double _topMargin = 55;
  static const double _bottomMargin = 55;

  // ==========================================================
  // LOAD KANNADA FONT INTO FLUTTER TEXT ENGINE
  // ==========================================================

  Future<void> _loadFlutterKannadaFont() async {
    if (_fontLoaded) return;

    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansKannada-Regular.ttf',
    );

    await ui.loadFontFromList(
      fontData.buffer.asUint8List(),
      fontFamily: _fontFamily,
    );

    _fontLoaded = true;

    print(
      'TPMS KANNADA FONT LOADED INTO FLUTTER ENGINE: '
      '${fontData.lengthInBytes} bytes',
    );
  }

  // ==========================================================
  // LOAD TEMPLATE
  // ==========================================================

  Future<String> _loadTemplate(String templateName) async {
    return await rootBundle.loadString('assets/templates/drfo/$templateName');
  }

  Future<String> _loadRfoTemplate(String templateName) async {
    return await rootBundle.loadString('assets/templates/rfo/$templateName');
  }

  // ==========================================================
  // PLACEHOLDER REPLACEMENT
  // ==========================================================

  String _replace(String template, String placeholder, String value) {
    return template.replaceAll(placeholder, value);
  }

  // ==========================================================
  // SAFE TEXT
  // ==========================================================

  String _safeText(String value) {
    try {
      return String.fromCharCodes(value.runes);
    } catch (_) {
      return value;
    }
  }

  // ==========================================================
  // PRINT NAMES: English in app, Kannada in letters.
  // Falls back to the saved English name when Kannada is blank.
  // ==========================================================

  Future<String> _printSectionName(
    ApplicationModel application,
  ) async {
    try {
      final id = application.sectionId;
      if (id != null) {
        final db = await DatabaseHelper.instance.database;
        final rows = await db.query(
          'section_master',
          where: 'id=?',
          whereArgs: [id],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final kannada =
              rows.first['kannadaName']?.toString().trim() ?? '';
          if (kannada.isNotEmpty) return _safeText(kannada);
        }
      }
    } catch (_) {
      // Fall through to English name.
    }
    return _safeText(application.section);
  }

  Future<String> _printBeatName(
    ApplicationModel application,
  ) async {
    try {
      final id = application.beatId;
      if (id != null) {
        final db = await DatabaseHelper.instance.database;
        final rows = await db.query(
          'beat_master',
          where: 'id=?',
          whereArgs: [id],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final kannada =
              rows.first['kannadaName']?.toString().trim() ?? '';
          if (kannada.isNotEmpty) return _safeText(kannada);
        }
      }
    } catch (_) {
      // Fall through to English name.
    }
    return _safeText(application.beat);
  }

  // ==========================================================
  // DATE FORMAT
  // ==========================================================

  String _date(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';

    try {
      final date = DateTime.parse(text);

      // Letter/list date format: dd-MM-yyyy.
      return '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.year}';
    } catch (_) {
      return text.replaceAll('/', '-');
    }
  }

  // ==========================================================
  // TREE / LAND LOCATION
  // ==========================================================

  String _location(ApplicationModel application) {
    if (application.treeLocationSame) {
      return application.applicantAddress;
    }

    return application.treeLocationAddress;
  }

  // ==========================================================
  // BUILD MASTER WITH APPLICATION DATA
  // ==========================================================

  // ==========================================================
  // BUILD FORWARDING REFERENCES
  // ==========================================================

  /// Government-agency placeholder value. MCC applications use the
  /// Kannada name of the MCC application type from its master instead
  /// of a government agency (which MCC hides).
  Future<String> _governmentAgencyKannadaFor(
    ApplicationModel application,
  ) async {
    if (application.applicationType.trim().toUpperCase() == 'MCC') {
      final kannada =
          await ApplicationTypeRepository().getKannadaName('MCC');
      if (kannada.isNotEmpty) return kannada;
    }
    return _masterKannadaName(
      MasterRepository(),
      application.governmentAgencyId,
    );
  }

  /// "(ಈ ಕಛೇರಿ ಸ್ವೀಕೃತಿ ದಿನಾಂಕ: <date>)" suffix for references
  /// that carry a received date.
  String _receivedSuffix(ApplicationReferenceModel ref) {
    final received = ref.receivedDate.trim();
    if (received.isEmpty) return '';
    return ' (ಈ ಕಛೇರಿ ಸ್ವೀಕೃತಿ ದಿನಾಂಕ: ${_date(received)})';
  }

  String _buildForwardedReference(
    ApplicationModel application, {
    int startNumber = 2,
  }) {
    final lines = <String>[];

    int number = startNumber;

    // --------------------------------------------------------
    // REFERENCES ENTERED BY CASE WORKER
    // --------------------------------------------------------

    for (final ref in application.forwardingReferences) {
      final sourceName = ref.forwardedBy.trim();

      final referenceNumber = ref.referenceNumber.trim();

      final referenceDate = ref.referenceDate.trim();

      // Ignore incomplete references.
      if (sourceName.isEmpty &&
          referenceNumber.isEmpty &&
          referenceDate.isEmpty) {
        continue;
      }

      String line = '$number. ';

      if (sourceName.isNotEmpty) {
        line += '$sourceName ರವರ ಕಛೇರಿ ಪತ್ರ';
      }

      if (referenceNumber.isNotEmpty) {
        if (sourceName.isNotEmpty) {
          line += ' ಸಂಖ್ಯೆ ';
        } else {
          line += 'ಕಛೇರಿ ಪತ್ರ ಸಂಖ್ಯೆ ';
        }

        line += referenceNumber;
      }

      if (referenceDate.isNotEmpty) {
        line += ', ದಿನಾಂಕ: ${_date(referenceDate)}';
      }

      line += _receivedSuffix(ref);

      lines.add(line);

      number++;
    }

    // --------------------------------------------------------
    // RFO ORDER DATE
    // --------------------------------------------------------

    final forwardingDate = application.drfoAssignmentDate.trim();

    if (forwardingDate.isNotEmpty) {
      lines.add(
        '$number. ತಮ್ಮ ಆದೇಶ ದಿನಾಂಕ: '
        '${_date(forwardingDate)}',
      );
    }

    return lines.join('\n');
  }

  String _rfoForwardedReferenceOfficer(ApplicationModel application) {
    for (final reference in application.forwardingReferences) {
      final officer = reference.forwardedBy.trim();

      if (officer.isNotEmpty) {
        return officer;
      }
    }

    return "";
  }

  Future<String> _rfoForwardedRecipientAddress(ApplicationModel application) async {
    for (final reference in application.forwardingReferences) {
      if (reference.forwardedBy.trim().isNotEmpty) {
        try {
          return await ForwardedAddressService.toAddress(
            kind: reference.sourceKind,
            sourceId: reference.sourceId,
            fallback: reference.forwardedBy.trim(),
          );
        } catch (_) {
          return reference.forwardedBy.trim();
        }
      }
    }
    return '';
  }

  Future<String> _buildRfoRtcReferences(ApplicationModel application) async {
    final lines = <String>[];

    final recipient = _rfoForwardedReferenceOfficer(application);

    final validReferences = application.forwardingReferences.where((reference) {
      return reference.forwardedBy.trim().isNotEmpty ||
          reference.referenceNumber.trim().isNotEmpty ||
          reference.referenceDate.trim().isNotEmpty;
    }).toList();

    if (validReferences.isNotEmpty) {
      final reference = validReferences.first;

      final forwardedBy = reference.forwardedBy.trim();

      final isSameAsRecipient =
          recipient.isNotEmpty &&
          forwardedBy.toLowerCase() == recipient.toLowerCase();

      String firstLine = "1. ";

      if (isSameAsRecipient) {
        firstLine += "ತಮ್ಮ ಕಛೇರಿ ಪತ್ರ";
      } else if (forwardedBy.isNotEmpty) {
        firstLine += "$forwardedBy ರವರ ಕಛೇರಿ ಪತ್ರ";
      } else {
        firstLine += "ಕಛೇರಿ ಪತ್ರ";
      }

      if (reference.referenceNumber.trim().isNotEmpty) {
        firstLine += " ಸಂಖ್ಯೆ ${reference.referenceNumber.trim()}";
      }

      if (reference.referenceDate.trim().isNotEmpty) {
        firstLine += ", ದಿನಾಂಕ: ${_date(reference.referenceDate.trim())}";
      }

      firstLine += _receivedSuffix(reference);

      lines.add(firstLine);
    }

    final section = await _printSectionName(application);

    final drfoReportDate = _date(application.drfoInspectionDate.trim());

    lines.add(
      "${lines.length + 1}. ಉಪ ವಲಯ ಅರಣ್ಯಾಧಿಕಾರಿ -ವ- ಮೋಜಣಿದಾರರು, "
      "$section ಶಾಖೆ ರವರ ವರದಿ ದಿನಾಂಕ: "
      "$drfoReportDate",
    );

    return lines.join("\n");
  }

  Future<String> _buildRfoNonRtcDeferredReferences({
    required ApplicationModel application,
    required RfoDeferredLetterRecipient primaryRecipient,
  }) async {
    final lines = <String>[];

    final toApplicant = primaryRecipient.recipientKey == "APPLICANT";

    final applicationDate = _date(application.applicationDate);

    final receivedDate = _date(application.receivedDate);

    if (toApplicant) {
      String applicantReference =
          "1. ನಿಮ್ಮ ಮನವಿ ದಿನಾಂಕ: "
          "$applicationDate";

      if (receivedDate.isNotEmpty) {
        applicantReference +=
            " (ಈ ಕಛೇರಿ ಸ್ವೀಕೃತಿ ದಿನಾಂಕ: "
            "$receivedDate)";
      }

      lines.add(applicantReference);
    } else {
      lines.add(
        "1. ${application.applicantName}, "
        "${application.applicantAddress} "
        "ರವರ ಮನವಿ ದಿನಾಂಕ: $applicationDate",
      );
    }

    final isForwarded =
        application.applicationSource.trim().toUpperCase() == "FORWARDED";

    int referenceNumber = 2;

    if (isForwarded) {
      for (final reference in application.forwardingReferences) {
        final forwardedBy = reference.forwardedBy.trim();

        final letterNumber = reference.referenceNumber.trim();

        final letterDate = _date(reference.referenceDate.trim());

        if (forwardedBy.isEmpty && letterNumber.isEmpty && letterDate.isEmpty) {
          continue;
        }

        final isAddressedOffice =
            !toApplicant &&
            primaryRecipient.sourceId != null &&
            primaryRecipient.sourceId == reference.sourceId &&
            (primaryRecipient.sourceKind == reference.sourceKind);

        String line = "$referenceNumber. ";

        if (isAddressedOffice) {
          line += "ತಮ್ಮ ಕಛೇರಿ ಪತ್ರ ಸಂಖ್ಯೆ";
        } else if (forwardedBy.isNotEmpty) {
          line += "$forwardedBy ರವರ ಕಛೇರಿ ಪತ್ರ ಸಂಖ್ಯೆ";
        } else {
          line += "ಕಛೇರಿ ಪತ್ರ ಸಂಖ್ಯೆ";
        }

        if (letterNumber.isNotEmpty) {
          line += ": $letterNumber";
        }

        if (letterDate.isNotEmpty) {
          line += " ದಿನಾಂಕ: $letterDate";
        }

        line += _receivedSuffix(reference);

        lines.add(line);
        referenceNumber++;
      }
    }

    final section = await _printSectionName(application);

    final drfoReportDate = _date(application.drfoInspectionDate.trim());

    lines.add(
      "$referenceNumber. "
      "ಉಪ ವಲಯ ಅರಣ್ಯಾಧಿಕಾರಿ -ವ- ಮೋಜಣಿದಾರರು, "
      "$section ಶಾಖೆ ರವರ ವರದಿ ದಿನಾಂಕ: "
      "$drfoReportDate",
    );

    return lines.join("\n");
  }

  Future<String> _buildDeferredReasons(ApplicationModel application) async {
    if (application.id == null) {
      print('DEFERRED REASONS: Application ID is NULL');
      return '';
    }

    final repository = InspectionDeferredReasonRepository();

    final reasons = await repository.getReasons(application.id!);

    print('DEFERRED REASONS: Application ID = ${application.id}');

    print('DEFERRED REASONS: ROW COUNT = ${reasons.length}');

    for (final reason in reasons) {
      print('DEFERRED REASON ROW: $reason');
    }

    final names = reasons
        .map(
          (e) =>
              e["documentReasonName"]?.toString().trim() ??
              e["reasonName"]?.toString().trim() ??
              '',
        )
        .where((name) => name.isNotEmpty)
        .toList();

    print('DEFERRED REASONS NAMES = $names');

    if (names.isEmpty) {
      return '';
    }

    if (names.length == 1) {
      return names.first;
    }

    if (names.length == 2) {
      return '${names[0]} ಮತ್ತು ${names[1]}';
    }

    return '${names.sublist(0, names.length - 1).join(', ')} ಮತ್ತು ${names.last}';
  }

  // ==========================================================
  // BUILD RECOMMENDED REPORT MASTER
  // ==========================================================

  Future<List<_RtcTreeTableRow>> _buildRtcTreeTableRows(
    ApplicationModel application,
  ) async {
    if (application.id == null) {
      return [];
    }

    final sites = await TreeCountSiteRepository().getSites(application.id!);

    final speciesList = await MasterRepository().getSpecies();

    final speciesNames = <int, String>{
      for (final item in speciesList)
        item['id']
            as int: item['kannadaName']?.toString().trim().isNotEmpty == true
            ? item['kannadaName'].toString().trim()
            : item['value']?.toString().trim() ?? '',
    };

    final detailRepository = TreeCountDetailRepository();

    final rows = <_RtcTreeTableRow>[];

    for (int index = 0; index < sites.length; index++) {
      final site = sites[index];
      if (site.id == null) {
        continue;
      }

      final details = await detailRepository.getBySite(site.id!);

      final siteLocation = site.siteDetails.trim().isNotEmpty
          ? site.siteDetails
          : _location(application);

      rows.add(
        _RtcTreeTableRow(
          serialNumber: index + 1,
          applicantName: _safeText(application.applicantName),
          siteDetails: _safeText(siteLocation),
          speciesNames: details
              .map((detail) => speciesNames[detail.speciesId] ?? '')
              .toList(),
          treeCounts: details.map((detail) => detail.treeCount).toList(),
        ),
      );
    }

    return rows;
  }

  String _joinKannadaNames(List<String> names) {
    final values = names
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (values.isEmpty) {
      return '—';
    }

    if (values.length == 1) {
      return values.first;
    }

    if (values.length == 2) {
      return '${values[0]} ಮತ್ತು ${values[1]}';
    }

    return '${values.sublist(0, values.length - 1).join(', ')} '
        'ಮತ್ತು ${values.last}';
  }

  Future<List<_NotRecommendedTreeTableRow>> _buildNotRecommendedTreeTableRows(
    ApplicationModel application,
  ) async {
    if (application.id == null) {
      return [];
    }

    final trees = await TreeRepository().getTrees(application.id!);

    final masterRepository = MasterRepository();

    final speciesList = await masterRepository.getSpecies();

    final reasonList = await masterRepository.getMasters(
      'Recommendation Reason',
    );

    String kannadaName(Map<String, dynamic> item) {
      final name = item['kannadaName']?.toString().trim() ?? '';

      return name.isNotEmpty ? name : '';
    }

    final speciesNames = <int, String>{
      for (final item in speciesList) item['id'] as int: kannadaName(item),
    };

    final reasonNames = <int, String>{
      for (final item in reasonList) item['id'] as int: kannadaName(item),
    };

    final treeLocation = _location(application);

    final applicantAndLocation = [
      _safeText(application.applicantName),
      _safeText(treeLocation),
    ].where((value) => value.trim().isNotEmpty).join(', ');

    final rows = <_NotRecommendedTreeTableRow>[];

    for (int index = 0; index < trees.length; index++) {
      final tree = trees[index];

      final selectedReasons = tree.recommendationReasonIds
          .map((id) => reasonNames[id] ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      rows.add(
        _NotRecommendedTreeTableRow(
          serialNumber: index + 1,
          applicantAndLocation: applicantAndLocation,
          speciesName: speciesNames[tree.speciesId] ?? '—',
          reasonNames: _joinKannadaNames(selectedReasons),
        ),
      );
    }

    return rows;
  }

  Future<List<_GlTreeEnumerationRow>> _buildGlTreeEnumerationRows(
    ApplicationModel application, {bool rfoApprovedOnly = false}
  ) async {
    if (application.id == null) {
      return [];
    }

    final masterRepository = MasterRepository();

    final trees = await TreeRepository().getTrees(application.id!);

    final speciesList = await masterRepository.getSpecies();

    final recommendationTypes = await masterRepository.getMasters(
      'Recommendation Type',
    );

    final recommendationReasons = await masterRepository.getMasters(
      'Recommendation Reason',
    );

    final commonFirewoodRate = await masterRepository.getFirewoodRate() ?? 0;

    final poleRateRepository = PoleRateRepository();

    final poleSpeciesList = await masterRepository.getSpeciesByGroup('POLE');

    String normalizedSpeciesName(Map<String, dynamic>? item) {
      return item?['value']?.toString().trim().toUpperCase() ?? '';
    }

    final poleSpeciesByName = <String, Map<String, dynamic>>{};

    for (final poleSpecies in poleSpeciesList) {
      final name = normalizedSpeciesName(poleSpecies);

      if (name.isNotEmpty) {
        poleSpeciesByName.putIfAbsent(name, () => poleSpecies);
      }
    }

    final speciesById = <int, Map<String, dynamic>>{
      for (final item in speciesList) item['id'] as int: item,
    };

    final recommendationTypeById = <int, Map<String, dynamic>>{
      for (final item in recommendationTypes) item['id'] as int: item,
    };

    final reasonNameById = <int, String>{
      for (final item in recommendationReasons)
        item['id']
            as int: item['kannadaName']?.toString().trim().isNotEmpty == true
            ? item['kannadaName'].toString().trim()
            : item['value']?.toString().trim() ?? '',
    };

    const includedRecommendationCodes = <String>{
      'FULL',
      'BRANCH',
      'TWIG',
      'TOP',
    };

    final approvedIds = rfoApprovedOnly
        ? (await RfoItemApprovalRepository().getApplicationDecisions(application.id!))
            .where((row) => row['itemKey'] == 'TREE' && {'Approve', 'Modify'}.contains(row['decision']))
            .map((row) => row['itemId']).toSet()
        : <dynamic>{};
    final includedTrees = trees.where((tree) {
      final recommendation = recommendationTypeById[tree.recommendationTypeId];

      final code =
          recommendation?['code']?.toString().trim().toUpperCase() ?? '';

      return includedRecommendationCodes.contains(code) && (!rfoApprovedOnly || approvedIds.contains(tree.id));
    }).toList();

    final moneyFormat = NumberFormat('#,##,##0.00', 'en_IN');

    final rows = <_GlTreeEnumerationRow>[];

    for (int index = 0; index < includedTrees.length; index++) {
      final tree = includedTrees[index];

      final species = speciesById[tree.speciesId];

      final recommendation = recommendationTypeById[tree.recommendationTypeId];

      final recommendationCode =
          recommendation?['code']?.toString().trim().toUpperCase() ?? '';

      final speciesName =
          species?['kannadaName']?.toString().trim().isNotEmpty == true
          ? species!['kannadaName'].toString().trim()
          : species?['value']?.toString().trim() ?? '—';

      final recommendationKannadaName =
          recommendation?['kannadaName']?.toString().trim().isNotEmpty == true
          ? recommendation!['kannadaName'].toString().trim()
          : recommendation?['value']?.toString().trim() ?? '';

      final reasonNames = tree.recommendationReasonIds
          .map((id) => reasonNameById[id] ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      final reasonText = _joinKannadaNames(reasonNames);

      String mergedMeasurement = '';

      if (recommendationCode == 'BRANCH') {
        final count = tree.numberOfBranches ?? 0;

        mergedMeasurement = count == 1
            ? '1 ಸಂಖ್ಯೆ ಕೊಂಬೆ'
            : '$count ಸಂಖ್ಯೆ ಕೊಂಬೆಗಳು';
      } else if (recommendationCode == 'TWIG') {
        final count = tree.numberOfTwigs ?? 0;

        mergedMeasurement = count == 1
            ? '1 ಸಂಖ್ಯೆ ಸಣ್ಣ ತುದಿ'
            : '$count ಸಂಖ್ಯೆ ಸಣ್ಣ ತುದಿಗಳು';
      } else if (recommendationCode == 'TOP') {
        mergedMeasurement = '20 ಅಡಿ ಮೇಲಿನ ಭಾಗ ಮಾತ್ರ';
      }

      final mergeGbhAndHeight =
          recommendationCode == 'BRANCH' ||
          recommendationCode == 'TWIG' ||
          recommendationCode == 'TOP';

      final gbh = tree.gbh ?? 0;
      final height = tree.height ?? 0;

      // ------------------------------------------------------
      // POLE RATE MATCHING
      // ------------------------------------------------------

      Map<String, dynamic>? matchingPoleRate;

      final selectedSpeciesName = normalizedSpeciesName(species);

      final poleSpecies = poleSpeciesByName[selectedSpeciesName];

      if (recommendationCode == 'FULL' &&
          !tree.notFitForTimber &&
          poleSpecies != null &&
          gbh > 0 &&
          height > 0) {
        final poleRates = await poleRateRepository.getRatesBySpecies(
          poleSpecies['id'] as int,
        );

        for (int rateIndex = 0; rateIndex < poleRates.length; rateIndex++) {
          final rate = poleRates[rateIndex];
          final isLastRate = rateIndex == poleRates.length - 1;

          final lengthFrom = (rate['lengthFrom'] as num?)?.toDouble() ?? 0;

          final lengthUpto =
              (rate['lengthUpto'] as num?)?.toDouble() ?? double.infinity;

          final girthFrom = (rate['girthFrom'] as num?)?.toDouble() ?? 0;

          final girthUpto =
              (rate['girthUpto'] as num?)?.toDouble() ?? double.infinity;

          final lengthMatches =
              height >= lengthFrom &&
              (height < lengthUpto || (isLastRate && height <= lengthUpto));

          final girthMatches =
              gbh >= girthFrom &&
              (gbh < girthUpto || (isLastRate && gbh <= girthUpto));

          if (lengthMatches && girthMatches) {
            matchingPoleRate = rate;
            break;
          }
        }
      }

      final isPole = matchingPoleRate != null;

      final poleCount = isPole ? 1 : 0;

      final poleValue = isPole
          ? (matchingPoleRate!['rate'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      double timberVolume = 0;

      if (recommendationCode == 'FULL' &&
          !isPole &&
          !tree.notFitForTimber &&
          gbh > 0 &&
          height > 0) {
        timberVolume = (gbh * gbh * height) / (4 * math.pi);
      }

      final timberRate =
          (species?['ratePerCubicMeter'] as num?)?.toDouble() ?? 0;

      final firewood = isPole ? 0.0 : tree.firewood;

      final double timberValue =
          isPole || tree.notFitForTimber || recommendationCode != 'FULL'
          ? 0.0
          : timberVolume * timberRate;

      final firewoodValue = firewood * commonFirewoodRate;

      final totalValue = timberValue + poleValue + firewoodValue;

      final recommendationLines = <String>[
        if (reasonText.isNotEmpty && reasonText != '—') reasonText,
        if (recommendationKannadaName.isNotEmpty) recommendationKannadaName,
        if (tree.notFitForTimber) 'ನಾಟಿಗಾಗಿ ಯೋಗ್ಯವಿಲ್ಲ',
      ];

      rows.add(
        _GlTreeEnumerationRow(
          serialNumber: index + 1,
          treeNumber: tree.treeNumber,
          speciesName: speciesName,
          gbh: recommendationCode == 'FULL' ? gbh.toStringAsFixed(2) : '',
          height: recommendationCode == 'FULL' ? height.toStringAsFixed(2) : '',
          mergeGbhAndHeight: mergeGbhAndHeight,
          mergedMeasurement: mergedMeasurement,
          timberVolume:
              isPole || tree.notFitForTimber || recommendationCode != 'FULL'
              ? '—'
              : timberVolume.toStringAsFixed(3),

          poleCount: isPole ? '1' : '—',

          firewood: isPole ? '—' : firewood.toStringAsFixed(2),

          timberValue:
              isPole || tree.notFitForTimber || recommendationCode != 'FULL'
              ? '—'
              : moneyFormat.format(timberValue),

          poleValue: isPole ? moneyFormat.format(poleValue) : '—',

          firewoodValue: isPole ? '—' : moneyFormat.format(firewoodValue),

          totalValue: moneyFormat.format(totalValue),

          recommendationDetails: recommendationLines.join('\n'),
          recommendationReason: reasonText,

          timberVolumeNumber: timberVolume,

          poleCountNumber: poleCount,

          firewoodNumber: firewood,

          timberValueNumber: timberValue,

          poleValueNumber: poleValue,

          firewoodValueNumber: firewoodValue,

          totalValueNumber: totalValue,
        ),
      );
    }

    return rows;
  }

  Future<String> _buildRecommendedReportMaster(
    String template,
    ApplicationModel application, {bool rfoApprovedOnly = false}
  ) async {
    final applicant = _safeText(application.applicantName);

    final address = _safeText(application.applicantAddress);

    final location = _safeText(_location(application));

    final section = _safeText(application.section);

    final remarks = application.drfoOverallRemarks.isNotEmpty
        ? _safeText(application.drfoOverallRemarks)
        : '';

    final officeConfiguration = await OfficeConfigurationRepository()
        .getConfiguration();

    final rangeName =
        officeConfiguration?["rangeName"]?.toString().trim().isNotEmpty == true
        ? officeConfiguration!["rangeName"].toString().trim()
        : 'ಮೈಸೂರು';

    final rangeLocation = rangeName;

    final masterRepository = MasterRepository();

    final urbanRuralKannada = await _masterKannadaName(
      masterRepository,
      application.urbanRuralId,
    );

    final governmentAgencyKannada =
        await _governmentAgencyKannadaFor(application);

    final structureTypeKannada = await _masterKannadaName(
      masterRepository,
      application.structureTypeId,
    );

    final purposeKannada = await _masterKannadaName(
      masterRepository,
      application.purposeId,
    );

    final whyRemovingItem = await masterRepository.getMasterById(
      application.whyRemovingId,
    );

    final whyRemovingKannada =
        whyRemovingItem?['kannadaName']?.toString().trim().isNotEmpty == true
        ? whyRemovingItem!['kannadaName'].toString().trim()
        : whyRemovingItem?['value']?.toString().trim() ?? '';

    final whyRemovingCode =
        whyRemovingItem?['code']?.toString().trim().toUpperCase() ?? '';

    final workNameText = whyRemovingCode == 'WORKS'
        ? application.workName.trim()
        : '';

    final additionalTreeLocation = application.treeLocationSame
        ? ''
        : application.treeLocationAddress.trim();

    // ----------------------------------------------------------
    // DOCUMENT GENERATION DATE
    // ----------------------------------------------------------

    final now = DateTime.now();

    final letterDate =
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year}';

    // ----------------------------------------------------------
    // FORWARDING REFERENCES + RFO ORDER
    // ----------------------------------------------------------

    final forwardedReference = _buildForwardedReference(
      application,
      startNumber: application.applicationType.trim().toUpperCase() == 'RTC'
          ? 1
          : 2,
    );

    String revenueOpinionOffice = '';

    if (application.id != null) {
      final revenueSelection = await ApplicationRevenueOpinionRepository()
          .getByApplication(application.id!);

      if (revenueSelection != null) {
        final revenueOpinion = await RevenueOpinionRepository().getById(
          revenueSelection.revenueOpinionId,
        );

        revenueOpinionOffice = revenueOpinion?.officeName.trim() ?? '';
      }
    }

    // ----------------------------------------------------------
    // GOVERNMENT/PRIVATE LAND RECOMMENDED-TREE DETAILS
    // ----------------------------------------------------------

    int glRecommendedTreeCount = 0;
    String glRecommendationReasons = '';

    String recommendedSpeciesSummary = '';
    String treeStatusSummary = '';

    final applicationType = application.applicationType.trim().toUpperCase();

    if ((applicationType == 'GL' ||
            applicationType == 'STGL' ||
            applicationType == 'CGL' ||
            applicationType == 'PL') &&
        application.id != null) {
      final treeRepository = TreeRepository();

      final trees = await treeRepository.getTrees(application.id!);

      final recommendationTypes = await masterRepository.getMasters(
        'Recommendation Type',
      );

      final recommendationCodeById = <int, String>{
        for (final item in recommendationTypes)
          item['id'] as int:
              item['code']?.toString().trim().toUpperCase() ?? '',
      };

      const recommendedCodes = <String>{'FULL', 'BRANCH', 'TWIG', 'TOP'};

      final approvedIds = rfoApprovedOnly
          ? (await RfoItemApprovalRepository().getApplicationDecisions(application.id!))
              .where((row) => row['itemKey'] == 'TREE' && {'Approve', 'Modify'}.contains(row['decision']))
              .map((row) => row['itemId']).toSet()
          : <dynamic>{};
      final recommendedTrees = trees.where((tree) {
        final code = recommendationCodeById[tree.recommendationTypeId] ?? '';

        return recommendedCodes.contains(code) && (!rfoApprovedOnly || approvedIds.contains(tree.id));
      }).toList();

      glRecommendedTreeCount = recommendedTrees.length;

      final speciesMaster = await masterRepository.getSpecies();

      final speciesNameById = <int, String>{
        for (final item in speciesMaster)
          item['id']
              as int: item['kannadaName']?.toString().trim().isNotEmpty == true
              ? item['kannadaName'].toString().trim()
              : item['value']?.toString().trim() ?? '',
      };

      final speciesCounts = <String, int>{};

      for (final tree in recommendedTrees) {
        final speciesName = speciesNameById[tree.speciesId]?.trim() ?? '';

        if (speciesName.isNotEmpty) {
          speciesCounts[speciesName] = (speciesCounts[speciesName] ?? 0) + 1;
        }
      }

      recommendedSpeciesSummary = _joinKannadaNames(
        speciesCounts.entries
            .map((entry) => '${entry.value} ಸಂಖ್ಯೆ ${entry.key}')
            .toList(),
      );

      final treeStatusMaster = await masterRepository.getMasters('Tree Status');

      final treeStatusNameById = <int, String>{
        for (final item in treeStatusMaster)
          item['id']
              as int: item['kannadaName']?.toString().trim().isNotEmpty == true
              ? item['kannadaName'].toString().trim()
              : item['value']?.toString().trim() ?? '',
      };

      final treeStatusCounts = <String, int>{};

      for (final tree in recommendedTrees) {
        final statusId = tree.treeStatusId;

        if (statusId == null) continue;

        final statusName = treeStatusNameById[statusId]?.trim() ?? '';

        if (statusName.isNotEmpty) {
          treeStatusCounts[statusName] =
              (treeStatusCounts[statusName] ?? 0) + 1;
        }
      }

      treeStatusSummary = _joinKannadaNames(
        treeStatusCounts.entries
            .map((entry) => '${entry.value} ಸಂಖ್ಯೆ ${entry.key}')
            .toList(),
      );

      final reasonMaster = await masterRepository.getMasters(
        'Recommendation Reason',
      );

      final reasonNameById = <int, String>{
        for (final item in reasonMaster)
          item['id']
              as int: item['kannadaName']?.toString().trim().isNotEmpty == true
              ? item['kannadaName'].toString().trim()
              : item['value']?.toString().trim() ?? '',
      };

      // A Dart Set preserves insertion order and removes duplicates.
      final uniqueReasonNames = <String>{};

      for (final tree in recommendedTrees) {
        for (final reasonId in tree.recommendationReasonIds) {
          final reasonName = reasonNameById[reasonId]?.trim() ?? '';

          if (reasonName.isNotEmpty) {
            uniqueReasonNames.add(reasonName);
          }
        }
      }

      glRecommendationReasons = _joinKannadaNames(uniqueReasonNames.toList());
    }

    // ----------------------------------------------------------
    // PLACEHOLDERS
    // ----------------------------------------------------------

    template = _replace(
      template,
      '{{OFFICE_NUMBER}}',
      _safeText(application.officeNumber),
    );

    template = _replace(template, '{{APPLICANT_NAME}}', applicant);

    template = _replace(template, '{{APPLICANT_ADDRESS}}', address);

    template = _replace(template, '{{TREE_LOCATION}}', location);

    template = _replace(
      template,
      '{{APPLICATION_DATE}}',
      _date(application.applicationDate),
    );

    template = _replace(
      template,
      '{{RECEIVED_DATE}}',
      _date(application.receivedDate),
    );

    template = _replace(
      template,
      '{{FORWARDED_REFERENCE}}',
      forwardedReference,
    );

    final inspectionDate = application.bfoVerificationDate.trim().isNotEmpty
        ? application.bfoVerificationDate
        : application.drfoInspectionDate;

    template = _replace(template, '{{INSPECTION_DATE}}', _date(inspectionDate));

    template = _replace(template, '{{DRFO_REMARKS}}', remarks);

    template = _replace(template, '{{DRFO_OBSERVATION}}', remarks);

    template = _replace(
      template,
      '{{DRFO_RECOMMENDATION}}',
      'ಅರ್ಜಿಯನ್ನು ಪರಿಶೀಲಿಸಿ ಅನುಮತಿ ನೀಡಲು ಶಿಫಾರಸ್ಸು ಮಾಡಲಾಗಿದೆ',
    );

    template = _replace(
      template,
      '{{GL_RECOMMENDED_TREE_COUNT}}',
      glRecommendedTreeCount.toString(),
    );

    template = _replace(
      template,
      '{{GL_RECOMMENDATION_REASONS}}',
      glRecommendationReasons.isNotEmpty ? glRecommendationReasons : '—',
    );

    template = _replace(
      template,
      '{{ADDITIONAL_TREE_LOCATION}}',
      additionalTreeLocation,
    );

    template = _replace(template, '{{URBAN_RURAL_KANNADA}}', urbanRuralKannada);

    template = _replace(
      template,
      '{{GOVERNMENT_AGENCY_KANNADA}}',
      governmentAgencyKannada,
    );

    template = _replace(
      template,
      '{{STRUCTURE_TYPE_KANNADA}}',
      structureTypeKannada,
    );

    template = _replace(template, '{{PURPOSE_KANNADA}}', purposeKannada);

    template = _replace(template, '{{WORK_NAME_TEXT}}', workNameText);

    template = _replace(
      template,
      '{{WHY_REMOVING_KANNADA}}',
      whyRemovingKannada,
    );

    template = _replace(
      template,
      '{{RECOMMENDED_SPECIES_SUMMARY}}',
      recommendedSpeciesSummary.isNotEmpty ? recommendedSpeciesSummary : '—',
    );

    template = _replace(
      template,
      '{{TOTAL_RECOMMENDED_TREES}}',
      glRecommendedTreeCount.toString(),
    );

    template = _replace(
      template,
      '{{TREE_STATUS_SUMMARY}}',
      treeStatusSummary.isNotEmpty ? treeStatusSummary : '—',
    );

    template = _replace(
      template,
      '{{UNIQUE_RECOMMENDATION_REASONS}}',
      glRecommendationReasons.isNotEmpty ? glRecommendationReasons : '—',
    );

    template = _replace(
      template,
      '{{REVENUE_OPINION_OFFICE}}',
      revenueOpinionOffice.isNotEmpty ? revenueOpinionOffice : 'ಕಂದಾಯ ಇಲಾಖೆ',
    );

    template = _replace(template, '{{SECTION}}', await _printSectionName(application));

    template = _replace(template, '{{BEAT}}', await _printBeatName(application));

    template = _replace(template, '{{RANGE_NAME}}', rangeName);

    template = _replace(template, '{{RANGE_LOCATION}}', rangeLocation);

    template = _replace(template, '{{LETTER_DATE}}', letterDate);

    return template;
  }

  Future<String> _buildRfoRtcApprovedMaster(
    String template,
    ApplicationModel application,
  ) async {
    final recipient = await _rfoForwardedRecipientAddress(application);

    final references = await _buildRfoRtcReferences(application);

    template = _replace(
      template,
      "{{FORWARDED_REFERENCE_OFFICER}}",
      recipient.isEmpty ? "—" : recipient,
    );

    // Replace this before using the common report builder,
    // because the common DRFO reference builder follows a
    // different reference pattern.
    template = _replace(template, "{{FORWARDED_REFERENCE}}", references);

    template = await _buildRecommendedReportMaster(template, application);

    return template;
  }

  Future<String> _buildRfoRtcDeferredMaster(
    String template,
    ApplicationModel application,
  ) async {
    final recipient = await _rfoForwardedRecipientAddress(application);

    final references = await _buildRfoRtcReferences(application);

    final deferredReasons = await _buildDeferredReasons(application);

    template = _replace(
      template,
      "{{FORWARDED_REFERENCE_OFFICER}}",
      recipient.isEmpty ? "—" : recipient,
    );

    template = _replace(template, "{{FORWARDED_REFERENCE}}", references);

    template = _replace(
      template,
      "{{DEFERRED_REASONS}}",
      deferredReasons.isEmpty
          ? "ಸ್ಥಳ ಪರಿಶೀಲನೆ ಮುಂದೂಡಲು ಕಾರಣಗಳು ದಾಖಲಾಗಿರುವುದಿಲ್ಲ"
          : deferredReasons,
    );

    template = await _buildRecommendedReportMaster(template, application);

    return template;
  }

  Future<String> _buildRfoNonRtcDeferredMaster({
    required String template,
    required ApplicationModel application,
    required RfoDeferredLetterRecipient primaryRecipient,
    required List<RfoDeferredLetterRecipient> copyRecipients,
    required bool isCopyPage,
  }) async {
    final masterRepository = MasterRepository();

    final deferredReasons = await _buildDeferredReasons(application);

    final references = await _buildRfoNonRtcDeferredReferences(
      application: application,
      primaryRecipient: primaryRecipient,
    );

    final governmentAgencyKannada =
        await _governmentAgencyKannadaFor(application);

    final urbanRuralKannada = await _masterKannadaName(
      masterRepository,
      application.urbanRuralId,
    );

    final applicationType = application.applicationType.trim().toUpperCase();

    final isPrivateApplication =
        applicationType == "PL" || applicationType == "SPL";

    String subjectJurisdiction;

    if (isPrivateApplication) {
      subjectJurisdiction = urbanRuralKannada.isNotEmpty
          ? "$urbanRuralKannada ಖಾಸಗಿ ಜಾಗದಲ್ಲಿರುವ"
          : "ಖಾಸಗಿ ಜಾಗದಲ್ಲಿರುವ";
    } else {
      subjectJurisdiction = governmentAgencyKannada.isNotEmpty
          ? "$governmentAgencyKannada ವ್ಯಾಪ್ತಿಯಲ್ಲಿರುವ"
          : "ಸರ್ಕಾರಿ ಜಾಗದಲ್ಲಿರುವ";
    }

    final toApplicant = primaryRecipient.recipientKey == "APPLICANT";

    final bodyApplicantPhrase = toApplicant
        ? "ನೀವು"
        : "${application.applicantName}, "
              "${application.applicantAddress} ಇವರು";

    String copyBlock = "";

    if (isCopyPage && copyRecipients.isNotEmpty) {
      final copyLines = <String>["[BOLD]", "ಪ್ರತಿ:", "[/BOLD]"];

      for (int index = 0; index < copyRecipients.length; index++) {
        copyLines.add(
          "${index + 1}. "
          "${await ForwardedAddressService.copyToAddress(kind: copyRecipients[index].sourceKind, sourceId: copyRecipients[index].sourceId, fallback: copyRecipients[index].recipientText)}",
        );
      }

      copyBlock = copyLines.join("\n");
    }

    template = _replace(
      template,
      "{{TO_ADDRESS}}",
      await ForwardedAddressService.toAddress(kind: primaryRecipient.sourceKind, sourceId: primaryRecipient.sourceId, fallback: primaryRecipient.recipientText),
    );

    template = _replace(
      template,
      "{{SUBJECT_JURISDICTION}}",
      subjectJurisdiction,
    );

    template = _replace(template, "{{RFO_DEFERRED_REFERENCES}}", references);

    template = _replace(
      template,
      "{{RFO_NOT_RECOMMENDED_REFERENCES}}",
      references,
    );

    template = _replace(
      template,
      "{{BODY_APPLICANT_PHRASE}}",
      bodyApplicantPhrase,
    );

    template = _replace(
      template,
      "{{DEFERRED_REASONS}}",
      deferredReasons.isEmpty
          ? "ಸ್ಥಳ ಪರಿಶೀಲನೆ ಮುಂದೂಡಲು ಕಾರಣಗಳು ದಾಖಲಾಗಿರುವುದಿಲ್ಲ"
          : deferredReasons,
    );

    template = _replace(
      template,
      "{{SIGNATURE_COPY_MARK}}",
      isCopyPage ? "ಸಹಿ/-" : "",
    );

    template = _replace(template, "{{COPY_BLOCK}}", copyBlock);

    template = await _buildRecommendedReportMaster(template, application);

    return template;
  }

  Future<String> _buildRfoRevenueOpinionRequestMaster({
    required String template,
    required ApplicationModel application,
    required bool isCopyPage,
    int? authorityId,
  }) async {
    final applicationId = application.id;

    if (applicationId == null) {
      throw Exception("Application ID is required for Revenue Opinion letter.");
    }

    final selection = await ApplicationRevenueOpinionRepository()
        .getByApplication(applicationId);

    if (selection == null) {
      throw Exception("Revenue Opinion selection is missing.");
    }

    final opinion = await RevenueOpinionRepository().getById(
      selection.revenueOpinionId,
    );

    if (opinion == null) {
      throw Exception("Selected Revenue Opinion master was not found.");
    }

    final addressOpinion = authorityId == null ? opinion : await RevenueOpinionRepository().getById(authorityId);
    if (addressOpinion == null || !addressOpinion.isActive) throw StateError('Select an active revenue opinion authority.');
    final officeName = addressOpinion.officeName.trim();

    final officeAddress = addressOpinion.officeAddress.trim();

    final recipientRole = addressOpinion.code.trim().toUpperCase();
    final kannadaTo = [
      addressOpinion.kannadaName.trim(),
      addressOpinion.kannadaDesignation.trim(),
      addressOpinion.kannadaOfficeAddress.trim(),
    ].where((value) => value.isNotEmpty).join('\n');
    final toAddress = {'ACF', 'DCF'}.contains(recipientRole)
        ? await OfficerRepository().addressForRole(recipientRole)
        : kannadaTo.isNotEmpty
            ? kannadaTo
            : [officeName, officeAddress].where((value) => value.isNotEmpty).join("\n");

    if (toAddress.isEmpty) {
      throw Exception("Revenue Opinion office name/address is missing.");
    }

    final additionalTreeLocation = application.treeLocationSame
        ? ""
        : application.treeLocationAddress.trim();

    final treeLocationSubjectPhrase = additionalTreeLocation;

    final treeLocationBodyPhrase = additionalTreeLocation;

    final revenueOpinionRemarks = opinion.remarks.trim().isNotEmpty
        ? opinion.remarks.trim()
        : opinion.revenueOpinion.trim();

    String copyBlock = "";

    if (isCopyPage) {
      copyBlock = [
        "[BOLD]",
        "ಪ್ರತಿ:",
        "[/BOLD]",
        "${application.applicantName}, "
            "${application.applicantAddress} ರವರಿಗೆ "
            "ಮಾಹಿತಿಗಾಗಿ ಕಳುಹಿಸುತ್ತಾ ಸದರಿ ಮರಗಳನ್ನು "
            "ತೆರವುಗೊಳಿಸಲು ಇ-ಕಟಾವಣೆ ತಂತ್ರಾಂಶದಲ್ಲಿ "
            "ಅರ್ಜಿಯನ್ನು ಸಲ್ಲಿಸಲು ತಿಳಿಸಿದೆ.",
      ].join("\n");
    }

    template = _replace(template, "{{REVENUE_OPINION_TO_ADDRESS}}", toAddress);

    template = _replace(
      template,
      "{{TREE_LOCATION_SUBJECT_PHRASE}}",
      treeLocationSubjectPhrase,
    );

    template = _replace(
      template,
      "{{TREE_LOCATION_BODY_PHRASE}}",
      treeLocationBodyPhrase,
    );

    template = _replace(
      template,
      "{{REVENUE_OPINION_REMARKS}}",
      revenueOpinionRemarks,
    );

    template = _replace(
      template,
      "{{DRFO_REPORT_DATE}}",
      _date(application.drfoInspectionDate),
    );

    template = _replace(
      template,
      "{{SIGNATURE_COPY_MARK}}",
      isCopyPage ? "ಸಹಿ/-" : "",
    );

    template = _replace(template, "{{COPY_BLOCK}}", copyBlock);

    template = await _buildRecommendedReportMaster(template, application);

    return template;
  }

  Future<String> _buildDeferredLetterMaster(
    String template,
    ApplicationModel application,
  ) async {
    final applicant = _safeText(application.applicantName);

    final address = _safeText(application.applicantAddress);

    final location = _safeText(_location(application));

    final section = _safeText(application.section);

    // ----------------------------------------------------------
    // OFFICE CONFIGURATION
    // ----------------------------------------------------------

    final officeConfiguration = await OfficeConfigurationRepository()
        .getConfiguration();

    final rangeName =
        officeConfiguration?["rangeName"]?.toString().trim().isNotEmpty == true
        ? officeConfiguration!["rangeName"].toString().trim()
        : 'ಮೈಸೂರು';

    final rangeLocation = rangeName;

    final remarks = application.drfoOverallRemarks.isNotEmpty
        ? _safeText(application.drfoOverallRemarks)
        : 'ಸ್ಥಳ ಪರಿಶೀಲನೆ ಮುಂದೂಡಲಾಗಿದೆ';

    // ----------------------------------------------------------
    // DATE ON WHICH LETTER IS GENERATED
    // ----------------------------------------------------------

    final now = DateTime.now();

    final generatedDate =
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year}';

    // ----------------------------------------------------------
    // FORWARDING REFERENCES + RFO ORDER
    // ----------------------------------------------------------

    final forwardedReference = _buildForwardedReference(
      application,
      startNumber: application.applicationType.trim().toUpperCase() == 'RTC'
          ? 1
          : 2,
    );

    final deferredReasons = await _buildDeferredReasons(application);

    // ----------------------------------------------------------
    // OFFICE NUMBER
    // ----------------------------------------------------------

    template = _replace(
      template,
      '{{OFFICE_NUMBER}}',
      _safeText(application.officeNumber),
    );

    // ----------------------------------------------------------
    // APPLICANT
    // ----------------------------------------------------------

    template = _replace(template, '{{APPLICANT_NAME}}', applicant);

    template = _replace(template, '{{APPLICANT_ADDRESS}}', address);

    // ----------------------------------------------------------
    // TREE LOCATION
    // ----------------------------------------------------------

    template = _replace(template, '{{TREE_LOCATION}}', location);

    // ----------------------------------------------------------
    // APPLICATION DATE
    // ----------------------------------------------------------

    template = _replace(
      template,
      '{{APPLICATION_DATE}}',
      _date(application.applicationDate),
    );

    // ----------------------------------------------------------
    // RECEIVED DATE
    // ----------------------------------------------------------

    template = _replace(
      template,
      '{{RECEIVED_DATE}}',
      _date(application.receivedDate),
    );

    // ----------------------------------------------------------
    // FORWARDED / RFO ORDER REFERENCE
    // ----------------------------------------------------------

    template = _replace(
      template,
      '{{FORWARDED_REFERENCE}}',
      forwardedReference,
    );

    template = _replace(template, '{{DEFERRED_REASONS}}', deferredReasons);

    // ----------------------------------------------------------
    // DRFO REMARKS
    // ----------------------------------------------------------

    template = _replace(template, '{{DRFO_REMARKS}}', remarks);

    // ----------------------------------------------------------
    // SECTION (Kannada in print)
    // ----------------------------------------------------------

    template = _replace(template, '{{SECTION}}', await _printSectionName(application));

    template = _replace(template, '{{BEAT}}', await _printBeatName(application));

    // ----------------------------------------------------------
    // RANGE NAME
    // ----------------------------------------------------------

    template = _replace(template, '{{RANGE_NAME}}', rangeName);

    // ----------------------------------------------------------
    // RANGE LOCATION
    // ----------------------------------------------------------

    template = _replace(template, '{{RANGE_LOCATION}}', rangeLocation);

    // ----------------------------------------------------------
    // INSPECTION DATE
    //
    // Kept compatible with the existing template.
    // The RFO order/forwarding date is used here.
    // ----------------------------------------------------------

    template = _replace(
      template,
      '{{INSPECTION_DATE}}',
      _date(application.drfoAssignmentDate),
    );

    // ----------------------------------------------------------
    // LETTER DATE
    //
    // This is ALWAYS the date on which the PDF is generated.
    // ----------------------------------------------------------

    template = _replace(template, '{{LETTER_DATE}}', generatedDate);

    return template;
  }

  // ==========================================================
  // TEXT PARAGRAPH
  // ==========================================================

  Future<ui.Paragraph> _buildParagraph({
    required String text,
    required double width,
    required double fontSize,
    ui.TextAlign alignment = ui.TextAlign.left,
    bool bold = false,
    double lineHeight = 1.45,
  }) async {
    final paragraphStyle = ui.ParagraphStyle(
      textAlign: alignment,
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
      height: lineHeight,
    );

    final textStyle = ui.TextStyle(
      color: const ui.Color(0xFF000000),
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
    );

    final builder = ui.ParagraphBuilder(paragraphStyle);

    builder.pushStyle(textStyle);
    builder.addText(text);

    final paragraph = builder.build();

    paragraph.layout(ui.ParagraphConstraints(width: width));

    return paragraph;
  }

  // ==========================================================
  // DRAW ONE PAGE
  // ==========================================================

  Future<double> _drawRtcTreeTable({
    required ui.Canvas canvas,
    required double y,
    required double contentWidth,
    required List<_RtcTreeTableRow> rows,
  }) async {
    final tableX = _leftMargin * _scale;
    final padding = 5 * _scale;

    final columnWidths = <double>[
      contentWidth * 0.09,
      contentWidth * 0.22,
      contentWidth * 0.31,
      contentWidth * 0.23,
      contentWidth * 0.15,
    ];

    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFF000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.7 * _scale;

    final headerPaint = ui.Paint()
      ..color = const ui.Color(0xFFF2F2F2)
      ..style = ui.PaintingStyle.fill;

    Future<List<ui.Paragraph>> buildCells(
      List<String> values, {
      bool bold = false,
    }) async {
      final cells = <ui.Paragraph>[];

      for (int index = 0; index < values.length; index++) {
        cells.add(
          await _buildParagraph(
            text: _safeText(values[index]),
            width: columnWidths[index] - (padding * 2),
            fontSize: 10 * _scale,
            alignment: ui.TextAlign.center,
            bold: bold,
          ),
        );
      }

      return cells;
    }

    double rowHeightFor(List<ui.Paragraph> paragraphs) {
      double greatestHeight = 0;

      for (final paragraph in paragraphs) {
        if (paragraph.height > greatestHeight) {
          greatestHeight = paragraph.height;
        }
      }

      return greatestHeight + (padding * 2);
    }

    void drawRowBorders(double top, double rowHeight) {
      canvas.drawRect(
        ui.Rect.fromLTWH(tableX, top, contentWidth, rowHeight),
        borderPaint,
      );

      double x = tableX;

      for (int index = 0; index < columnWidths.length - 1; index++) {
        x += columnWidths[index];

        canvas.drawLine(
          ui.Offset(x, top),
          ui.Offset(x, top + rowHeight),
          borderPaint,
        );
      }
    }

    void drawCells(
      List<ui.Paragraph> paragraphs,
      double top,
      double rowHeight,
    ) {
      double x = tableX;

      for (int index = 0; index < paragraphs.length; index++) {
        final paragraph = paragraphs[index];

        canvas.drawParagraph(
          paragraph,
          ui.Offset(x + padding, top + ((rowHeight - paragraph.height) / 2)),
        );

        x += columnWidths[index];
      }
    }

    final headerCells = await buildCells([
      'ಕ್ರ.\nಸಂಖ್ಯೆ',
      'ಅರ್ಜಿದಾರರ\nಹೆಸರು',
      'ಗ್ರಾಮ/ ಸರ್ವೇ ನಂ.',
      'ಮರದ\nಜಾತಿ',
      'ಮರಗಳ\nಸಂಖ್ಯೆ',
    ], bold: true);

    final headerHeight = rowHeightFor(headerCells);

    y = _pagePosition(y, headerHeight);
    canvas.drawRect(
      ui.Rect.fromLTWH(tableX, y, contentWidth, headerHeight),
      headerPaint,
    );

    drawRowBorders(y, headerHeight);
    drawCells(headerCells, y, headerHeight);

    y += headerHeight;

    for (final row in rows) {
      final species = row.speciesNames.isEmpty
          ? '—'
          : row.speciesNames.join('\n');

      final counts = row.treeCounts.isEmpty
          ? '—'
          : row.treeCounts.map((count) => count.toString()).join('\n');

      final rowCells = await buildCells([
        row.serialNumber.toString(),
        row.applicantName,
        row.siteDetails,
        species,
        counts,
      ]);

      final rowHeight = rowHeightFor(rowCells);

      final rowY = _pagePosition(y, rowHeight);
      if (rowY != y) {
        y = _pagePosition(rowY, headerHeight + rowHeight);
        canvas.drawRect(
          ui.Rect.fromLTWH(tableX, y, contentWidth, headerHeight),
          headerPaint,
        );
        drawRowBorders(y, headerHeight);
        drawCells(headerCells, y, headerHeight);
        y += headerHeight;
      }
      drawRowBorders(y, rowHeight);
      drawCells(rowCells, y, rowHeight);

      y += rowHeight;
    }

    return y;
  }

  Future<double> _drawNotRecommendedTreeTable({
    required ui.Canvas canvas,
    required double y,
    required double contentWidth,
    required List<_NotRecommendedTreeTableRow> rows,
  }) async {
    final tableX = _leftMargin * _scale;
    final padding = 5 * _scale;

    final columnWidths = <double>[
      contentWidth * 0.09,
      contentWidth * 0.38,
      contentWidth * 0.21,
      contentWidth * 0.32,
    ];

    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFF000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.7 * _scale;

    final headerPaint = ui.Paint()
      ..color = const ui.Color(0xFFF2F2F2)
      ..style = ui.PaintingStyle.fill;

    Future<List<ui.Paragraph>> buildCells(
      List<String> values, {
      bool bold = false,
    }) async {
      final cells = <ui.Paragraph>[];

      for (int index = 0; index < values.length; index++) {
        cells.add(
          await _buildParagraph(
            text: _safeText(values[index]),
            width: columnWidths[index] - (padding * 2),
            fontSize: 10 * _scale,
            alignment: ui.TextAlign.center,
            bold: bold,
          ),
        );
      }

      return cells;
    }

    double rowHeightFor(List<ui.Paragraph> paragraphs) {
      double greatestHeight = 0;

      for (final paragraph in paragraphs) {
        if (paragraph.height > greatestHeight) {
          greatestHeight = paragraph.height;
        }
      }

      return greatestHeight + (padding * 2);
    }

    void drawRowBorders(double top, double rowHeight) {
      canvas.drawRect(
        ui.Rect.fromLTWH(tableX, top, contentWidth, rowHeight),
        borderPaint,
      );

      double x = tableX;

      for (int index = 0; index < columnWidths.length - 1; index++) {
        x += columnWidths[index];

        canvas.drawLine(
          ui.Offset(x, top),
          ui.Offset(x, top + rowHeight),
          borderPaint,
        );
      }
    }

    void drawCells(
      List<ui.Paragraph> paragraphs,
      double top,
      double rowHeight,
    ) {
      double x = tableX;

      for (int index = 0; index < paragraphs.length; index++) {
        final paragraph = paragraphs[index];

        canvas.drawParagraph(
          paragraph,
          ui.Offset(x + padding, top + ((rowHeight - paragraph.height) / 2)),
        );

        x += columnWidths[index];
      }
    }

    final headerCells = await buildCells([
      'ಕ್ರ. ಸಂ.',
      'ಅರ್ಜಿದಾರರ ಹೆಸರು ಮತ್ತು\nವಿಳಾಸ / ಸ್ಥಳ',
      'ಮರದ ಜಾತಿ',
      'ಕಾರಣ',
    ], bold: true);

    final headerHeight = rowHeightFor(headerCells);

    y = _pagePosition(y, headerHeight);
    canvas.drawRect(
      ui.Rect.fromLTWH(tableX, y, contentWidth, headerHeight),
      headerPaint,
    );

    drawRowBorders(y, headerHeight);
    drawCells(headerCells, y, headerHeight);

    y += headerHeight;

    for (final row in rows) {
      final rowCells = await buildCells([
        row.serialNumber.toString(),
        row.applicantAndLocation,
        row.speciesName,
        row.reasonNames,
      ]);

      final rowHeight = rowHeightFor(rowCells);

      final rowY = _pagePosition(y, rowHeight);
      if (rowY != y) {
        y = _pagePosition(rowY, headerHeight + rowHeight);
        canvas.drawRect(
          ui.Rect.fromLTWH(tableX, y, contentWidth, headerHeight),
          headerPaint,
        );
        drawRowBorders(y, headerHeight);
        drawCells(headerCells, y, headerHeight);
        y += headerHeight;
      }
      drawRowBorders(y, rowHeight);
      drawCells(rowCells, y, rowHeight);

      y += rowHeight;
    }

    return y;
  }

  Future<double> _drawGlTreeEnumerationTable({
    required ui.Canvas canvas,
    required double y,
    required double contentWidth,
    required List<_GlTreeEnumerationRow> rows,
  }) async {
    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFF000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.6 * _scale;

    final headerPaint = ui.Paint()
      ..color = const ui.Color(0xFFF2F2F2)
      ..style = ui.PaintingStyle.fill;

    // The values are relative widths. They are automatically
    // scaled to the available page width.
    final relativeWidths = <double>[
      22, // 0: Serial number
      31, // 1: Tree number
      46, // 2: Species
      32, // 3: GBH
      32, // 4: Height
      35, // 5: Timber volume
      30, // 6: Pole quantity
      35, // 7: Firewood
      37, // 8: Timber value
      37, // 9: Pole value
      37, // 10: Firewood value
      40, // 11: Total value
      56, // 12: Recommendation details
    ];

    final totalRelativeWidth = relativeWidths.reduce((a, b) => a + b);

    final widths = relativeWidths
        .map((width) => contentWidth * width / totalRelativeWidth)
        .toList();

    final xPositions = <double>[_leftMargin * _scale];

    for (final width in widths) {
      xPositions.add(xPositions.last + width);
    }

    void drawBox({
      required double left,
      required double top,
      required double width,
      required double height,
      bool header = false,
    }) {
      final rect = ui.Rect.fromLTWH(left, top, width, height);

      if (header) {
        canvas.drawRect(rect, headerPaint);
      }

      canvas.drawRect(rect, borderPaint);
    }

    Future<ui.Paragraph> cellParagraph({
      required String text,
      required double width,
      double fontSize = 7.2,
      ui.TextAlign alignment = ui.TextAlign.center,
      bool bold = false,
    }) {
      return _buildParagraph(
        text: _safeText(text),
        width: width - (4 * _scale),
        fontSize: fontSize * _scale,
        alignment: alignment,
        bold: bold,
      );
    }

    void drawParagraphInBox({
      required ui.Paragraph paragraph,
      required double left,
      required double top,
      required double width,
      required double height,
    }) {
      canvas.drawParagraph(
        paragraph,
        ui.Offset(left + (2 * _scale), top + ((height - paragraph.height) / 2)),
      );
    }

    // ========================================================
    // GROUPED TABLE HEADER
    // ========================================================

    final topHeaderHeight = 22 * _scale;
    final bottomHeaderHeight = 35 * _scale;
    final completeHeaderHeight = topHeaderHeight + bottomHeaderHeight;

    Future<void> drawHeader() async {
      final rowSpanHeaders = <int, String>{
        0: 'ಕ್ರ.\nಸಂ.',
        1: 'ಮರ\nಸಂಖ್ಯೆ',
        2: 'ಮರದ ಜಾತಿ',
        3: 'ಸುತ್ತಳತೆ\n(ಮೀ ಗಳಲ್ಲಿ)',
        4: 'ಎತ್ತರ\n(ಮೀ ಗಳಲ್ಲಿ)',
        12: 'ಷರಾ',
      };

      for (final entry in rowSpanHeaders.entries) {
        final column = entry.key;

        drawBox(
          left: xPositions[column],
          top: y,
          width: widths[column],
          height: completeHeaderHeight,
          header: true,
        );

        final paragraph = await cellParagraph(
          text: entry.value,
          width: widths[column],
          bold: true,
        );

        drawParagraphInBox(
          paragraph: paragraph,
          left: xPositions[column],
          top: y,
          width: widths[column],
          height: completeHeaderHeight,
        );
      }

      // Volume group: columns 5 and 6.
      final volumeGroupWidth = widths[5] + widths[6] + widths[7];

      drawBox(
        left: xPositions[5],
        top: y,
        width: volumeGroupWidth,
        height: topHeaderHeight,
        header: true,
      );

      final volumeGroupParagraph = await cellParagraph(
        text: 'ಪರಿಮಾಣ',
        width: volumeGroupWidth,
        bold: true,
      );

      drawParagraphInBox(
        paragraph: volumeGroupParagraph,
        left: xPositions[5],
        top: y,
        width: volumeGroupWidth,
        height: topHeaderHeight,
      );

      // Estimated value group: columns 7, 8 and 9.
      final valueGroupWidth = widths[8] + widths[9] + widths[10] + widths[11];

      drawBox(
        left: xPositions[8],
        top: y,
        width: valueGroupWidth,
        height: topHeaderHeight,
        header: true,
      );

      final valueGroupParagraph = await cellParagraph(
        text: 'ಸಿನಿಯರೇಜ್ ದರದಂತೆ ಮೌಲ್ಯ',
        width: valueGroupWidth,
        bold: true,
      );

      drawParagraphInBox(
        paragraph: valueGroupParagraph,
        left: xPositions[8],
        top: y,
        width: valueGroupWidth,
        height: topHeaderHeight,
      );

      final bottomHeaders = <int, String>{
        5: 'ನಾಟ\n(ಘ.ಮೀ)',
        6: 'ಪೋಲ್\n(ಸಂಖ್ಯೆ)',
        7: 'ಸೌದೆ\n(ಟನ್)',
        8: 'ನಾಟ\n(ರೂ.)',
        9: 'ಪೋಲ್\n(ರೂ.)',
        10: 'ಸೌದೆ\n(ರೂ.)',
        11: 'ಒಟ್ಟು\n(ರೂ.)',
      };

      for (final entry in bottomHeaders.entries) {
        final column = entry.key;

        drawBox(
          left: xPositions[column],
          top: y + topHeaderHeight,
          width: widths[column],
          height: bottomHeaderHeight,
          header: true,
        );

        final paragraph = await cellParagraph(
          text: entry.value,
          width: widths[column],
          bold: true,
        );

        drawParagraphInBox(
          paragraph: paragraph,
          left: xPositions[column],
          top: y + topHeaderHeight,
          width: widths[column],
          height: bottomHeaderHeight,
        );
      }
    }

    y = _pagePosition(y, completeHeaderHeight);
    await drawHeader();
    y += completeHeaderHeight;

    // ========================================================
    // TREE ROWS
    // ========================================================

    for (final row in rows) {
      final normalTexts = <int, String>{
        0: row.serialNumber.toString(),
        1: row.treeNumber,
        2: row.speciesName,
        5: row.timberVolume,
        6: row.poleCount,
        7: row.firewood,
        8: row.timberValue,
        9: row.poleValue,
        10: row.firewoodValue,
        11: row.totalValue,
        12: row.recommendationDetails,
      };

      if (!row.mergeGbhAndHeight) {
        normalTexts[3] = row.gbh;
        normalTexts[4] = row.height;
      }

      final paragraphs = <int, ui.Paragraph>{};

      double rowHeight = 30 * _scale;

      for (final entry in normalTexts.entries) {
        final paragraph = await cellParagraph(
          text: entry.value,
          width: widths[entry.key],
          fontSize: entry.key == 12 ? 6.7 : 7.0,
        );

        paragraphs[entry.key] = paragraph;

        final requiredHeight = paragraph.height + (8 * _scale);

        if (requiredHeight > rowHeight) {
          rowHeight = requiredHeight;
        }
      }

      ui.Paragraph? mergedParagraph;

      if (row.mergeGbhAndHeight) {
        mergedParagraph = await cellParagraph(
          text: row.mergedMeasurement,
          width: widths[3] + widths[4],
        );

        final requiredHeight = mergedParagraph.height + (8 * _scale);

        if (requiredHeight > rowHeight) {
          rowHeight = requiredHeight;
        }
      }

      final rowY = _pagePosition(y, rowHeight);
      if (rowY != y) {
        y = _pagePosition(rowY, completeHeaderHeight + rowHeight);
        await drawHeader();
        y += completeHeaderHeight;
      }
      for (int column = 0; column < widths.length; column++) {
        if (row.mergeGbhAndHeight && (column == 3 || column == 4)) {
          continue;
        }

        drawBox(
          left: xPositions[column],
          top: y,
          width: widths[column],
          height: rowHeight,
        );

        final paragraph = paragraphs[column];

        if (paragraph != null) {
          drawParagraphInBox(
            paragraph: paragraph,
            left: xPositions[column],
            top: y,
            width: widths[column],
            height: rowHeight,
          );
        }
      }

      if (row.mergeGbhAndHeight && mergedParagraph != null) {
        final mergedWidth = widths[3] + widths[4];

        drawBox(
          left: xPositions[3],
          top: y,
          width: mergedWidth,
          height: rowHeight,
        );

        drawParagraphInBox(
          paragraph: mergedParagraph,
          left: xPositions[3],
          top: y,
          width: mergedWidth,
          height: rowHeight,
        );
      }

      y += rowHeight;
    }

    // ========================================================
    // TOTAL ROW
    // ========================================================

    final moneyFormat = NumberFormat('#,##,##0.00', 'en_IN');

    final totalVolume = rows.fold<double>(
      0,
      (total, row) => total + row.timberVolumeNumber,
    );

    final totalPoleCount = rows.fold<int>(
      0,
      (total, row) => total + row.poleCountNumber,
    );

    final totalFirewood = rows.fold<double>(
      0,
      (total, row) => total + row.firewoodNumber,
    );

    final totalTimberValue = rows.fold<double>(
      0,
      (total, row) => total + row.timberValueNumber,
    );

    final totalPoleValue = rows.fold<double>(
      0,
      (total, row) => total + row.poleValueNumber,
    );

    final totalFirewoodValue = rows.fold<double>(
      0,
      (total, row) => total + row.firewoodValueNumber,
    );

    final grandTotal = rows.fold<double>(
      0,
      (total, row) => total + row.totalValueNumber,
    );

    final totalRowHeight = 25 * _scale;
    final totalY = _pagePosition(y, totalRowHeight);
    if (totalY != y) {
      y = _pagePosition(totalY, completeHeaderHeight + totalRowHeight);
      await drawHeader();
      y += completeHeaderHeight;
    }

    final labelWidth = widths.sublist(0, 5).reduce((a, b) => a + b);

    drawBox(
      left: xPositions[0],
      top: y,
      width: labelWidth,
      height: totalRowHeight,
      header: true,
    );

    final totalLabel = await cellParagraph(
      text: 'ಒಟ್ಟು:',
      width: labelWidth,
      bold: true,
    );

    drawParagraphInBox(
      paragraph: totalLabel,
      left: xPositions[0],
      top: y,
      width: labelWidth,
      height: totalRowHeight,
    );

    final totalTexts = <int, String>{
      5: totalVolume.toStringAsFixed(3),
      6: totalPoleCount.toString(),
      7: totalFirewood.toStringAsFixed(2),
      8: moneyFormat.format(totalTimberValue),
      9: moneyFormat.format(totalPoleValue),
      10: moneyFormat.format(totalFirewoodValue),
      11: moneyFormat.format(grandTotal),
      12: '',
    };

    for (final entry in totalTexts.entries) {
      drawBox(
        left: xPositions[entry.key],
        top: y,
        width: widths[entry.key],
        height: totalRowHeight,
        header: true,
      );

      if (entry.value.isNotEmpty) {
        final paragraph = await cellParagraph(
          text: entry.value,
          width: widths[entry.key],
          fontSize: 6.7,
          bold: true,
        );

        drawParagraphInBox(
          paragraph: paragraph,
          left: xPositions[entry.key],
          top: y,
          width: widths[entry.key],
          height: totalRowHeight,
        );
      }
    }

    return y + totalRowHeight;
  }

  double _pagePosition(double y, double blockHeight) {
    final pageHeight = (_pageHeight * _scale).round().toDouble();
    final top = _topMargin * _scale;
    final bottom = _bottomMargin * _scale;
    if (blockHeight > pageHeight - top - bottom) {
      throw StateError(
        'A document block is taller than an A4 page. Split the table cell or signature block.',
      );
    }
    final page = (y / pageHeight).floor();
    final start = math.max(y, page * pageHeight + top);
    return start + blockHeight <= (page + 1) * pageHeight - bottom
        ? start
        : (page + 1) * pageHeight + top;
  }

  // Split unusually long paragraphs at shaped text-line boundaries, preserving Kannada.
  double _drawFlowParagraph(
    ui.Canvas canvas,
    ui.Paragraph paragraph,
    double x,
    double y,
  ) {
    final usable =
        (_pageHeight * _scale).round() - (_topMargin + _bottomMargin) * _scale;
    if (paragraph.height <= usable) {
      y = _pagePosition(y, paragraph.height);
      canvas.drawParagraph(paragraph, ui.Offset(x, y));
      return y + paragraph.height;
    }
    final metrics = paragraph.computeLineMetrics();
    double sourceTop = 0;
    for (var index = 0; index < metrics.length; index++) {
      final sourceBottom = index + 1 == metrics.length
          ? paragraph.height
          : metrics[index + 1].baseline - metrics[index + 1].ascent;
      final lineHeight = sourceBottom - sourceTop;
      y = _pagePosition(y, lineHeight);
      canvas.save();
      canvas.clipRect(ui.Rect.fromLTWH(x, y, paragraph.width, lineHeight));
      canvas.drawParagraph(paragraph, ui.Offset(x, y - sourceTop));
      canvas.restore();
      y += lineHeight;
      sourceTop = sourceBottom;
    }
    return y;
  }

  Future<List<Uint8List>> _renderLetterPages(
    List<String> lines, {
    _RfoLetterheadData? rfoLetterhead,
    List<_RtcTreeTableRow> rtcTreeRows = const [],
    List<_NotRecommendedTreeTableRow> notRecommendedTreeRows = const [],
    List<_GlTreeEnumerationRow> glTreeEnumerationRows = const [],
  }) async {
    final width = (_pageWidth * _scale).round();
    final height = (_pageHeight * _scale).round();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);

    final contentWidth = (_pageWidth - _leftMargin - _rightMargin) * _scale;

    double y = _topMargin * _scale;

    const defaultFontSize = 11.5;
    const boldFontSize = 11.5;

    // ==========================================================
    // RFO LETTERHEAD
    // ==========================================================

    if (rfoLetterhead != null) {
      final titleParagraph = await _buildParagraph(
        text: "ಕರ್ನಾಟಕ ಸರ್ಕಾರ",
        width: contentWidth,
        fontSize: 13 * _scale,
        alignment: ui.TextAlign.center,
        bold: true,
      );

      canvas.drawParagraph(titleParagraph, ui.Offset(_leftMargin * _scale, y));

      y += titleParagraph.height + (8 * _scale);

      // Three-part letterhead:
      // letter number | centered logo | office details
      final leftColumnWidth = 180 * _scale;
      final logoColumnWidth = 92 * _scale;
      final columnGap = 5 * _scale;
      final rightColumnWidth =
          contentWidth - leftColumnWidth - logoColumnWidth - (columnGap * 2);

      final leftHeader =
          "ಪತ್ರ ಸಂಖ್ಯೆ:\n"
          "${rfoLetterhead.letterNumber}";

      final rangeNameText = rfoLetterhead.rangeName.trim();

      final rangeNameWithValaya = rangeNameText.endsWith("ವಲಯ")
          ? rangeNameText
          : "$rangeNameText ವಲಯ";

      final rightBodyLines = <String>[
        "$rangeNameWithValaya, "
            "${rfoLetterhead.rangeLocation}",
        if (rfoLetterhead.rangeOfficeAddress.trim().isNotEmpty)
          rfoLetterhead.rangeOfficeAddress,
        if (rfoLetterhead.rangeEmail.trim().isNotEmpty)
          "e-mail: ${rfoLetterhead.rangeEmail}",
      ];
      final leftParagraph = await _buildParagraph(
        text: rfoLetterhead.doSenderName == null ? leftHeader : rfoLetterhead.doSenderAddress + "\nಪತ್ರ ಸಂಖ್ಯೆ: " + rfoLetterhead.letterNumber,
        width: leftColumnWidth,
        lineHeight: rfoLetterhead.doSenderName == null ? 1.45 : 1.1,
        fontSize: defaultFontSize * _scale,
        alignment: ui.TextAlign.left,
        bold: false,
      );

      final rightTitleParagraph = await _buildParagraph(
        text: "ವಲಯ ಅರಣ್ಯಾಧಿಕಾರಿಗಳ ಕಛೇರಿ",
        width: rightColumnWidth,
        fontSize: defaultFontSize * _scale,
        alignment: ui.TextAlign.center,
        bold: true,
      );

      // Second head line (range + location) is bold like the first.
      final rightRangeParagraph = await _buildParagraph(
        text: rightBodyLines.isNotEmpty ? rightBodyLines.first : "",
        width: rightColumnWidth,
        fontSize: defaultFontSize * _scale,
        alignment: ui.TextAlign.center,
        bold: true,
        lineHeight: 1.18,
      );

      final rightBodyParagraph = await _buildParagraph(
        text: rightBodyLines.length > 1
            ? rightBodyLines.sublist(1).join("\n")
            : "",
        width: rightColumnWidth,
        fontSize: defaultFontSize * _scale,
        alignment: ui.TextAlign.center,
        bold: false,
        lineHeight: 1.18,
      );

      final rightDateParagraph = await _buildParagraph(
        text: "ದಿನಾಂಕ: ${rfoLetterhead.approvalDate}",
        width: rightColumnWidth,
        fontSize: defaultFontSize * _scale,
        alignment: ui.TextAlign.center,
        bold: false,
        lineHeight: 1.1,
      );

      final double dateTopGap = 7 * _scale;

      final rightHeaderHeight =
          rightTitleParagraph.height +
          rightRangeParagraph.height +
          rightBodyParagraph.height +
          dateTopGap +
          rightDateParagraph.height;

      final leftX = _leftMargin * _scale;

      final logoX = leftX + leftColumnWidth + columnGap;

      final rightX = logoX + logoColumnWidth + columnGap;

      double senderNameHeight = 0;
      if (rfoLetterhead.doSenderName != null) {
        final senderName = await _buildParagraph(text: rfoLetterhead.doSenderName!,
          width: leftColumnWidth, fontSize: (defaultFontSize + 1) * _scale,
          alignment: ui.TextAlign.left, bold: true, lineHeight: 1.1);
        canvas.drawParagraph(senderName, ui.Offset(leftX, y));
        senderNameHeight = senderName.height;
      }
      canvas.drawParagraph(leftParagraph, ui.Offset(leftX, y + senderNameHeight));

      canvas.drawParagraph(rightTitleParagraph, ui.Offset(rightX, y));

      canvas.drawParagraph(
        rightRangeParagraph,
        ui.Offset(rightX, y + rightTitleParagraph.height),
      );

      canvas.drawParagraph(
        rightBodyParagraph,
        ui.Offset(rightX,
            y + rightTitleParagraph.height + rightRangeParagraph.height),
      );

      canvas.drawParagraph(
        rightDateParagraph,
        ui.Offset(
          rightX,
          y +
              rightTitleParagraph.height +
              rightRangeParagraph.height +
              rightBodyParagraph.height +
              dateTopGap,
        ),
      );

      double logoHeight = 0;

      final logoPath = rfoLetterhead.logoPath.trim();

      if (logoPath.isNotEmpty) {
        try {
          final logoFile = File(logoPath);

          if (await logoFile.exists()) {
            final logoBytes = await logoFile.readAsBytes();

            final codec = await ui.instantiateImageCodec(logoBytes);

            final frame = await codec.getNextFrame();

            final logoImage = frame.image;

            const maximumLogoSize = 81.25;

            final imageWidth = logoImage.width.toDouble();

            final imageHeight = logoImage.height.toDouble();

            final ratio = math.min(
              (maximumLogoSize * _scale) / imageWidth,
              (maximumLogoSize * _scale) / imageHeight,
            );

            final drawWidth = imageWidth * ratio;

            final drawHeight = imageHeight * ratio;

            final destinationRect = ui.Rect.fromLTWH(
              logoX + ((logoColumnWidth - drawWidth) / 2),
              y,
              drawWidth,
              drawHeight,
            );

            final sourceRect = ui.Rect.fromLTWH(0, 0, imageWidth, imageHeight);

            canvas.drawImageRect(
              logoImage,
              sourceRect,
              destinationRect,
              ui.Paint(),
            );

            logoHeight = drawHeight;

            codec.dispose();
          }
        } catch (_) {
          // If the configured logo cannot be read,
          // generate the letter without failing.
        }
      }

      y +=
          math.max(
            math.max(leftParagraph.height + senderNameHeight, rightHeaderHeight),
            logoHeight,
          ) +
          (18 * _scale);
    }

    if (rfoLetterhead?.doSenderName != null) {
      canvas.drawLine(ui.Offset(_leftMargin * _scale, y - 8 * _scale),
        ui.Offset((_pageWidth - _rightMargin) * _scale, y - 8 * _scale),
        ui.Paint()..color = const ui.Color(0xFF111111)..strokeWidth = 1.2 * _scale);
    }

    bool right = false;
    bool center = false;
    bool justify = false;
    bool bold = false;
    bool small = false;

    double contentEnd = y;
    bool footerReserved = false;
    double? signatureY;
    double? drfoDateY;
    double? drfoPlaceY;
    // ==========================================================
    // FIXED HORIZONTAL POSITIONS
    // ==========================================================

    // "ವಿಷಯ:" and "ಉಲ್ಲೇಖ:" MUST begin at exactly
    // the same horizontal position.
    final double labelX = (_leftMargin + 30) * _scale;

    // Actual text following "ವಿಷಯ:"
    final double subjectTextX = (_leftMargin + 92) * _scale;

    // Actual reference text following "ಉಲ್ಲೇಖ:"
    // Same starting point as subject text.
    final double referenceTextX = (_leftMargin + 92) * _scale;

    // Normal body text.
    final double bodyX = _leftMargin * _scale;

    // Right-side signature block.
    // This is intentionally not at the extreme right edge.
    final double signatureBlockWidth = 210 * _scale;

    final double signatureBlockX = (_pageWidth - _rightMargin - 210) * _scale;

    // First-line indentation for body paragraphs.

    // ==========================================================
    // MAIN LOOP
    // ==========================================================

    for (int i = 0; i < lines.length; i++) {
      contentEnd = math.max(contentEnd, y);
      final rawLine = lines[i];

      final line = rawLine.trimRight();
      final trimmed = line.trim();

      // ========================================================
      // FORMATTING DIRECTIVES
      // ========================================================

      // DO closing is one pagination unit: thanks, recipient on the left,
      // and signature on the right. All wording stays in the editable template.
      if (trimmed == '[DO_CLOSING]') {
        final end = lines.indexWhere((line) => line.trim() == '[/DO_CLOSING]', i + 1);
        if (end < 0) throw StateError('Close [DO_CLOSING] in the DO template.');
        final parts = <String, List<String>>{'thanks': [], 'to': [], 'signature': []};
        var part = 'thanks';
        for (var j = i + 1; j < end; j++) {
          final text = lines[j].trim();
          if (text == '[DO_TO]') { part = 'to'; continue; }
          if (text == '[DO_SIGNATURE]') { part = 'signature'; continue; }
          parts[part]!.add(text);
        }
        final thanks = await _buildParagraph(text: parts['thanks']!.join('\n').trim(),
          width: contentWidth, fontSize: defaultFontSize * _scale, alignment: ui.TextAlign.center, bold: false);
        final recipient = await _buildParagraph(text: parts['to']!.join('\n').trim(),
          width: signatureBlockX - bodyX - 12 * _scale, fontSize: defaultFontSize * _scale,
          alignment: ui.TextAlign.left, bold: false, lineHeight: 1.18);
        final signature = await _buildParagraph(text: parts['signature']!.join('\n').trim(),
          width: signatureBlockWidth, fontSize: defaultFontSize * _scale,
          alignment: ui.TextAlign.center, bold: true, lineHeight: 1.18);
        final gap = 25 * _scale;
        final height = thanks.height + gap + math.max(recipient.height, signature.height);
        y = _pagePosition(y, height);
        canvas.drawParagraph(thanks, ui.Offset(bodyX, y));
        final footerTop = y + thanks.height + gap;
        canvas.drawParagraph(recipient, ui.Offset(bodyX, footerTop));
        canvas.drawParagraph(signature, ui.Offset(signatureBlockX, footerTop));
        y += height + 4 * _scale;
        i = end;
        continue;
      }

      if (trimmed == '[RIGHT]') {
        right = true;
        center = false;
        justify = false;
        continue;
      }

      if (trimmed == '[/RIGHT]') {
        right = false;
        continue;
      }

      if (trimmed == '[CENTER]') {
        center = true;
        right = false;
        justify = false;
        continue;
      }

      if (trimmed == '[/CENTER]') {
        center = false;
        continue;
      }

      if (trimmed == '[JUSTIFY]') {
        justify = true;
        right = false;
        center = false;
        continue;
      }

      if (trimmed == '[/JUSTIFY]') {
        justify = false;
        continue;
      }

      if (trimmed == '[BOLD]') {
        bold = true;
        continue;
      }

      if (trimmed == '[/BOLD]') {
        bold = false;
        continue;
      }

      if (trimmed == '[SMALL]') {
        small = true;
        continue;
      }

      if (trimmed == '[/SMALL]') {
        small = false;
        continue;
      }

      // ========================================================
      // RTC RECOMMENDED-LETTER TREE TABLE
      // ========================================================

      if (trimmed == '{{RTC_TREE_TABLE}}') {
        y = await _drawRtcTreeTable(
          canvas: canvas,
          y: y,
          contentWidth: contentWidth,
          rows: rtcTreeRows,
        );

        y += 8 * _scale;
        continue;
      }

      if (trimmed == '{{GL_TREE_ENUMERATION_TABLE}}') {
        y = await _drawGlTreeEnumerationTable(
          canvas: canvas,
          y: y,
          contentWidth: contentWidth,
          rows: glTreeEnumerationRows,
        );

        y += 12 * _scale;
        continue;
      }

      if (trimmed == '{{NOT_RECOMMENDED_TREE_TABLE}}') {
        y = await _drawNotRecommendedTreeTable(
          canvas: canvas,
          y: y,
          contentWidth: contentWidth,
          rows: notRecommendedTreeRows,
        );

        y += 8 * _scale;
        continue;
      }

      // ========================================================
      // DRFO SIGNATURE DESIGNATION
      // Keep both designation lines compact and record their
      // positions so Date and Place appear alongside them.
      // ========================================================

      final bool isDrfoDesignation =
          trimmed == "ಉಪವಲಯ ಅರಣ್ಯಾಧಿಕಾರಿ -ವ- ಮೋಜಣಿದಾರ" ||
          trimmed == "ಉಪ ವಲಯ ಅರಣ್ಯಾಧಿಕಾರಿ -ವ- ಮೋಜಣಿದಾರ";

      if (isDrfoDesignation && i + 1 < lines.length) {
        final sectionLine = lines[i + 1].trim();

        if (sectionLine.isNotEmpty && !sectionLine.startsWith("[")) {
          final firstSignatureLine = await _buildParagraph(
            text: trimmed,
            width: signatureBlockWidth,
            fontSize: defaultFontSize * _scale,
            alignment: ui.TextAlign.center,
            bold: bold,
            lineHeight: 1.05,
          );

          final secondSignatureLine = await _buildParagraph(
            text: sectionLine,
            width: signatureBlockWidth,
            fontSize: defaultFontSize * _scale,
            alignment: ui.TextAlign.center,
            bold: bold,
            lineHeight: 1.05,
          );

          y = _pagePosition(
            y,
            firstSignatureLine.height + secondSignatureLine.height,
          );
          final firstLineY = y;
          final secondLineY = firstLineY + firstSignatureLine.height;

          drfoDateY = firstLineY;
          drfoPlaceY = secondLineY;
          signatureY ??= firstLineY;

          canvas.drawParagraph(
            firstSignatureLine,
            ui.Offset(signatureBlockX, firstLineY),
          );

          canvas.drawParagraph(
            secondSignatureLine,
            ui.Offset(signatureBlockX, secondLineY),
          );

          y = secondLineY + secondSignatureLine.height + (4 * _scale);

          i++;
          continue;
        }
      }

      // ========================================================
      // RFO SIGNATURE DESIGNATION
      // Keep designation and range/location as one paragraph
      // so the two lines use normal line spacing.
      // ========================================================

      if (right && trimmed == "ವಲಯ ಅರಣ್ಯಾಧಿಕಾರಿ" && i + 1 < lines.length) {
        final rangeLine = lines[i + 1].trim();

        if (rangeLine.isNotEmpty && !rangeLine.startsWith("[")) {
          final signatureParagraph = await _buildParagraph(
            text: "$trimmed\n$rangeLine",
            width: signatureBlockWidth,
            fontSize: defaultFontSize * _scale,
            alignment: ui.TextAlign.center,
            bold: bold,
            lineHeight: 1.05,
          );

          y = _pagePosition(y, signatureParagraph.height);
          signatureY = y;

          canvas.drawParagraph(
            signatureParagraph,
            ui.Offset(signatureBlockX, y),
          );

          y += signatureParagraph.height + (4 * _scale);

          i++;
          continue;
        }
      }

      // ========================================================
      // EMPTY LINE
      // ========================================================

      if (trimmed.isEmpty) {
        y += 9 * _scale;
        continue;
      }

      // ========================================================
      // SPECIAL: REFERENCE SECTION
      //
      // Result:
      //
      //             ಉಲ್ಲೇಖ:   1. Applicant...
      //                       continuation...
      //                       2. ...
      //                       3. ...
      //
      // "ಉಲ್ಲೇಖ:" begins at exactly the same X as "ವಿಷಯ:".
      // Reference text begins at exactly the same X as
      // the subject text.
      // ========================================================

      if (trimmed == 'ಉಲ್ಲೇಖ:' || trimmed.startsWith('ಉಲ್ಲೇಖ:')) {
        // ------------------------------------------------------
        // Draw "ಉಲ್ಲೇಖ:"
        // ------------------------------------------------------

        final labelParagraph = await _buildParagraph(
          text: 'ಉಲ್ಲೇಖ:',
          width: 65 * _scale,
          fontSize: defaultFontSize * _scale,
          alignment: ui.TextAlign.left,
          bold: false,
        );

        y = _pagePosition(y, labelParagraph.height);
        canvas.drawParagraph(labelParagraph, ui.Offset(labelX, y));

        // ------------------------------------------------------
        // Reference items start beside the label.
        // ------------------------------------------------------

        double referenceY = y;

        int j = i + 1;

        // Skip only blank lines immediately after
        // "ಉಲ್ಲೇಖ:".
        while (j < lines.length && lines[j].trim().isEmpty) {
          j++;
        }

        while (j < lines.length) {
          final referenceLine = lines[j].trimRight().trim();

          // Stop when reference list is finished.
          if (referenceLine.isEmpty) {
            break;
          }

          // Only numbered references belong here.
          if (!RegExp(r'^[1-9]\d*\.\s').hasMatch(referenceLine)) {
            break;
          }

          final referenceParagraph = await _buildParagraph(
            text: _safeText(referenceLine),
            width: contentWidth - (referenceTextX - bodyX),
            fontSize: (bold ? boldFontSize : defaultFontSize) * _scale,
            alignment: ui.TextAlign.left,
            bold: bold,
          );

          referenceY =
              _drawFlowParagraph(
                canvas,
                referenceParagraph,
                referenceTextX,
                referenceY,
              ) +
              (3 * _scale);

          j++;
        }

        // Move below complete reference block.
        y = referenceY + (3 * _scale);

        // Skip consumed lines.
        i = j - 1;

        continue;
      }

      // ========================================================
      // ALIGNMENT
      // ========================================================

      ui.TextAlign alignment = ui.TextAlign.left;

      if (right) {
        alignment = ui.TextAlign.right;
      } else if (center) {
        alignment = ui.TextAlign.center;
      } else if (justify) {
        alignment = ui.TextAlign.justify;
      }

      // ========================================================
      // SPECIAL HORIZONTAL POSITION
      // ========================================================

      double x = bodyX;
      double paragraphWidth = contentWidth;

      // ========================================================
      // SUBJECT
      //
      // IMPORTANT:
      // The label "વિષય:" and the subject text are drawn
      // separately so wrapped lines NEVER return to the
      // "ವಿಷಯ:" position.
      // ========================================================

      if (trimmed.startsWith('ವಿಷಯ:')) {
        final subjectText = trimmed.substring('ವಿಷಯ:'.length).trimLeft();

        // Draw subject label.
        final subjectLabel = await _buildParagraph(
          text: 'ವಿಷಯ:',
          width: 65 * _scale,
          fontSize: (bold ? boldFontSize : defaultFontSize) * _scale,
          alignment: ui.TextAlign.left,
          bold: bold,
        );

        // Actual subject body starts at subjectTextX.
        final subjectParagraph = await _buildParagraph(
          text: _safeText(subjectText),
          width: contentWidth - (subjectTextX - bodyX),
          fontSize: (bold ? boldFontSize : defaultFontSize) * _scale,
          alignment: ui.TextAlign.left,
          bold: bold,
        );

        y = _pagePosition(
          y,
          math.min(
            subjectParagraph.height,
            (_pageHeight - _topMargin - _bottomMargin) * _scale - 1,
          ),
        );
        canvas.drawParagraph(subjectLabel, ui.Offset(labelX, y));
        y =
            _drawFlowParagraph(canvas, subjectParagraph, subjectTextX, y) +
            (4 * _scale);

        continue;
      }

      // ========================================================
      // NORMAL BODY PARAGRAPH
      //
      // Body text is justified.
      //
      // First line is indented.
      //
      // Continuation lines start from the normal body margin.
      // ========================================================

      final bool isReferenceNumber = RegExp(r'^[1-9]\d*\.\s').hasMatch(trimmed);

      final bool isOfficeAddress =
          trimmed == 'ರವರಿಗೆ,' ||
          trimmed == 'ಮಾನ್ಯರೆ,' ||
          trimmed.startsWith('ವಲಯ ಅರಣ್ಯಾಧಿಕಾರಿಗಳು') ||
          trimmed.contains('ವಲಯ,');

      // Extra spacing before "ಮಾನ್ಯರೆ,"
      if (trimmed == 'ಮಾನ್ಯರೆ,') {
        y += 9 * _scale;
      }

      final bool isThanking =
          trimmed == 'ವಂದನೆಗಳೊಂದಿಗೆ,' ||
          trimmed == 'ತಮ್ಮ ನಂಬುಗೆಯೊಂದಿಗೆ,' ||
          trimmed == 'ತಮ್ಮ ನಂಬಿಕೆಯೊಂದಿಗೆ,' ||
          trimmed == 'ತಮ್ಮ ನಂಬಿಗೆಯೊಂದಿಗೆ,' ||
          trimmed == 'ತಮ್ಮ ನಂಬಿಗೆಯ,';

      // Body paragraphs only.
      final bool isBodyParagraph =
          justify ||
          (!trimmed.startsWith('ದಿನಾಂಕ:') &&
              !trimmed.startsWith('ಸ್ಥಳ:') &&
              !isReferenceNumber &&
              !isOfficeAddress &&
              !isThanking &&
              !right &&
              !center);

      if (isBodyParagraph) {
        alignment = ui.TextAlign.justify;
      }

      // ========================================================
      // FOOTER / SIGNATURE / DATE / PLACE
      // ========================================================

      final bool isDateLine = trimmed.startsWith('ದಿನಾಂಕ:');

      final bool isPlaceLine = trimmed.startsWith('ಸ್ಥಳ:');

      // --------------------------------------------------------
      // THANKING LINE
      // --------------------------------------------------------

      if ((isThanking || right) && !footerReserved) {
        // Reserve the closing and signature together, including handwritten-signature gaps.
        double footerHeight = 0;
        var closingEnd = lines.indexWhere(
          (line) => line.trim() == '[/RIGHT]',
          i,
        );
        if (closingEnd < i) closingEnd = i;
        for (var j = i; j <= closingEnd; j++) {
          final text = lines[j].trim();
          if (text.startsWith('[')) continue;
          if (text.isEmpty) {
            footerHeight += 9 * _scale;
            continue;
          }
          final measured = await _buildParagraph(
            text: _safeText(text),
            width: signatureBlockWidth,
            fontSize: defaultFontSize * _scale,
            alignment: ui.TextAlign.center,
            bold: bold,
          );
          footerHeight += measured.height + 4 * _scale;
        }
        y = _pagePosition(y, footerHeight);
        signatureY = null;
        drfoDateY = null;
        drfoPlaceY = null;
        footerReserved = true;
      }

      if (isThanking) {
        x = bodyX;
        paragraphWidth = contentWidth;
        alignment = ui.TextAlign.center;
      }

      // --------------------------------------------------------
      // RIGHT SIDE SIGNATURE BLOCK
      // --------------------------------------------------------

      if (right) {
        x = signatureBlockX;
        paragraphWidth = signatureBlockWidth;
        alignment = ui.TextAlign.center;

        signatureY ??= y;
      }

      // --------------------------------------------------------
      // DATE / PLACE
      //
      // These are printed on the LEFT side of the signature
      // block and vertically aligned with the signature block.
      //
      // DATE  -> same line as "ತಮ್ಮ ನಂಬುಗೆಯೊಂದಿಗೆ,"
      // PLACE -> same line as designation below it.
      // --------------------------------------------------------

      if (isDateLine || isPlaceLine) {
        x = bodyX;
        paragraphWidth = signatureBlockX - bodyX - (10 * _scale);

        alignment = ui.TextAlign.left;
      }

      // ========================================================
      // BUILD PARAGRAPH
      // ========================================================

      // --------------------------------------------------------
      // BODY FIRST-LINE INDENT
      //
      // We cannot simply move the entire paragraph because
      // continuation lines must remain at bodyX.
      //
      // Therefore the first line receives a visual indentation
      // while the paragraph width remains the full body width.
      // --------------------------------------------------------

      String paragraphText = _safeText(trimmed);

      if (isBodyParagraph) {
        paragraphText = ' ' * 0 + paragraphText;
      }

      final paragraph = await _buildParagraph(
        text: paragraphText,
        width: paragraphWidth,
        fontSize:
            (small
                ? 9.5
                : bold
                ? boldFontSize
                : defaultFontSize) *
            _scale,
        alignment: alignment,
        bold: bold,
      );

      final paragraphHeight = paragraph.height;

      // ========================================================
      // PAGE LIMIT
      // ========================================================

      // ========================================================
      // DRAW
      // ========================================================

      if (isBodyParagraph) {
        // ------------------------------------------------------
        // For justified body paragraphs, draw using an
        // indented paragraph width and then preserve the
        // left body margin for continuation lines.
        //
        // The first line indent is achieved by inserting
        // a small visual-width leading space.
        // ------------------------------------------------------

        final indentedText =
            '\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0'
            '${_safeText(trimmed)}';

        final indentedParagraph = await _buildParagraph(
          text: indentedText,
          width: paragraphWidth,
          fontSize:
              (small
                  ? 9.5
                  : bold
                  ? boldFontSize
                  : defaultFontSize) *
              _scale,
          alignment: ui.TextAlign.justify,
          bold: bold,
        );

        y = _drawFlowParagraph(canvas, indentedParagraph, x, y) + (4 * _scale);
      } else {
        if (!isDateLine && !isPlaceLine) {
          y = _pagePosition(y, paragraphHeight);
        }
        double drawY = y;

        // ------------------------------------------------------
        // DATE / PLACE
        // ------------------------------------------------------

        if (isDateLine) {
          if (drfoDateY != null) {
            drawY = drfoDateY!;
          } else if (signatureY != null) {
            drawY = signatureY!;
          }
        } else if (isPlaceLine) {
          if (drfoPlaceY != null) {
            drawY = drfoPlaceY!;
          } else if (signatureY != null) {
            drawY = signatureY! + paragraphHeight + (4 * _scale);
          }
        }

        canvas.drawParagraph(paragraph, ui.Offset(x, drawY));

        // Date/place are positioned beside the signature,
        // therefore they must NOT move the normal document Y.
        if (!isDateLine && !isPlaceLine) {
          final double extraSpacing = isOfficeAddress ? 0 : 4 * _scale;

          y += paragraphHeight + extraSpacing;
        }
      }
    }

    final picture = recorder.endRecording();

    final pages = <Uint8List>[];
    // Trailing blank template lines must not create an empty final page.
    final pageCount = math.max(
      1,
      ((math.max(contentEnd, y) - 1) / height).floor() + 1,
    );
    try {
      for (var page = 0; page < pageCount; page++) {
        final pageRecorder = ui.PictureRecorder();
        final pageCanvas = ui.Canvas(pageRecorder);
        pageCanvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
        pageCanvas.clipRect(
          ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        );
        pageCanvas.translate(0, -page * height.toDouble());
        pageCanvas.drawPicture(picture);
        final pagePicture = pageRecorder.endRecording();
        final image = await pagePicture.toImage(width, height);
        pagePicture.dispose();
        try {
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          if (data == null) throw StateError('Unable to render document page.');
          pages.add(data.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      }
    } finally {
      picture.dispose();
    }
    return pages;
  }

  // ==========================================================
  // RENDER MASTER TO PNG
  // ==========================================================

  Future<List<Uint8List>> _renderMasterToPng(
    String master, {
    _RfoLetterheadData? rfoLetterhead,
    List<_RtcTreeTableRow> rtcTreeRows = const [],
    List<_NotRecommendedTreeTableRow> notRecommendedTreeRows = const [],
    List<_GlTreeEnumerationRow> glTreeEnumerationRows = const [],
  }) async {
    final lines = master.trimRight().split('\n');

    return await _renderLetterPages(
      lines,
      rfoLetterhead: rfoLetterhead,
      rtcTreeRows: rtcTreeRows,
      notRecommendedTreeRows: notRecommendedTreeRows,
      glTreeEnumerationRows: glTreeEnumerationRows,
    );
  }

  // ==========================================================
  // SAFE FILE NAME
  // ==========================================================

  void _appendRenderedPages(pw.Document pdf, List<Uint8List> pages, {bool landscape = false}) {
    for (final bytes in pages) {
      final image = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
        ),
      );
    }
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  // ==========================================================
  // GENERATED DOCUMENT FOLDER
  // ==========================================================

  Future<Directory> _getGeneratedFolder(String officeNumber) async {
    final base = await getApplicationDocumentsDirectory();

    final safeOfficeNumber = _safeFileName(officeNumber);

    final folder = Directory(
      '${base.path}/TPMS/Generated Documents/'
      '$safeOfficeNumber',
    );

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    return folder;
  }

  // ==========================================================
  // SAVE PDF
  // ==========================================================

  Future<File> _savePdf({
    required String officeNumber,
    required String fileName,
    required List<int> bytes,
  }) async {
    final folder = await _getGeneratedFolder(officeNumber);

    final file = File('${folder.path}/$fileName');

    await file.writeAsBytes(bytes);
    await File(file.path + '.officer-addresses').writeAsString(await OfficerRepository().fingerprint());

    // Cloud: generated PDFs travel to other devices.
    CloudFileService.uploadGenerated(officeNumber, file);

    return file;
  }

  // ==========================================================
  // CLEAR OLD GENERATED DOCUMENTS
  // ==========================================================

  Future<void> clearGeneratedDocuments(String officeNumber) async {
    final base = await getApplicationDocumentsDirectory();

    final safeOfficeNumber = _safeFileName(officeNumber);
    final folder = Directory(
      '${base.path}/TPMS/Generated Documents/'
      '$safeOfficeNumber',
    );

    if (!await folder.exists()) {
      return;
    }

    await for (final entity in folder.list()) {
      if (entity is! File) {
        continue;
      }

      final fileName = entity.path.toLowerCase();

      final isPdf = fileName.endsWith('.pdf');

      final isMahazar = fileName.contains('mahazar');

      // Preserve the Mahazar generated by the inspecting officer.
      // Only old DRFO letters and enumeration lists are removed.
      if (isPdf && !isMahazar) {
        await entity.delete();
      }
    }

    // Cloud: keep remote listing in sync, then re-upload survivors.
    await CloudFileService.deletePrefix(
      CloudFileService.docsBucket,
      'generated/$officeNumber',
    );
    await for (final entity in folder.list()) {
      if (entity is File &&
          entity.path.toLowerCase().endsWith('.pdf')) {
        CloudFileService.uploadGenerated(officeNumber, entity);
      }
    }
  }

  Future<void> _deleteExistingMahazarFiles(String officeNumber) async {
    final base = await getApplicationDocumentsDirectory();

    final safeOfficeNumber = _safeFileName(officeNumber);

    final folder = Directory(
      '${base.path}/TPMS/Generated Documents/'
      '$safeOfficeNumber',
    );

    if (!await folder.exists()) {
      return;
    }

    await for (final entity in folder.list()) {
      if (entity is! File) {
        continue;
      }

      final fileName = entity.path.toLowerCase();

      if (fileName.endsWith('.pdf') && fileName.contains('mahazar')) {
        await entity.delete();
      }
    }

    // Cloud: keep remote listing in sync, then re-upload survivors.
    await CloudFileService.deletePrefix(
      CloudFileService.docsBucket,
      'generated/$officeNumber',
    );
    await for (final entity in folder.list()) {
      if (entity is File &&
          entity.path.toLowerCase().endsWith('.pdf')) {
        CloudFileService.uploadGenerated(officeNumber, entity);
      }
    }
  }

  // ==========================================================
  // GET EXISTING GENERATED DOCUMENTS
  // ==========================================================

  Future<List<File>> getGeneratedDocuments(String officeNumber) async {
    final base = await getApplicationDocumentsDirectory();

    final safeOfficeNumber = _safeFileName(officeNumber);

    final folder = Directory(
      '${base.path}/TPMS/Generated Documents/'
      '$safeOfficeNumber',
    );

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    // Cloud: download PDFs generated on other devices, and push
    // up local-only PDFs from before cloud sync existed.
    final remoteKeys = await CloudFileService.listKeys(
      CloudFileService.docsBucket,
      'generated/$officeNumber',
    );
    final remoteNames =
        remoteKeys.map((k) => k.split('/').last).toSet();
    for (final key in remoteKeys) {
      final name = key.split('/').last;
      try {
        await CloudFileService.ensureLocal(
          bucket: CloudFileService.docsBucket,
          key: key,
          localPath: '${folder.path}/$name',
        );
      } catch (_) {
        // Offline or missing remotely; local list still works.
      }
    }

    final List<File> files = [];

    await for (final entity in folder.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
        files.add(entity);
        final name =
            entity.path.split(Platform.pathSeparator).last;
        if (!remoteNames.contains(name)) {
          CloudFileService.uploadGenerated(officeNumber, entity);
        }
      }
    }

    final application = await ApplicationRepository().getByOfficeNumber(officeNumber);
    if (application != null) {
      for (final file in files) {
        await refreshOfficerAddresses(file, application: application);
      }
    }

    // Keep documents in a predictable order
    files.sort((a, b) => a.path.compareTo(b.path));

    return files;
  }

  // ==========================================================
  // DRFO DEFERRED LETTER
  // ==========================================================

  Future<File> generateDrfoDeferredLetter(ApplicationModel application) async {
    await _loadFlutterKannadaFont();

    print(
      'Generating DRFO Deferred Letter using '
      'Flutter Kannada text engine...',
    );

    // ----------------------------------------------------------
    // LOAD MASTER TEMPLATE
    // ----------------------------------------------------------

    final templateName =
        application.applicationType.trim().toUpperCase() == 'RTC'
        ? 'DRFO_DEFERRED_RTC.txt'
        : 'DRFO_DEFERRED_NON_RTC.txt';

    final template = await _loadTemplate(templateName);

    // ----------------------------------------------------------
    // INSERT APPLICATION VALUES
    // ----------------------------------------------------------

    final master = await _buildDeferredLetterMaster(template, application);

    // ----------------------------------------------------------
    // RENDER KANNADA THROUGH FLUTTER TEXT ENGINE
    // ----------------------------------------------------------

    final pngBytes = await _renderMasterToPng(master);

    // ----------------------------------------------------------
    // CREATE FINAL PDF
    // ----------------------------------------------------------

    final pdf = pw.Document();

    _appendRenderedPages(pdf, pngBytes);

    final bytes = await pdf.save();

    return await _savePdf(
      officeNumber: application.officeNumber,
      fileName:
          '${_safeFileName(application.officeNumber)}'
          '_DRFO_DEFERRED.pdf',
      bytes: bytes,
    );
  }

  // ==========================================================
  // DRFO RECOMMENDED REPORT
  // ==========================================================

  Future<bool> _areAllTreesNotRecommended(ApplicationModel application) async {
    if (application.id == null) {
      return false;
    }

    final trees = await TreeRepository().getTrees(application.id!);

    if (trees.isEmpty) {
      return false;
    }

    final recommendationTypes = await MasterRepository().getMasters(
      'Recommendation Type',
    );

    final notRecommendedType = recommendationTypes
        .where((item) => item['code']?.toString().trim().toUpperCase() == 'NR')
        .toList();

    if (notRecommendedType.isEmpty) {
      return false;
    }

    final notRecommendedTypeId = notRecommendedType.first['id'] as int;

    return trees.every(
      (tree) => tree.recommendationTypeId == notRecommendedTypeId,
    );
  }

  Future<File> generateDrfoRecommendedReport(
    ApplicationModel application,
  ) async {
    await _loadFlutterKannadaFont();

    print(
      'Generating DRFO Recommended Report using '
      'Flutter Kannada text engine...',
    );

    final applicationType = application.applicationType.trim().toUpperCase();

    final isRtcApplication = applicationType == 'RTC';
    final isGovernmentLand =
        applicationType == 'GL' ||
        applicationType == 'STGL' ||
        applicationType == 'CGL';

    final isPrivateLand = applicationType == 'PL';

    final isNotRecommended =
        !isRtcApplication && await _areAllTreesNotRecommended(application);

    final isBranchOnly = (applicationType == 'PL' || applicationType == 'SPL') &&
        application.id != null &&
        await TreeRepository().areAllTreesBranchOnly(application.id!);

    final template = await _loadTemplate(
      isBranchOnly ? 'DRFO_BRANCH_PERMISSION_PL.txt' : isRtcApplication
          ? 'DRFO_RECOMMENDED_RTC.txt'
          : isNotRecommended
          ? 'DRFO_NOT_RECOMMENDED.txt'
          : isGovernmentLand
          ? 'DRFO_RECOMMENDED_GL.txt'
          : isPrivateLand
          ? 'DRFO_RECOMMENDED_PL.txt'
          : 'DRFO_RECOMMENDED.txt',
    );

    final rtcTreeRows = isRtcApplication
        ? await _buildRtcTreeTableRows(application)
        : const <_RtcTreeTableRow>[];

    final notRecommendedTreeRows = isNotRecommended
        ? await _buildNotRecommendedTreeTableRows(application)
        : const <_NotRecommendedTreeTableRow>[];

    final master = await _buildRecommendedReportMaster(template, application);

    final pngBytes = await _renderMasterToPng(
      master,
      rtcTreeRows: rtcTreeRows,
      notRecommendedTreeRows: notRecommendedTreeRows,
    );

    final pdf = pw.Document();

    _appendRenderedPages(pdf, pngBytes);

    final bytes = await pdf.save();

    return await _savePdf(
      officeNumber: application.officeNumber,
      fileName:
          '${_safeFileName(application.officeNumber)}'
          '${isNotRecommended ? '_DRFO_NOT_RECOMMENDED.pdf' : '_DRFO_RECOMMENDED.pdf'}',
      bytes: bytes,
    );
  }

  Future<File> generateRfoRtcApprovedLetter(
    ApplicationModel application,
  ) async {
    await _loadFlutterKannadaFont();

    final applicationType = application.applicationType.trim().toUpperCase();

    if (applicationType != "RTC") {
      throw Exception(
        "RTC RFO letter can be generated only "
        "for RTC applications.",
      );
    }

    final isDeferred =
        application.inspectionDecision.trim().toUpperCase() == "DEFERRED";

    final template = await _loadRfoTemplate(
      isDeferred ? "RFO_DEFERRED_RTC.txt" : "RFO_APPROVED_RTC.txt",
    );

    final master = isDeferred
        ? await _buildRfoRtcDeferredMaster(template, application)
        : await _buildRfoRtcApprovedMaster(template, application);

    final rtcTreeRows = isDeferred
        ? <_RtcTreeTableRow>[]
        : await _buildRtcTreeTableRows(application);

    final officeConfiguration = await OfficeConfigurationRepository()
        .getConfiguration();

    final rangeName =
        officeConfiguration?["rangeName"]?.toString().trim().isNotEmpty == true
        ? officeConfiguration!["rangeName"].toString().trim()
        : "";

    final rangeLocation =
        officeConfiguration?["rangeLocation"]?.toString().trim().isNotEmpty ==
            true
        ? officeConfiguration!["rangeLocation"].toString().trim()
        : rangeName;

    final rangeOfficeAddress =
        officeConfiguration?["rangeOfficeAddress"]?.toString().trim() ?? "";

    final rangeEmail =
        officeConfiguration?["rangeEmail"]?.toString().trim() ?? "";

    final logoPath =
        officeConfiguration?["rfoOfficeLogoPath"]?.toString().trim() ?? "";

    final letterhead = _RfoLetterheadData(
      // For now use the application number,
      // as instructed.
      letterNumber: application.officeNumber,
      rangeName: rangeName,
      rangeLocation: rangeLocation,
      rangeOfficeAddress: rangeOfficeAddress,
      rangeEmail: rangeEmail,
      logoPath: logoPath,
      approvalDate: _date(application.rfoApprovalDate),
    );

    final pngBytes = await _renderMasterToPng(
      master,
      rfoLetterhead: letterhead,
      rtcTreeRows: rtcTreeRows,
    );

    final pdf = pw.Document();

    _appendRenderedPages(pdf, pngBytes);

    final bytes = await pdf.save();

    return await _savePdf(
      officeNumber: application.officeNumber,
      fileName:
          "${_safeFileName(application.officeNumber)}"
          "${isDeferred ? '_RFO_DEFERRED_RTC.pdf' : '_RFO_APPROVED_RTC.pdf'}",
      bytes: bytes,
    );
  }

  Future<File> generateRfoNonRtcDecisionLetter(
    ApplicationModel application,
  ) async {
    await _loadFlutterKannadaFont();

    final applicationType = application.applicationType.trim().toUpperCase();

    final isDeferred =
        application.inspectionDecision.trim().toUpperCase() == "DEFERRED";

    final isNotRecommended =
        !isDeferred && await _areAllTreesNotRecommended(application);

    if (applicationType == "RTC" || (!isDeferred && !isNotRecommended)) {
      throw Exception(
        "This RFO letter can be generated only "
        "for deferred or fully not-recommended "
        "non-RTC applications.",
      );
    }

    final applicationId = application.id;

    if (applicationId == null) {
      throw Exception("Application ID is required.");
    }

    final recipientRepository = RfoDeferredLetterRecipientRepository();

    final recipients = await recipientRepository.getRecipients(applicationId);

    RfoDeferredLetterRecipient? primaryRecipient;

    final copyRecipients = <RfoDeferredLetterRecipient>[];

    for (final recipient in recipients) {
      if (recipient.isPrimary) {
        primaryRecipient = recipient;
      } else {
        copyRecipients.add(recipient);
      }
    }

    if (primaryRecipient == null) {
      throw Exception(
        "Select the To recipient before "
        "generating the RFO letter.",
      );
    }

    final template = await _loadRfoTemplate(
      isNotRecommended
          ? "RFO_NOT_RECOMMENDED_NON_RTC.txt"
          : "RFO_DEFERRED_NON_RTC.txt",
    );

    final originalMaster = await _buildRfoNonRtcDeferredMaster(
      template: template,
      application: application,
      primaryRecipient: primaryRecipient,
      copyRecipients: copyRecipients,
      isCopyPage: false,
    );

    String? copyMaster;

    if (copyRecipients.isNotEmpty) {
      copyMaster = await _buildRfoNonRtcDeferredMaster(
        template: template,
        application: application,
        primaryRecipient: primaryRecipient,
        copyRecipients: copyRecipients,
        isCopyPage: true,
      );
    }

    final notRecommendedTreeRows = isNotRecommended
        ? await _buildNotRecommendedTreeTableRows(application)
        : <_NotRecommendedTreeTableRow>[];

    final officeConfiguration = await OfficeConfigurationRepository()
        .getConfiguration();

    final rangeName =
        officeConfiguration?["rangeName"]?.toString().trim().isNotEmpty == true
        ? officeConfiguration!["rangeName"].toString().trim()
        : "";

    final rangeLocation =
        officeConfiguration?["rangeLocation"]?.toString().trim().isNotEmpty ==
            true
        ? officeConfiguration!["rangeLocation"].toString().trim()
        : rangeName;

    final rangeOfficeAddress =
        officeConfiguration?["rangeOfficeAddress"]?.toString().trim() ?? "";

    final rangeEmail =
        officeConfiguration?["rangeEmail"]?.toString().trim() ?? "";

    final logoPath =
        officeConfiguration?["rfoOfficeLogoPath"]?.toString().trim() ?? "";

    final letterhead = _RfoLetterheadData(
      letterNumber: application.officeNumber,
      rangeName: rangeName,
      rangeLocation: rangeLocation,
      rangeOfficeAddress: rangeOfficeAddress,
      rangeEmail: rangeEmail,
      logoPath: logoPath,
      approvalDate: _date(application.rfoApprovalDate),
    );

    final originalPngBytes = await _renderMasterToPng(
      originalMaster,
      rfoLetterhead: letterhead,
      notRecommendedTreeRows: notRecommendedTreeRows,
    );

    final pdf = pw.Document();

    _appendRenderedPages(pdf, originalPngBytes);

    if (copyMaster != null) {
      final copyPngBytes = await _renderMasterToPng(
        copyMaster,
        rfoLetterhead: letterhead,
        notRecommendedTreeRows: notRecommendedTreeRows,
      );

      _appendRenderedPages(pdf, copyPngBytes);
    }

    final bytes = await pdf.save();

    return await _savePdf(
      officeNumber: application.officeNumber,
      fileName:
          "${_safeFileName(application.officeNumber)}"
          "${isNotRecommended ? '_RFO_NOT_RECOMMENDED_NON_RTC.pdf' : '_RFO_DEFERRED_NON_RTC.pdf'}",
      bytes: bytes,
    );
  }

  Future<File> generateRfoRevenueOpinionRequestLetter(
    ApplicationModel application, {
    int? authorityId,
    int? requestCycle,
  }) async {
    await _loadFlutterKannadaFont();

    final applicationType = application.applicationType.trim().toUpperCase();

    if (applicationType != "PL") {
      throw Exception(
        "Revenue Opinion request letter can be generated "
        "only for Private Land applications.",
      );
    }

    final template = await _loadRfoTemplate(
      "RFO_REVENUE_OPINION_REQUEST_PL.txt",
    );

    final originalMaster = await _buildRfoRevenueOpinionRequestMaster(
      template: template,
      application: application,
      isCopyPage: false,
      authorityId: authorityId,
    );

    final copyMaster = await _buildRfoRevenueOpinionRequestMaster(
      template: template,
      application: application,
      isCopyPage: true,
      authorityId: authorityId,
    );

    final officeConfiguration = await OfficeConfigurationRepository()
        .getConfiguration();

    final rangeName =
        officeConfiguration?["rangeName"]?.toString().trim().isNotEmpty == true
        ? officeConfiguration!["rangeName"].toString().trim()
        : "";

    final rangeLocation =
        officeConfiguration?["rangeLocation"]?.toString().trim().isNotEmpty ==
            true
        ? officeConfiguration!["rangeLocation"].toString().trim()
        : rangeName;

    final rangeOfficeAddress =
        officeConfiguration?["rangeOfficeAddress"]?.toString().trim() ?? "";

    final rangeEmail =
        officeConfiguration?["rangeEmail"]?.toString().trim() ?? "";

    final logoPath =
        officeConfiguration?["rfoOfficeLogoPath"]?.toString().trim() ?? "";

    final letterhead = _RfoLetterheadData(
      letterNumber: application.officeNumber,
      rangeName: rangeName,
      rangeLocation: rangeLocation,
      rangeOfficeAddress: rangeOfficeAddress,
      rangeEmail: rangeEmail,
      logoPath: logoPath,
      approvalDate: _date(application.rfoApprovalDate),
    );

    final originalPngBytes = await _renderMasterToPng(
      originalMaster,
      rfoLetterhead: letterhead,
    );

    final copyPngBytes = await _renderMasterToPng(
      copyMaster,
      rfoLetterhead: letterhead,
    );

    final pdf = pw.Document();

    _appendRenderedPages(pdf, originalPngBytes);

    _appendRenderedPages(pdf, copyPngBytes);

    final bytes = await pdf.save();

    return await _savePdf(
      officeNumber: application.officeNumber,
      fileName:
          "${_safeFileName(application.officeNumber)}"
          "_RFO_REVENUE_OPINION_REQUEST" + (requestCycle == null ? '' : '_CYCLE_' + requestCycle.toString()) + '.pdf',
      bytes: bytes,
    );
  }

  Future<List<Uint8List>> _renderTagguBelePatti(String template, List<_GlTreeEnumerationRow> rows) async {
    String block(String tag) {
      final match = RegExp('\\[' + tag + '\\]([\\s\\S]*?)\\[/' + tag + '\\]').firstMatch(template);
      if (match == null) throw StateError('Missing [' + tag + '] block in Taggu Bele Patti template.');
      return match.group(1)!.trim();
    }
    final title = block('TITLE');
    final intro = block('INTRO');
    final totalLabel = block('TOTAL');
    final headings = block('HEADERS').split('|').map((s) => s.trim()).toList();
    if (headings.length != 17) throw StateError('Taggu Bele Patti requires 17 editable column headings separated by |.');
    final total = rows.fold<double>(0, (sum, row) => sum + row.totalValueNumber);
    final showConservator = (total * 100).round() > 2300000;
    final weights = <double>[25,33,63,45,40,38,45,45,51,51,52,52,52,45,45,45,55];
    if (!showConservator) { headings.removeAt(15); weights.removeAt(15); }
    final width = PdfPageFormat.a4.landscape.width * _scale;
    final height = PdfPageFormat.a4.landscape.height * _scale;
    final margin = 32 * _scale;
    final content = width - margin * 2;
    final bottom = height - margin;
    final sumWeights = weights.reduce((a,b) => a+b);
    final widths = weights.map((w) => content * w / sumWeights).toList();
    final x = <double>[margin];
    for (final w in widths) { x.add(x.last+w); }
    final border = ui.Paint()..color=const ui.Color(0xFF000000)..style=ui.PaintingStyle.stroke..strokeWidth=0.45*_scale;
    final pages = <Uint8List>[];
    late ui.PictureRecorder recorder;
    late ui.Canvas canvas;
    double y = margin;
    double? lotTop;
    Future<ui.Paragraph> paragraph(String text, double w, {bool bold=false, double size=7.8}) =>
      _buildParagraph(text:text,width:w,fontSize:size*_scale,alignment:ui.TextAlign.center,bold:bold,lineHeight:1.25);
    Future<List<ui.Paragraph>> cells(List<String> values, {bool bold=false}) async {
      return Future.wait(List.generate(values.length, (i) => paragraph(values[i], widths[i]-4*_scale,bold:bold)));
    }
    final header = await cells(headings,bold:true);
    final headerHeight = header.map((p)=>p.height).reduce(math.max)+10*_scale;
    void drawCells(List<ui.Paragraph> paragraphs, double h, {bool skipLot=false}) {
      for(var i=skipLot?1:0;i<paragraphs.length;i++) {
        canvas.drawRect(ui.Rect.fromLTWH(x[i],y,widths[i],h),border);
        canvas.drawParagraph(paragraphs[i],ui.Offset(x[i]+2*_scale,y+4*_scale));
      }
    }
    Future<void> closeLot() async {
      if(lotTop==null)return;
      canvas.drawRect(ui.Rect.fromLTWH(x[0],lotTop!,widths[0],y-lotTop!),border);
      final label=await paragraph('1',widths[0]-4*_scale);
      canvas.drawParagraph(label,ui.Offset(x[0]+2*_scale,lotTop!+4*_scale));
      lotTop=null;
    }
    Future<void> finishPage() async {
      await closeLot();
      final picture=recorder.endRecording();
      final image=await picture.toImage(width.round(),height.round());
      final data=await image.toByteData(format:ui.ImageByteFormat.png);
      pages.add(data!.buffer.asUint8List());image.dispose();picture.dispose();
    }
    Future<void> startPage({bool first=false}) async {
      recorder=ui.PictureRecorder();canvas=ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xFFFFFFFF),ui.BlendMode.src);y=margin;
      final heading=await paragraph(title,content,bold:true,size:12);
      canvas.drawParagraph(heading,ui.Offset(margin,y));
      final titleWidth=heading.longestLine;
      canvas.drawLine(ui.Offset(margin+(content-titleWidth)/2,y+heading.height),ui.Offset(margin+(content+titleWidth)/2,y+heading.height),border);
      y+=heading.height+12*_scale;
      if(first) {
        final description=await paragraph(intro,content,bold:true,size:10.5);
        canvas.drawParagraph(description,ui.Offset(margin,y));y+=description.height+14*_scale;
      }
      if(y+headerHeight+30*_scale>bottom)throw StateError('Shorten the Taggu Bele Patti introductory text or column headings.');
      drawCells(header,headerHeight);y+=headerHeight;
    }
    await startPage(first:true);
    for(var index=0;index<rows.length;index++) {
      final row=rows[index];
      final values=<String>['',row.treeNumber,row.speciesName,
        row.mergeGbhAndHeight?row.mergedMeasurement:row.gbh,row.height,
        row.timberVolume,row.poleCount,row.firewood,row.timberValue,row.poleValue,row.firewoodValue,row.totalValue,
        '', '', '', if(showConservator)'',row.recommendationReason];
      final measured=await cells(values);
      final h=math.max(27*_scale,measured.map((p)=>p.height).reduce(math.max)+8*_scale);
      final reserve=index==rows.length-1?27*_scale:0;
      if(y+h+reserve>bottom) {await finishPage();await startPage();}
      if(y+h+reserve>bottom)throw StateError('A tree row is too tall to print. Shorten its recommendation reason.');
      lotTop??=y;
      drawCells(measured,h,skipLot:true);y+=h;
    }
    await closeLot();
    final totalHeight=27*_scale;
    final label=await paragraph(totalLabel,x[11]-margin-4*_scale,bold:true);
    canvas.drawRect(ui.Rect.fromLTWH(margin,y,x[11]-margin,totalHeight),border);
    canvas.drawParagraph(label,ui.Offset(margin+2*_scale,y+5*_scale));
    for(var i=11;i<widths.length;i++) {
      canvas.drawRect(ui.Rect.fromLTWH(x[i],y,widths[i],totalHeight),border);
      if(i==11) {
        final amount=await paragraph(NumberFormat('#,##,##0.00','en_IN').format(total),widths[i]-4*_scale,bold:true);
        canvas.drawParagraph(amount,ui.Offset(x[i]+2*_scale,y+5*_scale));
      }
    }
    y+=totalHeight;
    await finishPage();return pages;
  }

  Future<String> _buildGovernmentDoReferences(ApplicationModel application) async {
    final appReceived = _date(application.receivedDate);
    final references = <String>[
      '1. ' + application.applicantName + ' ರವರ ಮನವಿ ದಿನಾಂಕ: ' + _date(application.applicationDate) +
        (appReceived.isEmpty ? '.' : ' (ಸ್ವೀಕೃತಿ ದಿನಾಂಕ: $appReceived).'),
    ];
    for (final reference in application.forwardingReferences) {
      if (reference.forwardedBy.trim().isEmpty && reference.referenceNumber.trim().isEmpty && reference.referenceDate.trim().isEmpty) continue;
      references.add((references.length + 1).toString() + '. ' + reference.forwardedBy.trim() +
        ' ರವರ ಪತ್ರ ಸಂಖ್ಯೆ: ' + reference.referenceNumber.trim() + ', ದಿನಾಂಕ: ' + _date(reference.referenceDate) + _receivedSuffix(reference) + '.');
    }
    references.add((references.length + 1).toString() + '. ಉಪ ವಲಯ ಅರಣ್ಯಾಧಿಕಾರಿ -ವ- ಮೋಜಣಿದಾರರು, ' +
      await _printSectionName(application) + ' ಶಾಖೆ ರವರ ವರದಿ ದಿನಾಂಕ: ' + _date(application.drfoInspectionDate) + '.');
    return references.join('\n');
  }

  Future<String> _auctionLayoutFingerprint() async =>
      'taggu-landscape-v1\n' + await _loadRfoTemplate('RFO_GL_DO.txt') +
      '\n' + await _loadRfoTemplate('RFO_GL_TAGGU_BELE_PATTI.txt');

  Future<List<File>> generateGovernmentLandLetters(ApplicationModel application, GovernmentApproval approval, {bool afterReply = false}) async {
    if (!GovernmentApproval.isGovernment(application.applicationType) || approval.applicationId != application.id) throw StateError('Government application is required.');
    final error = GovernmentApprovalRepository.validateOptions(approval);
    if (error != null) throw StateError(error);
    if (afterReply && !approval.allApproved) throw StateError('Approve all five fields of a valid government reply before final approval.');
    if (afterReply && (approval.permissionType != 'Valuation' || approval.khataGiven != false || approval.requestLetterPath.isEmpty)) throw StateError('A saved government document request is required for reply-based valuation approval.');
    await _loadFlutterKannadaFont();
    final auction = approval.permissionType == 'Auction' || (afterReply && approval.answers['nature'] == 'Not satisfied');
    final request = !auction && approval.khataGiven == false && !afterReply;
    final templates = auction ? ['RFO_GL_DO.txt', 'RFO_GL_TAGGU_BELE_PATTI.txt'] : [request ? 'RFO_GL_DOCUMENT_REQUEST.txt' : 'RFO_GL_VALUATION.txt'];
    String officerAddress = '';
    if (!request) {
      final officers = await TreeOfficerRepository().getAll();
      final selected = officers.where((row) => row['id'] == approval.treeOfficerId).toList();
      if (selected.isEmpty) throw StateError('Select Tree officer.');
      // Designation + posting address only (officer names print
      // in To address in the DO letter alone).
      officerAddress = await OfficerRepository().addressForRole(selected.single['code'].toString());
    }
    String? senderName;
    String senderAddress = '';
    String recipientName = '';
    if (auction) {
      final directory = await OfficerRepository().getAll();
      final sender = directory.where((row) => row['role'] == 'RFO').toList();
      if (sender.isEmpty) throw StateError('Add the RFO officer in Administration > Officers before generating the DO letter.');
      senderName = sender.single['name'].toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      senderAddress = OfficerRepository.formatAddress(sender.single);
      final selected = (await TreeOfficerRepository().getAll()).firstWhere((row) => row['id'] == approval.treeOfficerId);
      final recipientRows = directory.where((row) => row['role'] == selected['code']).toList();
      if (recipientRows.isEmpty) throw StateError('Add the ${selected['code']} officer in Administration > Officers before generating the DO letter.');
      recipientName = recipientRows.single['name'].toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    final config = await OfficeConfigurationRepository().getConfiguration();
    final range = config?['rangeName']?.toString() ?? '';
    final location = config?['rangeLocation']?.toString() ?? range;
    final rows = await _buildGlTreeEnumerationRows(application, rfoApprovedOnly: auction);
    if (rows.isEmpty) throw StateError('No recommended trees are available for the government letter.');
    final money = NumberFormat('#,##,##0.00', 'en_IN');
    final total = rows.fold<double>(0, (sum, row) => sum + row.totalValueNumber);
    final answers = approval.answers;
    final replyReceived = _date(answers['receivedDate'] ?? '');
    final replyReference = afterReply
        ? '3. ' + application.applicantName + ' ರವರ ಪತ್ರ ಸಂಖ್ಯೆ: ' + (answers['letterNumber'] ?? '') + ', ದಿನಾಂಕ: ' + _date(answers['letterDate'] ?? '') + (replyReceived.isEmpty ? '.' : ' (ಸ್ವೀಕೃತಿ ದಿನಾಂಕ: $replyReceived).')
        : '';
    var valuationReferences = await _buildGovernmentDoReferences(application);
    if (afterReply) {
      final forwardedCount = application.forwardingReferences.where((reference) =>
          reference.forwardedBy.trim().isNotEmpty || reference.referenceNumber.trim().isNotEmpty || reference.referenceDate.trim().isNotEmpty).length;
      valuationReferences += '\n' + (forwardedCount + 3).toString() + '. ' +
          (answers['authority'] ?? '') + ' ರವರ ಪತ್ರ ಸಂಖ್ಯೆ: ' + (answers['letterNumber'] ?? '') +
          ', ದಿನಾಂಕ: ' + _date(answers['letterDate'] ?? '') +
          (replyReceived.isEmpty ? '.' : ' (ಸ್ವೀಕೃತಿ ದಿನಾಂಕ: $replyReceived).');
    }
    final values = <String,String>{
      '{{APPLICANT_LETTER_NUMBER_PHRASE}}': application.applicantLetterNumber.trim().isEmpty ? '' : ' ಸಂಖ್ಯೆ: ' + application.applicantLetterNumber.trim(),
      '{{VALUATION_REFERENCES}}': valuationReferences,
      '{{RFO_NAME}}': senderName ?? '',
      '{{DO_REFERENCES}}': await _buildGovernmentDoReferences(application),
      '{{TREE_OFFICER_NAME}}': recipientName,
      '{{RFO_DESIGNATION_ADDRESS}}': senderAddress,
      '{{OFFICE_NUMBER}}': application.officeNumber,
      '{{APPLICANT_NAME}}': application.applicantName,
      '{{APPLICANT_ADDRESS}}': application.applicantAddress,
      '{{APPLICATION_DATE}}': _date(application.applicationDate),
      '{{RECEIVED_DATE}}': _date(application.receivedDate),
      '{{DRFO_REPORT_DATE}}': _date(application.drfoInspectionDate),
      '{{TREE_LOCATION}}': _location(application),
      '{{SECTION}}': await _printSectionName(application),
      '{{BEAT}}': await _printBeatName(application),
      '{{APPLICATION_TYPE}}': application.applicationType,
      '{{RANGE_NAME}}': range, '{{RANGE_LOCATION}}': location,
      '{{LETTER_DATE}}': _date(application.rfoApprovalDate),
      '{{TREE_OFFICER_TO_ADDRESS}}': officerAddress,
      '{{TOTAL_RECOMMENDED_TREES}}': rows.length.toString(),
      '{{GRAND_TOTAL_VALUE}}': money.format(total),
      '{{APPLICANT_REPLY_REFERENCE}}': replyReference,
      '{{REPLY_AUTHORITY}}': answers['authority'] ?? '',
      '{{REPLY_LETTER_NUMBER}}': answers['letterNumber'] ?? '',
      '{{REPLY_LETTER_DATE}}': _date(answers['letterDate'] ?? ''),
      '{{REPLY_RECEIVED_DATE}}': _date(answers['receivedDate'] ?? ''),
      '{{DOCUMENT_REQUEST_DATE}}': _date(approval.requestDate.isEmpty ? application.rfoApprovalDate : approval.requestDate),
    };
    final files = <File>[];
    for (final templateName in templates) {
      var master = await _loadRfoTemplate(templateName);
      final isDo = templateName == 'RFO_GL_DO.txt';
      final isPatti = templateName == 'RFO_GL_TAGGU_BELE_PATTI.txt';
      final isValuation = templateName == 'RFO_GL_VALUATION.txt';
      // Resolve the saved approval date before the shared report's current-date fallback.
      master = master.replaceAll('{{LETTER_DATE}}', _date(application.rfoApprovalDate));
      if (isDo || isPatti || isValuation || request) master = await _buildRecommendedReportMaster(master, application, rfoApprovedOnly: auction || isValuation);
      master = master.replaceAllMapped(RegExp(r'\{\{[A-Z_]+\}\}'), (match) {
        final key = match.group(0)!;
        if (key == '{{GL_TREE_ENUMERATION_TABLE}}' || key == '{{TAGGU_BELE_TABLE}}') return key;
        if (!values.containsKey(key)) throw StateError('Unknown government template placeholder: ' + key);
        if (key == '{{APPLICANT_REPLY_REFERENCE}}' || key == '{{APPLICANT_LETTER_NUMBER_PHRASE}}') return values[key]!;
        return values[key]!.trim().isEmpty ? '—' : values[key]!;
      });
      final pages = isPatti ? await _renderTagguBelePatti(master, rows) : await _renderMasterToPng(master, glTreeEnumerationRows: rows, rfoLetterhead: _RfoLetterheadData(
        doSenderName: isDo ? senderName : null, doSenderAddress: isDo ? senderAddress : '',
        letterNumber: application.officeNumber, rangeName: range, rangeLocation: location,
        rangeOfficeAddress: config?['rangeOfficeAddress']?.toString() ?? '', rangeEmail: config?['rangeEmail']?.toString() ?? '',
        logoPath: config?['rfoOfficeLogoPath']?.toString() ?? '', approvalDate: _date(application.rfoApprovalDate),
      ));
      final pdf = pw.Document(); _appendRenderedPages(pdf, pages, landscape: isPatti);
      files.add(await _savePdf(officeNumber: application.officeNumber,
        fileName: _safeFileName(application.officeNumber) + '_' + templateName.replaceAll('.txt', '.pdf'), bytes: await pdf.save()));
      if (auction) await File(files.last.path + '.auction-layout').writeAsString(await _auctionLayoutFingerprint());
      if (isValuation) await File(files.last.path + '.valuation-layout').writeAsString(await _loadRfoTemplate('RFO_GL_VALUATION.txt'));
      if (request) await File(files.last.path + '.request-layout').writeAsString(await _loadRfoTemplate('RFO_GL_DOCUMENT_REQUEST.txt'));
    }
    return files;
  }

  Future<File> generateRfoPrivateLandBranchPermissionLetter(
    ApplicationModel application,
  ) async {
    final type = application.applicationType.trim().toUpperCase();
    if (application.id == null || !{'PL', 'SPL'}.contains(type) ||
        application.inspectionDecision.trim().toUpperCase() == 'DEFERRED' ||
        !await TreeRepository().areAllTreesBranchOnly(application.id!)) {
      throw StateError('Branch permission requires at least one branch-only recommendation and no Full Tree or missing recommendations.');
    }
    await _loadFlutterKannadaFont();
    final config = await OfficeConfigurationRepository().getConfiguration();
    final range = config?['rangeName']?.toString() ?? '';
    final location = config?['rangeLocation']?.toString() ?? range;
    final trees = await TreeRepository().getTrees(application.id!);
    final masters = MasterRepository();
    final species = await masters.getSpecies();
    final recommendations = await masters.getMasters('Recommendation Type');
    String name(Map<String, dynamic> row) =>
        row['kannadaName']?.toString().trim().isNotEmpty == true
            ? row['kannadaName'].toString() : row['value']?.toString() ?? '—';
    final speciesNames = {for (final row in species) row['id']: name(row)};
    final recommendationNames = {for (final row in recommendations) row['id']: name(row)};
    final codes = {for (final row in recommendations) row['id']: row['code']?.toString().trim().toUpperCase()};
    final permittedTrees = trees.where((tree) {
      final code = codes[tree.recommendationTypeId];
      return code != null && code.isNotEmpty && code != 'NR' && code != 'FULL';
    });
    final details = permittedTrees.map((tree) {
      final code = codes[tree.recommendationTypeId];
      final quantity = code == 'BRANCH' ? ' / ಕೊಂಬೆಗಳ ಸಂಖ್ಯೆ: ' + (tree.numberOfBranches ?? 0).toString()
          : code == 'TWIG' ? ' / ಸಣ್ಣ ತುದಿಗಳ ಸಂಖ್ಯೆ: ' + (tree.numberOfTwigs ?? 0).toString() : '';
      return tree.treeNumber + '. ' + (speciesNames[tree.speciesId] ?? '—') + ' — ' +
          (recommendationNames[tree.recommendationTypeId] ?? '—') + quantity;
    }).join('\n');
    final values = <String, String>{
      '{{OFFICE_NUMBER}}': application.officeNumber,
      '{{APPLICATION_DATE}}': _date(application.applicationDate),
      '{{APPLICANT_NAME}}': application.applicantName,
      '{{APPLICANT_ADDRESS}}': application.applicantAddress,
      '{{TREE_LOCATION}}': _location(application),
      '{{SECTION}}': await _printSectionName(application),
      '{{BEAT}}': await _printBeatName(application),
      '{{RANGE_NAME}}': range, '{{RANGE_LOCATION}}': location,
      '{{LETTER_DATE}}': _date(application.rfoApprovalDate),
      '{{TREE_DETAILS}}': details,
    };
    final template = await _loadRfoTemplate('RFO_BRANCH_PERMISSION_PL.txt');
    final master = template.replaceAllMapped(RegExp(r'\{\{[A-Z_]+\}\}'), (match) {
      final value = values[match.group(0)];
      if (value == null) throw StateError('Unknown branch permission placeholder: ' + match.group(0)!);
      return value.trim().isEmpty ? '—' : value;
    });
    final pages = await _renderMasterToPng(master, rfoLetterhead: _RfoLetterheadData(
      letterNumber: application.officeNumber, rangeName: range, rangeLocation: location,
      rangeOfficeAddress: config?['rangeOfficeAddress']?.toString() ?? '',
      rangeEmail: config?['rangeEmail']?.toString() ?? '',
      logoPath: config?['rfoOfficeLogoPath']?.toString() ?? '',
      approvalDate: _date(application.rfoApprovalDate),
    ));
    final pdf = pw.Document();
    _appendRenderedPages(pdf, pages);
    return _savePdf(officeNumber: application.officeNumber,
      fileName: _safeFileName(application.officeNumber) + '_RFO_PRIVATE_LAND_BRANCH_PERMISSION.pdf',
      bytes: await pdf.save());
  }

  /// Officer-master display name for a tree-officer role code.
  /// Tree-officer mapping names are never printed; the mapping only
  /// carries the felling-permission flag.
  Future<String> _officerMasterDisplayName(
    String roleCode,
    String fallback,
  ) async {
    try {
      final directory = await OfficerRepository().getAll();
      for (final row in directory) {
        if ((row['role']?.toString() ?? '').trim().toUpperCase() ==
            roleCode.trim().toUpperCase()) {
          final name = (row['name']?.toString() ?? '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          if (name.isNotEmpty) return name;
        }
      }
    } catch (_) {
      // Fall through to mapping name.
    }
    return fallback;
  }

  Future<Map<String, String>> _privateLandApprovalValues(ApplicationModel application, RevenueReply reply, {bool addressTreeOfficer = true}) async {
    final applicationId = application.id;
    if (applicationId == null) throw StateError('Application is missing.');
    final officerRepository = TreeOfficerRepository();
    final officerId = await officerRepository.getSelection(applicationId);
    final officers = await officerRepository.getAll();
    final selected = officers.where((row) => row['id'] == officerId);
    if (selected.isEmpty || selected.first['name'].toString().trim().isEmpty) {
      throw StateError('Select Tree officer on the Final Approval page before generating the approval letter.');
    }
    final masterRepository = MasterRepository();
    final recommendationTypes = await masterRepository.getMasters('Recommendation Type');
    final recommendedIds = recommendationTypes.where((row) =>
        {'FULL', 'BRANCH', 'TWIG', 'TOP'}.contains(row['code']?.toString().trim().toUpperCase()))
        .map((row) => row['id']).toSet();
    final trees = await TreeRepository().getTrees(applicationId);
    final recommended = trees.where((tree) => recommendedIds.contains(tree.recommendationTypeId)).toList();
    final decisions = await RfoItemApprovalRepository().getApplicationDecisions(applicationId);
    final approvedIds = decisions.where((row) => row['itemKey'] == 'TREE' &&
        {'APPROVE', 'MODIFY'}.contains(row['decision']?.toString().trim().toUpperCase())).map((row) => row['itemId']).toSet();
    final approvedCount = recommended.where((tree) => approvedIds.contains(tree.id)).length;
    if (approvedCount == 0) throw StateError('No RFO-approved recommended trees are available for the approval letter.');
    final revenueSelection = await ApplicationRevenueOpinionRepository().getByApplication(applicationId);
    final opinion = revenueSelection == null ? null : await RevenueOpinionRepository().getById(revenueSelection.revenueOpinionId);
    final revenueRemarks = opinion == null ? '' : (opinion.remarks.trim().isNotEmpty ? opinion.remarks.trim() : opinion.revenueOpinion.trim());
    final locationPhrase = application.treeLocationSame ? '' : application.treeLocationAddress.trim();
    final whyRemoving = await _masterKannadaName(masterRepository, application.whyRemovingId);
    final replyDetails = ['ownership', 'reserved', 'taxes', 'dispute', 'extra']
        .map((key) => reply.answers[key]?.trim() ?? '').where((value) => value.isNotEmpty).join(', ');
    // To address: designation + posting address only. Officer names
    // appear in To address in the DO letter alone.
    String treeOfficerToAddress = '';
    if (addressTreeOfficer &&
        {'ACF', 'DCF'}.contains(selected.first['code'])) {
      treeOfficerToAddress =
          await OfficerRepository().addressForRole(
                selected.first['code'].toString(),
              );
    }
    return {
      '{{TREE_OFFICER_TO_ADDRESS}}': treeOfficerToAddress,
      '{{TREE_LOCATION_SUBJECT_PHRASE}}': locationPhrase,
      '{{TREE_LOCATION_BODY_PHRASE}}': locationPhrase,
      '{{RECEIVED_DATE}}': _date(application.receivedDate),
      '{{DRFO_REPORT_DATE}}': _date(application.drfoInspectionDate),
      '{{WHY_REMOVING_KANNADA}}': whyRemoving,
      '{{TOTAL_RECOMMENDED_TREES}}': recommended.length.toString(),
      '{{TOTAL_APPROVED_TREES}}': approvedCount.toString(),
      '{{REVENUE_OPINION_REMARKS}}': revenueRemarks,
      '{{REVENUE_REPLY_DETAILS}}': replyDetails,
    };
  }

  /// Extra applicant letter generated at final approval when the
  /// applicant has not applied online. Editable template
  /// RFO_APPLY_ONLINE_PL.txt (user supplies final wording, keeping
  /// the {{PLACEHOLDERS}}).
  Future<File> generateRfoApplyOnlineLetter(
    ApplicationModel application,
    RevenueReply reply,
  ) async {
    await _loadFlutterKannadaFont();
    final config = await OfficeConfigurationRepository().getConfiguration();
    final range = config?['rangeName']?.toString() ?? '';
    final location = config?['rangeLocation']?.toString() ?? range;
    var master = await _loadRfoTemplate('RFO_APPLY_ONLINE_PL.txt');
    final values = <String, String>{
      '{{OFFICE_NUMBER}}': application.officeNumber,
      '{{APPLICATION_DATE}}': _date(application.applicationDate),
      '{{APPLICANT_NAME}}': application.applicantName,
      '{{APPLICANT_ADDRESS}}': application.applicantAddress,
      '{{RECEIVED_DATE}}': _date(application.receivedDate),
      '{{SECTION}}': await _printSectionName(application),
      '{{BEAT}}': await _printBeatName(application),
      '{{RANGE_NAME}}': range,
      '{{RANGE_LOCATION}}': location,
      '{{LETTER_DATE}}': _date(application.rfoApprovalDate),
    };
    master = master.replaceAllMapped(RegExp(r'\{\{[A-Z_]+\}\}'), (match) {
      final value = values[match.group(0)];
      if (value == null) {
        throw StateError(
            'Unknown apply-online template placeholder: ' +
                match.group(0)!);
      }
      return value.trim().isEmpty ? '—' : value;
    });
    final pages = await _renderMasterToPng(master,
        rfoLetterhead: _RfoLetterheadData(
          letterNumber: application.officeNumber,
          rangeName: range,
          rangeLocation: location,
          rangeOfficeAddress:
              config?['rangeOfficeAddress']?.toString() ?? '',
          rangeEmail: config?['rangeEmail']?.toString() ?? '',
          logoPath: config?['rfoOfficeLogoPath']?.toString() ?? '',
          approvalDate: _date(application.rfoApprovalDate),
        ));
    final pdf = pw.Document();
    _appendRenderedPages(pdf, pages);
    return await _savePdf(
        officeNumber: application.officeNumber,
        fileName: _safeFileName(application.officeNumber) +
            '_RFO_APPLY_ONLINE_CYCLE_' +
            reply.cycle.toString() +
            '.pdf',
        bytes: await pdf.save());
  }

  Future<File?> generateRfoPrivateLandDecisionLetter(
    ApplicationModel application, RevenueReply reply, {PrivateLandOutcome? outcomeOverride}
  ) async {
    if (!reply.allApproved || reply.answers['nature'] == RevenueReply.wrongAuthority) {
      throw StateError('Approve the revenue reply before generating a final decision.');
    }
    final approved = reply.answers['nature'] == RevenueReply.satisfied;
    final outcome = approved
        ? (outcomeOverride ?? await TreeOfficerRepository().getCompletionOutcome(application.id!)) : null;
    if (outcome == PrivateLandOutcome.onlinePermission) return null;
    await _loadFlutterKannadaFont();
    final config = await OfficeConfigurationRepository().getConfiguration();
    final range = config?['rangeName']?.toString() ?? '';
    final location = config?['rangeLocation']?.toString() ?? range;
    var master = await _loadRfoTemplate(
      !approved ? 'RFO_REJECTED_PL.txt'
          : outcome == PrivateLandOutcome.applicantLetter ? 'RFO_APPROVED_PL_APPLICANT.txt'
          : 'RFO_APPROVED_PL.txt',
    );
      final values = <String, String>{
        '{{APPLICANT_LETTER_NUMBER_PHRASE}}': application.applicantLetterNumber.trim().isEmpty ? '' : ' ಸಂಖ್ಯೆ: ' + application.applicantLetterNumber.trim(),
        '{{OFFICE_NUMBER}}': application.officeNumber,
        '{{APPLICATION_DATE}}': _date(application.applicationDate),
        '{{APPLICANT_NAME}}': application.applicantName,
        '{{APPLICANT_ADDRESS}}': application.applicantAddress,
        '{{TREE_LOCATION}}': _location(application),
        '{{SECTION}}': await _printSectionName(application),
        '{{BEAT}}': await _printBeatName(application),
        '{{RANGE_NAME}}': range,
        '{{RANGE_LOCATION}}': location,
        '{{LETTER_DATE}}': _date(application.rfoApprovalDate),
        '{{RFO_APPROVAL_DATE}}': _date(application.rfoApprovalDate),
        '{{REVENUE_REQUEST_DATE}}': _date(reply.requestedAt),
        '{{REVENUE_AUTHORITY}}': reply.answers['authority'] ?? '',
        '{{REVENUE_LETTER_NUMBER}}': reply.answers['letterNumber'] ?? '',
        '{{REVENUE_LETTER_DATE}}': _date(reply.answers['letterDate'] ?? ''),
        '{{REVENUE_RECEIVED_DATE}}': _date(reply.answers['receivedDate'] ?? ''),
        '{{ONLINE_APPLICATION_NUMBER}}': reply.answers['onlineApplicationNumber'] ?? '',
        '{{LAND_OWNERSHIP_DETAILS}}': reply.answers['ownership'] ?? '',
        '{{GOVERNMENT_RESERVED_TREES}}': reply.answers['reserved'] ?? '',
        '{{TAX_PAYMENT_DETAILS}}': reply.answers['taxes'] ?? '',
        '{{DISPUTE_DETAILS}}': reply.answers['dispute'] ?? '',
        '{{EXTRA_DETAILS}}': reply.answers['extra'] ?? '',
        '{{REJECTION_REASON}}': reply.answers['unsatisfiedDetails'] ?? '',
        '{{UNSATISFIED_DETAILS}}': reply.answers['unsatisfiedDetails'] ?? '',
      };
      if (approved) values.addAll(await _privateLandApprovalValues(application, reply, addressTreeOfficer: outcome == PrivateLandOutcome.treeOfficerLetter));
      if (!approved) {
        final recommendationTypes = await MasterRepository().getMasters('Recommendation Type');
        final ids = recommendationTypes.where((row) => {'FULL','BRANCH','TWIG','TOP'}.contains(row['code']?.toString().trim().toUpperCase())).map((row)=>row['id']).toSet();
        final trees = await TreeRepository().getTrees(application.id!);
        final locationPhrase = application.treeLocationSame ? '' : application.treeLocationAddress.trim();
        values.addAll({
          '{{TREE_LOCATION_SUBJECT_PHRASE}}': locationPhrase,
          '{{TREE_LOCATION_BODY_PHRASE}}': locationPhrase,
          '{{RECEIVED_DATE}}': _date(application.receivedDate),
          '{{TOTAL_RECOMMENDED_TREES}}': trees.where((tree)=>ids.contains(tree.recommendationTypeId)).length.toString(),
        });
      }

      // Optional online number must not assert that an online application was submitted when it is blank.
      master = master.replaceAllMapped(
        RegExp(r'\[IF_ONLINE_APPLICATION_NUMBER\]([\s\S]*?)\[/IF_ONLINE_APPLICATION_NUMBER\]'),
        (match) => (reply.answers['onlineApplicationNumber'] ?? '').trim().isEmpty ? '' : match.group(1)!,
      );
      // Substitute once so values containing placeholder-like text stay literal.
      master = master.replaceAllMapped(RegExp(r'\{\{[A-Z_]+\}\}'), (match) {
        final value = values[match.group(0)];
        if (value == null) throw StateError('Unknown private-land decision template placeholder: ' + match.group(0)!);
        if (match.group(0) == '{{APPLICANT_LETTER_NUMBER_PHRASE}}' || match.group(0) == '{{TREE_LOCATION_SUBJECT_PHRASE}}' || match.group(0) == '{{TREE_LOCATION_BODY_PHRASE}}') return value;
        return value.trim().isEmpty ? '—' : value;
      });
    final pages = await _renderMasterToPng(master, rfoLetterhead: _RfoLetterheadData(
      letterNumber: application.officeNumber, rangeName: range, rangeLocation: location,
      rangeOfficeAddress: config?['rangeOfficeAddress']?.toString() ?? '',
      rangeEmail: config?['rangeEmail']?.toString() ?? '',
      logoPath: config?['rfoOfficeLogoPath']?.toString() ?? '',
      approvalDate: _date(application.rfoApprovalDate),
    ));
    final pdf = pw.Document();
    _appendRenderedPages(pdf, pages);
    final file = await _savePdf(officeNumber: application.officeNumber,
      fileName: _safeFileName(application.officeNumber) +
          (approved ? (outcome == PrivateLandOutcome.applicantLetter
              ? '_RFO_PRIVATE_LAND_APPROVED_APPLICANT' : '_RFO_PRIVATE_LAND_APPROVED')
              : '_RFO_PRIVATE_LAND_REJECTED') +
          '_CYCLE_' + reply.cycle.toString() + '.pdf',
      bytes: await pdf.save());
    if (!approved) await File(file.path + '.rejection-layout').writeAsString(await _loadRfoTemplate('RFO_REJECTED_PL.txt'));
    return file;
  }

  Future<bool> _mahazarRequiresUpdate(ApplicationModel application) async {
    final applicationId = application.id;

    if (applicationId == null) {
      return false;
    }

    final applicationVerification = await ApplicationVerificationRepository()
        .getVerification(applicationId);

    const mahazarApplicationFields = [
      "applicationTypeStatus",
      "governmentAgencyStatus",
      "urbanRuralStatus",
      "whyRemovingStatus",
      "purposeStatus",
      "structureTypeStatus",
      "workNameStatus",
      "gpsStatus",
    ];

    final applicationDetailsModified = mahazarApplicationFields.any(
      (field) =>
          applicationVerification?[field]?.toString().trim().toUpperCase() ==
          "MODIFY",
    );

    final treeDetailsModified = await TreeVerificationRepository()
        .hasModifiedTreeForApplication(applicationId);

    final mahazarVerification = await MahazarVerificationRepository()
        .getVerification(applicationId);

    final mahazarDetailsModified =
        mahazarVerification?["verification"]?.toString().trim().toUpperCase() ==
        "MODIFY";

    return applicationDetailsModified ||
        treeDetailsModified ||
        mahazarDetailsModified;
  }

  // ==========================================================
  // AUTOMATIC DRFO DOCUMENT GENERATION
  // ==========================================================
  //
  // NON-RTC:
  //
  // DEFERRED INSPECTION
  //     -> DRFO Deferred Letter ONLY
  //
  // COMPLETED INSPECTION
  //     -> DRFO Recommended Letter
  //     -> Mahazar, if available
  //     -> Tree Enumeration, if available
  //
  // RTC applications are intentionally excluded here.
  // ==========================================================

  Future<List<File>> generateDocumentsForApplication(
    ApplicationModel application,
  ) async {
    final List<File> generatedFiles = [];

    // Remove documents belonging to an earlier
    // generation of this application.
    await clearGeneratedDocuments(application.officeNumber);

    final String applicationType = application.applicationType
        .trim()
        .toUpperCase();

    // ----------------------------------------------------------
    // RTC IS NOT PART OF THIS NON-RTC DOCUMENT BUNDLE
    // ----------------------------------------------------------

    if (applicationType == 'RTC') {
      if (application.inspectionDecision.trim().toUpperCase() == 'DEFERRED') {
        final File deferredLetter = await generateDrfoDeferredLetter(
          application,
        );

        generatedFiles.add(deferredLetter);
      } else if (application.drfoInspectionDate.isNotEmpty) {
        final File recommendedLetter = await generateDrfoRecommendedReport(
          application,
        );

        generatedFiles.add(recommendedLetter);
      }

      return generatedFiles;
    }

    // ----------------------------------------------------------
    // DEFERRED INSPECTION
    //
    // ONLY DRFO DEFERRED LETTER
    // ----------------------------------------------------------

    if (application.inspectionDecision.trim().toUpperCase() == 'DEFERRED') {
      final File deferredLetter = await generateDrfoDeferredLetter(application);

      generatedFiles.add(deferredLetter);

      return generatedFiles;
    }

    // ----------------------------------------------------------
    // COMPLETED INSPECTION
    //
    // DRFO RECOMMENDED LETTER IS ALWAYS GENERATED
    // ----------------------------------------------------------

    if (application.drfoInspectionDate.isNotEmpty) {
      final File recommendedLetter = await generateDrfoRecommendedReport(
        application,
      );

      generatedFiles.add(recommendedLetter);

      // --------------------------------------------------------
      // SUPPORTING DOCUMENT CHECK
      // --------------------------------------------------------

      if (application.id != null) {
        final allTreesNotRecommended = await _areAllTreesNotRecommended(
          application,
        );

        final shouldUpdateMahazar =
            !allTreesNotRecommended &&
            await _mahazarRequiresUpdate(application);

        if (shouldUpdateMahazar) {
          final mahazar = await MahazarRepository().getByApplication(
            application.id!,
          );

          if (mahazar != null) {
            // The original inspecting-officer Mahazar is now outdated.
            await _deleteExistingMahazarFiles(application.officeNumber);

            final updatedMahazarFile = await generateMahazar(
              application,
              mahazar,
              isUpdated: true,
            );

            // Return it with the DRFO letter and enumeration list
            // so it is immediately available for View and Print.
            generatedFiles.add(updatedMahazarFile);
          }
        }

        // ------------------------------------------------------
        // TREE ENUMERATION
        // ------------------------------------------------------

        final TreeRepository treeRepository = TreeRepository();

        final trees = await treeRepository.getTrees(application.id!);

        if (!allTreesNotRecommended && trees.isNotEmpty) {
          final File enumerationFile = await generateTreeEnumeration(
            application,
          );

          generatedFiles.add(enumerationFile);
        }
      }
    }

    return generatedFiles;
  }

  // ==========================================================
  // OPEN / PRINT
  // ==========================================================

  // Existing PDFs are refreshed from saved application data before viewing/printing.
  // Dates and workflow status are not changed. New letters use these same resolvers.
  Future<void> refreshOfficerAddresses(File file, {ApplicationModel? application}) async {
    final name = file.uri.pathSegments.last.toUpperCase();
    final rtc = name.contains('_RFO_APPROVED_RTC') || name.contains('_RFO_DEFERRED_RTC');
    final nonRtc = name.contains('_RFO_DEFERRED_NON_RTC') || name.contains('_RFO_NOT_RECOMMENDED_NON_RTC');
    final privateRejected = name.contains('_RFO_PRIVATE_LAND_REJECTED');
    final governmentRequest = name.contains('_RFO_GL_DOCUMENT_REQUEST');
    final privateApproval = name.contains('_RFO_PRIVATE_LAND_APPROVED') && !name.contains('_APPLICANT');
    final revenueRequest = name.contains('_RFO_REVENUE_OPINION_REQUEST');
    final governmentPatti = name.contains('_RFO_GL_TAGGU_BELE_PATTI.');
    final governmentDo = name.contains('_RFO_GL_DO.');
    final governmentAuction = governmentDo || governmentPatti;
    final governmentValuation = name.contains('_RFO_GL_VALUATION');
    if (!rtc && !nonRtc && !privateApproval && !revenueRequest && !governmentValuation && !governmentAuction && !governmentRequest && !privateRejected) return;
    final officers = OfficerRepository();
    final fingerprint = await officers.fingerprint();
    final marker = File(file.path + '.officer-addresses');
    final layoutMarker = File(file.path + '.auction-layout');
    final rejectionMarker = File(file.path + '.rejection-layout');
    final requestMarker = File(file.path + '.request-layout');
    final valuationMarker = File(file.path + '.valuation-layout');
    final layoutCurrent = (!privateRejected || (await rejectionMarker.exists() && await rejectionMarker.readAsString() == await _loadRfoTemplate('RFO_REJECTED_PL.txt'))) &&
        (!governmentRequest || (await requestMarker.exists() && await requestMarker.readAsString() == await _loadRfoTemplate('RFO_GL_DOCUMENT_REQUEST.txt'))) &&
        (!governmentAuction || (await layoutMarker.exists() && await layoutMarker.readAsString() == await _auctionLayoutFingerprint())) &&
        (!governmentValuation || (await valuationMarker.exists() && await valuationMarker.readAsString() == await _loadRfoTemplate('RFO_GL_VALUATION.txt')));
    if (layoutCurrent && await marker.exists() && await marker.readAsString() == fingerprint) return;
    var app = application;
    if (app == null) {
      final folderName = file.parent.uri.pathSegments.where((part) => part.isNotEmpty).last;
      final matches = (await ApplicationRepository().getApplications()).where((a) => _safeFileName(a.officeNumber) == folderName).toList();
      if (matches.length != 1) throw StateError('Cannot identify the application for this letter.');
      app = matches.single;
    }
    // Reload so temporary date/type settings cannot affect the caller's model.
    app = await ApplicationRepository().getByOfficeNumber(app.officeNumber);
    if (app == null) throw StateError('Application for this letter was not found.');
    bool affected = false;
    GovernmentApproval? government;
    RevenueReply? savedReply;
    int? requestAuthorityId;
    final cycleMatch = RegExp(r'_CYCLE_(\d+)').firstMatch(name);
    final cycle = cycleMatch == null ? 1 : int.parse(cycleMatch.group(1)!);
    if (governmentValuation || governmentAuction || governmentRequest) {
      government = await GovernmentApprovalRepository().get(app.id!);
      if (government == null) throw StateError('Government approval details are missing.');
      // Older auction drafts had no officer selection; preserve their saved PDF.
      if (governmentAuction && government.treeOfficerId == null) return;
      affected = true;
    } else if (rtc) {
      for (final ref in app.forwardingReferences) {
        if (ref.forwardedBy.trim().isNotEmpty) {
          affected = await officers.sourceRole(ref.sourceId, ref.forwardedBy) != null;
          break;
        }
      }
    } else if (nonRtc) {
      for (final recipient in await RfoDeferredLetterRecipientRepository().getRecipients(app.id!)) {
        if (await officers.sourceRole(recipient.sourceId, recipient.recipientText) != null) affected = true;
      }
    } else if (privateApproval || privateRejected) {
      final selectedId = await TreeOfficerRepository().getSelection(app.id!);
      final rows = await TreeOfficerRepository().getAll();
      affected = privateRejected || rows.any((row) => row['id'] == selectedId && {'ACF','DCF'}.contains(row['code']));
      if (affected) {
        final history = await RevenueReplyRepository().history(app.id!);
        final matches = history.where((reply) => reply.cycle == cycle).toList();
        if (matches.isEmpty) throw StateError('Saved revenue opinion for this approval letter was not found.');
        savedReply = matches.single;
      }
    } else if (revenueRequest) {
      final history = await RevenueReplyRepository().history(app.id!);
      final matches = history.where((reply) => reply.cycle == cycle).toList();
      if (matches.isNotEmpty) savedReply = matches.single;
      final previous = history.where((reply) => reply.cycle == cycle - 1).toList();
      if (previous.isNotEmpty) requestAuthorityId = previous.single.nextAuthorityId;
      requestAuthorityId ??= (await ApplicationRevenueOpinionRepository().getByApplication(app.id!))?.revenueOpinionId;
      final authority = requestAuthorityId == null ? null : await RevenueOpinionRepository().getById(requestAuthorityId);
      affected = authority != null && {'ACF','DCF'}.contains(authority.code.trim().toUpperCase());
    }
    if (affected) {
      final backup = File(file.path + '.before-officer-address-update');
      if (!await backup.exists()) await file.copy(backup.path);
      File? regenerated;
      if (governmentValuation || governmentAuction || governmentRequest) {
        if (governmentRequest) { app.rfoApprovalDate = government!.requestDate; }
        else if (government!.finalDate.isNotEmpty) app.rfoApprovalDate = government.finalDate;
        final refreshed = await generateGovernmentLandLetters(app, government, afterReply: !governmentRequest && government.permissionType == 'Valuation' && government.khataGiven == false && government.requestLetterPath.isNotEmpty);
        regenerated = governmentDo ? refreshed.first : governmentPatti ? refreshed.last : refreshed.single;
      } else if (rtc) {
        app.inspectionDecision = name.contains('_RFO_DEFERRED_RTC') ? 'DEFERRED' : 'COMPLETED';
        regenerated = await generateRfoRtcApprovedLetter(app);
      } else if (nonRtc) {
        regenerated = await generateRfoNonRtcDecisionLetter(app);
      } else if (privateApproval || privateRejected) {
        regenerated = await generateRfoPrivateLandDecisionLetter(app, savedReply!, outcomeOverride: privateRejected ? null : PrivateLandOutcome.treeOfficerLetter);
      } else {
        if (savedReply != null) app.rfoApprovalDate = savedReply.requestedAt;
        regenerated = await generateRfoRevenueOpinionRequestLetter(app, authorityId: requestAuthorityId, requestCycle: cycleMatch == null ? null : cycle);
      }
      if (regenerated == null) throw StateError('The saved letter could not be refreshed.');
      if (!await FileSystemEntity.identical(file.path, regenerated.path)) {
        await file.writeAsBytes(await regenerated.readAsBytes());
      }
    }
    await marker.writeAsString(fingerprint);
  }

  Future<bool> openPdf(File file) async {
    await refreshOfficerAddresses(file);
    return await Printing.layoutPdf(
      onLayout: (_) async {
        return await file.readAsBytes();
      },
    );
  }

  DateTime? _parseMahazarDate(String value) {
    final text = value.trim();

    if (text.isEmpty) return null;

    final formats = [
      DateFormat("dd-MM-yyyy"),
      DateFormat("dd/MM/yyyy"),
      DateFormat("yyyy-MM-dd"),
      DateFormat("yyyy-MM-dd'T'HH:mm:ss"),
    ];

    for (final format in formats) {
      try {
        return format.parseStrict(text);
      } catch (_) {
        // Try next supported format.
      }
    }

    return DateTime.tryParse(text);
  }

  String _kannadaNumberWords(int number) {
    const units = <int, String>{
      0: "ಸೊನ್ನೆ",
      1: "ಒಂದು",
      2: "ಎರಡು",
      3: "ಮೂರು",
      4: "ನಾಲ್ಕು",
      5: "ಐದು",
      6: "ಆರು",
      7: "ಏಳು",
      8: "ಎಂಟು",
      9: "ಒಂಬತ್ತು",
      10: "ಹತ್ತು",
      11: "ಹನ್ನೊಂದು",
      12: "ಹನ್ನೆರಡು",
      13: "ಹದಿಮೂರು",
      14: "ಹದಿನಾಲ್ಕು",
      15: "ಹದಿನೈದು",
      16: "ಹದಿನಾರು",
      17: "ಹದಿನೇಳು",
      18: "ಹದಿನೆಂಟು",
      19: "ಹತ್ತೊಂಬತ್ತು",
      20: "ಇಪ್ಪತ್ತು",
      30: "ಮೂವತ್ತು",
      40: "ನಲವತ್ತು",
      50: "ಐವತ್ತು",
      60: "ಅರವತ್ತು",
      70: "ಎಪ್ಪತ್ತು",
      80: "ಎಂಬತ್ತು",
      90: "ತೊಂಬತ್ತು",
    };

    if (units.containsKey(number)) {
      return units[number]!;
    }

    if (number < 100) {
      final tens = (number ~/ 10) * 10;
      final remainder = number % 10;

      return "${units[tens]} ${units[remainder]}";
    }

    if (number < 1000) {
      final hundreds = number ~/ 100;
      final remainder = number % 100;

      final hundredText = "${units[hundreds]} ನೂರು";

      if (remainder == 0) {
        return hundredText;
      }

      return "$hundredText ${_kannadaNumberWords(remainder)}";
    }

    if (number < 10000) {
      final thousands = number ~/ 1000;
      final remainder = number % 1000;

      final thousandText = "${units[thousands]} ಸಾವಿರ";

      if (remainder == 0) {
        return thousandText;
      }

      return "$thousandText ${_kannadaNumberWords(remainder)}";
    }

    return number.toString();
  }

  String _kannadaOrdinal(int number) {
    const ordinalNumbers = <int, String>{
      1: "ಮೊದಲನೇ",
      2: "ಎರಡನೇ",
      3: "ಮೂರನೇ",
      4: "ನಾಲ್ಕನೇ",
      5: "ಐದನೇ",
      6: "ಆರನೇ",
      7: "ಏಳನೇ",
      8: "ಎಂಟನೇ",
      9: "ಒಂಬತ್ತನೇ",
      10: "ಹತ್ತನೇ",
      11: "ಹನ್ನೊಂದನೇ",
      12: "ಹನ್ನೆರಡನೇ",
      13: "ಹದಿಮೂರನೇ",
      14: "ಹದಿನಾಲ್ಕನೇ",
      15: "ಹದಿನೈದನೇ",
      16: "ಹದಿನಾರನೇ",
      17: "ಹದಿನೇಳನೇ",
      18: "ಹದಿನೆಂಟನೇ",
      19: "ಹತ್ತೊಂಬತ್ತನೇ",
      20: "ಇಪ್ಪತ್ತನೇ",
      21: "ಇಪ್ಪತ್ತೊಂದನೇ",
      22: "ಇಪ್ಪತ್ತೆರಡನೇ",
      23: "ಇಪ್ಪತ್ತಮೂರನೇ",
      24: "ಇಪ್ಪತ್ತನಾಲ್ಕನೇ",
      25: "ಇಪ್ಪತ್ತೈದನೇ",
      26: "ಇಪ್ಪತ್ತಾರನೇ",
      27: "ಇಪ್ಪತ್ತೇಳನೇ",
      28: "ಇಪ್ಪತ್ತೆಂಟನೇ",
      29: "ಇಪ್ಪತ್ತೊಂಬತ್ತನೇ",
      30: "ಮೂವತ್ತನೇ",
      31: "ಮೂವತ್ತೊಂದನೇ",
    };

    return ordinalNumbers[number] ?? _kannadaNumberWords(number);
  }

  String _kannadaMonthName(int month) {
    const months = <int, String>{
      1: "ಜನವರಿ",
      2: "ಫೆಬ್ರವರಿ",
      3: "ಮಾರ್ಚ್",
      4: "ಏಪ್ರಿಲ್",
      5: "ಮೇ",
      6: "ಜೂನ್",
      7: "ಜುಲೈ",
      8: "ಆಗಸ್ಟ್",
      9: "ಸೆಪ್ಟೆಂಬರ್",
      10: "ಅಕ್ಟೋಬರ್",
      11: "ನವೆಂಬರ್",
      12: "ಡಿಸೆಂಬರ್",
    };

    return months[month] ?? "";
  }

  String _mahazarTimePeriodKannada(String time) {
    final text = time.trim().toUpperCase();

    final match = RegExp(r"(\d{1,2})(?::(\d{1,2}))?").firstMatch(text);

    if (match == null) {
      return "";
    }

    int hour = int.tryParse(match.group(1) ?? "") ?? 0;

    final isAM = text.contains("AM");
    final isPM = text.contains("PM");

    if (isAM && hour == 12) {
      hour = 0;
    } else if (isPM && hour < 12) {
      hour += 12;
    }

    if (hour >= 5 && hour < 12) {
      return "ಬೆಳಗ್ಗೆ";
    }

    if (hour >= 12 && hour < 16) {
      return "ಮಧ್ಯಾಹ್ನ";
    }

    if (hour >= 16 && hour < 22) {
      return "ಸಂಜೆ";
    }

    return "ರಾತ್ರಿ";
  }

  String _mahazarTimeWithoutPeriod(String time) {
    return time
        .replaceAll(RegExp(r"\s*(AM|PM)\s*", caseSensitive: false), "")
        .trim();
  }

  Future<String> _masterKannadaName(
    MasterRepository repository,
    int? id,
  ) async {
    if (id == null) return "";

    final item = await repository.getMasterById(id);

    if (item == null) return "";

    final kannadaName = item["kannadaName"]?.toString().trim() ?? "";

    if (kannadaName.isNotEmpty) {
      return kannadaName;
    }

    return item["value"]?.toString().trim() ?? "";
  }

  Future<String> _mahazarBoundaryText({
    required MasterRepository repository,
    required int? locationId,
    required String additionalText,
  }) async {
    final locationName = await _masterKannadaName(repository, locationId);

    final details = additionalText.trim();

    return [locationName, details].where((value) => value.isNotEmpty).join(" ");
  }

  String _formatDocumentDecimal(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }

  // ==========================================================
  // MAHAZAR PDF
  // ==========================================================

  Future<File> generateMahazar(
    ApplicationModel application,
    dynamic mahazar, {
    bool isUpdated = false,
  }) async {
    await _loadFlutterKannadaFont();

    final masterRepository = MasterRepository();

    final applicationType = application.applicationType.trim().toUpperCase();

    // Private Land uses its own Mahazar format.
    // Other application types temporarily continue
    // using the old template until their formats are supplied.
    final usesCommonLandMahazar =
        applicationType == "PL" ||
        applicationType == "GL" ||
        applicationType == "STGL" ||
        applicationType == "CGL";

    final templateFile = usesCommonLandMahazar
        ? "PRIVATE_LAND_MAHAZAR.txt"
        : "MAHAZAR.txt";

    // ========================================================
    // OFFICE CONFIGURATION
    // ========================================================

    final officeConfiguration = await OfficeConfigurationRepository()
        .getConfiguration();

    final rangeName =
        officeConfiguration?["rangeName"]?.toString().trim().isNotEmpty == true
        ? officeConfiguration!["rangeName"].toString().trim()
        : "ಮೈಸೂರು";

    final rangeLocation =
        officeConfiguration?["rangeLocation"]?.toString().trim().isNotEmpty ==
            true
        ? officeConfiguration!["rangeLocation"].toString().trim()
        : rangeName;

    // ========================================================
    // MAHAZAR DATE
    // ========================================================

    final mahazarDateText = mahazar.mahazarDate?.toString().trim() ?? "";

    final mahazarDate = _parseMahazarDate(mahazarDateText);

    final mahazarYearKannada = mahazarDate == null
        ? ""
        : _kannadaOrdinal(mahazarDate.year % 100);

    final mahazarMonthKannada = mahazarDate == null
        ? ""
        : _kannadaMonthName(mahazarDate.month);

    final mahazarDayKannada = mahazarDate == null
        ? ""
        : _kannadaOrdinal(mahazarDate.day);

    // ========================================================
    // TIME
    // ========================================================

    final savedStartTime = mahazar.startTime?.toString().trim() ?? "";

    final manualStartTime = mahazar.startTimeManual?.toString().trim() ?? "";

    final savedEndTime = mahazar.endTime?.toString().trim() ?? "";

    final manualEndTime = mahazar.endTimeManual?.toString().trim() ?? "";

    final startingTime = manualStartTime.isNotEmpty
        ? manualStartTime
        : savedStartTime;

    final endingTime = manualEndTime.isNotEmpty ? manualEndTime : savedEndTime;

    final startTimePeriodKannada = _mahazarTimePeriodKannada(startingTime);

    final endTimePeriodKannada = _mahazarTimePeriodKannada(endingTime);

    final startingTimeForDocument = _mahazarTimeWithoutPeriod(startingTime);

    final endingTimeForDocument = _mahazarTimeWithoutPeriod(endingTime);
    // ========================================================
    // APPLICATION MASTER VALUES
    // ========================================================

    final urbanRuralKannada = await _masterKannadaName(
      masterRepository,
      application.urbanRuralId,
    );

    final governmentAgencyKannada =
        await _governmentAgencyKannadaFor(application);

    final landClassificationKannada =
        applicationType == "PL" || applicationType == "SPL"
        ? urbanRuralKannada
        : governmentAgencyKannada;

    final structureTypeKannada = await _masterKannadaName(
      masterRepository,
      application.structureTypeId,
    );

    final purposeKannada = await _masterKannadaName(
      masterRepository,
      application.purposeId,
    );

    final overallRemarkKannada = await _masterKannadaName(
      masterRepository,
      application.overallRemarkId,
    );

    final whyRemovingItem = await masterRepository.getMasterById(
      application.whyRemovingId,
    );

    final whyRemovingKannada =
        whyRemovingItem?["kannadaName"]?.toString().trim().isNotEmpty == true
        ? whyRemovingItem!["kannadaName"].toString().trim()
        : whyRemovingItem?["value"]?.toString().trim() ?? "";

    final whyRemovingCode =
        whyRemovingItem?["code"]?.toString().trim().toUpperCase() ?? "";

    final workNameText = whyRemovingCode == "WORKS"
        ? application.workName.trim()
        : "";

    // ========================================================
    // BOUNDARIES
    // ========================================================

    final north = await _mahazarBoundaryText(
      repository: masterRepository,
      locationId: mahazar.northLocationId as int?,
      additionalText: mahazar.northBoundary?.toString() ?? "",
    );

    final east = await _mahazarBoundaryText(
      repository: masterRepository,
      locationId: mahazar.eastLocationId as int?,
      additionalText: mahazar.eastBoundary?.toString() ?? "",
    );

    final south = await _mahazarBoundaryText(
      repository: masterRepository,
      locationId: mahazar.southLocationId as int?,
      additionalText: mahazar.southBoundary?.toString() ?? "",
    );

    final west = await _mahazarBoundaryText(
      repository: masterRepository,
      locationId: mahazar.westLocationId as int?,
      additionalText: mahazar.westBoundary?.toString() ?? "",
    );

    // ========================================================
    // RECOMMENDED TREES
    // ========================================================

    final allTrees = application.id == null
        ? <dynamic>[]
        : await TreeRepository().getTrees(application.id!);

    final recommendationTypes = await masterRepository.getMasters(
      "Recommendation Type",
    );

    final recommendationCodeById = <int, String>{
      for (final item in recommendationTypes)
        item["id"] as int: item["code"]?.toString().trim().toUpperCase() ?? "",
    };

    const recommendedCodes = <String>{"FULL", "BRANCH", "TWIG", "TOP"};

    final recommendedTrees = allTrees.where((tree) {
      final code = recommendationCodeById[tree.recommendationTypeId] ?? "";

      return recommendedCodes.contains(code);
    }).toList();

    // ========================================================
    // RECOMMENDED TREES — SPECIES-WISE TOTAL
    // ========================================================

    final speciesMasters = await masterRepository.getSpecies();

    final speciesNameById = <int, String>{
      for (final item in speciesMasters)
        item["id"]
            as int: item["kannadaName"]?.toString().trim().isNotEmpty == true
            ? item["kannadaName"].toString().trim()
            : item["value"]?.toString().trim() ?? "",
    };

    final recommendedSpeciesCounts = <String, int>{};

    for (final tree in recommendedTrees) {
      final speciesName = speciesNameById[tree.speciesId]?.trim() ?? "";

      if (speciesName.isNotEmpty) {
        recommendedSpeciesCounts[speciesName] =
            (recommendedSpeciesCounts[speciesName] ?? 0) + 1;
      }
    }

    final recommendedSpeciesParts = recommendedSpeciesCounts.entries
        .map((entry) => "${entry.value} ಸಂಖ್ಯೆ ${entry.key}")
        .toList();

    final recommendedSpeciesSummary = _joinKannadaNames(
      recommendedSpeciesParts,
    );

    // ========================================================
    // UNIQUE RECOMMENDATION REASONS
    // ========================================================

    final recommendationReasonMasters = await masterRepository.getMasters(
      "Recommendation Reason",
    );

    final recommendationReasonById = <int, String>{
      for (final item in recommendationReasonMasters)
        item["id"]
            as int: item["kannadaName"]?.toString().trim().isNotEmpty == true
            ? item["kannadaName"].toString().trim()
            : item["value"]?.toString().trim() ?? "",
    };

    final uniqueReasons = <String>{};

    for (final tree in recommendedTrees) {
      for (final reasonId in tree.recommendationReasonIds) {
        final reason = recommendationReasonById[reasonId]?.trim() ?? "";

        if (reason.isNotEmpty) {
          uniqueReasons.add(reason);
        }
      }
    }

    final uniqueRecommendationReasons = _joinKannadaNames(
      uniqueReasons.toList(),
    );

    // ========================================================
    // TREE STATUS SUMMARY
    // ========================================================

    final treeStatusMasters = await masterRepository.getMasters("Tree Status");

    final treeStatusById = <int, String>{
      for (final item in treeStatusMasters)
        item["id"]
            as int: item["kannadaName"]?.toString().trim().isNotEmpty == true
            ? item["kannadaName"].toString().trim()
            : item["value"]?.toString().trim() ?? "",
    };

    final statusCounts = <String, int>{};

    for (final tree in recommendedTrees) {
      final statusId = tree.treeStatusId;

      final statusName = statusId == null
          ? ""
          : treeStatusById[statusId]?.trim() ?? "";

      if (statusName.isNotEmpty) {
        statusCounts[statusName] = (statusCounts[statusName] ?? 0) + 1;
      }
    }

    final statusParts = statusCounts.entries
        .map((entry) => "${entry.value} ಸಂಖ್ಯೆ ${entry.key}")
        .toList();

    final treeStatusSummary = _joinKannadaNames(statusParts);

    // ========================================================
    // TIMBER, POLE AND FIREWOOD TOTALS
    // ========================================================

    final enumerationRows = await _buildGlTreeEnumerationRows(application);

    final totalTimberVolume = enumerationRows.fold<double>(
      0,
      (total, row) => total + row.timberVolumeNumber,
    );

    final totalPoleCount = enumerationRows.fold<int>(
      0,
      (total, row) => total + row.poleCountNumber,
    );

    final totalFirewood = enumerationRows.fold<double>(
      0,
      (total, row) => total + row.firewoodNumber,
    );

    final produceParts = <String>[];

    if (totalTimberVolume > 0) {
      produceParts.add(
        "ಒಟ್ಟು ${_formatDocumentDecimal(totalTimberVolume, decimals: 3)} ಘ.ಮೀ ನಾಟ",
      );
    }

    if (totalPoleCount > 0) {
      produceParts.add("ಒಟ್ಟು $totalPoleCount ಸಂಖ್ಯೆ ಕಡ್ಡಿಗಳು (ಪೋಲ್‌ಗಳು)");
    }

    if (totalFirewood > 0) {
      produceParts.add(
        "ಒಟ್ಟು ${_formatDocumentDecimal(totalFirewood)} ಟನ್ ಸೌದೆ",
      );
    }

    final produceSummary = produceParts.isEmpty
        ? "ಯಾವುದೇ ನಾಟ, ಕಡ್ಡಿಗಳು ಅಥವಾ ಸೌದೆ"
        : _joinKannadaNames(produceParts);

    // ========================================================
    // LOCATION AND GPS
    // ========================================================

    final additionalTreeLocation = application.treeLocationSame
        ? ""
        : application.treeLocationAddress.trim();

    final isPrivateApplication =
        applicationType == "PL" || applicationType == "SPL";

    final landLocationParts = <String>[
      if (isPrivateApplication) "ತಮ್ಮ",
      if (!application.treeLocationSame && additionalTreeLocation.isNotEmpty)
        additionalTreeLocation,
      "${getLandType(application)}ದಲ್ಲಿರುವ",
    ];

    final landLocationPhrase = landLocationParts.join(" ");

    final treeLocation = _safeText(_location(application));

    final gps = application.gpsCoordinates.trim().replaceAll(
      RegExp(r"\s*,\s*"),
      ", ",
    );

    // ========================================================
    // LOAD APPLICATION-SPECIFIC TEMPLATE
    // ========================================================

    String template = await _loadTemplate(templateFile);

    // ========================================================
    // PRIVATE LAND PLACEHOLDERS
    // ========================================================

    template = _replace(
      template,
      "{{MAHAZAR_YEAR_KANNADA}}",
      mahazarYearKannada,
    );

    template = _replace(
      template,
      "{{MAHAZAR_MONTH_KANNADA}}",
      mahazarMonthKannada,
    );

    template = _replace(template, "{{MAHAZAR_DAY_KANNADA}}", mahazarDayKannada);

    template = _replace(template, "{{RANGE_NAME}}", rangeName);

    template = _replace(template, "{{RANGE_LOCATION}}", rangeLocation);

    template = _replace(template, "{{TREE_LOCATION}}", treeLocation);

    template = _replace(
      template,
      "{{APPLICANT_NAME}}",
      _safeText(application.applicantName),
    );

    template = _replace(
      template,
      "{{APPLICANT_ADDRESS}}",
      _safeText(application.applicantAddress),
    );

    template = _replace(
      template,
      "{{LAND_LOCATION_PHRASE}}",
      landLocationPhrase,
    );

    template = _replace(
      template,
      "{{ADDITIONAL_TREE_LOCATION}}",
      additionalTreeLocation,
    );

    template = _replace(template, "{{URBAN_RURAL_KANNADA}}", urbanRuralKannada);

    template = _replace(
      template,
      "{{LAND_CLASSIFICATION_KANNADA}}",
      landClassificationKannada,
    );

    template = _replace(
      template,
      "{{LAND_TYPE_KANNADA}}",
      getLandType(application),
    );

    template = _replace(
      template,
      "{{STRUCTURE_TYPE_KANNADA}}",
      structureTypeKannada,
    );

    template = _replace(template, "{{PURPOSE_KANNADA}}", purposeKannada);

    template = _replace(
      template,
      "{{OVERALL_REMARK_KANNADA}}",
      overallRemarkKannada,
    );

    template = _replace(template, "{{WORK_NAME_TEXT}}", workNameText);

    template = _replace(
      template,
      "{{WHY_REMOVING_KANNADA}}",
      whyRemovingKannada,
    );

    template = _replace(
      template,
      "{{RECOMMENDED_SPECIES_SUMMARY}}",
      recommendedSpeciesSummary,
    );

    template = _replace(
      template,
      "{{TOTAL_RECOMMENDED_TREES}}",
      recommendedTrees.length.toString(),
    );

    template = _replace(template, "{{TREE_STATUS_SUMMARY}}", treeStatusSummary);

    template = _replace(
      template,
      "{{UNIQUE_RECOMMENDATION_REASONS}}",
      uniqueRecommendationReasons,
    );

    template = _replace(template, "{{PRODUCE_SUMMARY}}", produceSummary);

    template = _replace(template, "{{GPS}}", gps);

    template = _replace(template, "{{NORTH}}", north);

    template = _replace(template, "{{EAST}}", east);

    template = _replace(template, "{{SOUTH}}", south);

    template = _replace(template, "{{WEST}}", west);

    template = _replace(
      template,
      "{{START_TIME_PERIOD_KANNADA}}",
      startTimePeriodKannada,
    );

    template = _replace(
      template,
      "{{END_TIME_PERIOD_KANNADA}}",
      endTimePeriodKannada,
    );

    template = _replace(template, "{{START_TIME}}", startingTimeForDocument);

    template = _replace(template, "{{END_TIME}}", endingTimeForDocument);

    // Old-template placeholders remain supported temporarily
    // for other application types.

    template = _replace(template, "{{MAHAZAR_DATE}}", _date(mahazarDateText));

    template = _replace(template, "{{LAND_TYPE}}", getLandType(application));

    template = _replace(
      template,
      "{{SECTION}}",
      await _printSectionName(application),
    );

    template = _replace(
      template,
      "{{BEAT}}",
      await _printBeatName(application),
    );

    template = _replace(
      template,
      "{{TOTAL_TREES}}",
      recommendedTrees.length.toString(),
    );

    template = _replace(template, "{{PURPOSE}}", purposeKannada);

    template = _replace(
      template,
      "{{TREE_REASONS}}",
      uniqueRecommendationReasons,
    );

    template = _replace(
      template,
      "{{TOTAL_VOLUME}}",
      _formatDocumentDecimal(totalTimberVolume, decimals: 3),
    );

    template = _replace(
      template,
      "{{TOTAL_FIREWOOD}}",
      _formatDocumentDecimal(totalFirewood),
    );

    // ========================================================
    // RENDER AND SAVE PDF
    // ========================================================

    final pngBytes = await _renderMasterToPng(template);

    final pdf = pw.Document();

    _appendRenderedPages(pdf, pngBytes);

    final bytes = await pdf.save();

    final fileSuffix = isUpdated
        ? "_UPDATED_MAHAZAR.pdf"
        : applicationType == "PL"
        ? "_PRIVATE_LAND_MAHAZAR.pdf"
        : "_MAHAZAR.pdf";

    return await _savePdf(
      officeNumber: application.officeNumber,
      fileName:
          "${_safeFileName(application.officeNumber)}"
          "$fileSuffix",
      bytes: bytes,
    );
  }

  // ==========================================================
  // TREE ENUMERATION PDF
  // ==========================================================

  Future<File> _generateCommonTreeEnumeration(
    ApplicationModel application,
  ) async {
    await _loadFlutterKannadaFont();
    final applicationType = application.applicationType.trim().toUpperCase();

    final isGovernmentApplication =
        applicationType == "GL" ||
        applicationType == "STGL" ||
        applicationType == "CGL" ||
        applicationType == "SGL" ||
        applicationType == "MCC";

    final governmentAgencyKannada =
        await _governmentAgencyKannadaFor(application);

    final governmentAgencyPrefix =
        isGovernmentApplication && governmentAgencyKannada.isNotEmpty
        ? "$governmentAgencyKannadaಯ "
        : "";

    final rows = await _buildGlTreeEnumerationRows(application);

    final officeConfiguration = await OfficeConfigurationRepository()
        .getConfiguration();

    final rangeName =
        officeConfiguration?['rangeName']?.toString().trim().isNotEmpty == true
        ? officeConfiguration!['rangeName'].toString().trim()
        : 'ಮೈಸೂರು';

    final moneyFormat = NumberFormat('#,##,##0.00', 'en_IN');

    final totalTimberVolume = rows.fold<double>(
      0,
      (total, row) => total + row.timberVolumeNumber,
    );

    final totalPoleCount = rows.fold<int>(
      0,
      (total, row) => total + row.poleCountNumber,
    );

    final totalFirewood = rows.fold<double>(
      0,
      (total, row) => total + row.firewoodNumber,
    );

    final totalTimberValue = rows.fold<double>(
      0,
      (total, row) => total + row.timberValueNumber,
    );

    final totalPoleValue = rows.fold<double>(
      0,
      (total, row) => total + row.poleValueNumber,
    );

    final totalFirewoodValue = rows.fold<double>(
      0,
      (total, row) => total + row.firewoodValueNumber,
    );

    final grandTotal = rows.fold<double>(
      0,
      (total, row) => total + row.totalValueNumber,
    );

    String master = await _loadTemplate('TREE_ENUMERATION_GL.txt');

    master = _replace(
      master,
      '{{APPLICANT_NAME}}',
      _safeText(application.applicantName),
    );

    master = _replace(
      master,
      '{{APPLICANT_ADDRESS}}',
      _safeText(application.applicantAddress),
    );

    master = _replace(
      master,
      '{{GOVERNMENT_AGENCY_PREFIX}}',
      governmentAgencyPrefix,
    );

    master = _replace(
      master,
      '{{TREE_LOCATION}}',
      _safeText(_location(application)),
    );

    master = _replace(
      master,
      '{{LAND_TYPE_KANNADA}}',
      getLandType(application),
    );

    master = _replace(
      master,
      '{{TOTAL_RECOMMENDED_TREES}}',
      rows.length.toString(),
    );

    master = _replace(
      master,
      '{{TOTAL_TIMBER_VOLUME}}',
      totalTimberVolume.toStringAsFixed(3),
    );

    master = _replace(
      master,
      '{{TOTAL_POLE_COUNT}}',
      totalPoleCount.toString(),
    );

    master = _replace(
      master,
      '{{TOTAL_FIREWOOD}}',
      totalFirewood.toStringAsFixed(2),
    );

    master = _replace(
      master,
      '{{TOTAL_TIMBER_VALUE}}',
      moneyFormat.format(totalTimberValue),
    );

    master = _replace(
      master,
      '{{TOTAL_POLE_VALUE}}',
      moneyFormat.format(totalPoleValue),
    );

    master = _replace(
      master,
      '{{TOTAL_FIREWOOD_VALUE}}',
      moneyFormat.format(totalFirewoodValue),
    );

    master = _replace(
      master,
      '{{GRAND_TOTAL_VALUE}}',
      moneyFormat.format(grandTotal),
    );

    master = _replace(master, '{{SECTION}}', await _printSectionName(application));

    master = _replace(master, '{{BEAT}}', await _printBeatName(application));

    master = _replace(master, '{{RANGE_NAME}}', _safeText(rangeName));

    final pngBytes = await _renderMasterToPng(
      master,
      glTreeEnumerationRows: rows,
    );

    final pdf = pw.Document();

    _appendRenderedPages(pdf, pngBytes);

    final bytes = await pdf.save();

    return await _savePdf(
      officeNumber: application.officeNumber,
      fileName:
          '${_safeFileName(application.officeNumber)}'
          '_TREE_ENUMERATION.pdf',
      bytes: bytes,
    );
  }

  Future<File> generateTreeEnumeration(ApplicationModel application) async {
    final applicationType = application.applicationType.trim().toUpperCase();

    if (applicationType == 'GL' ||
        applicationType == 'STGL' ||
        applicationType == 'CGL' ||
        applicationType == 'PL' ||
        applicationType == 'SGL' ||
        applicationType == 'SPL') {
      return await _generateCommonTreeEnumeration(application);
    }

    await _loadFlutterKannadaFont();
    const rangeName = 'ಮೈಸೂರು';

    final TreeRepository treeRepository = TreeRepository();

    final MasterRepository masterRepository = MasterRepository();

    final trees = application.id == null
        ? <dynamic>[]
        : await treeRepository.getTrees(application.id!);

    // --------------------------------------------------------
    // Species master
    // --------------------------------------------------------

    final speciesList = await masterRepository.getSpecies();

    final Map<int, String> speciesMap = {
      for (final item in speciesList)
        item['id'] as int: item['value'].toString(),
    };

    // --------------------------------------------------------
    // Build enumeration
    // --------------------------------------------------------

    final StringBuffer master = StringBuffer();

    master.writeln('ಮರಗಳ ಎಣಿಕೆ ಪಟ್ಟಿ');

    master.writeln();

    master.writeln('ಅರ್ಜಿದಾರರು: ${_safeText(application.applicantName)}');

    master.writeln();

    master.writeln('ವಿಳಾಸ: ${_safeText(application.applicantAddress)}');

    master.writeln();

    master.writeln('ಖಾತೆ/ಸ್ಥಳ: ${_safeText(_location(application))}');

    master.writeln();

    master.writeln(
      '------------------------------------------------------------',
    );

    master.writeln(
      'ಕ್ರ.ಸಂ. | ಮರ ಸಂಖ್ಯೆ | ಮರದ ಜಾತಿ | ಸುತ್ತಳತೆ | ಎತ್ತರ | ಘ.ಮೀ. | ಟನ್ | ಶಿಫಾರಸ್ಸು',
    );

    master.writeln(
      '------------------------------------------------------------',
    );

    double totalFirewood = 0;

    for (int i = 0; i < trees.length; i++) {
      final tree = trees[i];

      String species = '';

      try {
        final speciesId = tree.speciesId;

        species = speciesMap[speciesId] ?? tree.speciesName?.toString() ?? '';
      } catch (_) {
        try {
          species = tree.speciesName.toString();
        } catch (_) {}
      }

      String treeNumber = '';
      String gbh = '';
      String height = '';
      String firewood = '';
      String recommendation = '';
      String remarks = '';

      try {
        treeNumber = tree.treeNumber.toString();
      } catch (_) {}

      try {
        gbh = tree.gbh?.toString() ?? '';
      } catch (_) {}

      try {
        height = tree.height?.toString() ?? '';
      } catch (_) {}

      try {
        firewood = tree.firewood?.toString() ?? '';
      } catch (_) {}

      try {
        recommendation = tree.recommendation.toString();
      } catch (_) {}

      try {
        remarks = tree.remarks.toString();
      } catch (_) {}

      final firewoodValue = double.tryParse(firewood) ?? 0;

      totalFirewood += firewoodValue;

      master.writeln(
        '${i + 1} | '
        '$treeNumber | '
        '$species | '
        '$gbh | '
        '$height | '
        '— | '
        '$firewood | '
        '$recommendation',
      );

      if (remarks.trim().isNotEmpty) {
        master.writeln('   ಟಿಪ್ಪಣಿ: $remarks');
      }
    }

    master.writeln(
      '------------------------------------------------------------',
    );

    master.writeln();

    master.writeln('ಒಟ್ಟು ಮರಗಳು: ${trees.length}');

    master.writeln();

    master.writeln('ಒಟ್ಟು ಸೌದೆ: ${totalFirewood.toStringAsFixed(2)} ಟನ್');

    master.writeln();

    master.writeln('Abstract:');

    master.writeln();

    master.writeln('ಮರಗಳ ಸಂಖ್ಯೆ : ${trees.length}');

    master.writeln();

    master.writeln('ಒಟ್ಟು ನಾಟ : ______ ಘ.ಮೀ');

    master.writeln();

    master.writeln('ಒಟ್ಟು ಸೌದೆ : ${totalFirewood.toStringAsFixed(2)} ಟನ್');

    master.writeln();

    master.writeln();

    master.writeln('ಉಪವಲಯ ಅರಣ್ಯಾಧಿಕಾರಿ -ವ- ಮೋಜಣಿದಾರ');

    master.writeln(
      '${_safeText(application.section)} ಶಾಖೆ, ${_safeText(rangeName)} ವಲಯ',
    );

    final pngBytes = await _renderMasterToPng(master.toString());

    final pdf = pw.Document();

    _appendRenderedPages(pdf, pngBytes);

    final bytes = await pdf.save();

    return await _savePdf(
      officeNumber: application.officeNumber,
      fileName:
          '${_safeFileName(application.officeNumber)}'
          '_TREE_ENUMERATION.pdf',
      bytes: bytes,
    );
  }
}
