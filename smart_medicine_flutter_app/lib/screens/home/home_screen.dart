import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../services/medicine_service.dart';
import '../../widgets/medicine_card.dart';
import '../pharmacy/pharmacy_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MedicineService _medicineService = MedicineService();
  final TextEditingController _searchController = TextEditingController();

  List<MedicineSearchResult> _results = [];
  bool _isLoading = false;
  bool _isMapView = false;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Antibiotics',
    'Pain Relief',
    'Diabetes',
    'Cardiac',
    'Vitamins',
  ];

  @override
  void initState() {
    super.initState();
    _triggerSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _medicineService.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    _medicineService.debouncedSearch(
      query: _searchController.text,
      category: _selectedCategory,
      onResults: (res) {
        if (mounted) setState(() => _results = res);
      },
      onLoading: (loading) {
        if (mounted) setState(() => _isLoading = loading);
      },
    );
  }

  void _seedSampleData() async {
    setState(() => _isLoading = true);
    await _medicineService.seedSampleMedicineDatabase();
    _triggerSearch();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sample development medicines & inventory populated in Firestore!'),
        backgroundColor: AppColors.inStock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              AppStrings.appName,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.view_list_rounded : Icons.map_rounded),
            tooltip: _isMapView ? 'Switch to List' : 'View on Map',
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'My Prescriptions',
            onPressed: () => Navigator.pushNamed(context, '/prescription-orders'),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Seed Sample Data (Dev)',
            onPressed: _seedSampleData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top greeting banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${user?.displayName.isNotEmpty == true ? user!.displayName : "Patient"}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Search over verified neighborhood pharmacies for live availability.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search Bar with debouncing
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _triggerSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search by medicine or generic name (e.g. Amox)...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _triggerSearch();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Doctor's Prescription Upload Banner
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/upload-prescription'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Have a Doctor's Prescription?",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Upload photo • Check stock at chosen store • Chat live",
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ),

            // Horizontal Categories Scroll
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                      _triggerSearch();
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  );
                },
              ),
            ),

            // Results Header with List / Map View Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_results.length} medicines found',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                  InkWell(
                    onTap: () => setState(() => _isMapView = !_isMapView),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isMapView ? AppColors.primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _isMapView ? AppColors.primary : AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isMapView ? Icons.view_list_rounded : Icons.map_rounded,
                            size: 14,
                            color: _isMapView ? AppColors.primaryDark : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isMapView ? 'Show List' : 'Show Map',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isMapView ? AppColors.primaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results View: Either Google Map or List View
            Expanded(
              child: _isMapView
                  ? PharmacyMapScreen(
                      searchResults: _results,
                      onToggleView: () => setState(() => _isMapView = false),
                    )
                  : _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : _results.isEmpty
                          ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.medication_outlined, size: 56, color: Colors.slate.shade300),
                              const SizedBox(height: 12),
                              const Text(
                                'No medicines found',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Try another search term or click cloud button above to seed sample data.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            return MedicineCard(
                              item: item,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/medicine-details',
                                  arguments: item,
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
