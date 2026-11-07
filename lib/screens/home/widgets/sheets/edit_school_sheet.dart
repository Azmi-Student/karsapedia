import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/school_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/auth_service.dart';

class EditSchoolSheet extends StatefulWidget {
  final UserModel user;
  final VoidCallback onSaved;

  const EditSchoolSheet({
    super.key,
    required this.user,
    required this.onSaved,
  });

  static void show(BuildContext context, {required UserModel user, required VoidCallback onSaved}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditSchoolSheet(user: user, onSaved: onSaved),
    );
  }

  @override
  State<EditSchoolSheet> createState() => _EditSchoolSheetState();
}

class _EditSchoolSheetState extends State<EditSchoolSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<SchoolModel> _results = [];
  bool _isSearching = false;
  bool _isSaving = false;
  Timer? _debounceTimer;
  String _activeQuery = '';

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    final query = val.trim();

    if (query.length < 3) {
      setState(() {
        _results = [];
        _isSearching = false;
        _activeQuery = query;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _activeQuery = query;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final schools = await AuthService.searchSchools(query);

      if (_activeQuery == query && mounted) {
        setState(() {
          _results = schools;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _handleSelectSchool(SchoolModel item) async {
    setState(() => _isSaving = true);
    final res = await AuthService.updateProfile(
      name: widget.user.name,
      username: widget.user.username,
      phoneNumber: widget.user.phoneNumber,
      schoolName: item.name,
      schoolNpsn: item.npsn,
    );
    setState(() => _isSaving = false);

    if (!mounted) return;
    Navigator.pop(context);

    if (res['success'] == true) {
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Asal sekolah diubah ke ${item.name}.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal mengubah sekolah.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pilih Asal Sekolah',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: AppTheme.inputDecoration(
              hintText: 'Ketik nama sekolah, kota, atau NPSN...',
              prefixIcon: Icons.search_rounded,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _debounceTimer?.cancel();
                        _searchController.clear();
                        setState(() {
                          _results = [];
                          _isSearching = false;
                          _activeQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 14),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_searchController.text.trim().isNotEmpty && _searchController.text.trim().length < 3)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Ketik minimal 3 karakter untuk mencari sekolah...',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            )
          else if (_results.isEmpty && _searchController.text.trim().length >= 3)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Sekolah tidak ditemukan. Coba kata kunci nama atau kota lain.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final item = _results[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.school_outlined, size: 18, color: AppTheme.textPrimary),
                    ),
                    title: Text(
                      item.schoolName ?? item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      item.location ?? (item.npsn != null ? 'NPSN: ${item.npsn}' : item.name),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    onTap: _isSaving ? null : () => _handleSelectSchool(item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

