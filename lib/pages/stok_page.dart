import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockMaterialPage extends StatefulWidget {
  const StockMaterialPage({Key? key}) : super(key: key);

  @override
  State<StockMaterialPage> createState() => _StockMaterialPageState();
}

class _StockMaterialPageState extends State<StockMaterialPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<dynamic> materials = [];
  List<dynamic> filtered = [];

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMaterials();
  }

  Future<void> fetchMaterials() async {
    try {
      final List<dynamic> response = await supabase
          .from('material')
          .select('*, material_details(*)')
          .order('DESKRIPSI MATERIAL', ascending: true);

      setState(() {
        materials = response;
        filtered = response;
      });
    } catch (e) {
      print('Error fetching materials: $e');
    }
  }

  void searchMaterial(String query) {
    final results = materials.where((item) {
      final nama = item['DESKRIPSI MATERIAL']?.toString().toLowerCase() ?? '';
      return nama.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filtered = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok Material'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              onChanged: searchMaterial,
              decoration: InputDecoration(
                hintText: 'Cari material...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final detailList = item['material_details'];
                final detail = (detailList is List && detailList.isNotEmpty) ? detailList[0] : null;

                final imageUrl = detail != null ? detail['image_url'] : null;
                final stock = detail != null ? detail['stock'] ?? 0 : 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.image, size: 40),
                    title: Text(item['DESKRIPSI MATERIAL'] ?? 'Tanpa Nama'),
                    subtitle: Text('Stok: $stock'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MaterialDetailPage(
                            materialId: int.tryParse(item['id'].toString()) ?? 0,
                            materialName: item['DESKRIPSI MATERIAL'] ?? 'Tanpa Nama',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MaterialDetailPage extends StatefulWidget {
  final int materialId;
  final String materialName;

  const MaterialDetailPage({Key? key, required this.materialId, required this.materialName}) : super(key: key);

  @override
  State<MaterialDetailPage> createState() => _MaterialDetailPageState();
}

class _MaterialDetailPageState extends State<MaterialDetailPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController stokController = TextEditingController();

  bool loading = false;
  String? imageUrl;
  File? imageFile;

  @override
  void initState() {
    super.initState();
    fetchMaterialDetail();
  }

  Future<void> fetchMaterialDetail() async {
    final response = await supabase
        .from('material')
        .select('*, material_details(*)')
        .eq('id', widget.materialId)
        .single();

    if (response != null) {
      final detailList = response['material_details'];
      final detail = (detailList is List && detailList.isNotEmpty) ? detailList[0] : null;
      setState(() {
        stokController.text = detail?['stock']?.toString() ?? '0';
        imageUrl = detail?['image_url'];
      });
    }
  }

  Future<void> saveChanges() async {
    setState(() => loading = true);

    String? uploadedUrl = imageUrl;
    if (imageFile != null) {
      uploadedUrl = await uploadImage(imageFile!);
    }

    final existingDetail = await supabase
        .from('material_details')
        .select()
        .eq('material_id', widget.materialId)
        .maybeSingle();

    final data = {
      'stock': int.tryParse(stokController.text) ?? 0,
      'image_url': uploadedUrl,
      'material_id': widget.materialId
    };

    if (existingDetail == null) {
      await supabase.from('material_details').insert(data);
    } else {
      await supabase.from('material_details').update(data).eq('material_id', widget.materialId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data berhasil disimpan')));
      Navigator.pop(context);
    }

    setState(() => loading = false);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String> uploadImage(File file) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'material/$fileName';

    await supabase.storage.from('foto_material').upload(path, file);
    final publicUrl = supabase.storage.from('foto_material').getPublicUrl(path);

    return publicUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.materialName)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: imageFile != null
                          ? Image.file(imageFile!, fit: BoxFit.cover)
                          : (imageUrl != null
                              ? Image.network(imageUrl!, fit: BoxFit.cover)
                              : const Center(child: Text('Tap untuk unggah foto'))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: stokController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stok Material',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: saveChanges,
                    child: const Text('Simpan Perubahan'),
                  )
                ],
              ),
            ),
    );
  }
}