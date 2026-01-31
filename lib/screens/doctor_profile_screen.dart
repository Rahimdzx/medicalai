import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});
  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _nameController = TextEditingController();
  final _specController = TextEditingController();
  final _feesController = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController.text = user?.displayName ?? "";
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Settings")),
      body: auth.isLoading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: () async {
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) setState(() => _image = File(picked.path));
              },
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _image != null ? FileImage(_image!) : 
                  (auth.user?.photoURL != null ? NetworkImage(auth.user!.photoURL!) : null),
                child: (_image == null && auth.user?.photoURL == null) ? const Icon(Icons.camera_alt, size: 40) : null,
              ),
            ),
          ),
          const SizedBox(height: 25),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _specController, decoration: const InputDecoration(labelText: "Specialization", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _feesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Consultation Fee ($)", border: OutlineInputBorder())),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            onPressed: () async {
              await auth.updateDoctorProfile(
                name: _nameController.text,
                specialization: _specController.text,
                fees: double.tryParse(_feesController.text) ?? 0.0,
                imageFile: _image,
              );
              Navigator.pop(context);
            },
            child: const Text("Save Updates"),
          ),
        ],
      ),
    );
  }
}
