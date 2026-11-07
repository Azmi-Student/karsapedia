import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/school_model.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _schoolController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  String? _selectedNpsn;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isLoading = false;
  String? _errorMessage;

  // State untuk Live Autocomplete Sekolah
  Timer? _debounce;
  List<SchoolModel> _schoolSuggestions = [];
  bool _isSearchingSchools = false;
  bool _showSchoolDropdown = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSchoolChanged(String query) {
    _selectedNpsn = null; // Reset NPSN jika diedit manual
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final term = query.trim();
    if (term.length < 3) {
      setState(() {
        _schoolSuggestions = [];
        _showSchoolDropdown = false;
        _isSearchingSchools = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() {
        _isSearchingSchools = true;
        _showSchoolDropdown = true;
      });

      final results = await AuthService.searchSchools(term);

      if (!mounted) return;

      setState(() {
        _schoolSuggestions = results;
        _isSearchingSchools = false;
      });
    });
  }

  void _selectSchool(SchoolModel school) {
    setState(() {
      _schoolController.text = school.name;
      _selectedNpsn = school.npsn;
      _showSchoolDropdown = false;
      _schoolSuggestions = [];
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showSchoolDropdown = false;
    });

    final result = await AuthService.register(
      name: _nameController.text,
      username: _usernameController.text.isNotEmpty ? _usernameController.text : null,
      email: _emailController.text,
      password: _passwordController.text,
      passwordConfirmation: _passwordConfirmationController.text,
      schoolName: _schoolController.text.isNotEmpty ? _schoolController.text : null,
      schoolNpsn: _selectedNpsn,
      phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen(user: result['user'])),
        (route) => false,
      );
    } else {
      setState(() {
        _errorMessage = result['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pendaftaran Akun'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Daftar Akun Baru',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Lengkapi formulir di bawah ini untuk mulai mengakses platform pembelajaran Karsapedia.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bento Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFECDD3)),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Field Nama Lengkap
                          const Text(
                            'NAMA LENGKAP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Budi Santoso',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nama lengkap wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Field Username
                          const Text(
                            'USERNAME (OPSIONAL)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: 'Contoh: budisantoso (tanpa spasi)',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Field Email
                          const Text(
                            'EMAIL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: 'nama@karsapedia.test',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Email wajib diisi';
                              }
                              if (!val.contains('@')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Field Asal Sekolah (dengan Live Autocomplete)
                          const Text(
                            'ASAL SEKOLAH',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _schoolController,
                            onChanged: _onSchoolChanged,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Contoh: SMKN 1 Surabaya',
                              suffixIcon: _isSearchingSchools
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : null,
                            ),
                          ),

                          // Dropdown Rekomendasi Sekolah
                          if (_showSchoolDropdown) ...[
                            const SizedBox(height: 6),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _schoolSuggestions.isEmpty && !_isSearchingSchools
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        'Sekolah tidak ditemukan dalam database. Nama ini akan disimpan sebagai sekolah baru saat mendaftar.',
                                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      itemCount: _schoolSuggestions.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      itemBuilder: (context, index) {
                                        final item = _schoolSuggestions[index];
                                        return InkWell(
                                          onTap: () => _selectSchool(item),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.schoolName ?? item.name,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                if (item.location != null && item.location!.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    item.location!,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Field Nomor Telepon
                          const Text(
                            'NOMOR TELEPON (OPSIONAL)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: '081234567890',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Field Kata Sandi
                          const Text(
                            'KATA SANDI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Minimal 8 karakter',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 18,
                                  color: AppTheme.textMuted,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.length < 8) {
                                return 'Kata sandi minimal 8 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Field Konfirmasi Kata Sandi
                          const Text(
                            'KONFIRMASI KATA SANDI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordConfirmationController,
                            obscureText: _obscureConfirmation,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Ulangi kata sandi',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmation ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 18,
                                  color: AppTheme.textMuted,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmation = !_obscureConfirmation;
                                  });
                                },
                              ),
                            ),
                            validator: (val) {
                              if (val != _passwordController.text) {
                                return 'Konfirmasi kata sandi tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Tombol Daftar
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Daftar'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Link Kembali ke Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah memiliki akun? ',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

