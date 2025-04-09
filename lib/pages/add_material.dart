import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AddMaterialPage extends StatefulWidget {
  @override
  _AddMaterialPageState createState() => _AddMaterialPageState();
}

class _AddMaterialPageState extends State<AddMaterialPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  TextEditingController namaController = TextEditingController();
  TextEditingController katalogController = TextEditingController();
  TextEditingController satuanController = TextEditingController();

  Future<void> addMaterial() async {
    if (_formKey.currentState!.validate()) {
      final uuid = Uuid().v4(); // Generate UUID

      try {
        await supabase.from('material').insert({
          'id': uuid, // ID dengan UUID
          'DESKRIPSI MATERIAL': namaController.text,
          'KATALOG': katalogController.text,
          'SATUAN': satuanController.text,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material berhasil ditambahkan!')),
        );
        Navigator.pop(context, true); // Kembali ke halaman sebelumnya dan refresh data
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan material: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    katalogController.dispose();
    satuanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Material')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama Material'),
                validator: (value) =>
                    value!.isEmpty ? 'Nama material tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: katalogController,
                decoration: const InputDecoration(labelText: 'Katalog'),
                validator: (value) =>
                    value!.isEmpty ? 'Katalog tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: satuanController,
                decoration: const InputDecoration(labelText: 'Satuan'),
                validator: (value) =>
                    value!.isEmpty ? 'Satuan tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: addMaterial,
                child: const Text('Simpan Material'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
