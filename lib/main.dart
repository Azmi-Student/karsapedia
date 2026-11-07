import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final token = await StorageService.getToken();
  final user = await StorageService.getUser();

  runApp(KarsapediaApp(
    initialUser: token != null && user != null ? user : null,
  ));
}

class KarsapediaApp extends StatelessWidget {
  final UserModel? initialUser;

  const KarsapediaApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karsapedia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialUser != null
          ? HomeScreen(user: initialUser!)
          : const LoginScreen(),
    );
  }
}
