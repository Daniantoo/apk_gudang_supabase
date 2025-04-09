import 'package:apk_gudang_supabase/pages/detail_tug10.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../services/tug10_service.dart';
import '../services/pdf_service.dart';
import '../models/tug10_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LaporanTUG10Page extends StatefulWidget {
  @override
  _LaporanTUG10PageState createState() => _LaporanTUG10PageState();
}

class _LaporanTUG10PageState extends State<LaporanTUG10Page> {
  final TUG10Service _service = TUG10Service();
  late Future<List<TUG10Model>> _laporanFuture;
  late PdfService _pdfService;

  @override
  void initState() {
    super.initState();
    _laporanFuture = _service.fetchLaporanTUG10();
    _pdfService = PdfService(Supabase.instance.client);
  }

  void _generateAndOpenPdf(String tug10Id) async {
    try {
      File pdfFile = await _pdfService.generatePdfFromId(tug10Id);
      OpenFile.open(pdfFile.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuka PDF: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Laporan TUG 10')),
      body: FutureBuilder<List<TUG10Model>>(
        future: _laporanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Belum ada laporan.'));
          }

          final laporan = snapshot.data!;
          return ListView.builder(
            itemCount: laporan.length,
            itemBuilder: (context, index) {
              final data = laporan[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text('No BA: ${data.noBA}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pengirim: ${data.namaPengirim}'),
                      Text('Jumlah Barang: ${data.barang.length} item'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.picture_as_pdf, color: Colors.red),
                    onPressed: () => _generateAndOpenPdf(data.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailLaporanPage(laporan: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
