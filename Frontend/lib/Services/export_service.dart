import 'dart:typed_data';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../Models/report.dart';

class ExportService {
  static Future<bool> exportToPDF(List<Report> reports, String fileName) async {
    final bytes = await generatePDFBytes(reports);
    
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select where to save the PDF report',
      fileName: '$fileName.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsBytes(bytes);
      return true;
    }
    return false;
  }

  static Future<Uint8List> generatePDFBytes(List<Report> reports) async {
    final pdf = pw.Document();
    final fontFallback = await PdfGoogleFonts.notoSansRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              "Report Monitoring Log",
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                fontFallback: [fontFallback],
              ),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.TableHelper.fromTextArray(
            headers: [
              'ID',
              'Machine',
              'Customer',
              'Start Time',
              'End Time',
              'Duration',
              'Area',
              'Energy',
              'Water',
            ],
            data: reports.map((r) => [
              r.id.toString(),
              r.machineName ?? '',
              r.customerName ?? '',
              r.startTime != null ? DateFormat('MM-dd HH:mm').format(r.startTime!) : '',
              r.endTime != null ? DateFormat('MM-dd HH:mm').format(r.endTime!) : '',
              r.duration ?? '',
              r.areaCovered ?? '',
              r.energyConsumption ?? '',
              r.waterUsage ?? '',
            ]).toList(),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              fontFallback: [fontFallback],
            ),
            cellStyle: pw.TextStyle(
              fontSize: 8,
              fontFallback: [fontFallback],
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 22,
            columnWidths: {
              0: const pw.FixedColumnWidth(25), // ID
              1: const pw.FlexColumnWidth(2),   // Machine
              2: const pw.FlexColumnWidth(2),   // Customer
              3: const pw.FixedColumnWidth(65), // Start
              4: const pw.FixedColumnWidth(65), // End
              5: const pw.FixedColumnWidth(55), // Duration
              6: const pw.FixedColumnWidth(55), // Area
              7: const pw.FixedColumnWidth(55), // Energy
              8: const pw.FixedColumnWidth(55), // Water
            },
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
              7: pw.Alignment.center,
              8: pw.Alignment.center,
            },
          ),
        ],
      ),
    );

    return await pdf.save();
  }

  static Future<bool> exportToExcel(List<Report> reports, String fileName) async {
    final bytes = generateExcelBytes(reports);

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select where to save the Excel report',
      fileName: '$fileName.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsBytes(bytes);
      return true;
    }
    return false;
  }

  static Uint8List generateExcelBytes(List<Report> reports) {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Reports'];
    excel.delete('Sheet1');

    List<String> headers = [
      'ID',
      'Machine',
      'Customer',
      'Start Time',
      'End Time',
      'Duration',
      'Area Covered',
      'Energy Consumption',
      'Water Usage',
    ];
    sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (var r in reports) {
      sheetObject.appendRow([
        IntCellValue(r.id),
        TextCellValue(r.machineName ?? ''),
        TextCellValue(r.customerName ?? ''),
        TextCellValue(r.startTime != null ? DateFormat('yyyy-MM-dd HH:mm').format(r.startTime!) : ''),
        TextCellValue(r.endTime != null ? DateFormat('yyyy-MM-dd HH:mm').format(r.endTime!) : ''),
        TextCellValue(r.duration ?? ''),
        TextCellValue(r.areaCovered ?? ''),
        TextCellValue(r.energyConsumption ?? ''),
        TextCellValue(r.waterUsage ?? ''),
      ]);
    }

    var bytes = excel.save();
    return Uint8List.fromList(bytes ?? []);
  }

  static Future<bool> printReports(List<Report> reports) async {
    final pdfBytes = await generatePDFBytes(reports);

    return await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Report_Log_Print',
    );
  }
}
