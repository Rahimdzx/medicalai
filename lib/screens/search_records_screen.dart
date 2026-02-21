import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';

class SearchRecordsScreen extends StatefulWidget {
  const SearchRecordsScreen({super.key});

  @override
  State<SearchRecordsScreen> createState() => _SearchRecordsScreenState();
}

class _SearchRecordsScreenState extends State<SearchRecordsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  String _sortBy = 'date_desc';
  List<PatientRecord> _allRecords = [];
  List<PatientRecord> _filteredRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      QuerySnapshot snapshot;
      
      if (authProvider.userRole == 'doctor') {
        snapshot = await FirebaseFirestore.instance
            .collection('records')
            .where('doctorId', isEqualTo: authProvider.user?.uid)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('records')
            .where('patientEmail', isEqualTo: authProvider.user?.email)
            .get();
      }

      _allRecords = snapshot.docs
          .map((doc) => PatientRecord.fromFirestore(doc))
          .toList();
      
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading records: $e');
    }

    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    List<PatientRecord> results = List.from(_allRecords);

    // تطبيق البحث النصي
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((record) {
        return record.patientEmail.toLowerCase().contains(query) ||
            record.diagnosis.toLowerCase().contains(query) ||
            record.prescription.toLowerCase().contains(query) ||
            (record.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // تطبيق فلتر التاريخ
    if (_dateRange != null) {
      results = results.where((record) {
        return record.createdAt.isAfter(_dateRange!.start) &&
            record.createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // تطبيق الترتيب
    switch (_sortBy) {
      case 'date_desc':
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'date_asc':
        results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'patient':
        results.sort((a, b) => a.patientEmail.compareTo(b.patientEmail));
        break;
      case 'diagnosis':
        results.sort((a, b) => a.diagnosis.compareTo(b.diagnosis));
        break;
    }

    setState(() => _filteredRecords = results);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.search ?? 'Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHint ?? 'Search by patient, diagnosis, prescription...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _applyFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // فلاتر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // فلتر التاريخ
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      _dateRange != null
                          ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                          : l10n.dateRange ?? 'Date Range',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: _selectDateRange,
                  ),
                ),
                const SizedBox(width: 8),
                // الترتيب
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  onSelected: (value) {
                    setState(() => _sortBy = value);
                    _applyFilters();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'date_desc',
                      child: _buildSortOption(
                        'Newest First',
                        Icons.arrow_downward,
                        _sortBy == 'date_desc',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'date_asc',
                      child: _buildSortOption(
                        'Oldest First',
                        Icons.arrow_upward,
                        _sortBy == 'date_asc',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'patient',
                      child: _buildSortOption(
                        'By Patient',
                        Icons.person,
                        _sortBy == 'patient',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'diagnosis',
                      child: _buildSortOption(
                        'By Diagnosis',
                        Icons.medical_services,
                        _sortBy == 'diagnosis',
                      ),
                    ),
                  ],
                ),
                // مسح الفلاتر
                if (_dateRange != null)
                  IconButton(
                    icon: const Icon(Icons.filter_alt_off),
                    onPressed: () {
                      setState(() => _dateRange = null);
                      _applyFilters();
                    },
                    tooltip: 'Clear filters',
                  ),
              ],
            ),
          ),

          // عدد النتائج
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredRecords.length} ${l10n.results ?? 'results'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // قائمة النتائج
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRecords.length,
                        itemBuilder: (context, index) {
                          return _SearchResultCard(
                            record: _filteredRecords[index],
                            searchQuery: _searchQuery,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(String title, IconData icon, bool isSelected) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isSelected ? Theme.of(context).primaryColor : null),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
        if (isSelected) ...[
          const Spacer(),
          Icon(Icons.check, size: 18, color: Theme.of(context).primaryColor),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No records found' : 'No matching records',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
      _applyFilters();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SearchResultCard extends StatelessWidget {
  final PatientRecord record;
  final String searchQuery;

  const _SearchResultCard({
    required this.record,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRecordDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHighlightedText(
                          record.patientEmail,
                          searchQuery,
                          const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          record.date,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              _buildHighlightedText(
                record.diagnosis,
                searchQuery,
                TextStyle(color: Colors.grey[800]),
              ),
              if (record.prescription.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.medication, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildHighlightedText(
                        record.prescription,
                        searchQuery,
                        TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle baseStyle, {
    int maxLines = 2,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final index = textLower.indexOf(queryLower, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: baseStyle));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: baseStyle.copyWith(
          backgroundColor: Colors.yellow.withOpacity(0.5),
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _showRecordDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.patientEmail,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            record.date,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailSection('Diagnosis', record.diagnosis, Icons.medical_services, Colors.red),
                const SizedBox(height: 16),
                _buildDetailSection('Prescription', record.prescription, Icons.medication, Colors.green),
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailSection('Notes', record.notes!, Icons.notes, Colors.orange),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Text(content),
        ),
      ],
    );
  }
}
