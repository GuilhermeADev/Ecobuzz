import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecobuzz/screens/home/home_screen.dart'; 

// --- ★ ATUALIZADO: Importe a tela de Foto de Perfil ★ ---
import 'profile_pic_screen.dart';


class TransportScreen extends StatefulWidget {
  // Recebe os dados das DUAS telas anteriores
  final List<String> selectedMaterials;
  final String atuacaoAddress; // <-- ★ AQUI ESTÁ A VARIÁVEL ★
  final double? atuacaoLat;
  final double? atuacaoLng;
  final double? atuacaoRadius;

  const TransportScreen({
    super.key,
    required this.selectedMaterials,
    required this.atuacaoAddress, // <-- ★ ELA PRECISA ESTAR AQUI ★
    this.atuacaoLat,
    this.atuacaoLng,
    this.atuacaoRadius,
  });

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  String? _selectedTransport;
  bool _isLoading = false;

  final List<String> _allTransports = [
    'Triciclo elétrico', 'Moto', 'Carroça', 'Sacola', 'Caminhonete',
    'Carro', 'Caminhão', 'Kombi', 'Bicicleta', 'Van'
  ];

  Future<void> _saveDataAndNavigate() async {
    if (_selectedTransport == null) return;

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Usuário não está logado.");
      }

      // --- ★ ATUALIZADO: Salva todos os dados do catador ★ ---
      final Map<String, dynamic> dataToSave = {
        'collectedMaterials': widget.selectedMaterials, // Da tela de Materiais
        'atuacaoAddress': widget.atuacaoAddress,       // Da tela de Endereço
        'transportMode': _selectedTransport,         // Desta tela
      };
      // Inclui localização/raio se fornecidos
      if (widget.atuacaoLat != null && widget.atuacaoLng != null) {
        dataToSave['atuacaoLocation'] = {
          'lat': widget.atuacaoLat,
          'lng': widget.atuacaoLng,
          'radius': widget.atuacaoRadius ?? 0,
        };
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        dataToSave,
        SetOptions(merge: true), // Merge para não apagar 'role', 'cpf', etc.
      );

      if (mounted) {
        // --- ★ ATUALIZADO: Navega para a tela de Foto, não para a Home ★ ---
        // Usamos pushAndRemoveUntil para que o usuário não possa "voltar"
        // para as telas de onboarding (CPF, Endereço, etc.)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ProfilePicScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar dados: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
       if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color corFundo = Color(0xFF0A3C32);
    const Color corChipSelecionado = Colors.orange;
    const Color corChipNormal = Colors.white24;
    const Color corTextoBotao = Colors.grey;

    return Scaffold(
      backgroundColor: corFundo,
      body: SafeArea(
        child: SingleChildScrollView( // Adicionado para evitar overflow
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/ecobuzz_logo.png',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.recycling, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 60), // Ajustado de Spacer
                const Text(
                  'E onde você carrega\no que coleta?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: _allTransports.map((transport) {
                    final bool isSelected = _selectedTransport == transport;
                    return ChoiceChip(
                      label: Text(transport),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold
                      ),
                      selected: isSelected,
                      backgroundColor: corChipNormal,
                      selectedColor: corChipSelecionado,
                      showCheckmark: false,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedTransport = transport;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 60), // Ajustado de Spacer

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: corTextoBotao),
                      onPressed: _isLoading ? null : () {
                        Navigator.of(context).pop();
                      },
                    ),
                    if (_isLoading)
                       const Padding(
                         padding: EdgeInsets.all(8.0),
                         child: CircularProgressIndicator(color: Colors.white),
                       )
                    else
                      IconButton(
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color: _selectedTransport != null ? Colors.white : corTextoBotao,
                        ),
                        onPressed: _selectedTransport == null ? null : _saveDataAndNavigate,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

