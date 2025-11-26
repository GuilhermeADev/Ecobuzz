import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'transport_screen.dart';

class AddressScreen extends StatefulWidget {
  final List<String> selectedMaterials;

  const AddressScreen({super.key, required this.selectedMaterials});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final MapController _mapController = MapController();

  LatLng _selectedPoint = LatLng(-23.55052, -46.633308);
  double _selectedRadius = 500;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TransportScreen(
            selectedMaterials: widget.selectedMaterials,
            atuacaoAddress: _addressController.text,
            atuacaoLat: _selectedPoint.latitude,
            atuacaoLng: _selectedPoint.longitude,
            atuacaoRadius: _selectedRadius,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color corFundo = Color(0xFF0A3C32);
    const Color corTextoBotao = Colors.grey;

    return Scaffold(
      backgroundColor: corFundo,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/ecobuzz_logo.png',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.recycling, color: Colors.white, size: 40),
                ),

                const SizedBox(height: 60),

                const Text(
                  'E onde você coleta\nos materiais?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 32),

                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar endereço (Ex: Bairro, Cidade)',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira sua região de atuação.';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 320,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedPoint,
                        initialZoom: 13,
                        onTap: (tapPosition, point) {
                          setState(() {
                            _selectedPoint = point;
                          });
                        },
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
                              color: Colors.deepOrange.withOpacity(0.2),
                              borderStrokeWidth: 2,
                              borderColor: Colors.deepOrange,
                              useRadiusInMeter: true,
                              radius: _selectedRadius,
                            )
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
                ),

                const SizedBox(height: 12),

                Text(
                  'Raio de atuação: ${_selectedRadius.toInt()} m',
                  style: const TextStyle(color: Colors.white70),
                ),

                Slider(
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  value: _selectedRadius,
                  label: '${_selectedRadius.toInt()} m',
                  onChanged: (v) => setState(() => _selectedRadius = v),
                ),

                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.my_location),
                      label: const Text('Usar este ponto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () {
                        _addressController.text =
                            '${_selectedPoint.latitude.toStringAsFixed(6)}, '
                            '${_selectedPoint.longitude.toStringAsFixed(6)}';
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      child: const Text(
                        'Limpar',
                        style: TextStyle(color: Colors.white70),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedPoint = LatLng(-23.55052, -46.633308);
                          _selectedRadius = 500;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: corTextoBotao),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white),
                      onPressed: _nextStep,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
