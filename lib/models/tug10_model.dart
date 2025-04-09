import 'dart:convert';

class TUG10Model {
  final String id;
  final String noBA;
  final String unitPengirim;
  final String namaPengirim;
  final String jabatanPengirim;
  final String pekerjaan; // Dropdown (Penggantian, Pemeliharaan, dll.)
  final String deskripsiPekerjaan;
  final String lokasiPekerjaan;
  final String tanggalPenggantian;
  final String tanggalPembuatanTUG;
  final String fotoSuratPengembalian; // URL Foto
  final String namaSopir;
  final String noSimKtpSopir;
  final String fotoSimKtpSopir; // URL Foto
  final String namaKendaraan;
  final String fotoKendaraan; // URL Foto
  final String namaSatpam; // Dropdown (BUDHI SETIAWAN, ACHMAD EFENDI, dll.)
  final List<Barang> barang;
  final int nomorUrut; // List barang dalam laporan

  TUG10Model({
    required this.id,
    required this.noBA,
    required this.unitPengirim,
    required this.namaPengirim,
    required this.jabatanPengirim,
    required this.pekerjaan,
    required this.deskripsiPekerjaan,
    required this.lokasiPekerjaan,
    required this.tanggalPenggantian,
    required this.tanggalPembuatanTUG,
    required this.fotoSuratPengembalian,
    required this.namaSopir,
    required this.noSimKtpSopir,
    required this.fotoSimKtpSopir,
    required this.namaKendaraan,
    required this.fotoKendaraan,
    required this.namaSatpam,
    required this.barang,
    required this.nomorUrut,
  });

  // Konversi dari JSON (Supabase)
  factory TUG10Model.fromJson(Map<String, dynamic> json, List<Barang> barangList) {
    return TUG10Model(
      id: json['id'] ?? '',
      noBA: json['no_ba_pengembalian'] ?? '',
      unitPengirim: json['unit_pengirim'] ?? '',
      namaPengirim: json['nama_pengirim'] ?? '',
      jabatanPengirim: json['jabatan_pengirim'] ?? '',
      pekerjaan: json['pekerjaan'] ?? '', // Pastikan dropdown sesuai dengan opsi
      deskripsiPekerjaan: json['deskripsi_pekerjaan'] ?? '',
      lokasiPekerjaan: json['lokasi_pekerjaan'] ?? '',
      tanggalPenggantian: json['tanggal_penggantian'] ?? '',
      tanggalPembuatanTUG: json['tanggal_pembuatan_tug'] ?? '',
      fotoSuratPengembalian: json['foto_surat_pengembalian'] ?? '',
      namaSopir: json['nama_sopir'] ?? '',
      noSimKtpSopir: json['no_sim_ktp_sopir'] ?? '',
      fotoSimKtpSopir: json['foto_sim_ktp_sopir'] ?? '',
      namaKendaraan: json['nama_kendaraan'] ?? '',
      fotoKendaraan: json['foto_kendaraan'] ?? '',
      nomorUrut: json['nomor_urut'] ?? '',
      namaSatpam: json['nama_satpam'] ?? '', // Harus salah satu dari opsi dropdown
        barang: json['daftar_barang'] != null 
          ? (jsonDecode(json['daftar_barang']) as List)
              .map((item) => Barang.fromJson(item))
              .toList()
          : [],
          
    );
  }
}

// Model untuk barang dalam laporan
class Barang {
  final String materialId;
  final String namaMaterial;
  final int jumlah;
  final String jenis;
  final String satuan;
  final String fotoBarang;
  final String keterangan;

  // Gunakan named parameters dengan {}
  Barang({
    required this.materialId,
    required this.namaMaterial,
    required this.jumlah,
    required this.jenis,
    required this.satuan,
    required this.fotoBarang,
    required this.keterangan,
  });

  factory Barang.fromJson(Map<String, dynamic> json) {
    return Barang(
      // Pastikan semua parameter sesuai dengan urutan dan tipe data
      materialId: json['material_id'] ?? '',
      namaMaterial: json['nama_material'] ?? '',
      jumlah: (json['jumlah_barang'] as num?)?.toInt() ?? 0,
      jenis: json['jenis_barang'] ?? '',
      satuan: json['satuan'] ?? '',
      fotoBarang: json['foto_barang'] ?? '',
      keterangan: json['keterangan'] ?? '',
    );
  }
}