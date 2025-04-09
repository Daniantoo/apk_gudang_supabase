import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class GenerateTUG10PDFPage extends StatelessWidget {
  final Map<String, dynamic> data;

  GenerateTUG10PDFPage({required this.data});

  Future<void> generateTUG10PDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo PLN
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(data['logo_pln']),
                    width: 100,
                    height: 100,
                  ),
                ),
                pw.SizedBox(height: 10),
                
                pw.Center(
                  child: pw.Text(
                    "BON PENGEMBALIAN", 
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 10),
                
                pw.Text("No: ${data['no_tug']}", style: pw.TextStyle(fontSize: 12)),
                pw.Text("PEKERJAAN: ${data['pekerjaan']}", style: pw.TextStyle(fontSize: 12)),
                pw.Text("LOKASI: ${data['lokasi']}", style: pw.TextStyle(fontSize: 12)),
                pw.Text("TANGGAL: ${data['tanggal']}", style: pw.TextStyle(fontSize: 12)),
                
                pw.SizedBox(height: 10),
                
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text("Nama Barang", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text("Jumlah", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text("Satuan", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text("Keterangan", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...data['barang'].map<pw.TableRow>((item) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text(item['nama']),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text(item['jumlah'].toString()),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text(item['satuan']),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text(item['keterangan']),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text("Yang Menyerahkan"),
                        pw.SizedBox(height: 40),
                        pw.Text(data['pengirim']),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text("Yang Menerima"),
                        pw.SizedBox(height: 40),
                        pw.Text(data['penerima']),
                      ],
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                pw.Text("Lampiran Foto", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text("Surat Pengembalian"),
                pw.Image(pw.MemoryImage(data['foto_surat']), width: 250, height: 180),
                
                pw.Text("SIM/KTP Sopir"),
                pw.Image(pw.MemoryImage(data['foto_sim']), width: 250, height: 180),
                
                pw.Text("Foto Kendaraan"),
                pw.Image(pw.MemoryImage(data['foto_kendaraan']), width: 250, height: 180),
              ],
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/TUG10.pdf");
    await file.writeAsBytes(await pdf.save());
    
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'TUG10.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Generate TUG 10 PDF")),
      body: Center(
        child: ElevatedButton(
          onPressed: generateTUG10PDF,
          child: Text("Generate PDF"),
        ),
      ),
    );
  }
}
