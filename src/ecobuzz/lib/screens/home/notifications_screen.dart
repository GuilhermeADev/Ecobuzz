import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Cores
const Color _primaryColor = Color(0xFF0E423E);
const Color _backgroundColor = Color(0xFFF7F7F7);
const Color _starColor = Colors.amber; // Amarelo para estrelas
const Color _readColor = Color(0xFFE0E0E0); // Cor para notificações lidas
const Color _unreadColor = Colors.white; // Cor para notificações não lidas

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Determina o ícone e a cor de fundo com base no tipo de notificação
  Map<String, dynamic> _getNotificationStyle(String type) {
    switch (type) {
      case 'avaliar_catador':
        return {'icon': Icons.star_half, 'color': Colors.blueAccent};
      case 'novo_agendamento':
        return {'icon': Icons.calendar_month, 'color': _primaryColor};
      case 'coleta_aceita':
        return {'icon': Icons.check_circle_outline, 'color': Colors.green};
      case 'coleta_recusada':
        return {'icon': Icons.cancel_outlined, 'color': Colors.red};
      default:
        return {'icon': Icons.info_outline, 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );

    final notRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications');

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Avisos',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Erro: ${snap.error}'));
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty)
            return const Center(child: Text('Sem notificações.'));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>;
              final msg = (data['message'] as String?) ?? 'Notificação';
              final type = (data['type'] as String?) ?? '';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final isRead = (data['read'] as bool?) ?? false;
              final pickupId = data['pickupId'] as String?;
              final catadorId = data['catadorId'] as String?;

              final style = _getNotificationStyle(type);
              final indicatorColor = isRead ? _readColor : _unreadColor;
              final cardBackgroundColor = isRead
                  ? Colors.white
                  : const Color(
                      0xFFF0FDF4,
                    ); // Levemente verde claro para não lido

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: cardBackgroundColor,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: style['color'].withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(style['icon'], color: style['color']),
                  ),
                  title: Text(
                    msg,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: createdAt != null
                      ? Text(
                          '${createdAt.toLocal().day}/${createdAt.toLocal().month}/${createdAt.toLocal().year} ${createdAt.toLocal().hour}:${createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                  trailing:
                      type == 'avaliar_catador' &&
                          pickupId != null &&
                          catadorId != null
                      ? ElevatedButton(
                          onPressed: () => _openRatingDialog(
                            context,
                            d.id,
                            catadorId,
                            pickupId,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('Avaliar'),
                        )
                      : null,
                  onTap: () async {
                    // mark read
                    try {
                      if (!isRead) {
                        await d.reference.update({'read': true});
                      }
                    } catch (_) {}
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openRatingDialog(
    BuildContext context,
    String notificationId,
    String catadorId,
    String pickupId,
  ) {
    // Usa um FutureBuilder para garantir que os dados do catador (nome) sejam carregados, se necessário
    showDialog(
      context: context,
      builder: (ctx) => _RatingDialog(
        notificationId: notificationId,
        catadorId: catadorId,
        pickupId: pickupId,
      ),
    );
  }
}

class _RatingDialog extends StatefulWidget {
  final String notificationId;
  final String catadorId;
  final String pickupId;
  const _RatingDialog({
    required this.notificationId,
    required this.catadorId,
    required this.pickupId,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 5;
  final _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final reviewsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.catadorId)
          .collection('reviews');
      await reviewsRef.add({
        'rating': _rating,
        'comment': _controller.text.isNotEmpty ? _controller.text : null,
        'fromUserId': user.uid,
        'pickupId': widget.pickupId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // mark notification read
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(widget.notificationId)
          .update({'read': true});

      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avaliação enviada.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar avaliação: ${e.toString()}')),
        );
    } finally {
      if (mounted)
        setState(() {
          _isSaving = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Avaliar Coleta',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Deixe sua nota para o serviço prestado:'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final idx = i + 1;
              return IconButton(
                icon: Icon(
                  idx <= _rating ? Icons.star : Icons.star_border,
                  color: _starColor,
                  size: 30,
                ),
                onPressed: () => setState(() => _rating = idx),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Comentário (opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _primaryColor, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Enviar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
