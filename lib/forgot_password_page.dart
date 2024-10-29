import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperação de Senha - Integratour'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Campo de Email
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              // Botão de Recuperar Senha
              ElevatedButton(
                onPressed: () {
                  // Ação para recuperação de senha
                },
                child: const Text('Enviar Email de Recuperação'),
              ),
              const SizedBox(height: 10),
              // Voltar para Login
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Volta para a tela de login
                },
                child: const Text('Voltar para Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
