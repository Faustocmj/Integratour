import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'login_page.dart'; // Importando a tela de login

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inicializa o Firebase
  runApp(const MaterialApp(home: MainPage()));
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? selectedBusSize;
  int childrenCount = 0, menCount = 0, womenCount = 0, alcoholAdultsCount = 0;
  String? result, validationMessage;
  int busCapacity = 0;

  final firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> busSizes = [
    {'label': 'Pequeno (20 passageiros)', 'value': 'Pequeno', 'capacity': 20},
    {'label': 'Médio (30-50 passageiros)', 'value': 'Médio', 'capacity': 50},
    {'label': 'Grande (50-60 passageiros)', 'value': 'Grande', 'capacity': 60},
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Integratour'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Nova Pesquisa'),
              Tab(text: 'Pesquisas Concluídas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNewSearchTab(),
            _buildCompletedSearchesTab(),
          ],
        ),
        // Botão de voltar para a tela de login
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          child: const Icon(Icons.arrow_back),
        ),
      ),
    );
  }

  Widget _buildNewSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: _importFromTxt,
            child: const Text('Importar Arquivo .txt'),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Tamanho do Ônibus',
              border: OutlineInputBorder(),
            ),
            value: selectedBusSize,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  selectedBusSize = newValue;
                  busCapacity = busSizes
                      .firstWhere((bus) => bus['value'] == newValue)['capacity'];
                });
              }
            },
            items: busSizes.map<DropdownMenuItem<String>>((busSize) {
              return DropdownMenuItem<String>(
                value: busSize['value'] as String,
                child: Text(busSize['label']),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _buildStepperField(
            'Quantidade de Crianças',
            childrenCount,
            (val) => setState(() => childrenCount = val),
          ),
          const SizedBox(height: 20),
          _buildStepperField(
            'Quantidade de Homens',
            menCount,
            (val) => setState(() => menCount = val),
          ),
          const SizedBox(height: 20),
          _buildStepperField(
            'Quantidade de Mulheres',
            womenCount,
            (val) => setState(() => womenCount = val),
          ),
          const SizedBox(height: 20),
          _buildStepperField(
            'Adultos que consomem Álcool',
            alcoholAdultsCount,
            (val) => setState(() => alcoholAdultsCount = val),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_validateInputs()) {
                _finalizeSearch();
              }
            },
            child: const Text('Calcular e Finalizar'),
          ),
          const SizedBox(height: 20),
          if (result != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                result!,
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedSearchesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('pesquisas').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhuma pesquisa concluída.'));
        }
        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text('Ônibus: ${data['busSize']}'),
              subtitle: Text(
                'Crianças: ${data['children']}, Homens: ${data['men']}, Mulheres: ${data['women']}, Adultos com Álcool: ${data['alcoholAdults']}\nResultado: ${data['result']}',
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStepperField(String label, int value, Function(int) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text('$label: $value'),
        ),
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Future<void> _finalizeSearch() async {
    final data = {
      'busSize': selectedBusSize,
      'children': childrenCount,
      'men': menCount,
      'women': womenCount,
      'alcoholAdults': alcoholAdultsCount,
      'result': 'Pesquisa finalizada e salva!',
      'timestamp': FieldValue.serverTimestamp(),
    };
    await firestore.collection('pesquisas').add(data);
    setState(() {
      result = 'Pesquisa finalizada e salva!';
    });
  }

  Future<void> _importFromTxt() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (result != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final lines = content.split('\n');
      if (lines.length >= 4) {
        setState(() {
          childrenCount = int.parse(lines[0]);
          menCount = int.parse(lines[1]);
          womenCount = int.parse(lines[2]);
          alcoholAdultsCount = int.parse(lines[3]);
        });
      }
    }
  }

  bool _validateInputs() {
    final totalPassengers = childrenCount + menCount + womenCount;
    if (totalPassengers > busCapacity) {
      setState(() {
        validationMessage = 'Total de passageiros excede a capacidade do ônibus.';
      });
      return false;
    }
    return true;
  }
}
