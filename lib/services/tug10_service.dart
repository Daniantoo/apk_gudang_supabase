import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tug10_model.dart';
import 'dart:convert'; // Import untuk decode JSON

class TUG10Service {
  final supabase = Supabase.instance.client;

  Future<List<TUG10Model>> fetchLaporanTUG10() async {
    try {
      // Ambil data dari tabel tug_10
      final response = await supabase
          .from('tug_10')
          .select()
          .order('created_at', ascending: false);

      print("📌 Data Laporan dari Supabase: $response");

      List<TUG10Model> laporanList = [];

      for (var laporan in response) {
        // Ambil data barang dari kolom JSON (daftar_barang)
        List<dynamic> barangJsonList = [];
        if (laporan['daftar_barang'] != null) {
          // Decode JSON string menjadi List<dynamic>
          barangJsonList = jsonDecode(laporan['daftar_barang']);
        }

        // Konversi JSON barang ke List<Barang>
        List<Barang> barangList = barangJsonList.map((barangJson) {
          return Barang.fromJson(barangJson);
        }).toList();

        // Buat TUG10Model dengan data barang yang sudah di-parse
        laporanList.add(TUG10Model.fromJson(laporan, barangList));
      }

      return laporanList;
    } catch (e) {
      print("❌ Error saat fetch laporan: $e");
      return [];
    }
  }
}