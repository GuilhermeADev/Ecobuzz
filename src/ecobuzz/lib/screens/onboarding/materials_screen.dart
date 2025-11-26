// --- ★ ATUALIZADO: Importe a tela de Endereço ★ ---
import 'address_screen.dart';
import 'package:flutter/material.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  // Usamos um Set para garantir que não haja duplicatas
  final Set<String> _selectedMaterials = {};

  // Lista de todos os materiais
  final List<String> _allMaterials = [
    'Plástico', 'Alumínio', 'Papelão', 'Vidro', 'Papel', 'PET',
    'Óleo de Cozinha', 'Ferro', 'Latinha', 'Móveis', 'Eletrônicos',
    'Baterias', 'Metal', 'Outros'
  ];

  @override
  Widget build(BuildContext context) {
    const Color corFundo = Color(0xFF0A3C32); // Verde escuro do mockup
    const Color corChipSelecionado = Colors.orange;
    const Color corChipNormal = Colors.white24;
    const Color corTextoBotao = Colors.grey;

    return Scaffold(
      backgroundColor: corFundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/ecobuzz_logo.png', // Substitua pelo caminho do seu logo
                height: 40,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.recycling, color: Colors.white, size: 40),
              ),
              const Spacer(),
              const Text(
                'Qual tipo de material\nvocê recolhe?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              
              // Wrap para os chips
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12.0, // Espaço horizontal
                runSpacing: 12.0, // Espaço vertical
                children: _allMaterials.map((material) {
                  final bool isSelected = _selectedMaterials.contains(material);
                  return ChoiceChip(
                    label: Text(material),
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
                          _selectedMaterials.add(material);
                        } else {
                          _selectedMaterials.remove(material);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              
              const Spacer(flex: 2),

              // Botões de Navegação
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: corTextoBotao),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: _selectedMaterials.isNotEmpty ? Colors.white : corTextoBotao,
                    ),
                    onPressed: _selectedMaterials.isEmpty
                        ? null // Desabilitado se nada for selecionado
                        : () {
                            // --- ★ CORREÇÃO AQUI ★ ---
                            // Navega para a TELA DE ENDEREÇO, não a de transporte
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddressScreen(
                                  // Passa os materiais selecionados
                                  selectedMaterials: _selectedMaterials.toList(),
                                ),
                              ),
                            );
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

