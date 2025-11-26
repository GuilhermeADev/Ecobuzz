import 'package:flutter/material.dart';

// --- IMPORTAÇÕES DO FIREBASE ---
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Gerado pelo FlutterFire

// --- IMPORT PARA FORMATAÇÃO DE DATAS ---
// V ESTA LINHA ESTAVA FALTANDO V
import 'package:intl/date_symbol_data_local.dart'; 

// --- SUAS IMPORTAÇÕES DE TELA ---
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart'; 
import 'screens/auth/phone_verify_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/start_screen.dart';
import 'screens/onboarding/profile_selection_screen.dart';
import 'screens/onboarding/profile_pic_screen.dart';
import 'utils/app_colors.dart'; 
import 'screens/home/home_screen.dart';

// A função main() precisa ser 'async' para usar 'await'
void main() async { 


  // 1. Garante que o Flutter esteja pronto
  WidgetsFlutterBinding.ensureInitialized();
  
    // 2. Inicializa o Firebase (espera a conclusão)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  

  // 3. Inicializa a formatação de data em Português (espera a conclusão)
  // Esta linha agora funciona por causa do import que adicionei
  await initializeDateFormatting('pt_BR', null);
  
  // 4. Roda o aplicativo
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ecobuzz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Você pode definir seu tema global aqui
        scaffoldBackgroundColor: AppColors.offWhite, 
        primaryColor: Colors.green, // Exemplo
        // ...
      ),
      // Define a rota inicial
      initialRoute: '/', 
      
      // Define todas as rotas nomeadas do seu aplicativo
      routes: {
        '/': (context) => const StartScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/phone_verify': (context) => const PhoneVerifyScreen(),
        '/otp': (context) => const OTPScreen(),
        '/profile_selection': (context) => const ProfileSelectionScreen(),
        '/home': (context) => const HomeScreen(),
        // '/home': (context) => const HomeScreen(), // Adicione sua home aqui
      },
    );
  }
}
