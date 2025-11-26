import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:ecobuzz/screens/home/create_pickup_screen.dart'; // Mantida a dependência
// firebase_auth not needed in this screen after moving chat/report features

// Importação da tela de agendamento (Assumimos que existe no seu projeto)
import 'package:ecobuzz/screens/home/create_pickup_screen.dart';

// Cor Primária (Verde Escuro): #0E423E
const Color _primaryColor = Color(0xFF0E423E);
// Cor de fundo levemente esbranquiçada para o Scaffold
const Color _backgroundColor = Color(0xFFF7F7F7);
// Cor para os chips (seus botões)
const Color _chipColor = _primaryColor;

class CollectorProfileScreen extends StatelessWidget {
  final String userId;
  const CollectorProfileScreen({super.key, required this.userId});

  // Função auxiliar para criar os chips de material (Papelão, Latinha, PET)
  Widget _buildMaterialChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _chipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      // Utilizamos o AppBar para o botão de voltar e o título
      appBar: AppBar(
        title: const Text(
          'Perfil do Catador',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Erro: ${snapshot.error}'));
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Center(child: Text('Catador não encontrado.'));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = (data['name'] ?? 'Sem nome') as String;

            // Prioritize the actual Firestore field used in other parts of the app
            // Try 'collectedMaterials' (uses same name as collectors list), then
            // fallback to 'collectingMaterials' if present, and finally a default list.
            final List<String> collectingMaterials = (
                (data['collectedMaterials'] as List<dynamic>?) ??
                (data['collectingMaterials'] as List<dynamic>?) ??
                <dynamic>['Papelão', 'Latinha', 'PET'])
              .map((e) => e.toString())
              .toList();

          Widget avatar;
          if (data['photoBase64'] != null) {
            try {
              final bytes = base64Decode(data['photoBase64'] as String);
              avatar = CircleAvatar(
                radius: 44,
                backgroundImage: MemoryImage(bytes),
              );
            } catch (_) {
              avatar = const CircleAvatar(
                radius: 44,
                child: Icon(Icons.person, size: 40),
              );
            }
          } else if (data['photoURL'] != null) {
            avatar = CircleAvatar(
              radius: 44,
              backgroundImage: NetworkImage(data['photoURL'] as String),
            );
          } else {
            avatar = const CircleAvatar(
              radius: 44,
              child: Icon(Icons.person, size: 40),
            );
          }

          final location = data['atuacaoLocation'] as Map<String, dynamic>?;
          final availability = data['availability'] as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Seção de Perfil (Topo e Centralizada, inspirada no card)
                Center(
                  child: Column(
                    children: [
                      avatar,
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('reviews')
                                .get(),
                            builder: (context, rsnap) {
                              double avg = 0.0;
                              int count = 0;
                              if (rsnap.hasData && rsnap.data != null) {
                                for (final rd in rsnap.data!.docs) {
                                  final v = (rd.data() as Map<String, dynamic>)['rating'] as num?;
                                  if (v != null) {
                                    avg += v.toDouble();
                                    count++;
                                  }
                                }
                              }
                              final display = count > 0 ? (avg / count).toStringAsFixed(1) : '-';
                              return Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    display,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.amber,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      if (location != null)
                        Text(
                          '3.2 KM', // Distância mockada do card de preview
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Materiais de Coleta (Estilo Chips)
                const Text(
                  'Está coletando:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 8),
                if (collectingMaterials.isEmpty)
                  const Text('Não informado', style: TextStyle(color: Colors.grey)),
                if (collectingMaterials.isNotEmpty)
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: collectingMaterials
                        .map((m) => _buildMaterialChip(m))
                        .toList(),
                  ),
                const Divider(height: 48),

                // 3. Informações Adicionais (Área de Atuação e Disponibilidade)
                if (location != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Área de Atuação:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Endereço Central: ${data['atuacaoAddress'] ?? 'Não definido'}',
                        style: const TextStyle(fontSize: 15),
                      ),
                      Text(
                        'Raio de Coleta: ${((location['radius'] ?? 0) as num).toInt()} metros',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const Divider(height: 32),
                    ],
                  ),

                if (availability != null && availability.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Disponibilidade:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final entry in availability.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            '${entry.key}: ${(entry.value as List).map((r) => '${r['from']}-${r['to']}').join(', ')}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 32),

                // 4. Botões de Ação
                ElevatedButton(
                  onPressed: () {
                    // Mantém a lógica de navegação original
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreatePickupScreen(catadorId: userId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Agendar com este catador',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 24),
                // 6. Lista de Reviews (Preservada a lógica original)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('reviews')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting)
                      return const SizedBox();
                    final rdocs = snap.data?.docs ?? [];
                    if (rdocs.isEmpty)
                      return const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('Sem avaliações ainda.'),
                      );

                    double avg = 0.0;
                    for (final rd in rdocs) {
                      final v =
                          (rd.data() as Map<String, dynamic>)['rating']
                              as num? ??
                          0;
                      avg += v.toDouble();
                    }
                    avg = avg / rdocs.length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Avaliações de Clientes:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${avg.toStringAsFixed(1)} Média (${rdocs.length} avaliações)',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Listagem dos reviews
                        for (final rd in rdocs)
                          Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 1,
                            child: ListTile(
                              title: Row(
                                children: List.generate(5, (i) {
                                  final r =
                                      (rd.data()
                                              as Map<String, dynamic>)['rating']
                                          as num? ??
                                      0;
                                  return Icon(
                                    i < r ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                              ),
                              subtitle: Text(
                                (rd.data() as Map<String, dynamic>)['comment']
                                        as String? ??
                                    '',
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
