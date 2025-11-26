import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:ecobuzz/utils/app_colors.dart';
import 'address_picker_screen.dart';

// Cor base escura (verde escuro da imagem) - Ajuste conforme AppColors.verdePrincipal se existir
const Color _headerColor = Color(0xFF0E423E);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = true;
  bool _isUploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _photoBytes;

  // Estado da Área de Atuação (mantido)
  String? _atuacaoAddress;
  double? _atuacaoLat;
  double? _atuacaoLng;
  double? _atuacaoRadius;

  // Estado da Disponibilidade (mantido)
  final Map<String, List<Map<String, String>>> _availability = {};
  String? _editingDay;

  User? _user;
  String? _role;

  // Counts
  int _collectedCount = 0; // for catador: number of pickups concluded by this catador
  int _requestsCount = 0; // for cidadao: total pickups requested
  int _descartesCount = 0; // for cidadao: pickups concluded for this requester
  List<String> _collectedMaterials = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _user = FirebaseAuth.instance.currentUser;

    if (_user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _role = (data['role'] as String?) ?? _role;
        _nameController.text =
            (data['name'] ?? _user!.displayName ?? '') as String;
        _cpfController.text = (data['cpf'] ?? '') as String;
        _phoneController.text =
            (data['phone'] ?? _user!.phoneNumber ?? '') as String;
        if (data['photoBase64'] != null) {
          try {
            _photoBytes = base64Decode(data['photoBase64'] as String);
          } catch (_) {
            _photoBytes = null;
          }
        }
        // Área de atuação
        _atuacaoAddress = data['atuacaoAddress'] as String?;
        if (data['atuacaoLocation'] != null) {
          final loc = data['atuacaoLocation'] as Map<String, dynamic>;
          _atuacaoLat = (loc['lat'] as num?)?.toDouble();
          _atuacaoLng = (loc['lng'] as num?)?.toDouble();
          _atuacaoRadius = (loc['radius'] as num?)?.toDouble();
        }
        // Disponibilidade
          // Materiais coletados (se houver)
          final mats = (data['collectedMaterials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _collectedMaterials = mats;
        if (data['availability'] != null &&
            data['availability'] is Map<String, dynamic>) {
          final Map<String, dynamic> raw =
              data['availability'] as Map<String, dynamic>;
          raw.forEach((day, val) {
            try {
              final List<Map<String, String>> ranges = (val as List<dynamic>)
                  .map(
                    (e) => {
                      'from': '${(e as Map<String, dynamic>)['from'] ?? ''}',
                      'to': '${e['to'] ?? ''}',
                    },
                  )
                  .toList();
              _availability[day] = ranges;
            } catch (_) {}
          });
        }
      } else {
        _nameController.text = _user!.displayName ?? '';
        _phoneController.text = _user!.phoneNumber ?? '';
      }
    } catch (e) {
      // Caso de erro, apenas mostra a tela com valores disponíveis no Auth
      _nameController.text = _user!.displayName ?? '';
      _phoneController.text = _user!.phoneNumber ?? '';
    }

    setState(() {
      _loading = false;
    });
    // after loading basic profile, load counts
    await _loadCounts();
  }

  Future<void> _loadCounts() async {
    if (_user == null) return;
    final uid = _user!.uid;
    try {
      // For catador: count pickups where assignedTo == uid and status == 'concluido'
      final assignedQuery = await FirebaseFirestore.instance
          .collection('pickups')
          .where('assignedTo', isEqualTo: uid)
          .where('status', isEqualTo: 'concluido')
          .get();
      _collectedCount = assignedQuery.docs.length;

      // For cidadao: total requests (createdBy == uid)
      final requestsQuery = await FirebaseFirestore.instance
          .collection('pickups')
          .where('createdBy', isEqualTo: uid)
          .get();
      _requestsCount = requestsQuery.docs.length;

      // For cidadao: descartes feitos (createdBy == uid and status == 'concluido')
      final descartesQuery = await FirebaseFirestore.instance
          .collection('pickups')
          .where('createdBy', isEqualTo: uid)
          .where('status', isEqualTo: 'concluido')
          .get();
      _descartesCount = descartesQuery.docs.length;
    } catch (e) {
      // ignore errors for counts; keep defaults
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (_user == null) return;

    final uid = _user!.uid;
    setState(() => _loading = true);

    try {
      // Atualiza o documento no Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'cpf': _cpfController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _user!.email,
        // salva disponibilidade
        'availability': _availability,
      }, SetOptions(merge: true));

      // Atualiza o displayName no FirebaseAuth (opcional)
      await _user!.updateDisplayName(_nameController.text.trim());
      await _user!.reload();
      _user = FirebaseAuth.instance.currentUser;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados salvos com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erro ao salvar dados.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_user == null) return;
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (picked == null) return;
      setState(() => _isUploadingPhoto = true);

      Uint8List bytes = await picked.readAsBytes();

      // Compress / resize using image package
      const int maxSizeBytes = 700 * 1024; // 700 KB
      int quality = 85;
      img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Formato de imagem não suportado');
      const int maxWidth = 800;
      if (decoded.width > maxWidth)
        decoded = img.copyResize(decoded, width: maxWidth);
      Uint8List encoded = Uint8List.fromList(
        img.encodeJpg(decoded, quality: quality),
      );
      while (encoded.lengthInBytes > maxSizeBytes && quality > 30) {
        quality -= 10;
        encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
      }

      final String base64Image = base64Encode(encoded);
      final uid = _user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'photoBase64': base64Image,
      }, SetOptions(merge: true));
      // Update local preview bytes
      _photoBytes = encoded;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto atualizada.')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar foto: ${e.toString()}')),
        );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildMaterialChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _headerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Future<bool> _reauthenticateWithPassword(String currentPassword) async {
    if (_user == null || _user!.email == null) return false;
    try {
      final cred = EmailAuthProvider.credential(email: _user!.email!, password: currentPassword);
      await _user!.reauthenticateWithCredential(cred);
      // reload user
      await _user!.reload();
      _user = FirebaseAuth.instance.currentUser;
      return true;
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na reautenticação: ${e.message}')));
      return false;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na reautenticação: ${e.toString()}')));
      return false;
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('Alterar Senha'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_user?.email == null) const Text('Alteração de senha não disponível para este usuário.'),
                if (_user?.email != null) ...[
                  TextField(controller: currentController, obscureText: true, decoration: const InputDecoration(labelText: 'Senha atual')),
                  TextField(controller: newController, obscureText: true, decoration: const InputDecoration(labelText: 'Nova senha')),
                  TextField(controller: confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar nova senha')),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: saving ? null : () { Navigator.of(ctx).pop(); }, child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: saving || _user?.email == null ? null : () async {
                  final current = currentController.text.trim();
                  final n = newController.text.trim();
                  final c = confirmController.text.trim();
                  if (n.isEmpty || c.isEmpty || n != c) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As senhas não coincidem ou estão vazias.')));
                    return;
                  }
                  setStateDialog(() => saving = true);
                  final ok = await _reauthenticateWithPassword(current);
                  if (!ok) { setStateDialog(() => saving = false); return; }
                  try {
                    await _user!.updatePassword(n);
                    await _user!.reload();
                    _user = FirebaseAuth.instance.currentUser;
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha alterada com sucesso.')));
                    Navigator.of(ctx).pop();
                  } on FirebaseAuthException catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alterar senha: ${e.message}')));
                    setStateDialog(() => saving = false);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alterar senha: ${e.toString()}')));
                    setStateDialog(() => saving = false);
                  }
                },
                child: saving ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Alterar'),
              ),
            ],
          );
        });
      }
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final passwordController = TextEditingController();
    bool deleting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('Excluir Conta'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Esta ação é irreversível. Todos os seus dados serão removidos. Confirma?'),
                const SizedBox(height: 8),
                if (_user?.email == null) const Text('Exclusão exige reautenticação por senha (usuário sem e-mail não pode excluir por aqui).'),
                if (_user?.email != null) TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Senha atual')),
              ],
            ),
            actions: [
              TextButton(onPressed: deleting ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: deleting ? null : () async {
                  if (_user == null) return;
                  if (_user!.email == null) return;
                  final pwd = passwordController.text.trim();
                  if (pwd.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Digite sua senha para confirmar.')));
                    return;
                  }
                  setStateDialog(() => deleting = true);
                  final ok = await _reauthenticateWithPassword(pwd);
                  if (!ok) { setStateDialog(() => deleting = false); return; }

                  try {
                    final uid = _user!.uid;
                    // Remove user doc
                    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                    // Delete auth user
                    await _user!.delete();
                    // Sign out and navigate to login
                    await FirebaseAuth.instance.signOut();
                    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                  } on FirebaseAuthException catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir conta: ${e.message}')));
                    setStateDialog(() => deleting = false);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir conta: ${e.toString()}')));
                    setStateDialog(() => deleting = false);
                  }
                },
                child: deleting ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Text('Excluir'),
              ),
            ],
          );
        });
      }
    );
  }

  // --- Lógica de Disponibilidade (mantida) ---
  String _weekdayLabel(String key) {
    switch (key) {
      case 'monday':
        return 'Seg';
      case 'tuesday':
        return 'Ter';
      case 'wednesday':
        return 'Qua';
      case 'thursday':
        return 'Qui';
      case 'friday':
        return 'Sex';
      case 'saturday':
        return 'Sáb';
      case 'sunday':
        return 'Dom';
      default:
        return key;
    }
  }

  void _addEmptyRange(String day) {
    setState(() {
      _availability.putIfAbsent(day, () => []);
      _availability[day]!.add({'from': '08:00', 'to': '12:00'});
    });
  }

  Future<void> _editRangeTime(String day, int index, bool isFrom) async {
    final current =
        _availability[day]?[index][isFrom ? 'from' : 'to'] ?? '08:00';
    final initial = _parseTime(current);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    final formatted = _formatTime(picked);
    setState(() {
      _availability[day]?[index][isFrom ? 'from' : 'to'] = formatted;
    });
  }

  TimeOfDay _parseTime(String s) {
    try {
      final parts = s.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  List<Widget> _buildRangesForDay(String day) {
    final ranges = _availability[day] ?? [];
    if (ranges.isEmpty) return [const Text('Nenhum período definido.')];
    return List<Widget>.generate(ranges.length, (i) {
      final r = ranges[i];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _editRangeTime(day, i, true),
                child: Text('De: ${r['from'] ?? ''}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _editRangeTime(day, i, false),
                child: Text('Até: ${r['to'] ?? ''}'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _availability[day]?.removeAt(i);
                });
              },
            ),
          ],
        ),
      );
    });
  }
  // ----------------------------------------------------

  // Widget reutilizável para o par Label/Valor (Leitura, conforme a imagem)
  Widget _buildDisplayItem({
    required String label,
    required String value,
    bool isEditable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isEditable)
            const Divider(
              height: 8,
              color: Colors.grey,
            ), // Linha de separação discreta
        ],
      ),
    );
  }

  // Converte a estrutura de TextField para o visual de "Label/Valor" da imagem.
  // Usamos um TextField para manter a funcionalidade de edição, mas com o estilo limpo.
  Widget _buildStyledEditableField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.normal,
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.zero,
              border: UnderlineInputBorder(),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 0.5),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _headerColor, width: 1.5),
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Nenhum usuário logado.')),
      );
    }

    // Derived username (show only when we have a display name)
    final String? username = (_user!.displayName != null && _user!.displayName!.trim().isNotEmpty)
      ? '@${_user!.displayName!.replaceAll(' ', '_').toLowerCase()}'
      : null;
    // Use saved atuação address or an empty placeholder
    final String displayAddress = _atuacaoAddress ?? '-';
    // Use current system time instead of a static mock time
    final String systemTime = TimeOfDay.now().format(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      // -------------------- Bottom Navigation Bar (Placeholder Visual) --------------------
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Icon(Icons.home_outlined, size: 28, color: Colors.grey),
            Icon(Icons.search, size: 28, color: Colors.grey),
            Padding(
              padding: EdgeInsets.only(
                bottom: 20,
              ), // Pequeno ajuste para o botão do centro
              child: Icon(Icons.add_circle, size: 40, color: _headerColor),
            ),
            Icon(Icons.notifications_none, size: 28, color: Colors.grey),
            Icon(Icons.person, size: 30, color: _headerColor),
          ],
        ),
      ),

      // ----------------------------------------------------------------------------------
      body: Stack(
        children: [
          // 1. Cabeçalho Verde Escuro
          Container(
            height: 280, // Altura do cabeçalho
            width: double.infinity,
            decoration: const BoxDecoration(color: _headerColor),
          ),

          // 2. Conteúdo do Perfil no topo do Cabeçalho
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Column(
                children: [
                  // Área do Status Bar (Mock para 9:41)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          systemTime,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Foto de Perfil e Informações
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: _photoBytes != null
                            ? MemoryImage(_photoBytes!) as ImageProvider
                            : (_user!.photoURL != null
                                  ? NetworkImage(_user!.photoURL!)
                                  : null),
                        child: _photoBytes == null && _user!.photoURL == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      // Câmera de edição (mantida a lógica de upload)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadPhoto,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.laranja,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: _isUploadingPhoto
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _nameController.text.isNotEmpty ? _nameController.text : (_user!.displayName ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (username != null && username.isNotEmpty)
                    Text(
                      username,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  // Show what the user collects if they are a collector
                  if ((_role == 'catador' || _role == 'comprador')) ...[
                    const SizedBox(height: 8),
                    const Text('Está coletando:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_collectedMaterials.isEmpty)
                      Text('Não informado', style: TextStyle(color: Colors.white70)),
                    if (_collectedMaterials.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _collectedMaterials.map((m) => _buildMaterialChip(m)).toList(),
                      ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),

          // 3. Card Branco Flutuante com o conteúdo de edição
          Positioned.fill(
            top: 210, // Inicia abaixo do cabeçalho
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  30,
                  24,
                  100,
                ), // Espaço para o BottomNav
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campos de Perfil no estilo da imagem (mantendo os TextControllers originais)
                    _buildStyledEditableField(
                      controller: _nameController,
                      label: 'Nome',
                    ),

                    // E-mail (Somente Leitura, como na imagem)
                    _buildDisplayItem(
                      label: 'E-mail',
                      value: _user!.email ?? '-',
                    ),

                    // Endereço de Atuação (estilizado como item de exibição, mas com o botão "Editar")
                    _buildDisplayItem(label: 'Endereço', value: displayAddress),

                    _buildStyledEditableField(
                      controller: _phoneController,
                      label: 'Número',
                      keyboardType: TextInputType.phone,
                    ),
                    // CPF (campo que não aparece na imagem, mas foi mantido)
                    _buildStyledEditableField(
                      controller: _cpfController,
                      label: 'CPF',
                      keyboardType: TextInputType.number,
                    ),

                    // -------------------- Card de Coletas Realizadas --------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Coletas realizadas',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: () {
                            /* Adicione navegação */
                          },
                          child: Text(
                            'Ver mais',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.laranja,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _headerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _role == 'catador'
                          ? Row(
                              children: [
                                const Icon(Icons.add, color: Colors.red, size: 30),
                                const SizedBox(width: 8),
                                Text(
                                  '$_collectedCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.show_chart,
                                  color: Color(0xFFC8E6C9),
                                  size: 40,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Descartes feitos', style: TextStyle(color: Colors.white70)),
                                      const SizedBox(height: 8),
                                      Text('$_descartesCount', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      const Text('Solicitações', style: TextStyle(color: Colors.white70)),
                                      const SizedBox(height: 8),
                                      Text('$_requestsCount', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.show_chart,
                                  color: Color(0xFFC8E6C9),
                                  size: 40,
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 30),
                    // -------------------- Coletas atribuídas e Relatório (apenas para catador/collector logado)
                    if ((_role == 'catador' || _role == 'comprador'))
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('pickups')
                            .where('assignedTo', isEqualTo: _user!.uid)
                            .orderBy('dataHora', descending: true)
                            .snapshots(),
                        builder: (context, psnap) {
                          if (psnap.connectionState == ConnectionState.waiting) return const SizedBox();
                          final pdocs = psnap.data?.docs ?? [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Coletas atribuídas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              if (pdocs.isEmpty) const Text('Nenhuma coleta atribuída.'),
                              for (final pd in pdocs.take(6))
                                ListTile(
                                  dense: true,
                                  title: Text((pd.data() as Map<String, dynamic>)['solicitanteNome'] as String? ?? 'Solicitante'),
                                  subtitle: Text(((pd.data() as Map<String, dynamic>)['endereco'] as String?) ?? ''),
                                  trailing: Text(((pd.data() as Map<String, dynamic>)['status'] as String?) ?? ''),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.picture_as_pdf),
                                    label: const Text('Gerar relatório PDF'),
                                    onPressed: () async {
                                      try {
                                        final snaps = await FirebaseFirestore.instance.collection('pickups').where('assignedTo', isEqualTo: _user!.uid).get();
                                        final pickups = snaps.docs.map((d) => d.data()).toList();

                                        final Map<String, List<Map<String, dynamic>>> byMaterial = {};
                                        for (final p in pickups) {
                                          final List<dynamic>? mats = p['collectedMaterials'] as List<dynamic>?;
                                          if (mats == null || mats.isEmpty) {
                                            byMaterial.putIfAbsent('Não informado', () => []).add(p);
                                          } else {
                                            for (final m in mats) {
                                              final key = m.toString();
                                              byMaterial.putIfAbsent(key, () => []).add(p);
                                            }
                                          }
                                        }

                                        final doc = pw.Document();
                                        final now = DateTime.now();
                                        final df = DateFormat('dd/MM/yyyy HH:mm');

                                        final userName = _nameController.text.isNotEmpty ? _nameController.text : (_user!.displayName ?? 'Catador');

                                        doc.addPage(pw.MultiPage(build: (pw.Context ctx) {
                                          return [
                                            pw.Header(level: 0, child: pw.Text('Relatório de Coletas - $userName')),
                                            pw.Text('Gerado em: ${df.format(now)}'),
                                            pw.SizedBox(height: 8),
                                            pw.Text('Total de coletas atribuídas: ${pickups.length}'),
                                            pw.SizedBox(height: 8),
                                            pw.Text('Coletas por material', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                            pw.Table.fromTextArray(context: ctx, data: <List<String>>[
                                              <String>['Material', 'Quantidade'],
                                              ...byMaterial.entries.map((e) => [e.key, e.value.length.toString()])
                                            ]),
                                            pw.SizedBox(height: 12),
                                            pw.Text('Detalhes por material', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                            for (final entry in byMaterial.entries) ...[
                                              pw.SizedBox(height: 8),
                                              pw.Text('${entry.key} (${entry.value.length})', style: pw.TextStyle(decoration: pw.TextDecoration.underline)),
                                              pw.Column(children: entry.value.map((p) {
                                                final dt = p['dataHora'] is Timestamp ? (p['dataHora'] as Timestamp).toDate() : null;
                                                final dateStr = dt != null ? df.format(dt) : (p['createdAt'] is Timestamp ? df.format((p['createdAt'] as Timestamp).toDate()) : 'Sem data');
                                                final requester = p['solicitanteNome'] ?? p['createdBy'] ?? '';
                                                final addr = p['endereco'] ?? '';
                                                return pw.Text(' - $requester | $addr | $dateStr', style: pw.TextStyle(fontSize: 10));
                                              }).toList()),
                                            ],
                                          ];
                                        }));

                                        final bytes = await doc.save();
                                        await Printing.sharePdf(bytes: bytes, filename: 'relatorio_coletas_${_user!.uid}.pdf');
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar relatório: ${e.toString()}')));
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.chat),
                                    label: const Text('Abrir WhatsApp'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () async {
                                      final rawPhone = _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : (_user!.phoneNumber ?? '');
                                      if (rawPhone.isEmpty) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telefone não disponível.')));
                                        return;
                                      }
                                      final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
                                      if (digits.isEmpty) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telefone inválido.')));
                                        return;
                                      }
                                      String number = digits;
                                      if (!number.startsWith('55')) number = '55$number';
                                      final uri = Uri.parse('https://wa.me/$number');
                                      try {
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        } else {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')));
                                        }
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao abrir WhatsApp: ${e.toString()}')));
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
                    // -------------------- Lógica de Área de Atuação (Preservada) --------------------
                    const Text(
                      'Área de Atuação',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.map_outlined,
                        color: _headerColor,
                      ),
                      title: Text(
                        _atuacaoAddress ?? 'Área de atuação não definida',
                      ),
                      subtitle: _atuacaoLat != null
                          ? Text(
                              'Centro: ${_atuacaoLat!.toStringAsFixed(6)}, ${_atuacaoLng!.toStringAsFixed(6)} · Raio: ${_atuacaoRadius?.toInt() ?? 0} m',
                            )
                          : null,
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            final result = await Navigator.of(context)
                                .push<Map<String, dynamic>>(
                                  MaterialPageRoute(
                                    builder: (context) => AddressPickerScreen(
                                      initialAddress: _atuacaoAddress,
                                      initialLat: _atuacaoLat,
                                      initialLng: _atuacaoLng,
                                      initialRadius: _atuacaoRadius,
                                    ),
                                  ),
                                );
                            if (result == null) return;

                            final uid = _user!.uid;
                            final double lat = (result['lat'] is num)
                                ? (result['lat'] as num).toDouble()
                                : double.tryParse('${result['lat']}') ?? 0.0;
                            final double lng = (result['lng'] is num)
                                ? (result['lng'] as num).toDouble()
                                : double.tryParse('${result['lng']}') ?? 0.0;
                            final double radius = (result['radius'] is num)
                                ? (result['radius'] as num).toDouble()
                                : double.tryParse('${result['radius']}') ?? 0.0;

                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Salvando área: raio ${radius.toInt()} m',
                                  ),
                                ),
                              );

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .set({
                                  'atuacaoAddress': result['address'] ?? '',
                                  'atuacaoLocation': {
                                    'lat': lat,
                                    'lng': lng,
                                    'radius': radius,
                                  },
                                }, SetOptions(merge: true));

                            setState(() {
                              _atuacaoAddress = result['address'];
                              _atuacaoLat = lat;
                              _atuacaoLng = lng;
                              _atuacaoRadius = radius;
                            });

                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Área de atuação salva.'),
                                ),
                              );
                          } catch (e) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Erro ao salvar área: ${e.toString()}',
                                  ),
                                ),
                              );
                          }
                        },
                        child: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.laranja,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // -------------------- Lógica de Disponibilidade (Preservada) --------------------
                    const Text(
                      'Disponibilidade',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final day in [
                          'monday',
                          'tuesday',
                          'wednesday',
                          'thursday',
                          'friday',
                          'saturday',
                          'sunday',
                        ])
                          FilterChip(
                            label: Text(_weekdayLabel(day)),
                            selected:
                                _availability.containsKey(day) &&
                                _availability[day]!.isNotEmpty,
                            onSelected: (sel) {
                              setState(() {
                                if (sel) {
                                  _availability.putIfAbsent(day, () => []);
                                  _editingDay = day;
                                } else {
                                  _availability.remove(day);
                                  if (_editingDay == day) _editingDay = null;
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_editingDay != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Períodos de ${_weekdayLabel(_editingDay!)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _addEmptyRange(_editingDay!)),
                            child: const Text('Adicionar período'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._buildRangesForDay(_editingDay!),
                      const SizedBox(height: 8),
                    ],
                    // ----------------------------------------------------------------------------------

                    // Botões de Ação no novo estilo
                    ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.laranja,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Salvar',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _showChangePasswordDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Alterar senha', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.preto,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Sair'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _showDeleteAccountDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Excluir Conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
