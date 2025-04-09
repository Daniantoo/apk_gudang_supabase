import 'package:flutter/material.dart';
import '../models/tug10_model.dart';
import 'package:intl/intl.dart';

class DetailLaporanPage extends StatelessWidget {
  final TUG10Model laporan;

  DetailLaporanPage({required this.laporan});

  // Fungsi untuk memformat tanggal agar tidak menampilkan "T00:00:00"
  String formatTanggal(String tanggal) {
    try {
      DateTime dateTime = DateTime.parse(tanggal);
      return DateFormat('dd MMM yyyy').format(dateTime); // Contoh: 06 Mar 2025
    } catch (e) {
      return tanggal; // Jika error, tampilkan string aslinya
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail Laporan TUG 10')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informasi Laporan
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No BA Pengembalian: ${laporan.noBA}', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Unit Pengirim: ${laporan.unitPengirim}'),
                    Text('Nama Pengirim: ${laporan.namaPengirim}'),
                    Text('Jabatan Pengirim: ${laporan.jabatanPengirim}'),
                    Text('Pekerjaan: ${laporan.pekerjaan}'),
                    Text('Deskripsi Pekerjaan: ${laporan.deskripsiPekerjaan}'),
                    Text('Lokasi Pekerjaan: ${laporan.lokasiPekerjaan}'),
                    Text('Tanggal Penggantian: ${formatTanggal(laporan.tanggalPenggantian)}'),
                    Text('Tanggal Pembuatan TUG: ${formatTanggal(laporan.tanggalPembuatanTUG)}'),
                    Text('Nama Sopir: ${laporan.namaSopir}'),
                    Text('Nomor SIM/KTP Sopir: ${laporan.noSimKtpSopir}'),
                    Text('Nama Kendaraan: ${laporan.namaKendaraan}'),
                    Text('Nama Satpam: ${laporan.namaSatpam}'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10),

            // Daftar Barang dari JSON
            Text('Barang dalam Laporan:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: laporan.barang.length,
              itemBuilder: (context, index) {
                final barang = laporan.barang[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading: barang.fotoBarang.isNotEmpty
                        ? Image.network(barang.fotoBarang, width: 50, height: 50)
                        : Icon(Icons.image_not_supported),
                    title: Text(barang.namaMaterial),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jumlah: ${barang.jumlah}'),
                        Text('Jenis: ${barang.jenis}'),
                        if (barang.keterangan.isNotEmpty)
                          Text('Keterangan: ${barang.keterangan}'),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 20),

            // Bagian Lampiran Foto
            if (laporan.fotoSuratPengembalian.isNotEmpty) _buildImageSection('Foto Surat Pengembalian', laporan.fotoSuratPengembalian),
            if (laporan.fotoSimKtpSopir.isNotEmpty) _buildImageSection('Foto SIM/KTP Sopir', laporan.fotoSimKtpSopir),
            if (laporan.fotoKendaraan.isNotEmpty) _buildImageSection('Foto Kendaraan', laporan.fotoKendaraan),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk menampilkan gambar jika ada
  Widget _buildImageSection(String title, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Image.network(imageUrl, height: 200, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.image_not_supported, size: 200, color: Colors.grey);
        }),
      ],
    );
  }
}
  