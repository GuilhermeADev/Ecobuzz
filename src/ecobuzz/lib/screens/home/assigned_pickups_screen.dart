
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AssignedPickupsScreen extends StatefulWidget {
  const AssignedPickupsScreen({super.key});

  @override
  State<AssignedPickupsScreen> createState() => _AssignedPickupsScreenState();
}

class _AssignedPickupsScreenState extends State<AssignedPickupsScreen> {
  final pickupsRef = FirebaseFirestore.instance.collection('pickups');
  final usersRef = FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: usersRef.doc(user.uid).get(),
      builder: (context, roleSnap) {
        if (roleSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        String? role;
        if (roleSnap.hasData && roleSnap.data!.exists) {
          final m = roleSnap.data!.data() as Map<String, dynamic>?;
          if (m != null && m['role'] != null) role = m['role'].toString();
        }

        if (role != 'comprador') {
          return Scaffold(
            appBar: AppBar(title: const Text('Coletas Atribuídas a Mim')),
            body: const Center(
              child: Text('Acesso negado: apenas catadores podem ver esta tela.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Coletas Atribuídas a Mim')),
          body: StreamBuilder<QuerySnapshot>(
            stream: pickupsRef.where('assignedTo', isEqualTo: user.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('Nenhuma coleta atribuída a você.'));
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final d = docs[index];
                  final data = d.data() as Map<String, dynamic>;
                  final solicitante = (data['solicitanteNome'] as String?) ?? 'Solicitante';
                  final endereco = (data['endereco'] as String?) ?? '';
                  final ts = data['dataHora'] as Timestamp?;
                  final dateStr = ts != null ? DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate()) : 'Sem data';
                  final status = (data['status'] as String?) ?? 'pendente';

                  Widget trailing;

                  if (status == 'pendente') {
                    trailing = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () async {
                            try {
                              final ref = pickupsRef.doc(d.id);
                              await ref.update({
                                'status': 'agendada',
                                'catadorResponseAt': FieldValue.serverTimestamp(),
                                'catadorConfirmedBy': user.uid,
                              });
                              await ref.update({'tags': FieldValue.arrayRemove(['pendente'])});
                              await ref.update({'tags': FieldValue.arrayUnion(['agendada', 'confirmado'])});

                              // Notifica o solicitante que o catador aceitou
                              final createdBy = (data['createdBy'] as String?) ?? (data['createdById'] as String?);
                              if (createdBy != null && createdBy.isNotEmpty) {
                                try {
                                  await usersRef.doc(createdBy).collection('notifications').add({
                                    'type': 'status_update',
                                    'status': 'agendada',
                                    'pickupId': d.id,
                                    'catadorId': user.uid,
                                    'message': 'Seu agendamento foi aceito pelo catador.',
                                    'read': false,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                } catch (_) {}
                              }

                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coleta aceita.')));
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao aceitar: ${e.toString()}')));
                            }
                          },
                          child: const Text('Aceitar'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Recusar coleta'),
                                content: const Text('Tem certeza que deseja recusar esta coleta?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Recusar')),
                                ],
                              ),
                            );
                            if (confirm != true) return;
                            try {
                              final ref = pickupsRef.doc(d.id);
                              await ref.update({
                                'status': 'recusada',
                                'catadorResponseAt': FieldValue.serverTimestamp(),
                                'catadorConfirmedBy': user.uid,
                              });
                              await ref.update({'tags': FieldValue.arrayRemove(['pendente'])});
                              await ref.update({'tags': FieldValue.arrayUnion(['recusada'])});

                              // Notifica o solicitante que o catador recusou
                              final createdBy = (data['createdBy'] as String?) ?? (data['createdById'] as String?);
                              if (createdBy != null && createdBy.isNotEmpty) {
                                try {
                                  await usersRef.doc(createdBy).collection('notifications').add({
                                    'type': 'status_update',
                                    'status': 'recusada',
                                    'pickupId': d.id,
                                    'catadorId': user.uid,
                                    'message': 'Seu agendamento foi recusado pelo catador.',
                                    'read': false,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                } catch (_) {}
                              }

                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coleta recusada.')));
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao recusar: ${e.toString()}')));
                            }
                          },
                          child: const Text('Recusar', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                      ],
                    );
                  } else if (status == 'agendada') {
                    trailing = ElevatedButton(
                      onPressed: () async {
                        try {
                          final ref = pickupsRef.doc(d.id);
                          await ref.update({
                            'status': 'a_caminho',
                            'catadorStatusUpdatedAt': FieldValue.serverTimestamp(),
                            'catadorStatusUpdatedBy': user.uid,
                          });
                          await ref.update({'tags': FieldValue.arrayRemove(['agendada'])});
                          await ref.update({'tags': FieldValue.arrayUnion(['a_caminho'])});

                          // Notifica o solicitante que o catador está a caminho
                          final createdBy = (data['createdBy'] as String?) ?? (data['createdById'] as String?);
                          if (createdBy != null && createdBy.isNotEmpty) {
                            try {
                              await usersRef.doc(createdBy).collection('notifications').add({
                                'type': 'status_update',
                                'status': 'a_caminho',
                                'pickupId': d.id,
                                'catadorId': user.uid,
                                'message': 'O catador está a caminho da sua coleta.',
                                'read': false,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                            } catch (_) {}
                          }

                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status atualizado: a caminho')));
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar status: ${e.toString()}')));
                        }
                      },
                      child: const Text('A caminho'),
                    );
                  } else if (status == 'a_caminho') {
                    trailing = ElevatedButton(
                      onPressed: () async {
                        try {
                          final ref = pickupsRef.doc(d.id);
                          await ref.update({
                            'status': 'concluido',
                            'catadorStatusUpdatedAt': FieldValue.serverTimestamp(),
                            'catadorStatusUpdatedBy': user.uid,
                            'completedAt': FieldValue.serverTimestamp(),
                          });
                          await ref.update({'tags': FieldValue.arrayRemove(['a_caminho'])});
                          await ref.update({'tags': FieldValue.arrayUnion(['concluido'])});

                          final createdBy = (data['createdBy'] as String?) ?? (data['createdById'] as String?);
                          if (createdBy != null && createdBy.isNotEmpty) {
                            try {
                              await usersRef.doc(createdBy).collection('notifications').add({
                                'type': 'avaliar_catador',
                                'pickupId': d.id,
                                'catadorId': user.uid,
                                'message': 'Sua coleta foi concluída. Avalie o catador.',
                                'read': false,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                            } catch (_) {}
                          }

                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coleta marcada como concluída.')));
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao concluir: ${e.toString()}')));
                        }
                      },
                      child: const Text('Concluir'),
                    );
                  } else {
                    trailing = Text(status);
                  }

                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(solicitante)),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(endereco),
                        const SizedBox(height: 4),
                        Text(dateStr),
                        const SizedBox(height: 4),
                        Text('Status: $status', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: trailing,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
