// lib/screens/auth/phone_verify_screen.dart
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../utils/app_colors.dart';

class PhoneVerifyScreen extends StatelessWidget {
  const PhoneVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.preto),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Voltar', style: TextStyle(color: AppColors.preto, fontSize: 16)),
      ),
        body: Container(
        width: double.infinity,
        height: double.infinity,
        // -----------------------------------------------------------------
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/Fundo_cadastro.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const SizedBox(height: 32),
            const Text('Bem vindo ao Ecobuzz.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.preto, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Insira seu número para continuar', textAlign: TextAlign.center, style: TextStyle(color: AppColors.preto, fontSize: 16)),
            const SizedBox(height: 32),
            
            // Campo de Telefone Internacional
            IntlPhoneField(
              initialCountryCode: 'BR',
              decoration: InputDecoration(
                labelText: 'Número de Telefone',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.laranja, width: 2)),
              ),
              onChanged: (phone) {
                print(phone.completeNumber);
              },
            ),
            const SizedBox(height: 24),

            // Botão
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/otp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.laranja,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Continue', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}