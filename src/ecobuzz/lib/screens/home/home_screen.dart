import 'package:ecobuzz/widgets/agenda_view.dart';
import 'package:flutter/material.dart';
import 'package:ecobuzz/screens/home/create_pickup_screen.dart';
import 'package:ecobuzz/screens/profile/profile_screen.dart';
import 'package:ecobuzz/screens/home/collectors_screen.dart';
import 'package:ecobuzz/screens/home/notifications_screen.dart';


class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  // Telas para cada aba (não static para permitir widgets que dependam de estado)
  late final List<Widget> _views;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _views = <Widget>[
      const AgendaView(), // Aba 0 (Home)
      const CreatePickupScreen(), // Aba 1 (Lupa)
      const CollectorsScreen(), // Aba 2 (Catadores)
      const NotificationsScreen(), // Aba 3 (Sino)
      const ProfileScreen(), // Aba 4 (Perfil)
    ];
  }

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Colors.deepOrange;
    const Color inactiveColor = Colors.grey;

    return Scaffold(
      extendBody: true,
      body: _views.elementAt(_selectedIndex),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () { /* Ação do botão central */ },
        backgroundColor: activeColor,
        foregroundColor: Colors.white,
        elevation: 2.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner_outlined),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.home, color: _selectedIndex == 0 ? activeColor : inactiveColor),
                onPressed: () => _onItemTapped(0),
              ),
              IconButton(
                // Ícone mudado para "adicionar" para fazer mais sentido
                icon: Icon(Icons.add_location_alt_outlined, color: _selectedIndex == 1 ? activeColor : inactiveColor), 
                onPressed: () => _onItemTapped(1),
              ),
              IconButton(
                icon: Icon(Icons.people, color: _selectedIndex == 2 ? activeColor : inactiveColor),
                onPressed: () => _onItemTapped(2),
              ),
              const SizedBox(width: 40), // Espaço para o FAB
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: _selectedIndex == 3 ? activeColor : inactiveColor),
                onPressed: () => _onItemTapped(3),
              ),
              IconButton(
                icon: Icon(Icons.person_outline, color: _selectedIndex == 4 ? activeColor : inactiveColor),
                onPressed: () => _onItemTapped(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
