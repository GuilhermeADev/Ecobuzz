import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecobuzz/screens/home/collector_profile_screen.dart';
import 'package:ecobuzz/screens/home/assigned_pickups_screen.dart';

// Cores
const Color _primaryColor = Color(0xFF0E423E);
const Color _backgroundColor = Color(0xFFF7F7F7);
const Color _chipColor = Color(0xFF0E423E);

class CollectorsScreen extends StatefulWidget {
 const CollectorsScreen({super.key});

 @override
 State<CollectorsScreen> createState() => _CollectorsScreenState();
}

class _CollectorsScreenState extends State<CollectorsScreen> {
 final usersRef = FirebaseFirestore.instance.collection('users');

 // Favorites of current user (ids of collectors the requester favorited)
 Set<String> favs = {};

 @override
 void initState() {
  super.initState();
  _loadFavorites();
 }

 Future<void> _loadFavorites() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final doc = await usersRef.doc(user.uid).get();
  final arr = (doc.data()?['favorites'] as List<dynamic>?)?.map((e) => e.toString()).toList();
  if (arr != null) setState(() => favs = arr.toSet());
 }

 Future<void> _toggleFavorite(String collectorId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final myRef = usersRef.doc(user.uid);
  try {
   if (favs.contains(collectorId)) {
    await myRef.update({'favorites': FieldValue.arrayRemove([collectorId])});
    setState(() => favs.remove(collectorId));
   } else {
    await myRef.update({'favorites': FieldValue.arrayUnion([collectorId])});
    setState(() => favs.add(collectorId));
   }
  } catch (e) {
   if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao favoritar: ${e.toString()}')));
  }
 }

 // Filters
 final Set<String> _selectedMaterials = <String>{};
 bool _useMyArea = false;
 double _maxDistanceMeters = 5000; // default 5km
 double? _myLat;
 double? _myLng;

 // Haversine distance in meters
 double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000; // meters
  final phi1 = lat1 * (pi / 180.0);
  final phi2 = lat2 * (pi / 180.0);
  final dphi = (lat2 - lat1) * (pi / 180.0);
  final dlambda = (lon2 - lon1) * (pi / 180.0);
  final a = (sin(dphi/2) * sin(dphi/2)) + cos(phi1)*cos(phi2)*(sin(dlambda/2)*sin(dlambda/2));
  final c = 2 * atan2(sqrt(a), sqrt(1-a));
  return R * c;
 }

 void _openFilterSheet(List<String> allMaterials) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final materials = allMaterials;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filtrar Catadores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Materiais'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: materials.map((m) {
                        final selected = _selectedMaterials.contains(m);
                        return FilterChip(
                          label: Text(m),
                          selected: selected,
                          onSelected: (v) {
                            setModalState(() {
                              setState(() {
                                if (selected) {
                                  _selectedMaterials.remove(m);
                                } else {
                                  _selectedMaterials.add(m);
                                }
                              });
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Switch(
                          value: _useMyArea,
                          onChanged: (v) async {
                            if (v) {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final doc = await usersRef.doc(user.uid).get();
                                final loc = doc.data()?['atuacaoLocation'] as Map<String, dynamic>?;
                                if (loc != null) {
                                  setModalState(() {
                                    setState(() {
                                      _useMyArea = true;
                                      _myLat = (loc['lat'] as num?)?.toDouble();
                                      _myLng = (loc['lng'] as num?)?.toDouble();
                                    });
                                  });
                                } else {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sua área de atuação não está definida.')));
                                }
                              }
                            } else {
                              setModalState(() {
                                setState(() {
                                  _useMyArea = false;
                                });
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text('Usar minha área de atuação'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Distância máxima (km)'),
                    Slider(
                      min: 1,
                      max: 50,
                      divisions: 49,
                      value: (_maxDistanceMeters / 1000).clamp(1.0, 50.0),
                      label: '${(_maxDistanceMeters / 1000).toStringAsFixed(1)} km',
                      onChanged: (v) {
                        setModalState(() {
                          setState(() {
                            _maxDistanceMeters = v * 1000;
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedMaterials.clear();
                              _useMyArea = false;
                              _myLat = null;
                              _myLng = null;
                              _maxDistanceMeters = 5000;
                            });
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Limpar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Aplicar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  setState(() {});
 }

 // Widget para renderizar o chip de material com a cor primária
 Widget _buildMaterialChip(String label) {
  return Container(
   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
   decoration: BoxDecoration(
    color: _chipColor,
    borderRadius: BorderRadius.circular(8),
   ),
   child: Text(
    label.length > 8 ? label.substring(0, 8) : label, // Limita o texto
    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
   ),
  );
 }

// Widget para construir o Card de Catador no estilo da imagem
Widget _buildCollectorCard(BuildContext context, DocumentSnapshot d) {
  final data = d.data() as Map<String, dynamic>;
  final String name = (data['name'] ?? 'Sem nome') as String;
  final bool isFav = favs.contains(d.id);

  // Avatar
  Widget avatar;
  if (data['photoBase64'] != null) {
    try {
      final bytes = base64Decode(data['photoBase64'] as String);
      avatar = CircleAvatar(radius: 28, backgroundImage: MemoryImage(bytes));
    } catch (_) {
      avatar = const CircleAvatar(radius: 28, child: Icon(Icons.person));
    }
  } else if (data['photoURL'] != null) {
    avatar = CircleAvatar(radius: 28, backgroundImage: NetworkImage(data['photoURL'] as String));
  } else {
    avatar = const CircleAvatar(radius: 28, child: Icon(Icons.person));
  }

  final String distance = _useMyArea ? '3.2 KM' : '---';
  // rating will be loaded from the user's reviews subcollection
  final List<String> collectedMaterials = (data['collectedMaterials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

  return GestureDetector(
    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CollectorProfileScreen(userId: d.id))),
    child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 8),
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(d.id)
                            .collection('reviews')
                            .get(),
                        builder: (context, snap) {
                          double avg = 0.0;
                          int count = 0;
                          if (snap.hasData && snap.data != null) {
                            final docs = snap.data!.docs;
                            for (final rd in docs) {
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
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(display, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(distance, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(height: 10),
                  if (collectedMaterials.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: collectedMaterials.take(3).map((m) => _buildMaterialChip(m)).toList(),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
                  onPressed: () => _toggleFavorite(d.id),
                ),
                const Icon(Icons.arrow_forward, color: Color(0xFFFF9800), size: 24),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

 @override
 Widget build(BuildContext context) {
  return Scaffold(
   backgroundColor: _backgroundColor,
   appBar: AppBar(
    title: const Text('Catadores', style: TextStyle(color: Colors.black)),
    backgroundColor: _backgroundColor,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
    actions: [
     FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
      builder: (context, snapRole) {
       String? role;
       if (snapRole.hasData && snapRole.data != null && snapRole.data!.exists) {
        final data = snapRole.data!.data() as Map<String, dynamic>?;
        role = data != null ? (data['role'] as String?) : null;
       }
       return Row(children: [
        if (role == 'comprador') IconButton(
         icon: const Icon(Icons.assignment_turned_in, color: _primaryColor),
         tooltip: 'Minhas coletas atribuídas',
         onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssignedPickupsScreen()));
         },
        ),
        IconButton(
         icon: const Icon(Icons.filter_list, color: _primaryColor),
         onPressed: () async {
          final snapshot = await usersRef.where('role', isEqualTo: 'comprador').get();
          final Set<String> materials = {};
          for (final d in snapshot.docs) {
           final m = (d.data()['collectedMaterials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
           materials.addAll(m);
          }
          _openFilterSheet(materials.toList());
         },
        )
       ]);
      },
    ),
   ]),
   body: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     const Padding(
      padding: EdgeInsets.only(left: 24, top: 8, bottom: 16),
      child: Text(
       'Próximos da sua localização',
       style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
     ),
     // StreamBuilder para carregar a lista de catadores
     Expanded(
      child: StreamBuilder<QuerySnapshot>(
       stream: usersRef.where('role', isEqualTo: 'comprador').snapshots(),
       builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Nenhum catador encontrado.'));

        // Apply filters client-side (Lógica mantida)
        final filtered = docs.where((doc) {
         final data = doc.data() as Map<String, dynamic>;
         if (_selectedMaterials.isNotEmpty) {
          final userMaterials = (data['collectedMaterials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          final intersects = userMaterials.any((um) => _selectedMaterials.contains(um));
          if (!intersects) return false;
         }

         if (_useMyArea && _myLat != null && _myLng != null) {
          final loc = data['atuacaoLocation'] as Map<String, dynamic>?;
          if (loc == null) return false;
          final double lat = (loc['lat'] as num?)?.toDouble() ?? 0.0;
          final double lng = (loc['lng'] as num?)?.toDouble() ?? 0.0;
          final double radius = (loc['radius'] as num?)?.toDouble() ?? 0.0;
          final dist = _distanceMeters(_myLat!, _myLng!, lat, lng);
          if (!(dist <= _maxDistanceMeters || dist <= radius)) return false;
         }

         return true;
        }).toList();

        // Sort so favorites (from current requester) appear first (Lógica mantida)
        filtered.sort((a, b) {
         final aFav = favs.contains(a.id);
         final bFav = favs.contains(b.id);
         if (aFav == bFav) return 0;
         return aFav ? -1 : 1;
        });
        
        if (filtered.isEmpty) {
         return const Center(child: Text('Nenhum catador atende aos filtros.'));
        }

        // 3. Lista Vertical de Cards (Layout mais estável)
        return ListView.builder(
         padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
         itemCount: filtered.length,
         itemBuilder: (context, index) {
          return _buildCollectorCard(context, filtered[index]);
         },
        );
       },
      ),
     ),
    ],
   ),
  );
 }
}