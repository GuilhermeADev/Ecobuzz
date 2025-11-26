import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importe suas telas
import '../../utils/app_colors.dart'; // Mantenha seus imports de cores
import '../home/home_screen.dart';
// --- ★ NOVO: Importe a tela de Materiais ★ ---
import 'materials_screen.dart'; 

class CpfScreen extends StatefulWidget {
  // Recebe a data de nascimento da tela anterior
  final DateTime birthdate;

  const CpfScreen({super.key, required this.birthdate});

  @override
  State<CpfScreen> createState() => _CpfScreenState();
}

class _CpfScreenState extends State<CpfScreen> {
  final _cpfController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _cpfFormatter = MaskTextInputFormatter(
      mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});

  // --- ★ FUNÇÃO DE VALIDAÇÃO DE CPF ★ ---
  bool _isValidCpf(String cpf) {
    // 1. Remove formatação (pontos e traço)
    String numbers = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    // 2. Verifica se tem 11 dígitos
    if (numbers.length != 11) return false;

    // 3. Verifica se todos os dígitos são iguais (ex: 111.111.111-11)
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) return false;

    // 4. Converte para lista de inteiros
    List<int> digits = numbers.split('').map(int.parse).toList();

    // 5. Calcula o primeiro dígito verificador (dv1)
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += digits[i] * (10 - i);
    }
    int dv1 = (sum * 10) % 11;
    if (dv1 == 10) dv1 = 0;

    // 6. Verifica o primeiro dígito
    if (digits[9] != dv1) return false;

    // 7. Calcula o segundo dígito verificador (dv2)
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += digits[i] * (11 - i);
    }
    int dv2 = (sum * 10) % 11;
    if (dv2 == 10) dv2 = 0;

    // 8. Verifica o segundo dígito
    if (digits[10] != dv2) return false;

    // Se passou em tudo, é válido
    return true;
  }

  // --- ★ ATUALIZADO: Função de Salvar e NAVEGAÇÃO CONDICIONAL ★ ---
  Future<void> _saveDataAndContinue() async {
    // A validação agora checa o validator do TextFormField
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Usuário não encontrado. Faça login novamente.");
      }

      final cpf = _cpfController.text;
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // 1. Salva os dados de CPF e Data de Nasc.
      await userRef.set(
          {
            'birthdate': Timestamp.fromDate(widget.birthdate),
            'cpf': cpf,
          },
          SetOptions(merge: true));

      // 2. Lê o documento de volta para descobrir o 'role'
      final userDoc = await userRef.get();
      final userRole = userDoc.data()?['role'];

      // --- ★ NOVO PRINT DE DEBUG ★ ---
      // Verifique seu console/terminal para ver o que aparece aqui
      print("DEBUG: O perfil (role) do usuário é: '$userRole'");
      // --------------------------------

      // 3. Navegação Condicional
      if (mounted) {
        if (userRole == 'comprador') {
          // Se for CATADOR, vai para a tela de materiais
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MaterialsScreen()),
          );
        } else {
          // Se for CIDADAO ou COMPRADOR, vai para a Home
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar dados: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkGreenBackground = Color(0xFF0A3C30); 

    return Scaffold(
      backgroundColor: darkGreenBackground,
      body: SafeArea(
        // Adicionado SingleChildScrollView para evitar overflow do teclado
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                // Logo
                Image.asset(
                  'assets/ecobuzz_logo.png', // Substitua pelo caminho do seu logo
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.recycling, color: Colors.white, size: 40),
                ),
                // Ajustado Spacer para SizedBox
                SizedBox(height: MediaQuery.of(context).size.height * 0.2), 
                // Título
                const Text(
                  'Agora, seu CPF:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Campo de CPF
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _cpfController,
                    inputFormatters: [_cpfFormatter],
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'XXX.XXX.XXX-XX',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      // Bordas de Erro
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.redAccent, width: 2),
                      ),
                      errorStyle: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                    ),
                    textAlign: TextAlign.center,
                    // Validator atualizado
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, preencha o CPF.';
                      }
                      if (value.length != 14) {
                        return 'CPF incompleto.';
                      }
                      if (!_isValidCpf(value)) {
                        return 'CPF inválido.';
                      }
                      return null; // Válido!
                    },
                  ),
                ),
                // Ajustado Spacer para SizedBox
                SizedBox(height: MediaQuery.of(context).size.height * 0.2), 
                // Botões de Navegação
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Botão Voltar
        IconButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        // Botão Avançar (agora é o "Confirmar")
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(color: Colors.white),
          )
        else
          IconButton(
            onPressed: _saveDataAndContinue,
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ),
      ],
    );
  }
}


