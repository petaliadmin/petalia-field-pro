import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:petaliacropassist/features/parcels/domain/parcel.dart';
import 'package:petaliacropassist/l10n/gen/app_localizations.dart';
import '../constants/app_constants.dart';
import '../utils/geo_utils.dart';
import 'symptoms_catalog_service.dart';

class ExportService {
  /// Exports parcels and visits to an Excel file and shares it.
  static Future<void> exportToExcel(List<Parcel> parcels, AppLocalizations l10n) async {
    final excel = Excel.createExcel();
    final sheetName = l10n.tabParcels;
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    // Styling
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2E5A44'), // Nature Distilled Green
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      verticalAlign: VerticalAlign.Center,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Headers - Sheet 1: Parcels
    final headers = [
      l10n.reportHeaderParcel,
      l10n.reportHeaderOwner,
      l10n.reportHeaderVillage,
      l10n.addParcelLabelRegion,
      l10n.reportHeaderCrop,
      l10n.addParcelLabelVariety,
      l10n.reportHeaderSurface,
      l10n.addParcelLabelSemis,
      l10n.addParcelLabelSoil,
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var i = 0; i < parcels.length; i++) {
      final p = parcels[i];
      final area = GeoUtils.polygonAreaHa(p.boundary);
      
      sheet.appendRow([
        TextCellValue(p.name),
        TextCellValue(p.owner),
        TextCellValue(p.village),
        TextCellValue(p.region ?? '-'),
        TextCellValue(p.crop),
        TextCellValue(p.variety ?? '-'),
        DoubleCellValue(area),
        TextCellValue(p.semisDate != null ? DateFormat('dd/MM/yyyy').format(p.semisDate!) : '-'),
        TextCellValue(p.soilType ?? '-'),
      ]);
    }

    // Sheet 2: Visits
    final visitSheetName = l10n.parcelTabVisits;
    final visitSheet = excel[visitSheetName];
    
    final visitHeaders = [
      l10n.reportHeaderDate,
      l10n.reportHeaderParcel,
      l10n.addParcelLabelGrowth,
      l10n.reportHeaderDiagnosis,
      l10n.obsWhatDoYouSee,
    ];

    for (var i = 0; i < visitHeaders.length; i++) {
      final cell = visitSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(visitHeaders[i]);
      cell.cellStyle = headerStyle;
    }

    final obsBox = Hive.box(AppConstants.boxObservations);
    final sortedVisits = obsBox.values.toList()
      ..sort((a, b) => (b['at'] as String).compareTo(a['at'] as String));

    for (final v in sortedVisits) {
      final p = parcels.firstWhere(
        (element) => element.id == v['parcelId'], 
        orElse: () => Parcel(
          id: '', name: '?', owner: '?', village: '?', crop: '?', 
          growthStage: '', irrigation: '', healthScore: 0, 
          lastVisit: DateTime.now(), estimatedYield: 0, boundary: []
        )
      );
      
      final symptomsRaw = v['symptoms'] as List?;
      final symptomsText = symptomsRaw == null || symptomsRaw.isEmpty 
          ? '-' 
          : symptomsRaw.map((id) => SymptomsCatalogService.getLabelForId(id.toString(), Locale(l10n.localeName))).join(', ');

      visitSheet.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(v['at']))),
        TextCellValue(p.name),
        TextCellValue(v['stage'] ?? '-'),
        TextCellValue(v['note'] ?? '-'),
        TextCellValue(symptomsText),
      ]);
    }

    final fileBytes = excel.save();
    final fileName = 'Petalia_Export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    if (kIsWeb) {
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(fileBytes!),
            name: fileName,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          )
        ],
        text: l10n.exportTitle,
        subject: 'Petalia - ${l10n.exportTitle}',
      );
    } else {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(fileBytes!);

      await Share.shareXFiles(
        [XFile(file.path)], 
        text: l10n.exportTitle,
        subject: 'Petalia - ${l10n.exportTitle}',
      );
    }
  }

  /// Exports a professional PDF report and shares it.
  static Future<void> exportToPdf(List<Parcel> parcels, AppLocalizations l10n) async {
    await initializeDateFormatting('fr_FR', null);
    final pdf = pw.Document();
    
    // Use Standard PDF fonts to avoid TTF parsing errors (FormatException)
    // especially on Web or with specific Inter font versions.
    final ttfBold = pw.Font.helveticaBold();
    final ttfRegular = pw.Font.helvetica();
    
    final primaryColor = PdfColor.fromInt(0xFF2E5A44); // Nature Distilled Green
    final accentColor = PdfColor.fromInt(0xFFC5A059);  // Ochre

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: ttfRegular,
          bold: ttfBold,
        ),
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PETALIA FIELD PRO', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                    pw.Text('Rapport de Suivi Agronomique', style: pw.TextStyle(fontSize: 12, color: accentColor, letterSpacing: 1.2)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(DateFormat('dd MMMM yyyy', 'fr_FR').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('SÉNÉGAL AGRI-TECH ELITE', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.5, color: primaryColor),
            pw.SizedBox(height: 15),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(l10n.reportFooterNotice, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                pw.Text('Page ${context.pageNumber} / ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Executive Summary
          pw.Header(level: 0, text: 'RÉSUMÉ GLOBAL', textStyle: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold)),
          pw.Row(
            children: [
              _buildKpiCard('PARCELLES', parcels.length.toString(), primaryColor),
              pw.SizedBox(width: 15),
              _buildKpiCard('SURFACE TOTALE', '${parcels.fold<double>(0, (prev, p) => prev + GeoUtils.polygonAreaHa(p.boundary)).toStringAsFixed(2)} Ha', primaryColor),
            ],
          ),
          pw.SizedBox(height: 25),

          // Parcels Table
          pw.Header(level: 0, text: 'INVENTAIRE DES PARCELLES', textStyle: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold)),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headers: [l10n.reportHeaderParcel, l10n.reportHeaderOwner, l10n.reportHeaderCrop, l10n.reportHeaderSurface],
            data: parcels.map((p) => [
              p.name,
              p.owner,
              p.crop,
              '${GeoUtils.polygonAreaHa(p.boundary).toStringAsFixed(2)} Ha',
            ]).toList(),
          ),
          pw.SizedBox(height: 30),

          // Visits / Monitoring
          pw.Header(level: 0, text: 'JOURNAL DES VISITES RÉCENTES', textStyle: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold)),
          ..._buildVisitsContent(parcels, l10n, primaryColor),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    final fileName = 'Petalia_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
      subject: 'Petalia - ${l10n.exportTitle}',
    );
  }

  static pw.Widget _buildKpiCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: color, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildVisitsContent(List<Parcel> parcels, AppLocalizations l10n, PdfColor primaryColor) {
    final obsBox = Hive.box(AppConstants.boxObservations);
    final sortedVisits = obsBox.values.toList()
      ..sort((a, b) => (b['at'] as String).compareTo(a['at'] as String));

    if (sortedVisits.isEmpty) {
      return [pw.Text('Aucune visite enregistrée.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))];
    }

    return sortedVisits.take(15).map((v) {
      final p = parcels.firstWhere(
        (element) => element.id == v['parcelId'], 
        orElse: () => Parcel(
          id: '', name: '?', owner: '?', village: '?', crop: '?', 
          growthStage: '', irrigation: '', healthScore: 0, 
          lastVisit: DateTime.now(), estimatedYield: 0, boundary: []
        )
      );

      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(v['at']));
      
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(color: PdfColors.grey300, width: 2)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${p.name} — ${v['stage'] ?? 'Visite'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text(dateStr, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(v['note'] ?? '-', style: const pw.TextStyle(fontSize: 9)),
            if (v['symptoms'] != null && (v['symptoms'] as List).isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text('Observation : ${(v['symptoms'] as List).map((id) => SymptomsCatalogService.getLabelForId(id.toString(), Locale(l10n.localeName))).join(', ')}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey700, fontStyle: pw.FontStyle.italic)),
              ),
          ],
        ),
      );
    }).toList();
  }
}
