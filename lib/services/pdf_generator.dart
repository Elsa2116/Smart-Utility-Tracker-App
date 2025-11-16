import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import '../models/payment.dart';

class PdfGenerator {
  static Future<void> generateReceipt(Payment payment) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Payment Receipt',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('ID: ${payment.id}'),
                pw.Text('User ID: ${payment.userId}'),
                pw.Text('Type: ${payment.type}'),
                pw.Text('Amount: ETB ${payment.amount.toStringAsFixed(2)}'),
                pw.Text('Method: ${payment.paymentMethod}'),
                pw.Text('Status: ${payment.status}'),
                pw.Text('Date: ${payment.date.toString()}'),
                pw.Text('Notes: ${payment.notes}'),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/receipt_${payment.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    print('Receipt saved at: ${file.path}');

    // Open the PDF automatically
    await OpenFile.open(file.path);
  }
}
