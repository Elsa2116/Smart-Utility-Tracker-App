import 'dart:io'; // For file operations (creating, writing files)
import 'package:path_provider/path_provider.dart'; // To get device directories
import 'package:pdf/widgets.dart' as pw; // PDF generation library
import 'package:open_file/open_file.dart'; // To open files on the device
import '../models/payment.dart'; // Payment model

class PdfGenerator {
  // Static method to generate a PDF receipt for a payment
  static Future<void> generateReceipt(Payment payment) async {
    final pdf = pw.Document(); // Create a new PDF document

    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          // Build the content of the PDF
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start, // Align text to the left
              children: [
                // Title of the receipt
                pw.Text(
                  'Payment Receipt',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20), // Space between title and details

                // Payment details
                pw.Text('ID: ${payment.id}'), // Payment ID
                pw.Text('User ID: ${payment.userId}'), // Associated user ID
                pw.Text(
                    'Type: ${payment.type}'), // Payment type (e.g., electricity, water)
                pw.Text(
                    'Amount: ETB ${payment.amount.toStringAsFixed(2)}'), // Amount with 2 decimals
                pw.Text(
                    'Method: ${payment.paymentMethod}'), // Payment method (telebirr, etc.)
                pw.Text(
                    'Status: ${payment.status}'), // Payment status (pending, completed)
                pw.Text('Date: ${payment.date.toString()}'), // Payment date
                pw.Text('Notes: ${payment.notes}'), // Any additional notes
              ],
            ),
          );
        },
      ),
    );

    // Get the app's documents directory to save the PDF
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/receipt_${payment.id}.pdf'); // PDF file path

    // Write the PDF file to the device
    await file.writeAsBytes(await pdf.save());

    // Print the path for debugging
    print('Receipt saved at: ${file.path}');

    // Open the PDF automatically using default PDF viewer
    await OpenFile.open(file.path);
  }
}
