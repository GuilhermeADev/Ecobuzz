import 'package:ecobuzz/widgets/collection_card.dart';
import 'package:ecobuzz/widgets/user_profile_avatar.dart'; // Importa o widget do avatar
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para pegar o usuário
import 'package:cloud_firestore/cloud_firestore.dart'; // Para buscar dados

// --- ★ CORREÇÃO AQUI ★ ---
// Modelo atualizado para corresponder EXATAMENTE ao seu Firestore
class PickupModel {
  final String id;
  final String solicitanteNome;
  final String endereco;
  final Timestamp dataHora;
  final String status;
  final String? observacoes; // Opcional
  final String? telefone1;   // Opcional
  final List<String>? tags; // Opcional - tags atribuídas à coleta
  // 'telefone2' foi removido, pois não existe na sua estrutura

  PickupModel({
    required this.id,
    required this.solicitanteNome,
    required this.endereco,
    required this.dataHora,
    required this.status,
    this.observacoes,
    this.telefone1,
    this.tags,
  });

  factory PickupModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PickupModel(
      id: doc.id,
      solicitanteNome: data['solicitanteNome'] ?? 'Nome não informado',
      endereco: data['endereco'] ?? 'Endereço não informado',
      dataHora: data['dataHora'] ?? Timestamp.now(),
      status: data['status'] ?? 'desconhecido',
      observacoes: data['observacoes'], // Lê 'observacoes' (pode ser null)
      telefone1: data['phone1'],       // Lê 'phone1' (pode ser null)
      tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      // 'phone2' removido
    );
  }

  // --- ★ CORREÇÃO AQUI ★ ---
  // Converte para o formato Map<String, dynamic> esperado pelo CollectionCard,
  // tratando os valores nulos com segurança.
  Map<String, dynamic> toCardData() {
    final Map<String, dynamic> data = {
      'id': id,
      'requesterName': solicitanteNome,
      'address': endereco,
      'time': DateFormat('HH:mm').format(dataHora.toDate()),
      'status': status.isNotEmpty
          ? status[0].toUpperCase() + status.substring(1)
          : 'Desconhecido', // Capitaliza status
    };

    // Adiciona os campos opcionais APENAS se eles não forem nulos/vazios
    if (observacoes != null && observacoes!.isNotEmpty) {
      data['observation'] = observacoes!;
    }
    if (telefone1 != null && telefone1!.isNotEmpty) {
      data['phone1'] = telefone1!;
    }
    if (tags != null && tags!.isNotEmpty) {
      data['tags'] = tags;
    }
    // 'phone2' removido

    return data;
  }
}

class AgendaView extends StatefulWidget {
  const AgendaView({super.key});

  @override
  State<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
  DateTime _selectedDate = DateTime.now(); // Usa a data atual
  final User? currentUser = FirebaseAuth.instance.currentUser; // Pega o usuário logado
  String? _role;
  // Filtros ativos (representam tags a exibir). Se vazio => exibe todas
  final Set<String> _activeTagFilters = <String>{};

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("Erro: Usuário não está logado."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(currentUser!.uid),
              const SizedBox(height: 24),
              _buildDateSelector(),
              const SizedBox(height: 24),
              _buildFilterChips(),
              const SizedBox(height: 16),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // while we fetch role, show a loader in place of the list
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData && snapshot.data!.exists) {
                    _role = (snapshot.data!.data() as Map<String, dynamic>?)?['role'] as String?;
                  }
                  return _buildCollectionListStream(currentUser!.uid, role: _role);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CABEÇALHO (Busca nome e foto) ---
  Widget _buildHeader(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String userName = "Usuário"; // Nome padrão
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          userName = data['name'] ?? "Usuário"; // Pega o nome do Firestore
        }

        return Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: Column(
            children: [
              UserProfileAvatar(radius: 40), // Usa o widget que busca a foto
              const SizedBox(height: 12),
              Text(
                'Oie, ${userName.split(' ')[0]}', // Mostra só o primeiro nome
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Veja suas coletas agendadas',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- SELETOR DE DATA ---
  Widget _buildDateSelector() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () {
                  setState(() => _selectedDate =
                      _selectedDate.subtract(const Duration(days: 1)));
                },
              ),
              Text(
                _formatDateHeader(_selectedDate),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 20),
                onPressed: () {
                  setState(() => _selectedDate =
                      _selectedDate.add(const Duration(days: 1)));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 65,
          child: Center(
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = _selectedDate.add(Duration(days: index - 3));
                final isSelected = DateUtils.isSameDay(date, _selectedDate);
                return _buildDateCard(date, isSelected);
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now)) {
      return 'Hoje, ${DateFormat('d \'de\' MMMM', 'pt_BR').format(date)}';
    } else if (DateUtils.isSameDay(date, now.add(const Duration(days: 1)))) {
      return 'Amanhã, ${DateFormat('d \'de\' MMMM', 'pt_BR').format(date)}';
    } else if (DateUtils.isSameDay(
        date, now.subtract(const Duration(days: 1)))) {
      return 'Ontem, ${DateFormat('d \'de\' MMMM', 'pt_BR').format(date)}';
    } else {
      return DateFormat('d \'de\' MMMM', 'pt_BR').format(date);
    }
  }

  Widget _buildDateCard(DateTime date, bool isSelected) {
    const Color activeColor = Colors.deepOrange;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = date);
      },
      child: Container(
        width: 50,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: activeColor.withOpacity(0.5),
                      blurRadius: 5,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              DateFormat('E', 'pt_BR').format(date).toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FILTROS ---
  Widget _buildFilterChips() {
    const Color chipColor = Colors.deepOrange;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Agendadas'),
            selected: _activeTagFilters.contains('agendada'),
            onSelected: (v) => setState(() {
              if (v) _activeTagFilters.add('agendada'); else _activeTagFilters.remove('agendada');
            }),
            selectedColor: chipColor.withOpacity(0.18),
            backgroundColor: chipColor.withOpacity(0.06),
            labelStyle: TextStyle(color: Colors.deepOrange.shade900),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Atrasadas'),
            selected: _activeTagFilters.contains('atrasada'),
            onSelected: (v) => setState(() {
              if (v) _activeTagFilters.add('atrasada'); else _activeTagFilters.remove('atrasada');
            }),
            selectedColor: chipColor.withOpacity(0.18),
            backgroundColor: chipColor.withOpacity(0.06),
            labelStyle: TextStyle(color: Colors.deepOrange.shade900),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Confirmadas'),
            selected: _activeTagFilters.contains('confirmado'),
            onSelected: (v) => setState(() {
              if (v) _activeTagFilters.add('confirmado'); else _activeTagFilters.remove('confirmado');
            }),
            selectedColor: chipColor.withOpacity(0.18),
            backgroundColor: chipColor.withOpacity(0.06),
            labelStyle: TextStyle(color: Colors.deepOrange.shade900),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () { /* Ação de filtrar - já ativo via chips */},
          )
        ],
      ),
    );
  }

  // --- LISTA DE COLETAS (Lógica "Sem Índice") ---
  Widget _buildCollectionListStream(String userId, {String? role}) {
    // Build a query depending on the user's role:
    // - catador: show pickups where catadorId == userId (assigned to them)
    // - cidadao: show pickups where createdBy == userId (their requests)
    Query pickupsQuery = FirebaseFirestore.instance.collection('pickups');
    if (role == 'catador') {
      pickupsQuery = pickupsQuery.where('catadorId', isEqualTo: userId);
    } else {
      // default and for 'cidadao' show only requests created by this user
      pickupsQuery = pickupsQuery.where('createdBy', isEqualTo: userId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: pickupsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print("Erro ao buscar coletas: ${snapshot.error}");
          return const Center(child: Text('Erro ao carregar coletas.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 50.0),
              // Mensagem genérica, pois não filtramos por data ainda
              child: Text('Nenhuma coleta encontrada para seu usuário.'),
            ),
          );
        }

        // 2. Filtramos a data AQUI, no Dart, e também aplicamos filtros por tags
        final pickups = snapshot.data!.docs
            .map((doc) => PickupModel.fromFirestore(doc))
            // Filtra por data escolhida
            .where((pickup) => DateUtils.isSameDay(pickup.dataHora.toDate(), _selectedDate))
            .where((pickup) {
              // Se não houver filtros ativos, mostra tudo
              if (_activeTagFilters.isEmpty) return true;
              final List<String> pickupTags = pickup.tags ?? [];
              // Calcular tags dinâmicas se documento não tem tags
              if (pickupTags.isEmpty) {
                final List<String> dynamicTags = [];
                final now = DateTime.now();
                if (pickup.dataHora.toDate().isBefore(now) && pickup.status.toLowerCase() != 'concluido') {
                  dynamicTags.add('atrasada');
                }
                // Intersect
                return dynamicTags.any((t) => _activeTagFilters.contains(t));
              }
              return pickupTags.any((t) => _activeTagFilters.contains(t));
            })
            .toList();

        // 3. Se a lista filtrada estiver vazia
        if (pickups.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 50.0),
              child: Text('Nenhuma coleta agendada para este dia.'),
            ),
          );
        }

        // Ordena por hora
        pickups.sort((a, b) => a.dataHora.compareTo(b.dataHora));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: pickups
                .map((pickup) =>
                    CollectionCard(collectionData: pickup.toCardData()))
                .toList(),
          ),
        );
      },
    );
  }
}

