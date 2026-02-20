import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';
import 'doctor_profile_screen.dart';

class SpecialistListScreen extends StatefulWidget {
  const SpecialistListScreen({super.key});

  @override
  State<SpecialistListScreen> createState() => _SpecialistListScreenState();
}

class _SpecialistListScreenState extends State<SpecialistListScreen> {
  final DoctorService _doctorService = DoctorService();
  List<DoctorModel> _doctors = [];
  List<String> _specialties = [];
  String? _selectedSpecialty;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doctors = await _doctorService.getDoctors();
    final specialties = await _doctorService.getSpecialties();
    setState(() {
      _doctors = doctors;
      _specialties = specialties;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Specialist'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedSpecialty == null,
                    onSelected: (_) async {
                      setState(() => _isLoading = true);
                      final doctors = await _doctorService.getDoctors();
                      setState(() {
                        _selectedSpecialty = null;
                        _doctors = doctors;
                        _isLoading = false;
                      });
                    },
                  ),
                  ..._specialties.map((s) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(s),
                          selected: _selectedSpecialty == s,
                          onSelected: (_) async {
                            setState(() => _isLoading = true);
                            final doctors = await _doctorService.getDoctors(specialty: s);
                            setState(() {
                              _selectedSpecialty = s;
                              _doctors = doctors;
                              _isLoading = false;
                            });
                          },
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctors.isEmpty
              ? const Center(child: Text('No doctors found'))
              : ListView.builder(
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _doctors[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: doctor.photo != null ? NetworkImage(doctor.photo!) : null,
                          child: doctor.photo == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(doctor.name),
                        subtitle: Text(doctor.specialty),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '\$${doctor.price}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                Text('${doctor.rating}'),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doctor)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
