import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../repositories/office_configuration_repository.dart';
import '../../services/rfo_report_service.dart';
import '../../widgets/sync_bar.dart';

class RfoReportsScreen extends StatefulWidget {
  const RfoReportsScreen({super.key});

  @override
  State<RfoReportsScreen> createState() => _RfoReportsScreenState();
}

class _RfoReportsScreenState extends State<RfoReportsScreen> {
  final _dateFormat = DateFormat('dd-MM-yyyy');

  DateTime _from = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _to = DateTime.now();

  bool _loading = false;
  bool _generated = false;
  bool _printing = false;

  Map<String, RfoReportBucket> _typeRows = {};
  Map<String, RfoReportBucket> _sectionRows = {};
  RfoReportBucket _typeTotal = RfoReportBucket();
  RfoReportBucket _sectionTotal = RfoReportBucket();

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
      _generated = false;
    });
  }

  Future<void> _generate() async {
    if (_to.isBefore(_from)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('To date must be after From date.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final service = RfoReportService();
      final apps = await service.applicationsInPeriod(_from, _to);
      final typeRows = service.byType(apps);
      final sectionRows = service.bySectionBeat(apps);
      if (!mounted) return;
      setState(() {
        _typeRows = typeRows;
        _sectionRows = sectionRows;
        _typeTotal = service.total(typeRows.values);
        _sectionTotal = service.total(sectionRows.values);
        _generated = true;
      });
      if (apps.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No applications created in this period.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _dateField(String label, DateTime value, bool isFrom) {
    return Expanded(
      child: InkWell(
        onTap: () => _pickDate(isFrom),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          child: Text(_dateFormat.format(value)),
        ),
      ),
    );
  }

  Widget _reportTable(
    String title,
    Map<String, RfoReportBucket> rows,
    RfoReportBucket total,
    String rowHeader,
  ) {
    final entries = rows.entries.toList();
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  Colors.grey.shade200,
                ),
                border: TableBorder.all(
                  color: Colors.grey.shade400,
                ),
                columns: [
                  DataColumn(label: Text(rowHeader)),
                  for (final header in RfoReportBucket.headers())
                    DataColumn(
                      label: Text(header),
                      numeric: true,
                    ),
                ],
                rows: [
                  for (final entry in entries)
                    DataRow(
                      cells: [
                        DataCell(Text(entry.key)),
                        for (final cell in entry.value.toCells())
                          DataCell(Text(cell)),
                      ],
                    ),
                  DataRow(
                    color: WidgetStateProperty.all(
                      Colors.grey.shade100,
                    ),
                    cells: [
                      const DataCell(
                        Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      for (final cell in total.toCells())
                        DataCell(
                          Text(
                            cell,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _print() async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      final config =
          await OfficeConfigurationRepository().getConfiguration();
      final rangeName = config?['rangeName']?.toString().trim() ?? '';
      final rangeLocation =
          config?['rangeLocation']?.toString().trim() ?? '';
      final officeLine = [
        if (rangeName.isNotEmpty) rangeName,
        if (rangeLocation.isNotEmpty) rangeLocation,
      ].join(', ');
      final period =
          '${_dateFormat.format(_from)} to ${_dateFormat.format(_to)}';

      List<List<String>> tableData(
        Map<String, RfoReportBucket> rows,
        RfoReportBucket total,
      ) {
        return [
          for (final entry in rows.entries)
            [entry.key, ...entry.value.toCells()],
          ['Total', ...total.toCells()],
        ];
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (_) => [
            pw.Center(
              child: pw.Text(
                'RFO Monitoring Report',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            if (officeLine.isNotEmpty)
              pw.Center(
                child: pw.Text(officeLine, style: const pw.TextStyle(fontSize: 10)),
              ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Period (by application created date): $period',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '1. Application Type wise (numbers only)',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['Type', ...RfoReportBucket.shortHeaders()],
              data: tableData(_typeRows, _typeTotal),
              headerStyle: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              border: pw.TableBorder.all(),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                for (var i = 1; i <= 11; i++) i: pw.Alignment.center,
              },
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              '2. Section / Beat wise, all types (numbers only)',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: [
                'Section / Beat',
                ...RfoReportBucket.shortHeaders(),
              ],
              data: tableData(_sectionRows, _sectionTotal),
              headerStyle: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              border: pw.TableBorder.all(),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                for (var i = 1; i <= 11; i++) i: pw.Alignment.center,
              },
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated on ${_dateFormat.format(DateTime.now())}. '
              'Counts cover applications created in the selected period only. '
              'Draft entries are excluded.',
              style: const pw.TextStyle(fontSize: 7),
            ),
          ],
        ),
      );
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('RFO Reports'),
        actions: [
          if (_generated)
            IconButton(
              icon: _printing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.print),
              tooltip: 'Print',
              onPressed: _printing ? null : _print,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Period (by application created date)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _dateField('From', _from, true),
                      const SizedBox(width: 10),
                      _dateField('To', _to, false),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _generate,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.table_chart),
                      label: const Text('Generate Reports'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_generated) ...[
            _reportTable(
              '1. Application Type wise (numbers only)',
              _typeRows,
              _typeTotal,
              'Type',
            ),
            const SizedBox(height: 10),
            _reportTable(
              '2. Section / Beat wise, all types (numbers only)',
              _sectionRows,
              _sectionTotal,
              'Section / Beat',
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _printing ? null : _print,
                icon: const Icon(Icons.print),
                label: const Text('Print (A4 Landscape)'),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: const SyncBar(),
    );
  }
}
