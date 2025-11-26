import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Cor Primária (Verde Escuro): #0E423E
const Color _primaryColor = Color(0xFF0E423E);
const Color _accentColor = Color(0xFFFF9800); // Laranja para avisos e destaque secundário
const Color _backgroundColor = Color(0xFFF7F7F7); // Fundo mais claro

// Simple input formatter for Brazilian phone with DDD (Mantido)
class BRPhoneFormatter extends TextInputFormatter {
 @override
 TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
  final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
  String formatted = digits;
  if (digits.length <= 2) {
   formatted = digits;
  } else if (digits.length <= 6) {
   formatted = '(${digits.substring(0,2)}) ${digits.substring(2)}';
  } else if (digits.length <= 10) {
   final part2 = digits.length > 6 ? digits.substring(2, 6) : digits.substring(2);
   final part3 = digits.length > 6 ? digits.substring(6) : '';
   formatted = '(${digits.substring(0,2)}) $part2${part3.isNotEmpty ? '-$part3' : ''}';
  } else {
   final d = digits.substring(0,11);
   formatted = '(${d.substring(0,2)}) ${d.substring(2,7)}-${d.substring(7)}';
  }
  return TextEditingValue(
   text: formatted,
   selection: TextSelection.collapsed(offset: formatted.length),
  );
 }
}

class CreatePickupScreen extends StatefulWidget {
 final String? catadorId;
 const CreatePickupScreen({super.key, this.catadorId});

 @override
 State<CreatePickupScreen> createState() => _CreatePickupScreenState();
}

class _CreatePickupScreenState extends State<CreatePickupScreen> {
 final _formKey = GlobalKey<FormState>();
 bool _isLoading = false;

 // Controladores para os campos (Mantidos)
 final _solicitanteNomeController = TextEditingController();
 final _enderecoController = TextEditingController();
 final _observacoesController = TextEditingController();
 final _telefoneController = TextEditingController();
 final Set<String> _selectedMaterials = <String>{};
 final List<String> _allMaterials = [
  'Plástico', 'Alumínio', 'Papelão', 'Vidro', 'Papel', 'PET',
  'Óleo de Cozinha', 'Ferro', 'Latinha', 'Móveis', 'Eletrônicos',
  'Baterias', 'Metal', 'Outros'
 ];

 // Variáveis para data e hora (Mantidas)
 DateTime? _selectedDate;
 TimeOfDay? _selectedTime;

 @override
 void dispose() {
  _solicitanteNomeController.dispose();
  _enderecoController.dispose();
  _observacoesController.dispose();
  _telefoneController.dispose();
  super.dispose();
 }

 // --- Função para selecionar a Data --- (Mantida)
 Future<void> _selectDate(BuildContext context) async {
  final DateTime? picked = await showDatePicker(
   context: context,
   initialDate: _selectedDate ?? DateTime.now(),
   firstDate: DateTime.now(),
   lastDate: DateTime(2101),
   builder: (context, child) {
    return Theme(
     data: Theme.of(context).copyWith(
      colorScheme: ColorScheme.light(
       primary: _primaryColor, // Cor de destaque do DatePicker
       onPrimary: Colors.white,
       onSurface: Colors.black,
      ),
     ),
     child: child!,
    );
   },
  );
  if (picked != null && picked != _selectedDate) {
   setState(() {
    _selectedDate = picked;
   });
  }
 }

 // --- Função para selecionar a Hora --- (Mantida)
 Future<void> _selectTime(BuildContext context) async {
  final TimeOfDay? picked = await showTimePicker(
   context: context,
   initialTime: _selectedTime ?? TimeOfDay.now(),
   builder: (context, child) {
    return MediaQuery(
     data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
     child: Theme(
      data: Theme.of(context).copyWith(
       colorScheme: ColorScheme.light(
        primary: _primaryColor, // Cor de destaque do TimePicker
        onPrimary: Colors.white,
        onSurface: Colors.black,
       ),
      ),
      child: child!,
     ),
    );
   },
  );
  if (picked != null && picked != _selectedTime) {
   setState(() {
    _selectedTime = picked;
   });
  }
 }

 // --- Função para Salvar no Firebase --- (Mantida a Lógica)
 Future<void> _submitForm() async {
  if (!(_formKey.currentState?.validate() ?? false)) return;
  if (_selectedDate == null || _selectedTime == null) {
   ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
     content: const Text('Por favor, selecione data e hora.'),
     backgroundColor: _accentColor,
    ),
   );
   return;
  }

  setState(() { _isLoading = true; });

  try {
   final user = FirebaseAuth.instance.currentUser;
   if (user == null) {
    throw Exception("Usuário não está logado.");
   }

   final DateTime fullDateTime = DateTime(
    _selectedDate!.year,
    _selectedDate!.month,
    _selectedDate!.day,
    _selectedTime!.hour,
    _selectedTime!.minute,
   );
  
   final now = DateTime.now();
   final List<String> initialTags = ['agendada'];
   if (fullDateTime.isBefore(now)) {
    initialTags.add('atrasada');
   }

   final assignedTo = widget.catadorId;
   if (assignedTo != null) {
    initialTags.add('pendente');
   }

   final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
   final String? currentRole = (currentUserDoc.data()?['role'] as String?) ?? null;
   if (currentRole == 'cidadao' && assignedTo == null) {
    if (mounted) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Como cidadão, você deve agendar escolhendo um catador. Abra o perfil de um catador e agende por lá.'),
      backgroundColor: _accentColor,
     ));
    }
    setState(() { _isLoading = false; });
    return;
   }

   if (assignedTo != null && _selectedMaterials.isNotEmpty) {
    final doc = await FirebaseFirestore.instance.collection('users').doc(assignedTo).get();
    final data = doc.data();
    final List<dynamic>? accepts = data != null && data['collectedMaterials'] is List
     ? List<dynamic>.from(data['collectedMaterials'])
     : null;

    if (accepts == null || accepts.isEmpty) {
     if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: const Text('Este catador não possui materiais cadastrados. Escolha outro catador.'),
        backgroundColor: _accentColor,
       ),
      );
     }
     setState(() { _isLoading = false; });
     return;
    }

    final acceptedSet = accepts.map((e) => e.toString()).toSet();
    final unsupported = _selectedMaterials.where((m) => !acceptedSet.contains(m)).toList();
    if (unsupported.isNotEmpty) {
     if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: Text('Este catador não recolhe: ${unsupported.join(', ')}. Escolha outro catador.'),
        backgroundColor: _accentColor,
       ),
      );
     }
     setState(() { _isLoading = false; });
     return;
    }
   }

   // Cria o novo documento de coleta no Firestore
   final docRef = await FirebaseFirestore.instance.collection('pickups').add({
    'solicitanteNome': _solicitanteNomeController.text,
    'endereco': _enderecoController.text,
    'observacoes': _observacoesController.text.isNotEmpty ? _observacoesController.text : null,
    'phone1': _telefoneController.text.isNotEmpty
     ? '+55${_telefoneController.text.replaceAll(RegExp(r'[^0-9]'), '')}'
     : null,
    'dataHora': Timestamp.fromDate(fullDateTime),
    'status': assignedTo != null ? 'pendente' : 'agendada',
    'catadorId': widget.catadorId,
    'assignedTo': assignedTo,
    'assignedAt': assignedTo != null ? FieldValue.serverTimestamp() : null,
    'createdBy': user.uid,
    'collectedMaterials': _selectedMaterials.isNotEmpty ? _selectedMaterials.toList() : null,
    'tags': initialTags,
    'createdAt': FieldValue.serverTimestamp(),
   });

   // Envio de notificação (Mantido)
   if (assignedTo != null && assignedTo.isNotEmpty) {
    try {
     await FirebaseFirestore.instance.collection('users').doc(assignedTo).collection('notifications').add({
      'type': 'novo_agendamento',
      'pickupId': docRef.id,
      'message': 'Nova coleta agendada para você.',
      'fromUserId': user.uid,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
     });
    } catch (_) {}
   }

   // Sucesso!
   if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
     const SnackBar(
      content: Text('Nova coleta cadastrada com sucesso!'),
      backgroundColor: Colors.green,
     ),
    );
    // Limpa o formulário
    _formKey.currentState?.reset();
    _solicitanteNomeController.clear();
    _enderecoController.clear();
    _observacoesController.clear();
    _telefoneController.clear();
    setState(() {
     _selectedDate = null;
     _selectedTime = null;
    });
   }

  } catch (e) {
   if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
      content: Text('Erro ao cadastrar coleta: ${e.toString()}'),
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
 
 // Widget para construir os campos de input com o novo estilo
 Widget _buildStyledTextFormField({
  required TextEditingController controller,
  required String labelText,
  IconData? icon,
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? formatters,
  String? Function(String?)? validator,
  int maxLines = 1,
 }) {
  return TextFormField(
   controller: controller,
   keyboardType: keyboardType,
   inputFormatters: formatters,
   maxLines: maxLines,
   validator: validator,
   decoration: InputDecoration(
    labelText: labelText,
    // Estilo limpo e arredondado
    filled: true,
    fillColor: Colors.white,
    prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
    border: OutlineInputBorder(
     borderRadius: BorderRadius.circular(12),
     borderSide: BorderSide.none, // Remove a borda padrão do OutlineInputBorder
    ),
    enabledBorder: OutlineInputBorder(
     borderRadius: BorderRadius.circular(12),
     borderSide: const BorderSide(color: Colors.black12, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
     borderRadius: BorderRadius.circular(12),
     borderSide: const BorderSide(color: _primaryColor, width: 2),
    ),
   ),
  );
 }
 
 @override
 Widget build(BuildContext context) {
  // Cor primária para o botão principal
  const Color corPrimaria = _primaryColor;

  return Scaffold(
   backgroundColor: _backgroundColor,
   appBar: AppBar(
    title: const Text('Agendar Nova Coleta', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    centerTitle: true,
    backgroundColor: _backgroundColor,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
   ),
   body: SingleChildScrollView(
    padding: const EdgeInsets.all(24.0),
    child: Form(
     key: _formKey,
     child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
       // --- Nome do Solicitante ---
       _buildStyledTextFormField(
        controller: _solicitanteNomeController,
        labelText: 'Nome Completo',
        icon: Icons.person_outline,
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Campo obrigatório' : null,
       ),
       const SizedBox(height: 16),

       // --- Endereço ---
       _buildStyledTextFormField(
        controller: _enderecoController,
        labelText: 'Endereço Completo (Rua, Número, Bairro)',
        icon: Icons.location_on_outlined,
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Campo obrigatório' : null,
       ),
       const SizedBox(height: 16),
      
       // --- Data e Hora (Botões estilizados) ---
       Row(
        children: [
         // Botão Data
         Expanded(
          child: ElevatedButton.icon(
           style: ElevatedButton.styleFrom(
            backgroundColor: _selectedDate != null ? _primaryColor : Colors.white,
            foregroundColor: _selectedDate != null ? Colors.white : Colors.grey[700],
            elevation: 1,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
             side: BorderSide(color: _selectedDate != null ? _primaryColor : Colors.black12, width: 1)
            )
           ),
           icon: Icon(Icons.calendar_today, size: 18, color: _selectedDate != null ? Colors.white : Colors.grey),
           label: Text(
            _selectedDate == null
             ? 'Data'
             : DateFormat('dd/MM/yyyy').format(_selectedDate!),
            style: const TextStyle(fontSize: 16),
           ),
           onPressed: () => _selectDate(context),
          ),
         ),
         const SizedBox(width: 16),
         // Botão Hora
         Expanded(
          child: ElevatedButton.icon(
           style: ElevatedButton.styleFrom(
            backgroundColor: _selectedTime != null ? _primaryColor : Colors.white,
            foregroundColor: _selectedTime != null ? Colors.white : Colors.grey[700],
            elevation: 1,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
             side: BorderSide(color: _selectedTime != null ? _primaryColor : Colors.black12, width: 1)
            )
           ),
           icon: Icon(Icons.access_time, size: 18, color: _selectedTime != null ? Colors.white : Colors.grey),
           label: Text(
            _selectedTime == null
             ? 'Hora'
             : _selectedTime!.format(context),
            style: const TextStyle(fontSize: 16),
           ),
           onPressed: () => _selectTime(context),
          ),
         ),
        ],
       ),
       const SizedBox(height: 16),

       // --- Telefone (Opcional) ---
       _buildStyledTextFormField(
        controller: _telefoneController,
        labelText: 'Telefone',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        formatters: [BRPhoneFormatter()],
        validator: (value) {
         final v = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
         if (v.isEmpty) return null;
         if (v.length != 10 && v.length != 11) return 'Número inválido. Use DDD + número (10 ou 11 dígitos).';
         return null;
        },
       ),
       const SizedBox(height: 24),

       // --- Materiais a descartar ---
       const Text('Materiais a descartar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
       const SizedBox(height: 12),
       Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _allMaterials.map((m) {
         final sel = _selectedMaterials.contains(m);
         return ChoiceChip(
          label: Text(m),
          selected: sel,
          selectedColor: corPrimaria,
          labelStyle: TextStyle(
           color: sel ? Colors.white : Colors.black87,
           fontWeight: FontWeight.w500
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(8),
           side: BorderSide(color: sel ? corPrimaria : Colors.black12),
          ),
          onSelected: (v) {
           setState(() {
            if (v) _selectedMaterials.add(m); else _selectedMaterials.remove(m);
           });
          },
         );
        }).toList(),
       ),
       const SizedBox(height: 24),

       // --- Observações (Opcional) ---
        _buildStyledTextFormField(
        controller: _observacoesController,
        labelText: 'Observações (Detalhes da localização ou quantidade)',
        icon: Icons.notes_outlined,
        maxLines: 3,
       ),
       const SizedBox(height: 32),

       // --- Botão de Salvar ---
       ElevatedButton(
        style: ElevatedButton.styleFrom(
         backgroundColor: corPrimaria,
         foregroundColor: Colors.white,
         padding: const EdgeInsets.symmetric(vertical: 16),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
         textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
        ),
        onPressed: _isLoading ? null : _submitForm,
        child: _isLoading
         ? const SizedBox(
           height: 24,
           width: 24,
           child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          )
         : Text(widget.catadorId != null ? 'Agendar Coleta com Catador' : 'Salvar Coleta'),
       ),
      ],
     ),
    ),
   ),
  );
 }
}