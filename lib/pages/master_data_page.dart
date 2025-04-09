import 'dart:io';
import 'package:apk_gudang_supabase/pages/add_material.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';

class MaterialListPage extends StatefulWidget {
  @override
  _MaterialListPageState createState() => _MaterialListPageState();
}

class _MaterialListPageState extends State<MaterialListPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> materials = [];
  List<dynamic> filteredMaterials = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMaterials();
    searchController.addListener(_filterMaterials);
  }

  void dispose() {
  searchController.removeListener(_filterMaterials);
  searchController.dispose();
  super.dispose();
}

  Future<void> fetchMaterials() async {
  final response = await supabase.from('material').select();
  if (mounted) {
    setState(() {
      materials = response;
      filteredMaterials = materials;
    });
  }
}

  void _filterMaterials() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredMaterials = materials.where((material) {
        String nama = material['DESKRIPSI MATERIAL'].toString().toLowerCase();
        String katalog = material['KATALOG'].toString().toLowerCase();
        return nama.contains(query) || katalog.contains(query);
      }).toList();
    });
  }

  Future<void> deleteMaterial(String idBarang) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Material?'),
        content: Text('Apakah Anda yakin ingin menghapus material ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Hapus')),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('material').delete().match({'id': idBarang});
      fetchMaterials();
    }
  }

  void showDetailBottomSheet(dynamic material) {
    TextEditingController namaController = TextEditingController(text: material['DESKRIPSI MATERIAL']);
    TextEditingController kategoriController = TextEditingController(text: material['KATALOG']);
    TextEditingController stokController = TextEditingController(text: material['SATUAN']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Detail Material', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(controller: namaController, decoration: InputDecoration(labelText: 'Nama Material')),
              TextField(controller: kategoriController, decoration: InputDecoration(labelText: 'Katalog')),
              TextField(controller: stokController, decoration: InputDecoration(labelText: 'Satuan')),
              SizedBox(height: 20),
              QrImageView(
                data: material['id'].toString(),
                version: QrVersions.auto,
                size: 150.0,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('Simpan Perubahan'),
                    onPressed: () async {
                      await supabase.from('material').update({
                        'DESKRIPSI MATERIAL': namaController.text,
                        'KATALOG': kategoriController.text,
                        'SATUAN': stokController.text,
                      }).match({'id': material['id']});
                      Navigator.pop(context);
                      fetchMaterials();
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.delete, color: const Color.fromARGB(255, 224, 5, 5)),
                    label: Text('Hapus'),
                    style: ElevatedButton.styleFrom(),
                    onPressed: () {
                      Navigator.pop(context);
                      deleteMaterial(material['id'].toString());
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.download),
                label: Text('Simpan QR'),
                onPressed: () => saveQRCode(material['id'].toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveQRCode(String data) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/qrcode_$data.png';
    final file = File(path);

    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );

    if (qrValidationResult.status == QrValidationStatus.valid) {
      final painter = QrPainter.withQr(
        qr: qrValidationResult.qrCode!,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      final picData = await painter.toImageData(200);
      await file.writeAsBytes(picData!.buffer.asUint8List());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QR Code disimpan di $path')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Master Data Material')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Cari Material...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(
            child: filteredMaterials.isEmpty
                ? Center(child: Text('Tidak ada Material yang ditemukan'))
                : ListView.builder(
                    itemCount: filteredMaterials.length,
                    itemBuilder: (context, index) {
                      final material = filteredMaterials[index];
                      return Card(
                        margin: EdgeInsets.all(10),
                        child: ListTile(
                          title: Text(material['DESKRIPSI MATERIAL'] ?? 'Tanpa Nama'),
                          subtitle: Text(
                            'Katalog: ${material['KATALOG']} | Satuan: ${material['SATUAN']}'
                            ),
                          leading: Icon(Icons.inventory, color: Colors.blue),
                          onTap: () => showDetailBottomSheet(material),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMaterialPage()),
          );

          if (result == true) {
            fetchMaterials(); // Refresh data jika material baru ditambahkan
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Tambah Material',
      ),
    );
  }
}
