import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CollectionCard extends StatelessWidget {
  final Map<String, dynamic> collectionData;
  const CollectionCard({super.key, required this.collectionData});

  @override
  Widget build(BuildContext context) {
    Future<void> _openWhatsApp(BuildContext ctx, String rawPhone) async {
      final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Telefone inválido ou ausente.')));
        return;
      }
      // Ensure country code (Brazil) if missing
      String number = digits;
      if (!number.startsWith('55')) {
        number = '55$number';
      }
      final uri = Uri.parse('https://wa.me/$number');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')));
        }
      } catch (e) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Erro ao abrir WhatsApp: ${e.toString()}')));
      }
    }
    final String status = collectionData['status'];
    final bool isNew = status == 'Novo';
    final bool hasDetails = collectionData.containsKey('observation') || collectionData.containsKey('phone1');
    final List<dynamic>? tags = collectionData['tags'] as List<dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Linha superior: Ícone, Nome, Status e Seta
            _buildTopRow(status, isNew),
            
            // Renderiza o layout correto com base nos dados
            if (isNew)
              _buildSimpleLayout()
            else
              _buildDetailedLayout(hasDetails),
            
            // Renderiza o botão de chat se for o card detalhado
            if (hasDetails)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text('Conversar com ${collectionData['requesterName']}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final p1 = collectionData['phone1'] as String?;
                    final p2 = collectionData['phone2'] as String?;
                    final phone = (p1 != null && p1.isNotEmpty) ? p1 : (p2 ?? '');
                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telefone não disponível')));
                      return;
                    }
                    _openWhatsApp(context, phone);
                  },
                ),
              ),

            // Tags (se houver)
            if (tags != null && tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: tags.map((t) => _buildTagChip(t.toString())).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade800;
    if (tag.toLowerCase() == 'atrasada') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    } else if (tag.toLowerCase() == 'agendada') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    } else if (tag.toLowerCase() == 'confirmado') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(tag, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // Linha superior (comum a todos os cards)
  Widget _buildTopRow(String status, bool isNew) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.list_alt_outlined, color: Colors.grey[600], size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                collectionData['requesterName'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _buildStatusTag(status, isNew),
            ],
          ),
        ),
        Icon(Icons.expand_more, color: Colors.grey[700]),
      ],
    );
  }

  // Layout para cards "Novo" ou "Coletado" simples
  Widget _buildSimpleLayout() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        children: [
          _buildInfoRow(Icons.access_time, collectionData['time']),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on_outlined, collectionData['address']),
        ],
      ),
    );
  }

  // Layout para card "Coletado" com detalhes (Ana Maria)
  Widget _buildDetailedLayout(bool hasDetails) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coluna da Esquerda (Observação)
          if(hasDetails)
            Expanded(
              flex: 5,
              child: _buildInfoRow(
                Icons.comment_outlined,
                "Observação: ${collectionData['observation']}",
              ),
            ),
          
          if(hasDetails)
            const SizedBox(width: 16),

          // Coluna da Direita (Horário, Endereço, Telefones)
          Expanded(
            flex: 6,
            child: Column(
              children: [
                _buildInfoRow(Icons.access_time, collectionData['time']),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_outlined, collectionData['address']),
                if (collectionData.containsKey('phone1')) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.phone_outlined, collectionData['phone1']),
                ],
                if (collectionData.containsKey('phone2')) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.phone_outlined, collectionData['phone2']),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper para criar a tag de status
  Widget _buildStatusTag(String status, bool isNew) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isNew ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNew ? Icons.star : Icons.check_circle,
            color: isNew ? Colors.blue[700] : Colors.green[700],
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: isNew ? Colors.blue[700] : Colors.green[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Helper para criar linhas de informação (Ícone + Texto)
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[800], fontSize: 13),
          ),
        ),
      ],
    );
  }
}