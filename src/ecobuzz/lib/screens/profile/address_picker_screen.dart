import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddressPickerScreen extends StatefulWidget {
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;
  final double? initialRadius;

  const AddressPickerScreen({
    super.key,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
    this.initialRadius,
  });

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  final MapController _mapController = MapController();
  late LatLng _selectedPoint;
  double _radius = 500;
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _selectedPoint = widget.initialLat != null && widget.initialLng != null
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : LatLng(-23.55052, -46.633308);

    if (widget.initialRadius != null) _radius = widget.initialRadius!;
    if (widget.initialAddress != null) {
      _addressController.text = widget.initialAddress!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    // Salva diretamente no Firestore para o usuário logado
    _saveAndClose();
  }

  Future<void> _saveAndClose() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário não autenticado.')));
      return;
    }

    final double lat = _selectedPoint.latitude;
    final double lng = _selectedPoint.longitude;
    final double radius = _radius;
    final String address = _addressController.text;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'atuacaoAddress': address,
        'atuacaoLocation': {
          'lat': lat,
          'lng': lng,
          'radius': radius,
        }
      }, SetOptions(merge: true));

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Área de atuação salva.')));

      Navigator.of(context).pop({
        'address': address,
        'lat': lat,
        'lng': lng,
        'radius': radius,
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar área: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar área de atuação'),
        actions: [
          TextButton(
            onPressed: _onConfirm,
            child: const Text(
              'Salvar',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Descrição do endereço (opcional)',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPoint,
                initialZoom: 13,
                onTap: (tapPos, latlng) =>
                    setState(() => _selectedPoint = latlng),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'br.puc.ecobuzz',
                ),

                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedPoint,
                      color: Colors.deepOrange.withOpacity(0.15),
                      borderColor: Colors.deepOrange.withOpacity(0.6),
                      borderStrokeWidth: 2,
                      useRadiusInMeter: true,
                      radius: _radius,
                    ),
                  ],
                ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Raio de atuação: ${_radius.toInt()} m'),
                Slider(
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  value: _radius,
                  label: '${_radius.toInt()} m',
                  onChanged: (v) => setState(() => _radius = v),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
