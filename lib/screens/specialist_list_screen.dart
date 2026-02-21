import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
  List<DoctorModel> _filteredDoctors = [];
  List<String> _specialties = [];
  String? _selectedSpecialty;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final doctors = await _doctorService.getDoctors();
    final specialties = await _doctorService.getSpecialties();
    setState(() {
      _doctors = doctors;
      _filteredDoctors = doctors;
      _specialties = specialties;
      _isLoading = false;
    });
  }

  void _filterDoctors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDoctors = _selectedSpecialty == null
            ? _doctors
            : _doctors.where((d) => d.specialty == _selectedSpecialty).toList();
      } else {
        _filteredDoctors = _doctors.where((doctor) {
          final matchesName = doctor.name.toLowerCase().contains(query.toLowerCase());
          final matchesSpecialty = doctor.specialty.toLowerCase().contains(query.toLowerCase());
          final matchesSelectedSpecialty = _selectedSpecialty == null || doctor.specialty == _selectedSpecialty;
          return (matchesName || matchesSpecialty) && matchesSelectedSpecialty;
        }).toList();
      }
    });
  }

  Future<void> _filterBySpecialty(String? specialty) async {
    setState(() => _isLoading = true);

    if (specialty == null) {
      final doctors = await _doctorService.getDoctors();
      setState(() {
        _selectedSpecialty = null;
        _doctors = doctors;
        _filterDoctors(_searchController.text);
        _isLoading = false;
      });
    } else {
      final doctors = await _doctorService.getDoctors(specialty: specialty);
      setState(() {
        _selectedSpecialty = specialty;
        _filteredDoctors = doctors;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.findSpecialist),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterDoctors('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: _filterDoctors,
                ),
              ),
              // Specialty Filters
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(l10n.all),
                        selected: _selectedSpecialty == null,
                        onSelected: (_) => _filterBySpecialty(null),
                      ),
                    ),
                    ..._specialties.map((s) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(s),
                            selected: _selectedSpecialty == s,
                            onSelected: (_) => _filterBySpecialty(s),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredDoctors.isEmpty
              ? _buildEmptyState(context, l10n)
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _filteredDoctors[index];
                    return _DoctorListCard(
                      doctor: doctor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorProfileScreen(doctor: doctor),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            l10n.doctorNotFound,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          if (_searchController.text.isNotEmpty || _selectedSpecialty != null)
            TextButton(
              onPressed: () {
                _searchController.clear();
                _filterBySpecialty(null);
              },
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }
}

class _DoctorListCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;

  const _DoctorListCard({
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'doctor_${doctor.id}',
                child: CircleAvatar(
                  radius: 36,
                  backgroundImage: doctor.photo != null ? NetworkImage(doctor.photo!) : null,
                  child: doctor.photo == null
                      ? const Icon(Icons.person, size: 36)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${doctor.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                        Text(
                          ' ${doctor.rating}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.work_outline, size: 14, color: Colors.grey.shade600),
                        Text(
                          ' ${doctor.doctorNumber}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${doctor.price.toStringAsFixed(0)} ${doctor.currency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(l10n.bookAppointment),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
