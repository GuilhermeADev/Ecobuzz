import 'cpf_screen.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
// 1. Importe o formatador de máscara
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class BirthdateScreen extends StatefulWidget {
  const BirthdateScreen({super.key});

  @override
  _BirthdateScreenState createState() => _BirthdateScreenState();
}

class _BirthdateScreenState extends State<BirthdateScreen> {
  // 2. Variáveis para o campo de texto
  late TextEditingController _dateController;
  final _dateFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate; // Começa como nulo

  // --- NOVA VARIÁVEL DE ESTADO PARA O ERRO ---
  String? _dateErrorText;

  @override
  void initState() {
    super.initState();
    // 3. Inicializa o controller e remove a data padrão
    _dateController = TextEditingController();
    Intl.defaultLocale = 'pt_BR';
  }

  @override
  void dispose() {
    // 4. Lembre-se de dar dispose no controller
    _dateController.dispose();
    super.dispose();
  }

  // --- NOVA FUNÇÃO DE VALIDAÇÃO DE IDADE ---
  bool _isAdult(DateTime birthDate) {
    // Calcula a data de 18 anos atrás a partir de hoje
    final DateTime today = DateTime.now();
    final DateTime eighteenYearsAgo = DateTime(
      today.year - 18,
      today.month,
      today.day,
    );
    // Retorna true se a data de nascimento for ANTES ou IGUAL a 18 anos atrás
    return birthDate.isBefore(eighteenYearsAgo) ||
        birthDate.isAtSameMomentAs(eighteenYearsAgo);
  }

  void _onDateSelectedFromCalendar(DateTime selectedDay, DateTime focusedDay) {
    // Função para atualizar o estado a partir do calendário
    
    // --- VALIDAÇÃO DE IDADE ADICIONADA ---
    if (_isAdult(selectedDay)) {
      setState(() {
        _selectedDate = selectedDay;
        _focusedDay = focusedDay;
        // Atualiza o campo de texto
        _dateController.text = DateFormat('dd/MM/yyyy').format(selectedDay);
        _dateErrorText = null; // Limpa o erro
      });
    } else {
      // Se for menor de 18, não seleciona e mostra o erro
      setState(() {
        _selectedDate = null;
        _focusedDay = focusedDay; // Foca no dia clicado
         _dateController.text = DateFormat('dd/MM/yyyy').format(selectedDay);
        _dateErrorText = 'Você deve ter mais de 18 anos.';
      });
    }
  }

  void _onDateTyped(String value) {
    // Função para atualizar o estado a partir do campo de texto
    if (value.length == 10) {
      try {
        DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(value);
        
        // Validação 1: Formato (ex: 30/02 vira 01/03)
        if (DateFormat('dd/MM/yyyy').format(parsedDate) != value ||
            parsedDate.isAfter(DateTime.now()) ||
            parsedDate.isBefore(DateTime(1900))) {
              
          setState(() {
            _selectedDate = null;
            _dateErrorText = 'Data inválida.';
          });
          return;
        }

        // --- VALIDAÇÃO DE IDADE ADICIONADA ---
        // Validação 2: Idade
        if (_isAdult(parsedDate)) {
          setState(() {
            _selectedDate = parsedDate;
            _focusedDay = parsedDate;
            _dateErrorText = null; // Limpa o erro
          });
        } else {
          // Menor de 18
          setState(() {
            _selectedDate = null;
            _focusedDay = parsedDate;
            _dateErrorText = 'Você deve ter mais de 18 anos.';
          });
        }
      } catch (e) {
        // Formato inválido
        setState(() {
          _selectedDate = null;
           _dateErrorText = 'Data inválida.';
        });
      }
    } else {
      // Data incompleta
      setState(() {
        _selectedDate = null;
         _dateErrorText = null; // Limpa o erro enquanto digita
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color corFundo = Color(0xFF0A3C32);
    const Color corCalendario = Color(0xFFF8F8F8);
    const Color corDiaSelecionado = Colors.orange;
    const Color corTextoBotao = Colors.grey;

    return Scaffold(
      backgroundColor: corFundo,
      body: SafeArea(
        // 5. Adicionado SingleChildScrollView para evitar overflow com o teclado
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/ecobuzz_logo.png',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.recycling, color: Colors.white, size: 40),
                ),
                // Ajustado o Spacer para o SingleChildScrollView
                const SizedBox(height: 60),
                const Text(
                  'Selecione sua data\nde nascimento',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // --- 6. CAMPO DE DATA SUBSTITUÍDO POR TEXTFORMFIELD ---
                TextFormField(
                  controller: _dateController,
                  inputFormatters: [_dateFormatter],
                  keyboardType: TextInputType.datetime,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'DD/MM/AAAA',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today,
                        color: Colors.white, size: 20),
                    
                    // --- MOSTRA O ERRO AQUI ---
                    errorText: _dateErrorText,
                    errorStyle: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                  ),
                  onChanged: _onDateTyped, // Sincroniza ao digitar
                ),
                const SizedBox(height: 16),

                // --- CALENDÁRIO ---
                Container(
                  decoration: BoxDecoration(
                    color: corCalendario,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TableCalendar(
                    locale: 'pt_BR',
                    focusedDay: _focusedDay,
                    firstDay: DateTime(1900),
                    lastDay: DateTime.now(),
                    selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                    // 7. Chama a função de sincronia
                    onDaySelected: _onDateSelectedFromCalendar,
                    calendarFormat: CalendarFormat.month,
                    availableGestures: AvailableGestures.horizontalSwipe,
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: corDiaSelecionado.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: corDiaSelecionado,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60), // Ajustado o Spacer

                // --- BOTÕES DE NAVEGAÇÃO ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: corTextoBotao),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        // 8. Lógica de "avançar" agora depende de _selectedDate
                        // que é atualizado por *ambos* os inputs.
                        color: _selectedDate != null ? Colors.white : corTextoBotao,
                      ),
                      onPressed: _selectedDate == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CpfScreen(
                                    birthdate: _selectedDate!,
                                  ),
                                ),
                              );
                            },
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

