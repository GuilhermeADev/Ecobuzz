import 'dart:convert'; // Para Base64
import 'dart:typed_data'; // Para Uint8List
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileAvatar extends StatelessWidget {
  final double radius; // Tamanho do avatar

  const UserProfileAvatar({super.key, this.radius = 40}); // Valor padrão 40

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Se não houver usuário logado, mostra um ícone padrão
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: radius * 0.8, color: Colors.grey[600]), // Ajustado tamanho do ícone
      );
    }

    // Busca o documento do usuário no Firestore
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        // Enquanto carrega
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        }

        // Se deu erro ou não encontrou o documento
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: radius * 0.8, color: Colors.grey[600]), // Ajustado tamanho do ícone
          );
        }

        // Se encontrou o documento, pega os dados
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String? photoBase64 = data['photoBase64']; // Pega a string

        // Se HÁ uma string Base64 salva
        if (photoBase64 != null && photoBase64.isNotEmpty) {
          try {
            // Tenta decodificar
            final Uint8List imageBytes = base64Decode(photoBase64);
            // Mostra a imagem usando Image.memory
            return CircleAvatar(
              radius: radius,
              backgroundImage: MemoryImage(imageBytes),
              backgroundColor: Colors.grey[200], // Fundo enquanto carrega
            );
          } catch (e) {
            // Se der erro ao decodificar (string corrompida?)
            print("Erro ao decodificar Base64: $e");
            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.red[100], // Indica erro
              child: Icon(Icons.error_outline, size: radius * 0.8, color: Colors.red[700]), // Ajustado tamanho do ícone
            );
          }
        }

        // Se NÃO HÁ string Base64 salva, mostra o ícone padrão
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[300],
          child: Icon(Icons.person, size: radius * 0.8, color: Colors.grey[600]), // Ajustado tamanho do ícone
        );
      },
    );
  }
}

