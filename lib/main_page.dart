import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'firebase_options.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
  final User? user = FirebaseAuth.instance.currentUser;

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
          const SizedBox(height: 20),
          _buildBusSizeDropdown(),
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
              if (_validateInputs() && _validateAlcohol()) {
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
          if (validationMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                validationMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusSizeDropdown() {
    return DropdownButtonFormField<String>(
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
    );
  }

  Widget _buildCompletedSearchesTab() {
    if (user == null) {
      return const Center(child: Text('Usuário não autenticado.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('pesquisas')
          .where('userId', isEqualTo: user!.uid)
          .snapshots(),
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
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteSearch(doc.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _deleteSearch(String docId) async {
    try {
      await firestore.collection('pesquisas').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesquisa excluída com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir pesquisa: $e')),
      );
    }
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
    final geminiResponse = await _sendToGeminiAI();
    if (geminiResponse != null) {
      final data = {
        'userId': user!.uid,
        'busSize': selectedBusSize,
        'children': childrenCount,
        'men': menCount,
        'women': womenCount,
        'alcoholAdults': alcoholAdultsCount,
        'result': geminiResponse,
        'timestamp': FieldValue.serverTimestamp(),
      };
      await firestore.collection('pesquisas').add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pesquisa finalizada e salva!')),
      );

      setState(() {
        result = geminiResponse;
        validationMessage = null;
      });
    }
  }

  Future<String?> _sendToGeminiAI() async {
    const apiKey =
        'AIzaSyCuPxSLKzhD2KdrU44G4oII6z9k5PajeSk';

    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );

    final prompt = '''
      Em uma viagem de ônibus de 8 horas, precisamos calcular a quantidade necessária de alimentos e bebidas para um grupo de passageiros com as seguintes características:
      - $childrenCount criança e adolescente (até 17 anos)
      - $menCount número de homens adultos.
      - $womenCount número de mulheres adultas.
      - $alcoholAdultsCount número de adultos que consomem álcool (só os adultos bebem álcool).
      Com base nas informações acima, recomende as quantidades necessárias de:
      - Lanches naturais
      - Sucos
      - Água
      - Refrigerante
      - Cerveja (somente para os adultos que consomem álcool)

      As quantidades recomendadas devem ser fornecidas de acordo com os seguintes critérios:

      - Lanches naturais: quantidade suficiente para alimentar todos, considerando as necessidades médias para cada tipo de passageiro (crianças, homens, mulheres, e adultos com álcool).
      - Sucos: quantidade adequada para todos os passageiros, levando em consideração a faixa etária e preferências gerais de consumo.
      - Água: quantidade suficiente para manter todos hidratados durante a viagem de 8 horas, considerando as necessidades médias diárias de hidratação.
      - Refrigerante: quantidade suficiente para atender às necessidades médias de consumo de refrigerante dos passageiros adultos, considerando a proporção de homens e mulheres.
      - Cerveja: quantidade recomendada apenas para os adultos que consomem álcool, com base na quantidade média consumida por adulto em viagens longas.

      Por favor, forneça as quantidades para cada item na seguinte estrutura, sem explicações ou observações adicionais:

      - Lanches naturais: (coloque aqui a quantidade)
      - Sucos: (coloque aqui a quantidade)
      - Água: (coloque aqui a quantidade)
      - Refrigerante: (coloque aqui a quantidade)
      - Cerveja: (coloque aqui a quantidade)
    ''';

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text?.isNotEmpty ?? false) {
      return response.text
          ?.trim();
    } else {
      setState(() {
        validationMessage = 'Erro ao obter resposta do Gemini.';
      });
      return null;
    }
  }

  bool _validateInputs() {
    final totalPassengers = childrenCount + menCount + womenCount;
    if (totalPassengers > busCapacity) {
      setState(() {
        validationMessage =
            'Total de passageiros excede a capacidade do ônibus.';
      });
      return false;
    }
    return true;
  }

  bool _validateAlcohol() {
    final totalAdults = menCount + womenCount;
    if (alcoholAdultsCount > 0 && alcoholAdultsCount > totalAdults) {
      setState(() {
        validationMessage = 'Quantidade de adultos necessita ser maior que a quantidade de consumidores de alcool';
      });
      return false;
    }
    return true;
  }
}
