import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

Future<Uint8List> buildReceiptPdf({
  required String title,
  required String reference,
  required String amount,
  required List<MapEntry<String, String?>> rows,
}) async {
  final document = pw.Document();
  final teal = PdfColor.fromHex('#087A61');
  final deepTeal = PdfColor.fromHex('#063F3B');
  final ink = PdfColor.fromHex('#172033');
  final muted = PdfColor.fromHex('#61716D');
  final pale = PdfColor.fromHex('#F1F8F5');
  final border = PdfColor.fromHex('#DCE9E4');

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 42, vertical: 38),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(22, 20, 22, 18),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [deepTeal, teal],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 38,
                  height: 38,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#2A9B7E'),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(9),
                    ),
                  ),
                  child: pw.Text(
                    'ED',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        title.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 17,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Official payment receipt',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#B9F4D9'),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'RECEIPT',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#B9F4D9'),
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      reference,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PAYMENT RECEIVED',
                      style: pw.TextStyle(
                        color: muted,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: .8,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      amount,
                      style: pw.TextStyle(
                        color: ink,
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: pw.BoxDecoration(
                  color: pale,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Text(
                  'PAID',
                  style: pw.TextStyle(
                    color: teal,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'PAYMENT DETAILS',
            style: pw.TextStyle(
              color: teal,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: .8,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: border),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(1.05),
                1: pw.FlexColumnWidth(2),
              },
              children: [
                for (var i = 0; i < rows.length; i++)
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: i.isEven ? pale : PdfColors.white,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: pw.Text(
                          rows[i].key,
                          style: pw.TextStyle(
                            color: muted,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: pw.Text(
                          _displayValue(rows[i].value),
                          style: pw.TextStyle(
                            color: ink,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Divider(color: border),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Thank you for your payment.',
                style: pw.TextStyle(color: muted, fontSize: 9),
              ),
              pw.Text(
                'Generated by Edufy',
                style: pw.TextStyle(color: muted, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return document.save();
}

String _displayValue(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? '-' : normalized;
}

Future<void> printReceiptPdf({
  required String title,
  required String reference,
  required String amount,
  required List<MapEntry<String, String?>> rows,
}) async {
  final bytes = await buildReceiptPdf(
    title: title,
    reference: reference,
    amount: amount,
    rows: rows,
  );
  await Printing.layoutPdf(onLayout: (_) async => bytes);
}

Future<void> shareReceiptPdf({
  required String title,
  required String reference,
  required String amount,
  required List<MapEntry<String, String?>> rows,
}) async {
  final bytes = await buildReceiptPdf(
    title: title,
    reference: reference,
    amount: amount,
    rows: rows,
  );
  await Share.shareXFiles(
    [XFile.fromData(bytes, name: 'receipt.pdf', mimeType: 'application/pdf')],
    subject: title,
    text: '$title\n$reference\n$amount',
  );
}
