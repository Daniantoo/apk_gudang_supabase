import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'scan_qr.dart'; // Halaman scan QR
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:convert';

class Tug10Page extends StatefulWidget {
  @override
  _Tug10PageState createState() => _Tug10PageState();
}

class _Tug10PageState extends State<Tug10Page> {
  
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy'); // Format untuk menampilkan tanggal dalam format dd/MM/yyyy
  final SupabaseClient supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  TextEditingController noBaController = TextEditingController();
  TextEditingController unitPengirimController = TextEditingController();
  TextEditingController namaPengirimController = TextEditingController();
  TextEditingController jabatanPengirimController = TextEditingController();
  TextEditingController deskripsiPekerjaanController = TextEditingController();
  TextEditingController lokasiPekerjaanController = TextEditingController();
  TextEditingController namaSopirController = TextEditingController();
  TextEditingController noSimKtpSopirController = TextEditingController();
  TextEditingController namaKendaraanController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  TextEditingController tanggalPenggantianController = TextEditingController();
  TextEditingController tanggalTugController = TextEditingController();

  String? selectedPekerjaan;
  String? selectedSatpam;
  DateTime? tanggalPenggantian;
  DateTime? tanggalTug;
  File? fotoSuratPengembalian;
  File? fotoSimKtpSopir;
  File? fotoKendaraan;
  
  // URLs for uploaded images
  String? fotoSuratPengembalianUrl;
  String? fotoSimKtpSopirUrl;
  String? fotoKendaraanUrl;

  final List<String> pekerjaanOptions = ['Penggantian', 'Pemeliharaan', 'Pasang Baru', 'Penambahan'];
  final List<String> satpamOptions = ['BUDHI SETIAWAN', 'ACHMAD EFENDI', 'EDI KURNIAWAN', 'ASRORU MAULA', 'BAMBANG HARIONO'];

  // Search results
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;

  // Daftar barang yang masuk ke dalam queue
  List<Map<String, dynamic>> barangQueue = [];

  @override
  void initState() {
    super.initState();
    
    // Set initial value untuk tanggal hari ini
    final now = DateTime.now();
    tanggalPenggantian = now;
    tanggalTug = now;
    
    // Update text field controllers dengan format tanggal yang benar
    tanggalPenggantianController.text = dateFormat.format(now);
    tanggalTugController.text = dateFormat.format(now);
  }

  @override
  void dispose() {
    // Dispose semua controllers
    noBaController.dispose();
    unitPengirimController.dispose();
    namaPengirimController.dispose();
    jabatanPengirimController.dispose();
    deskripsiPekerjaanController.dispose();
    lokasiPekerjaanController.dispose();
    namaSopirController.dispose();
    noSimKtpSopirController.dispose();
    namaKendaraanController.dispose();
    searchController.dispose();
    tanggalPenggantianController.dispose();
    tanggalTugController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      
      setState(() {
        if (type == 'suratPengembalian') {
          fotoSuratPengembalian = imageFile;
        } else if (type == 'simKtp') {
          fotoSimKtpSopir = imageFile;
        } else if (type == 'kendaraan') {
          fotoKendaraan = imageFile;
        }
      });
    }
  }

  void _showImagePickerOptions(String type) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery, type);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Ambil Foto dengan Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera, type);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Method untuk menampilkan date picker dan update text field
  Future<void> _selectDate(BuildContext context, bool isPenggantian) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPenggantian ? (tanggalPenggantian ?? DateTime.now()) : (tanggalTug ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isPenggantian) {
          tanggalPenggantian = picked;
          tanggalPenggantianController.text = dateFormat.format(picked);
        } else {
          tanggalTug = picked;
          tanggalTugController.text = dateFormat.format(picked);
        }
      });
    }
  }

  Future<void> _scanQR() async {
    final scannedQR = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScanQRPage()),
    );

    if (scannedQR != null) {
      _fetchBarangData(scannedQR);
    }
  }

  // Search for materials
  Future<void> _searchMaterial(String keyword) async {
    setState(() {
      isSearching = true;
    });

    try {
      // Search in the material table where DESKRIPSI MATERIAL contains the keyword
      final response = await supabase
          .from('material')
          .select()
          .ilike('DESKRIPSI MATERIAL', '%$keyword%')
          .limit(10);

      setState(() {
        searchResults = List<Map<String, dynamic>>.from(response);
        isSearching = false;
      });
    } catch (e) {
      print("Error searching materials: $e");
      setState(() {
        isSearching = false;
        searchResults = [];
      });
    }
  }

  // Show search dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Cari Barang'),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Nama Barang',
                        hintText: 'Masukkan nama barang',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            if (searchController.text.isNotEmpty) {
                              _searchMaterial(searchController.text).then((_) {
                                setDialogState(() {}); // Refresh dialog
                              });
                            }
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _searchMaterial(value).then((_) {
                            setDialogState(() {}); // Refresh dialog
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    isSearching
                        ? CircularProgressIndicator()
                        : Expanded(
                            child: searchResults.isEmpty
                                ? Center(
                                    child: Text(
                                      searchController.text.isEmpty
                                          ? 'Masukkan kata kunci pencarian'
                                          : 'Tidak ada barang ditemukan',
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: searchResults.length,
                                    itemBuilder: (context, index) {
                                      final item = searchResults[index];
                                      return ListTile(
                                        title: Text(item['DESKRIPSI MATERIAL'] ?? 'Unnamed'),
                                        subtitle: Text('Satuan: ${item['SATUAN']}'),
                                        onTap: () {
                                          _addBarangToQueue(item);
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  ),
                          ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    searchController.clear();
                  },
                  child: Text('Batal'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Clear search when dialog is closed
      searchController.clear();
      setState(() {
        searchResults = [];
      });
    });
  }

  void _addBarangToQueue(Map<String, dynamic> barang) {
    setState(() {
      barangQueue.add({
        'id': barang['id'],
        'nama': barang['DESKRIPSI MATERIAL'] ?? 'Unnamed',
        'jumlah': 1, // Default 1, bisa diubah
        'jenis': 'PERSEDIAAN', // Default jenis
        'foto': null, // Foto barang, bisa diambil saat transaksi
      });
    });
  }

  Future<void> _fetchBarangData(String scannedQR) async {
    final response = await supabase.from('material').select().eq('id', scannedQR).single();

    if (response != null) {
      setState(() {
        barangQueue.add({
          'id': response['id'],
          'nama': response['DESKRIPSI MATERIAL'],
          'jumlah': 1, // Default 1, bisa diubah
          'jenis': 'PERSEDIAAN', // Default jenis
          'foto': null, // Foto barang, bisa diambil saat transaksi
        });
      });
    }
  }

  Future<String?> _uploadFile(File file, String folder, String fileName) async {
    try {
      final storagePath = '$folder/$fileName.jpg';
      await supabase.storage.from('tug_10').upload(storagePath, file);
      final publicUrl = supabase.storage.from('tug_10').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      print("Gagal upload file: $e");
      return null;
    }
  }

  Future<void> _uploadAllFiles() async {
    final uuid = Uuid().v4();
    
    if (fotoSuratPengembalian != null) {
      fotoSuratPengembalianUrl = await _uploadFile(
        fotoSuratPengembalian!, 
        'surat_pengembalian', 
        'surat_${uuid}'
      );
    }
    
    if (fotoSimKtpSopir != null) {
      fotoSimKtpSopirUrl = await _uploadFile(
        fotoSimKtpSopir!, 
        'sim_ktp', 
        'sim_${uuid}'
      );
    }
    
    if (fotoKendaraan != null) {
      fotoKendaraanUrl = await _uploadFile(
        fotoKendaraan!, 
        'kendaraan', 
        'kendaraan_${uuid}'
      );
    }
    
    // Upload foto barang dalam queue dan simpan URL-nya
    for (int i = 0; i < barangQueue.length; i++) {
      if (barangQueue[i]['foto'] == null && barangQueue[i]['fotoFile'] != null) {
        barangQueue[i]['foto'] = await _uploadFile(
          barangQueue[i]['fotoFile'], 
          'barang_foto', 
          'barang_${barangQueue[i]['id']}_${uuid}'
        );
      }
    }
  }

void _submitTug10() async {
  if (_formKey.currentState!.validate()) {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );
      
      await _uploadAllFiles();

      final tug10Id = Uuid().v4();

      // Convert barangQueue to JSON
      List<Map<String, dynamic>> barangList = barangQueue.map((barang) {
        return {
          'material_id': barang['id'],
          'nama_material': barang['nama'],  
          'jumlah_barang': barang['jumlah'],
          'satuan' : barang['satuan'],
          'jenis_barang': barang['jenis'],
          'foto_barang': barang['foto'],
          'keterangan': barang['keterangan'] ?? '',
        };
      }).toList();

      String barangJson = jsonEncode(barangList);

      // Insert to tug_10 with JSON data
      await supabase.from('tug_10').insert({
        'id': tug10Id,
        'no_ba_pengembalian': noBaController.text,
        'unit_pengirim': unitPengirimController.text,
        'nama_pengirim': namaPengirimController.text,
        'jabatan_pengirim': jabatanPengirimController.text,
        'pekerjaan': selectedPekerjaan,
        'deskripsi_pekerjaan': deskripsiPekerjaanController.text,
        'lokasi_pekerjaan': lokasiPekerjaanController.text,
        'tanggal_penggantian': tanggalPenggantian?.toIso8601String(),
        'tanggal_pembuatan_tug': tanggalTug?.toIso8601String(),
        'foto_surat_pengembalian': fotoSuratPengembalianUrl,
        'nama_sopir': namaSopirController.text,
        'no_sim_ktp_sopir': noSimKtpSopirController.text,
        'foto_sim_ktp_sopir': fotoSimKtpSopirUrl,
        'nama_kendaraan': namaKendaraanController.text,
        'foto_kendaraan': fotoKendaraanUrl,
        'nama_satpam': selectedSatpam,
        'daftar_barang': barangJson, // JSON data
        'created_at': DateTime.now().toIso8601String(),
      });

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TUG 10 berhasil disimpan!'))
      );
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data: $e'))
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Form TUG 10')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: noBaController,
                decoration: InputDecoration(labelText: 'No BA Pengembalian'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'No BA Pengembalian harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: unitPengirimController,
                decoration: InputDecoration(labelText: 'Unit Pengirim'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Unit Pengirim harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: namaPengirimController,
                decoration: InputDecoration(labelText: 'Nama Pengirim Barang'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama Pengirim harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: jabatanPengirimController,
                decoration: InputDecoration(labelText: 'Jabatan Pengirim Barang'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jabatan Pengirim harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: selectedPekerjaan,
                decoration: InputDecoration(labelText: 'Pekerjaan'),
                items: pekerjaanOptions.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (value) => setState(() => selectedPekerjaan = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pekerjaan harus dipilih';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: deskripsiPekerjaanController,
                decoration: InputDecoration(labelText: 'Deskripsi Pekerjaan'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi Pekerjaan harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: lokasiPekerjaanController,
                decoration: InputDecoration(labelText: 'Lokasi Pekerjaan'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lokasi Pekerjaan harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
             // Replaced the ListTile with TextFormField + suffix icon for date picker
              TextFormField(
                controller: tanggalPenggantianController,
                decoration: InputDecoration(
                  labelText: 'Tanggal Penggantian (DD/MM/YYYY)',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, true),
                  ),
                ),
                readOnly: true, // User tidak bisa mengetik langsung
                onTap: () => _selectDate(context, true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal Penggantian harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Replaced the ListTile with TextFormField + suffix icon for date picker
              TextFormField(
                controller: tanggalTugController,
                decoration: InputDecoration(
                  labelText: 'Tanggal Pembuatan TUG (DD/MM/YYYY)',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, false),
                  ),
                ),
                readOnly: true, // User tidak bisa mengetik langsung
                onTap: () => _selectDate(context, false),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal Pembuatan TUG harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Foto Surat Pengembalian
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Foto Surat Pengembalian', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      if (fotoSuratPengembalian != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Image.file(fotoSuratPengembalian!, fit: BoxFit.cover),
                        ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _showImagePickerOptions('suratPengembalian'),
                        child: Text('Pilih Foto Surat Pengembalian'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: namaSopirController,
                decoration: InputDecoration(labelText: 'Nama Sopir'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama Sopir harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: noSimKtpSopirController,
                decoration: InputDecoration(labelText: 'No SIM/KTP Sopir'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'No SIM/KTP Sopir harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Foto SIM/KTP Sopir
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Foto SIM/KTP Sopir', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      if (fotoSimKtpSopir != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Image.file(fotoSimKtpSopir!, fit: BoxFit.cover),
                        ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _showImagePickerOptions('simKtp'),
                        child: Text('Pilih Foto SIM/KTP Sopir'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: namaKendaraanController,
                decoration: InputDecoration(labelText: 'Nama Kendaraan/Nopol Kendaraan Pengangkut'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama/Nopol Kendaraan harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Foto Kendaraan Pengangkut
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Foto Kendaraan Pengangkut', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      if (fotoKendaraan != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Image.file(fotoKendaraan!, fit: BoxFit.cover),
                        ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _showImagePickerOptions('kendaraan'),
                        child: Text('Pilih Foto Kendaraan Pengangkut'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Nama Satpam
              DropdownButtonFormField<String>(
                value: selectedSatpam,
                decoration: InputDecoration(labelText: 'Nama Satpam yang Bertugas'),
                items: satpamOptions.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (value) => setState(() => selectedSatpam = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama Satpam harus dipilih';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              // Bagian Scan QR dan List Barang
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daftar Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _scanQR,
                              icon: Icon(Icons.qr_code_scanner),
                              label: Text('Scan QR Barang'),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showSearchDialog,
                              icon: Icon(Icons.search),
                              label: Text('Cari Barang'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      if (barangQueue.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Belum ada barang. Silakan scan QR atau cari barang untuk menambahkan.'),
                        ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: barangQueue.length,
                        itemBuilder: (context, index) {
                          final barang = barangQueue[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(barang['nama'], style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: barang['jumlah'].toString(),
                                          decoration: InputDecoration(labelText: 'Jumlah'),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            setState(() {
                                              barang['jumlah'] = int.tryParse(value) ?? 1;
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: barang['jenis'],
                                          decoration: InputDecoration(labelText: 'Jenis'),
                                          items: ['PERSEDIAAN', 'CADANG', 'PRE-MEMORY', 'ATTB', 'BONGKARAN'].map((e) {
                                            return DropdownMenuItem(value: e, child: Text(e));
                                          }).toList(),
                                          onChanged: (value) => setState(() => barang['jenis'] = value),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: barang['satuan'],
                                          decoration: InputDecoration(labelText: 'Satuan'),
                                          items: ['M', 'BH', 'U', 'SET', 'LONJOR', 'KG', '-'].map((e) {
                                            return DropdownMenuItem(value: e, child: Text(e));
                                          }).toList(),
                                          onChanged: (value) => setState(() => barang['satuan'] = value),
                                        ),
                                      ),
                                  SizedBox(height: 8),
                                  if (barang['foto'] == null && barang['fotoFile'] == null)
                                    ElevatedButton(
                                      onPressed: () async {
                                        final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
                                        if (pickedFile != null) {
                                          setState(() {
                                            barang['fotoFile'] = File(pickedFile.path);
                                          });
                                        }
                                      },
                                      child: Text("Ambil Foto Barang"),
                                    ),
                                  if (barang['fotoFile'] != null)
                                    Container(
                                      height: 100,
                                      width: double.infinity,
                                      child: Image.file(barang['fotoFile'], fit: BoxFit.cover),
                                      margin: EdgeInsets.only(top: 8),
                                    ),
                                  if (barang['foto'] != null && barang['fotoFile'] == null)
                                    Container(
                                      height: 100,
                                      width: double.infinity,
                                      child: Image.network(barang['foto'], fit: BoxFit.cover),
                                      margin: EdgeInsets.only(top: 8),
                                    ),
                                  SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: barang['keterangan'] ?? '',
                                    decoration: InputDecoration(labelText: 'Keterangan'),
                                    onChanged: (value) {
                                      setState(() {
                                        barang['keterangan'] = value;
                                      });
                                    },
                                  ),
				                          SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        barangQueue.removeAt(index);
                                      });
                                    },
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    label: Text("Hapus Barang"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
               // Tombol Submit
              ElevatedButton.icon(
                onPressed: _submitTug10,
                icon: Icon(Icons.save),
                label: Text('Simpan TUG 10'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}