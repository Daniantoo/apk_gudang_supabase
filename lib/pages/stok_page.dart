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
  bool loading = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMaterials();
  }

  Future<void> fetchMaterials() async {
  setState(() => loading = true);
  try {
    // Gunakan join untuk mengambil data yang terhubung
    final List<dynamic> response = await supabase
        .from('material')
        .select('id, "DESKRIPSI MATERIAL", material_details(id, stock, image_url)')
        .order('DESKRIPSI MATERIAL', ascending: true);

    setState(() {
      materials = response;
      filtered = response;
      loading = false;
    });
  } catch (e) {
    setState(() => loading = false);
    // Handle error
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
  child: GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    itemCount: filtered.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 3 / 4,
    ),
    itemBuilder: (context, index) {
      final item = filtered[index];
      final detailList = item['material_details'];
      final detail = (detailList is List && detailList.isNotEmpty) ? detailList[0] : null;

      final imageUrl = detail != null ? detail['image_url'] : null;
      final stock = detail != null ? detail['stock'] ?? 0 : 0;

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MaterialDetailPage(
                materialId: item['id'].toString(),
                materialName: item['DESKRIPSI MATERIAL'] ?? 'Tanpa Nama',
              ),
            ),
          );
        },
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 48, color: Colors.grey),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  item['DESKRIPSI MATERIAL'] ?? 'Tanpa Nama',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Text('Stok: $stock'),
              ),
            ],
          ),
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
  final String materialId;
  final String materialName;

  const MaterialDetailPage({
    Key? key,
    required this.materialId,
    required this.materialName,
  }) : super(key: key);

  @override
  State<MaterialDetailPage> createState() => _MaterialDetailPageState();
}

class _MaterialDetailPageState extends State<MaterialDetailPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController stokController = TextEditingController();
  bool loading = false;
  String? imageUrl;
  File? imageFile;
  Map<String, dynamic>? materialInfo;

  @override
  void initState() {
    super.initState();
    fetchMaterialDetail();
  }

  Future<void> fetchMaterialDetail() async {
    setState(() => loading = true);
    try {
      final response = await supabase
          .from('material_details')
          .select('*, material:material(*)')
          .eq('material_id', widget.materialId)
          .single();

      if (response != null) {
        setState(() {
          stokController.text = response['stock']?.toString() ?? '0';
          imageUrl = response['image_url'];
          materialInfo = response['material'];
        });
      }
    } catch (e) {
      print('Error fetching material detail: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> saveChanges() async {
    setState(() => loading = true);
    try {
      String? uploadedUrl = imageUrl;

      if (imageFile != null) {
      // Hapus foto lama jika ada
      if (imageUrl != null) {
        await deleteOldImageFromStorage(imageUrl!);
      }
      // Upload foto baru
      uploadedUrl = await uploadImage(imageFile!);
    }

      await supabase
          .from('material_details')
          .update({
            'stock': int.tryParse(stokController.text) ?? 0,
            'image_url': uploadedUrl,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('material_id', widget.materialId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disimpan')),
        );
        await fetchMaterialDetail(); 
      }
    } catch (e) {
      print("Error saat menyimpan: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> pickImage({required ImageSource source}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> removeImage() async {
    setState(() {
      imageFile = null;
      imageUrl = null;
    });
  }

  Future<String> uploadImage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'material/$fileName';

      await supabase.storage.from('material-images').upload(path, file);
      final publicUrl =
          supabase.storage.from('material-images').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      print("Error upload gambar: $e");
      rethrow;
    }
  }

  Future<void> deleteOldImageFromStorage(String url) async {
  try {
    final Uri uri = Uri.parse(url);
    final String fullPath = uri.pathSegments.skip(1).join('/'); // skip bucket name
    await supabase.storage.from('material-images').remove([fullPath]);
  } catch (e) {
    print('Gagal menghapus file lama: $e');
  }
}

  Widget buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: imageFile != null
                ? Image.file(imageFile!, fit: BoxFit.cover)
                : (imageUrl != null
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
                    : const Center(child: Text('Belum ada foto'))),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.photo),
              label: const Text('Galeri'),
              onPressed: () => pickImage(source: ImageSource.gallery),
            ),
            const SizedBox(width: 7),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Kamera'),
              onPressed: () => pickImage(source: ImageSource.camera),
            ),
            const SizedBox(width: 7),
            if (imageUrl != null || imageFile != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text('Hapus'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: removeImage,
              ),
          ],
        )
      ],
    );
  }

  Widget buildMaterialInfo() {
    if (materialInfo == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nama: ${materialInfo!['DESKRIPSI MATERIAL']}', style: const TextStyle(fontSize: 14)),
        Text('Katalog: ${materialInfo!['KATALOG'] ?? '-'}'),
        Text('Satuan: ${materialInfo!['SATUAN'] ?? '-'}'),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.materialName)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildImageSection(),
                  const SizedBox(height: 20),
                  const Text('Detail Material', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  buildMaterialInfo(),
                  TextField(
                    controller: stokController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stok Material',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                   child: ElevatedButton.icon(
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: loading
                        ? const Text('Menyimpan...')
                        : const Text('Simpan Perubahan'),
                    onPressed: loading
                        ? null
                        : () async {
                            await saveChanges(); // Di sini sudah termasuk Navigator.pop()
                            // fetchMaterialDetail() tidak perlu dipanggil di sini
                          },
                  ),
                  ),
                ],
              ),
            ),
    );
  }
}