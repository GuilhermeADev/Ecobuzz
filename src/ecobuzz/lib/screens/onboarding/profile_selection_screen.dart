import 'package:flutter/material.dart';
import 'dart:math';
// import '../../utils/app_colors.dart'; // Mantenha o seu import original
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- ★ Importe a tela de data de nascimento ★ ---
import 'package:ecobuzz/screens/onboarding/birthdate_screen.dart';


class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  late PageController _pageController;
  int _currentPage = 1;
  bool _isLoading = false; // Estado de carregamento

  // Lista de perfis (sem alteração)
  final List<Map<String, String>> _profileData = [
    {
      'image': 'assets/trabalhador.png',
      'label': 'Trabalha com reciclagem',
      'role': 'catador', // Papel no DB
    },
    {
      'image': 'assets/descarte.png',
      'label': 'Quer descartar corretamente',
      'role': 'cidadao', // Papel no DB
    },
    {
      'image': 'assets/comprador.png',
      'label': 'Compra materiais recicláveis',
      'role': 'comprador', // Papel no DB
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.7,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- FUNÇÃO DE SALVAR O PERFIL (COM ALTERAÇÃO NA NAVEGAÇÃO E NOME) ---
  Future<void> _confirmProfile() async {
    if (_isLoading) return; // Evita cliques duplos

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Pegar o usuário logado
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Nenhum usuário logado. Faça o login novamente.");
      }

      // 2. Pegar o papel (role) selecionado
      final selectedRole = _profileData[_currentPage]['role']!;

      // --- ★ NOVO: Pega o nome do perfil do Auth ★ ---
      final displayName = user.displayName;
      // ---------------------------------------------

      // 3. Salvar no Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'role': selectedRole,
          'uid': user.uid,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          // --- ★ NOVO: Inclui o nome se ele existir ★ ---
          if (displayName != null && displayName.isNotEmpty) 'name': displayName,
          // ------------------------------------------
        },
        SetOptions(merge: true), // 'merge: true' atualiza sem apagar outros dados
      );

      // 4. Mostrar sucesso e navegar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // A navegação está correta
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BirthdateScreen()), // Removido 'const'
        );
      }
    } catch (e) {
      // 5. Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar perfil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 6. Parar o loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Substitua pelas suas cores!
    const AppColors_preto = Colors.black;
    const AppColors_laranja = Colors.orange;
    const AppColors_verde = Colors.green;
    const AppColors_verdeClaro = Colors.lightGreen;
    // ---

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/Fundo_cadastro_sem_logo.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Bem vindo ao Ecobuzz.',
                  style: TextStyle(
                    color: AppColors_preto,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Conta pra gente, você...',
                  style: TextStyle(
                    color: AppColors_preto,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _profileData.length,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, index) {
                      double scale = max(0.85, 1 - (_currentPage - index).abs() * 0.15);
                      return Transform.scale(
                        scale: scale,
                        child: _buildProfileCard(
                          imagePath: _profileData[index]['image']!,
                          isSelected: index == _currentPage,
                          // --- Passei as cores para o método ---
                          appColorsVerde: AppColors_verde,
                          appColorsVerdeClaro: AppColors_verdeClaro,
                        ),
                      );
                    },
                  ),
                ),
                // Navegação por setas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors_preto),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    const SizedBox(width: 40),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: AppColors_preto),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Botão de confirmação
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirmProfile, // Chama a nova função
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors_laranja,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder( // Corrigido erro de digitação aqui
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Confirmar',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required String imagePath,
    required bool isSelected,
    // --- Cores recebidas como parâmetro ---
    required Color appColorsVerde,
    required Color appColorsVerdeClaro,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? appColorsVerde : Colors.grey.shade300,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  height: 250,
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(
                        height: 250,
                        child: Center(child: Icon(Icons.person, size: 80, color: appColorsVerdeClaro)));
                  },
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? appColorsVerde : Colors.white,
                    border: Border.all(color: appColorsVerde, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

