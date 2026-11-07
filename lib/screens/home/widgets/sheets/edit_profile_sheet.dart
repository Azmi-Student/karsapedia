import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/user_model.dart';
import '../../../../services/auth_service.dart';

class EditProfileSheet extends StatefulWidget {
  final UserModel user;
  final VoidCallback onSaved;

  const EditProfileSheet({
    super.key,
    required this.user,
    required this.onSaved,
  });

  static void show(BuildContext context, {required UserModel user, required VoidCallback onSaved}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(user: user, onSaved: onSaved),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(text: widget.user.username ?? '');
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final res = await AuthService.updateProfile(
      name: newName,
      username: _usernameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      schoolName: widget.user.school?.name,
      schoolNpsn: widget.user.school?.npsn,
    );
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    Navigator.pop(context);

    if (res['success'] == true) {
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biodata diri berhasil diperbarui.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal memperbarui biodata.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                'Edit Biodata Diri',
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: AppTheme.inputDecoration(
              labelText: 'Nama Lengkap',
              hintText: 'Masukkan nama lengkap Anda',
              prefixIcon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _usernameController,
            decoration: AppTheme.inputDecoration(
              labelText: 'Username',
              hintText: 'Masukkan username unik',
              prefixIcon: Icons.alternate_email_rounded,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: AppTheme.inputDecoration(
              labelText: 'Nomor WhatsApp / HP',
              hintText: 'Contoh: 08123456789',
              prefixIcon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSave,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }
}

