import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
// --- ★ NOVO: Importe o Firestore ★ ---
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() => _isLoading = true);

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não coincidem.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Passo 1: Criar o usuário no Firebase Authentication
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        // Passo 2: Salvar o nome no perfil do Firebase Auth (útil para o próprio Firebase)
        await user.updateDisplayName(_nameController.text.trim());
        await user.reload(); // Recarrega para garantir

        // --- ★ NOVO: Passo 3: Salvar o nome no Firestore ★ ---
        // Cria ou atualiza o documento do usuário na coleção 'users'
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {
            'name': _nameController.text.trim(), // Adiciona o campo 'name'
            'email': user.email, // Salva o email também, boa prática
            'uid': user.uid,
            'createdAt': FieldValue.serverTimestamp(), // Data de criação/atualização
          },
          // Usa merge: true para não sobrescrever outros campos caso o doc já exista
          SetOptions(merge: true), 
        );
        // --- ★ FIM DO PASSO 3 ★ ---

      }

      if (mounted) {
        // Navega para a próxima tela do fluxo (verificação de telefone)
        Navigator.pushNamed(context, '/phone_verify');
      }

    } on FirebaseAuthException catch (e) {
      String message = 'Ocorreu um erro ao criar a conta.';
      if (e.code == 'weak-password') {
        message = 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Este e-mail já está cadastrado.';
      } else if (e.code == 'invalid-email') {
        message = 'O formato do e-mail é inválido.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) { // Captura outros erros genéricos (como erro ao salvar no Firestore)
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
     finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/Fundo_cadastro.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Criar nova conta',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.preto, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(controller: _nameController, decoration: buildInputDecoration('Nome completo', Icons.person_outline)),
                  const SizedBox(height: 16),
                  TextField(controller: _emailController, decoration: buildInputDecoration('E-mail', Icons.email_outlined), keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  TextField(controller: _passwordController, decoration: buildInputDecoration('Senha', Icons.lock_outline), obscureText: true),
                  const SizedBox(height: 16),
                  TextField(controller: _confirmPasswordController, decoration: buildInputDecoration('Confirmar Senha', Icons.lock_outline), obscureText: true),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: buildButtonStyle(),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : buildButtonChild(),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.preto, fontSize: 16),
                        children: [
                          const TextSpan(text: 'Já tem uma conta? '),
                          TextSpan(
                            text: 'Login',
                            style: const TextStyle(color: AppColors.laranja, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()..onTap = () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.preto),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.laranja, width: 2)),
    );
  }

  ButtonStyle buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.laranja,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget buildButtonChild() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text('Continue', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
        SizedBox(width: 8),
        Icon(Icons.arrow_forward, color: Colors.white),
      ],
    );
  }
}
