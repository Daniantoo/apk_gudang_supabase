import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';
import 'package:open_file/open_file.dart';

class PdfService {
  final SupabaseClient supabase;

  PdfService(this.supabase);

  Future<void> generateAndOpenPdf(BuildContext context, String uuid) async {
    try {
      final pdfFile = await generatePdfFromId(uuid);
      OpenFile.open(pdfFile.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuat PDF: $e")),
      );
    }
  }

  Future<File> generatePdfFromId(String uuid) async {
    try {
      final response = await supabase.from('tug_10').select('*').eq('id', uuid).single();
      if (response == null || response['daftar_barang'] == null) {
        throw Exception("Data tidak ditemukan untuk UUID: $uuid");
      }
      return await _generatePdf(response);
    } catch (e) {
      print("Error generating PDF: $e");
      throw Exception("Gagal membuat PDF: $e");
    }
  }

  Future<File> _generatePdf(Map<String, dynamic> tugData) async {
    final pdf = pw.Document();
    final List<dynamic> items = tugData["daftar_barang"] is String
        ? jsonDecode(tugData["daftar_barang"])
        : tugData["daftar_barang"];

    final nomorTugFormatted = _generateNomorTug();
    final bgImages = await _loadBackgroundImages();
    final fotoSurat = await _imageFromUrl(tugData['foto_surat_pengembalian'] ?? '');
    final fotoSimKtp = await _imageFromUrl(tugData['foto_sim_ktp_sopir'] ?? '');
    final fotoKendaraan = await _imageFromUrl(tugData['foto_kendaraan'] ?? '');

    // Load all item images
    final List<pw.Widget> itemImages = await Future.wait(items.map((item) async {
      final fotoBarang = await _imageFromUrl(item['foto_barang'] ?? '');
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "${item['nama_material'] ?? '-'}",
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          fotoBarang,
        ],
      );
    }).toList());

    // First page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) => pw.Stack(
          children: [
            pw.Positioned.fill(child: pw.Image(
              bgImages[0],
              fit: pw.BoxFit.fill,
              )
              ),
            // TUG Number
            pw.Positioned(left: 466, top: 119, child: pw.Text("$nomorTugFormatted", style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic))),
            pw.Positioned(left: 339, top: 119, child: pw.Text("${tugData['nomor_urut'] ?? '-'}", style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic))),
            // New fields
            pw.Positioned(left: 660, top: 169, child: pw.Text("${tugData['no_ba_pengembalian'] ?? '-'}", style: pw.TextStyle(fontSize: 9))),
            pw.Positioned(left: 724, top: 451, child: pw.Text("${tugData['unit_pengirim'] ?? '-'}", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
            pw.Positioned(left: 724, top: 490, child: pw.Text("${tugData['nama_pengirim'] ?? '-'}", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
            pw.Positioned(left: 130, top: 154, child: pw.Text("${tugData['pekerjaan'] ?? '-'}", style: pw.TextStyle(fontSize: 9))),
            pw.Positioned(left: 130, top: 170, child: pw.Text("${tugData['deskripsi_pekerjaan'] ?? '-'}", style: pw.TextStyle(fontSize: 9))),
            pw.Positioned(left: 130, top: 184, child: pw.Text("${tugData['lokasi_pekerjaan'] ?? '-'}", style: pw.TextStyle(fontSize: 9))),
            // Change these lines in _generatePdf method:
            pw.Positioned(left: 660, top: 184, child: pw.Text(formatDate(tugData['tanggal_penggantian'] ?? '-'), style: pw.TextStyle(fontSize: 9))),
            pw.Positioned(left: 679, top: 419, child: pw.Text(formatDate(tugData['tanggal_pembuatan_tug'] ?? '-'), style: pw.TextStyle(fontSize: 9))),
            
            // Daftar Barang with custom positioning
            ...List.generate(items.length, (index) {
              final item = items[index];

              return pw.Stack(
                children: [
                  // Nama Barang
                  pw.Positioned(
                    left: 23, // Atur posisi sesuai kebutuhan
                    top: 221 + (index * 19), 
                    child: pw.Text(
                      "${item['nama_material'] ?? '-'}",
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ),

                  // Jumlah Barang
                  pw.Positioned(
                    left: 410, // Atur posisi berbeda dari Nama Barang
                    top: 222 + (index * 19),
                    child: pw.Text(
                      "${item['jumlah_barang'] ?? '-'}",
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ),

                  // Satuan Barang
                  pw.Positioned(
                    left: 492, // Atur posisi berbeda dari Nama Barang
                    top: 222 + (index * 19),
                    child: pw.Text(
                      "${item['satuan'] ?? '-'}",
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ),

                  // Keterangan Barang
                  pw.Positioned(
                    left: 640, // Atur posisi berbeda dari Nama & Jumlah
                    top: 222 + (index * 19),
                    child: pw.Text(
                      "${item['keterangan'] ?? '-'}",
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );

    // Second page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) => pw.Stack(
          children: [
            pw.Positioned.fill(child: pw.Image(
              bgImages[1],
              fit: pw.BoxFit.fill,
              )
              ),
            
            // Driver and vehicle information
           // pw.Positioned(left: 100, top: 100, child: pw.Text("Nama Sopir: ${tugData['nama_sopir'] ?? '-'}", style: pw.TextStyle(fontSize: 12))),
           // pw.Positioned(left: 100, top: 120, child: pw.Text("No SIM/KTP Sopir: ${tugData['no_sim_ktp_sopir'] ?? '-'}", style: pw.TextStyle(fontSize: 12))),
           // pw.Positioned(left: 100, top: 140, child: pw.Text("Nama Kendaraan: ${tugData['nama_kendaraan'] ?? '-'}", style: pw.TextStyle(fontSize: 12))),
           // pw.Positioned(left: 100, top: 160, child: pw.Text("Nama Satpam: ${tugData['nama_satpam'] ?? '-'}", style: pw.TextStyle(fontSize: 12))),
            
            // Photos
            pw.Positioned(left: 56, top: 128, child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 5),
                fotoSurat,
              ],
            )),
            
            pw.Positioned(left: 312, top: 128, child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 5),
                fotoSimKtp,
              ],
            )),

            pw.Positioned(left: 56, top: 467, child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 5),
                fotoKendaraan,
              ],
            )),
          ],
        ),
      ),
    );

     // Third page and subsequent pages
    int itemsPerPage = 4;
    int totalPages = (itemImages.length / itemsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) => pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Image(
                  bgImages[2],
                  fit: pw.BoxFit.fill,
                ),
              ),
              // Nama dan Foto Barang
              ...List.generate(itemsPerPage, (index) {
                int itemIndex = pageIndex * itemsPerPage + index;
                if (itemIndex >= itemImages.length) return pw.Container();
                return pw.Positioned(
                  left: (index % 2) * 250 + 60, // Atur posisi sesuai kebutuhan
                  top: (index ~/ 2) * 300 + 100 + ((index ~/ 2) * 50), // Atur posisi sesuai kebutuhan
                  child: itemImages[itemIndex],
                );
              }),
            ],
          ),
        ),
      );
    }

    final tempDir = await getTemporaryDirectory();
    final file = File("${tempDir.path}/laporan_tug10.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  String _generateNomorTug() {
    final now = DateTime.now();
    final romanMonth = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"][now.month - 1];
    return "$romanMonth    ${now.year}";
  }

  // Add this helper function to your PdfService class
  String formatDate(String dateString) {
    if (dateString == null || dateString == '-') return '-';
    
    try {
      final DateTime date = DateTime.parse(dateString);
      final List<String> indonesianMonths = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      
      final String day = date.day.toString().padLeft(2, '0');
      final String month = indonesianMonths[date.month - 1];
      final String year = date.year.toString();
      
      return '$day $month $year';
    } catch (e) {
      print("Error formatting date: $e");
      return dateString; // Return original string if parsing fails
    }
  }

  Future<List<pw.MemoryImage>> _loadBackgroundImages() async {
    final List<String> assets = ["assets/page1_tug10.png", "assets/page2_tug10.png", "assets/page3_tug10.png"];
    return Future.wait(assets.map((path) async {
      final ByteData data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    }));
  }

  Future<pw.Widget> _imageFromUrl(String url) async {
    if (url.isEmpty) return pw.Container();
    try {
      final Uint8List imageBytes = await _fetchImageFromUrl(url);
      return pw.Container(width: 226 , height: 298, child: pw.Image(pw.MemoryImage(imageBytes)));
    } catch (e) {
      print("Error loading image: $e");
      return pw.Container(
        width: 200, 
        height: 200, 
        decoration: pw.BoxDecoration(border: pw.Border.all()),
        child: pw.Center(child: pw.Text("Gambar tidak tersedia"))
      );
    }
  }

  Future<Uint8List> _fetchImageFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception("Gagal memuat gambar: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching image: $e"); 
      throw Exception("Gagal memuat gambar dari URL");
    }
  }
}