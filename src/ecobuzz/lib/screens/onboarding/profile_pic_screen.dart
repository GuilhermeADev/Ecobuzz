import 'dart:typed_data'; // Para Uint8List
import 'dart:convert'; // base64
import 'package:image/image.dart' as img;
import 'package:ecobuzz/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para pegar imagem
import 'package:firebase_auth/firebase_auth.dart'; // Para pegar o user ID
import 'package:cloud_firestore/cloud_firestore.dart'; // Para salvar no Firestore
// import 'package:firebase_storage/firebase_storage.dart'; // Para fazer upload da imagem

class ProfilePicScreen extends StatefulWidget {
  const ProfilePicScreen({super.key});

  @override
  State<ProfilePicScreen> createState() => _ProfilePicScreenState();
}

class _ProfilePicScreenState extends State<ProfilePicScreen> {
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Função para mostrar as opções (Câmera ou Galeria) - SEM MUDANÇAS
  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria de Fotos'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Câmera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Função para pegar a imagem - SEM MUDANÇAS
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        // ★ IMPORTANTE: Reduzir a qualidade para economizar espaço no Firestore ★
        imageQuality: 50, // Ajuste entre 0 (pior) e 100 (melhor)
        maxWidth: 800, // Redimensiona a imagem se for muito grande
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao selecionar imagem: ${e.toString()}")),
      );
    }
  }

  // --- ★ ATUALIZADO: Função "CRIAR CONTA" para fazer upload no Firebase Storage ★ ---
  Future<void> _createAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuário não está logado.");

      // Se não selecionou foto, segue para Home
      if (_imageFile == null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
        return;
      }

    // Leia os bytes da XFile (funciona em mobile e web)
    Uint8List bytes = await _imageFile!.readAsBytes();

    // Compress / resize efficiently using the 'image' package until it fits
    const int maxSizeBytes = 700 * 1024; // 700 KB to be safe for Firestore
    int quality = 85;
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Formato de imagem não suportado');

    // Resize if too wide
    const int maxWidth = 800;
    if (decoded.width > maxWidth) {
      decoded = img.copyResize(decoded, width: maxWidth);
    }

    Uint8List encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
    while (encoded.lengthInBytes > maxSizeBytes && quality > 30) {
      quality -= 10;
      encoded = Uint8List.fromList(img.encodeJpg(decoded!, quality: quality));
    }

    final String base64Image = base64Encode(encoded);

      // Salva Base64 no Firestore (campo photoBase64)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoBase64': base64Image,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao criar conta: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color corFundo = Color(0xFF0A3C32);

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
                  'assets/ecobuzz_logo.png', // Substitua pelo caminho do seu logo
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.recycling, color: Colors.white, size: 40),
                ),
                 SizedBox(height: MediaQuery.of(context).size.height * 0.1), // Ajuste de espaço
                const Text(
                  'Pra terminar, coloque\numa foto pra aparecer\nno seu perfil! :)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Círculo da Foto
                Center( // Centraliza o avatar
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    backgroundImage: _imageBytes != null
                        ? MemoryImage(_imageBytes!)
                        : null,
                    child: _imageBytes == null
                        ? const Icon(Icons.person, size: 60, color: Colors.white54)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Botão Adicionar Foto
                Center( // Centraliza o botão
                  child: TextButton(
                    onPressed: _showImagePickerOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Adicionar foto',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                 SizedBox(height: MediaQuery.of(context).size.height * 0.1), // Ajuste de espaço

                // Botão Criar Conta
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _createAccount,
                  child: _isLoading
                      ? const SizedBox( // Para centralizar melhor o indicador
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(width: 40), // Espaço vazio
                            Text(
                              'CRIAR CONTA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 20),
                          ],
                        ),
                ),
                 SizedBox(height: MediaQuery.of(context).size.height * 0.05), // Espaço inferior
              ],
            ),
          ),
        ),
      ),
    );
  }
}

